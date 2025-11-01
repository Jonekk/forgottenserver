#include "randomitemspawner.hpp"

#include "pugixml.hpp"
#include "game.h"
#include "gauss.hpp"
#include "map.h"
#include "tile.h"
#include "item.h"
#include "tools.h"
#include "scheduler.h"
#include "position.h"

#include <algorithm>
#include <cmath>
#include <optional>
#include <unordered_set>

extern Scheduler g_scheduler;
extern Game g_game;

// Keep a pointer to the active spawner instance for static callbacks
static RandomItemSpawner* g_ris_self = nullptr;

// ----------------------------- Utilities -------------------------------------

static constexpr uint16_t kMaxTileAttemptsPerTry = 20; // cap per attempt

static inline int32_t urand(int32_t a, int32_t b) { return uniform_random(a, b); }

static RISTimeMask parseTimeMaskCSV(const std::string& csv) {
    if (csv.empty()) return 0;
    RISTimeMask mask = 0;
    std::string s = asLowerCaseString(csv);
    size_t i = 0;
    auto add = [&](const std::string& tok){
        if (tok == "sunrise") mask |= static_cast<uint8_t>(RISTime::Sunrise);
        else if (tok == "sunset") mask |= static_cast<uint8_t>(RISTime::Sunset);
        else if (tok == "night") mask |= static_cast<uint8_t>(RISTime::Night);
        else if (tok == "day") mask |= static_cast<uint8_t>(RISTime::Day);
    };
    while (i <= s.size()) {
        size_t j = s.find(',', i);
        std::string tok = (j == std::string::npos) ? s.substr(i) : s.substr(i, j-i);
        tok.erase(0, tok.find_first_not_of(" \t\r\n"));
        if (!tok.empty()) {
            size_t end = tok.find_last_not_of(" \t\r\n");
            add(tok.substr(0, end + 1));
        }
        if (j == std::string::npos) break;
        i = j + 1;
    }
    return mask;
}

static bool isAllowedNow(RISTimeMask mask) {
    if (mask == 0) return true; // any time
    Game::TimeOfDay tod = g_game.getTimeOfDay(); // expects TOD_SUNRISE/TOD_SUNSET/TOD_NIGHT/TOD_DAY
    uint8_t now = 0;
    switch (tod) {
        case Game::TimeOfDay::TOD_SUNRISE: now = static_cast<uint8_t>(RISTime::Sunrise); break;
        case Game::TimeOfDay::TOD_SUNSET:  now = static_cast<uint8_t>(RISTime::Sunset);  break;
        case Game::TimeOfDay::TOD_NIGHT:   now = static_cast<uint8_t>(RISTime::Night);   break;
        case Game::TimeOfDay::TOD_DAY:     now = static_cast<uint8_t>(RISTime::Day);     break;
        default:                           now = static_cast<uint8_t>(RISTime::Day);     break;
    }
    return (mask & now) != 0;
}

static inline std::optional<uint32_t> parseU32(const std::string& s) {
    if (s.empty()) return std::nullopt;
    char* end = nullptr; unsigned long v = strtoul(s.c_str(), &end, 10);
    if (!end || *end) return std::nullopt; return static_cast<uint32_t>(v);
}

static uint32_t parseDurationMs(const std::string& txt) {
    if (txt.empty()) return 0;
    char* end = nullptr; long v = strtol(txt.c_str(), &end, 10);
    if (!end || *end == '\0') return static_cast<uint32_t>(std::max<long>(0, v));
    const std::string unit(end);
    uint32_t base = static_cast<uint32_t>(std::max<long>(0, v));
    if (unit == "ms") return base;
    if (unit == "s")  return base * 1000u;
    if (unit == "m")  return base * 60u * 1000u;
    if (unit == "h")  return base * 60u * 60u * 1000u;
    return base;
}

// ---------------------------- XML helpers ------------------------------------

static void loadAttrsNode(const pugi::xml_node& attrsNode, std::vector<RISCustomAttr>& out) {
    for (auto attr : attrsNode.children("attr")) {
        RISCustomAttr a;
        a.key   = attr.attribute("key").as_string("");
        a.type  = attr.attribute("type").as_string("string");
        a.value = attr.attribute("value").as_string("");
        if (!a.key.empty()) out.emplace_back(std::move(a));
    }
}

static void loadDecayNode(const pugi::xml_node& node, RISDecayCfg& out) {
    if (!node) return;
    out.enabled   = true;
    out.useNative = node.attribute("useNative").as_bool(false);
    out.timeMs    = parseDurationMs(node.attribute("time").as_string("0"));
    if (auto to = node.attribute("to")) {
        out.toId = static_cast<uint16_t>(to.as_uint());
    }
}

static void loadSpawnNode(const pugi::xml_node& node, RISSpawnCfg& out) {
    out.itemId = node.attribute("itemid").as_uint(0);
    const std::string count = node.attribute("count").as_string("");
    if (!count.empty()) {
        const auto dots = count.find("..");
        if (dots != std::string::npos) {
            out.countMin = std::max<uint16_t>(1, static_cast<uint16_t>(atoi(count.substr(0, dots).c_str())));
            out.countMax = std::max<uint16_t>(out.countMin, static_cast<uint16_t>(atoi(count.substr(dots+2).c_str())));
        } else {
            out.countMin = out.countMax = static_cast<uint16_t>(std::max(1, atoi(count.c_str())));
        }
    }
    const std::string chance = node.attribute("chance").as_string("");
    if (!chance.empty()) {
        out.chancePct = static_cast<uint8_t>(std::clamp<int>(atoi(chance.c_str()), 0, 100));
    }
    if (auto tod = node.attribute("timeOfDay")) {
        out.timeMask = parseTimeMaskCSV(tod.as_string());
    }
    loadDecayNode(node.child("decay"), out.decay);
    if (auto attrs = node.child("attrs")) {
        loadAttrsNode(attrs, out.attrs);
    }
}

// --------------------------- Class methods -----------------------------------

bool RandomItemSpawner::loadFromXml(const std::string& path) {
    pugi::xml_document doc;
    pugi::xml_parse_result result = doc.load_file(path.c_str());
    if (!result) {
        std::cout << "[RIS] Failed to load XML: " << path << " (" << result.description() << ")\n";
        return false;
    }

    auto root = doc.child("randomItemSpawner");
    if (!root) {
        std::cout << "[RIS] XML root <randomItemSpawner> missing.\n";
        return false;
    }

    intervalMs_ = root.attribute("checkIntervalMs").as_uint(15000);

    areas_.clear();

    for (auto area : root.children("area")) {
        AreaRuntime ar;
        ar.cfg.id = area.attribute("id").as_string("");
        // Center position
        Position center{};
        center.x = static_cast<uint16_t>(area.attribute("x").as_uint());
        center.y = static_cast<uint16_t>(area.attribute("y").as_uint());
        center.z = static_cast<uint8_t>(area.attribute("z").as_uint());
        ar.cfg.centerFallback = center; ar.cfg.centerPtr = nullptr; // fixed center

        ar.cfg.radius   = static_cast<uint16_t>(area.attribute("radius").as_uint(1));
        ar.cfg.spawnChancePerCheck = area.attribute("spawnChancePerCheck").as_double(0.10);
        ar.cfg.attemptsPerCheck    = area.attribute("attemptsPerCheck").as_uint(1);
        ar.cfg.maxActive           = area.attribute("maxActive").as_uint(10);
        ar.cfg.timeMask            = parseTimeMaskCSV(area.attribute("timeOfDay").as_string(""));

        if (auto at = area.child("allowedTiles")) {
            for (auto t : at.children("tile")) {
                const uint16_t id = static_cast<uint16_t>(t.attribute("id").as_uint());
                if (id != 0) {
                    ar.cfg.allowedGroundIds.push_back(id);
                    ar.allowedSet.insert(id);
                }
            }
        }

        if (auto itemsNode = area.child("items")) {
            uint64_t run = 0;
            for (auto it : itemsNode.children("item")) {
                SpawnItemDef si;
                si.itemId = static_cast<uint16_t>(it.attribute("id").as_uint());
                si.weight = it.attribute("weight").as_uint(1);
                if (si.itemId == 0 || si.weight == 0) continue;
                ar.cfg.items.push_back(si);
                run += si.weight;
                ar.itemPrefix.push_back(static_cast<uint32_t>(run));
            }
        }

        if (auto spawnsNode = area.child("spawns")) {
            for (auto s : spawnsNode.children("spawn")) {
                RISSpawnCfg cfg; loadSpawnNode(s, cfg);
                if (cfg.itemId != 0) {
                    if (cfg.timeMask == 0) cfg.timeMask = ar.cfg.timeMask; // inherit
                    ar.cfg.spawns.emplace_back(std::move(cfg));
                }
            }
        }

        areas_.emplace_back(std::move(ar));
    }

    // Optional initial resync
    resyncCountsOccasionally();
    return true;
}

void RandomItemSpawner::start() {
    if (running_) return;
    running_ = true;
    g_ris_self = this; // register instance for static callbacks
    scheduleTick();
}

void RandomItemSpawner::stop() { 
    running_ = false; 
    if (g_ris_self == this) g_ris_self = nullptr; 
}

void RandomItemSpawner::scheduleTick() {
    if (!running_) return;
    const uint32_t delay = std::max<uint32_t>(1000, intervalMs_);
    g_scheduler.addEvent(createSchedulerTask(delay, [this]() {
        if (!running_) return;
        runOnce();
        scheduleTick();
    }));
}

void RandomItemSpawner::runOnce() {
    for (auto& ar : areas_) {
        if (ar.cfg.maxActive > 0 && ar.active >= ar.cfg.maxActive) continue;
        const int roll = urand(1, 100);
        if (roll > static_cast<int>(ar.cfg.spawnChancePerCheck * 100.0)) continue;

        const uint32_t attempts = std::max<uint32_t>(1, ar.cfg.attemptsPerCheck);
        for (uint32_t i = 0; i < attempts; ++i) {
            if (trySpawnInArea(ar)) {
                if (ar.cfg.maxActive > 0 && ar.active >= ar.cfg.maxActive) break;
            }
        }
    }

    if (urand(1, 20) == 1) resyncCountsOccasionally();
}

uint16_t RandomItemSpawner::pickRandomItemId(const AreaRuntime& ar) const {
    if (ar.itemPrefix.empty()) return 0;
    const int32_t r = urand(1, static_cast<int32_t>(ar.itemPrefix.back()));
    const auto it = std::lower_bound(ar.itemPrefix.begin(), ar.itemPrefix.end(), static_cast<uint32_t>(r));
    const size_t idx = static_cast<size_t>(it - ar.itemPrefix.begin());
    return ar.cfg.items[idx].itemId;
}

static void pickRandomOffset(int16_t radius, int16_t& dx, int16_t& dy) {
    dx = static_cast<int16_t>(urand(-radius, radius));
    const int16_t span = static_cast<int16_t>(std::sqrt(radius*radius - dx*dx));
    dy = static_cast<int16_t>(urand(-span, span));
}

bool RandomItemSpawner::tileAllowed(const AreaRuntime& ar, const Position& pos) const {
    Tile* tile = g_game.map.getTile(pos);
    if (!tile) return false;

    if (!tile->getGround()) return false;
    if (tile->hasFlag(TILESTATE_BLOCKSOLID)) return false;
    if (tile->hasFlag(TILESTATE_FLOORCHANGE)) return false;

    if (!ar.allowedSet.empty()) {
        const Item* ground = tile->getGround();
        const uint16_t groundId = ground ? ground->getID() : 0;
        if (groundId == 0 || ar.allowedSet.find(groundId) == ar.allowedSet.end()) return false;
    }

    // Do not allow multiple RIS items on the same tile
    const uint32_t n = tile->getThingCount();
    for (uint32_t i = 0; i < n; ++i) {
        Thing* th = tile->getThing(i);
        Item* it = th ? th->getItem() : nullptr;
        if (!it) continue;
        if (it->isMoveable() || it->isBlocking()) return false;
        //auto tok = it->getCustomAttribute("ris:token");
        //if (tok && boost::get<std::string>(&(tok->value))) return false; // already an RIS-spawned item here
    }

    const Item* top = tile->getTopDownItem();
    if (top && top->isBlocking()) return false;

    return true;
}

bool RandomItemSpawner::trySpawnInArea(AreaRuntime& ar) {
    RISSpawnCfg chosen{};
    bool haveExplicit = false;

    if (!ar.cfg.spawns.empty()) {
        std::vector<size_t> candidates;
        candidates.reserve(ar.cfg.spawns.size());
        for (size_t i = 0; i < ar.cfg.spawns.size(); ++i) {
            const auto& s = ar.cfg.spawns[i];
            if (!isAllowedNow(s.timeMask)) continue;
            if (urand(1, 100) > s.chancePct) continue;
            candidates.push_back(i);
        }
        if (!candidates.empty()) {
            const size_t pick = static_cast<size_t>(urand(0, static_cast<int32_t>(candidates.size()-1)));
            chosen = ar.cfg.spawns[candidates[pick]];
            haveExplicit = true;
        } else {
            return false; // none eligible right now
        }
    } else {
        if (!isAllowedNow(ar.cfg.timeMask)) return false;
        const uint16_t itemId = pickRandomItemId(ar);
        if (itemId == 0) return false;
        chosen.itemId = itemId;
        chosen.countMin = chosen.countMax = 1;
    }

    // Find a valid tile
    int16_t dx = 0, dy = 0; Tile* tile = nullptr; Position pos{};
    for (uint32_t tries = 0; tries < kMaxTileAttemptsPerTry; ++tries) {
        pickRandomOffset(static_cast<int16_t>(ar.cfg.radius), dx, dy);
        const Position center = ar.cfg.centerPtr ? *ar.cfg.centerPtr : ar.cfg.centerFallback;
        pos = Position{ static_cast<uint16_t>(center.x + dx), static_cast<uint16_t>(center.y + dy), center.z };
        if (!tileAllowed(ar, pos)) continue;
        tile = g_game.map.getTile(pos);
        if (!tile) continue;

        const uint16_t count = static_cast<uint16_t>(urand(chosen.countMin, chosen.countMax));
        Item* item = Item::CreateItem(chosen.itemId, count);
        if (!item) continue;

        std::string token_name = "ris:token";
        std::string token_val = ar.cfg.id;
        item->setCustomAttribute<std::string>(token_name, token_val);

        applyCustomAttributes(item, chosen.attrs);

        if (g_game.internalAddItem(tile, item, INDEX_WHEREEVER, FLAG_NOLIMIT) != RETURNVALUE_NOERROR) {
            delete item; // or g_game.releaseItem(item) depending on your base
            continue;
        }

        
        maybeStartDecay(tile, item, chosen);
        ++ar.active;
        return true;
    }

    return false;
}

// ---------------------------- Decay helpers ----------------------------------

void RandomItemSpawner::applyCustomAttributes(Item* item, const std::vector<RISCustomAttr>& attrs) {
    if (!item) return;

    for (const auto& a : attrs) {
        std::string key = a.key; // API expects non-const std::string&
        const std::string keyLower = asLowerCaseString(a.key);

        if (keyLower == "quality") {
            if (auto v = parseU32(a.value)) {
                int quality = int(gaussianRandom50p(*v));
                item->setQuality(quality);
            }
            continue;
        }

        if (a.type == "number") {
            item->setCustomAttribute<int64_t>(key, static_cast<int64_t>(strtoll(a.value.c_str(), nullptr, 10)));
        } else if (a.type == "boolean") {
            const bool b = (a.value == "true" || a.value == "1");
            item->setCustomAttribute<bool>(key, b);
        } else {
            item->setCustomAttribute<std::string>(key, a.value);
        }
    }
}


void RandomItemSpawner::startNativeDecay(Item* item, uint32_t durationMs) {
    if (!item) return;
    if (durationMs > 0) item->setDuration(durationMs);
    g_game.startDecay(item);
}

void RandomItemSpawner::manualDecayReplace(const Position pos, uint16_t toItemId,
                                           const std::vector<RISCustomAttr> attrs) {
    Tile* tile = g_game.map.getTile(pos);
    if (!tile) return;

    Item* found = nullptr;
    const uint32_t n = tile->getThingCount();
    for (uint32_t i = 0; i < n; ++i) {
        Thing* th = tile->getThing(i);
        Item* it = th ? th->getItem() : nullptr;
        if (!it) continue;
        auto tok = it->getCustomAttribute("ris:token");
        if (!tok) continue;

        found = it;
        break;
    }
    if (!found) return;

    g_game.internalRemoveItem(found);
    if (g_ris_self) g_ris_self->onItemRemoved(found);

    // Disappear if no replacement requested
    if (toItemId == 0) return;

    Item* replacement = Item::CreateItem(toItemId);
    if (!replacement) return;
    applyCustomAttributes(replacement, attrs);
    g_game.internalAddItem(tile, replacement, INDEX_WHEREEVER, FLAG_NOLIMIT);
}

void RandomItemSpawner::maybeStartDecay(Tile* where, Item* item, const RISSpawnCfg& cfg) {
    if (!item || !cfg.decay.enabled) return;

    // Native (TFS) decay: optional per-instance duration override, then start
    if (cfg.decay.useNative) {
        if (cfg.decay.timeMs > 0) {
            item->setDuration(cfg.decay.timeMs);
        }
        g_game.startDecay(item);
        return;
    }

    // Manual decay: require time
    if (cfg.decay.timeMs == 0) return;

    const Position pos = where->getPosition();
    const uint16_t toIdOrZero = cfg.decay.toId ? static_cast<uint16_t>(*cfg.decay.toId) : 0; // 0 => disappear
    const auto attrsCopy = cfg.attrs; // capture by value

    g_scheduler.addEvent(createSchedulerTask(cfg.decay.timeMs, [pos, toIdOrZero, attrsCopy]() {
        RandomItemSpawner::manualDecayReplace(pos, toIdOrZero, attrsCopy);
    }));
}

// ------------------------ Count resync & helpers -----------------------------

bool RandomItemSpawner::isRISItem(const Item* item) {
    if (!item) return false;
    auto tok = item->getCustomAttribute("ris:token");
    if (!tok) return false;
    return boost::get<std::string>(&(tok->value)) != nullptr;
}

void RandomItemSpawner::onItemRemoved(Item* item) {
    if (!isRISItem(item)) return;
    const size_t idx = findAreaForItem(item);
    if (idx < areas_.size()) {
        auto& ar = areas_[idx];
        if (ar.active > 0) --ar.active;
    }
    std::cout <<"removing spawned item" <<std::endl;
    item->removeCustomAttribute("ris:token");
    item->setDecaying(DECAYING_FALSE);
    item->removeAttribute(ITEM_ATTRIBUTE_DECAYSTATE);
	item->removeAttribute(ITEM_ATTRIBUTE_DURATION);
}

size_t RandomItemSpawner::findAreaForItem(const Item *it) const {
    for (size_t i = 0; i < areas_.size(); ++i) {
        const auto& areaId = areas_[i].cfg.id;
        auto tok = it->getCustomAttribute("ris:token");
        const std::string* token_str = boost::get<std::string>(&(tok->value));
        if (tok && *token_str == areaId) return i;
    }
    return areas_.size();
}

void RandomItemSpawner::resyncCountsOccasionally() {
    for (auto& ar : areas_) ar.active = 0;
    for (const auto& ar : areas_) {
        const auto& cfg = ar.cfg;
        const Position center = cfg.centerPtr ? *cfg.centerPtr : cfg.centerFallback;
        const int16_t r = static_cast<int16_t>(cfg.radius);
        for (int16_t dx = -r; dx <= r; ++dx) {
            for (int16_t dy = -r; dy <= r; ++dy) {
                if (dx*dx + dy*dy > r*r) continue;
                Position pos{ static_cast<uint16_t>(center.x + dx), static_cast<uint16_t>(center.y + dy), center.z };
                Tile* tile = g_game.map.getTile(pos);
                if (!tile) continue;
                const uint32_t n = tile->getThingCount();
                for (uint32_t i = 0; i < n; ++i) {
                    Thing* th = tile->getThing(i);
                    Item* it = th ? th->getItem() : nullptr;
                    if (!it) continue;
                    if (!isRISItem(it)) continue;
                    const size_t owner = findAreaForItem(it);
                    if (owner < areas_.size()) ++const_cast<AreaRuntime&>(areas_[owner]).active;
                }
            }
        }
    }
}
