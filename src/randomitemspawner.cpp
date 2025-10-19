#include "randomitemspawner.hpp"

#include "pugixml.hpp"
#include "game.h"
#include "map.h"
#include "tile.h"
#include "item.h"
#include "tools.h" // if you want TFS helpers
#include "scheduler.h"

#include <algorithm>
#include <iostream>

extern Scheduler g_scheduler;

static constexpr uint16_t kMaxTileAttemptsPerTry = 20;
static constexpr uint32_t kResyncEveryNTicks = 60;

// ---------------- XML loader ----------------

bool RandomItemSpawner::loadFromXml(const std::string& file) {
    pugi::xml_document doc;
    pugi::xml_parse_result result = doc.load_file(file.c_str());
    if (!result) {
        std::cout << "[RandomItemSpawner] XML parse error: " << result.description() << "\n";
        return false;
    }

    auto root = doc.child("randomspawns");
    if (!root) {
        std::cout << "[RandomItemSpawner] Missing <randomspawns> root\n";
        return false;
    }

    if (auto attr = root.attribute("checkIntervalMs")) {
        checkIntervalMs_ = attr.as_uint(10000);
    }
    if (auto attr = root.attribute("actionIdTag")) {
        actionIdTag_ = static_cast<uint16_t>(attr.as_uint(65000));
    }

    areas_.clear();

    for (auto area : root.children("area")) {
        AreaRuntime ar;

        ar.cfg.id = area.attribute("id").as_string();
        ar.cfg.center.x = static_cast<uint16_t>(area.attribute("x").as_uint());
        ar.cfg.center.y = static_cast<uint16_t>(area.attribute("y").as_uint());
        ar.cfg.center.z = static_cast<uint8_t>(area.attribute("z").as_uint());
        ar.cfg.radius   = static_cast<uint16_t>(area.attribute("radius").as_uint());
        ar.cfg.spawnChancePerCheck = area.attribute("spawnChancePerCheck").as_double(0.10);
        ar.cfg.attemptsPerCheck    = area.attribute("attemptsPerCheck").as_uint(1);
        ar.cfg.maxActive           = area.attribute("maxActive").as_uint(10);

        // allowed ground tiles (IDs)
        if (auto at = area.child("allowedTiles")) {
            for (auto t : at.children("tile")) {
                const uint16_t id = static_cast<uint16_t>(t.attribute("id").as_uint());
                if (id != 0) {
                    ar.cfg.allowedGroundIds.push_back(id);
                    ar.allowedSet.insert(id);
                }
            }
        }

        // item pool
        auto itemsNode = area.child("items");
        uint64_t sum = 0;
        for (auto it : itemsNode.children("item")) {
            SpawnItemDef si;
            si.itemId = static_cast<uint16_t>(it.attribute("id").as_uint());
            si.weight = it.attribute("weight").as_uint(1);
            if (si.itemId == 0 || si.weight == 0) continue;
            ar.cfg.items.push_back(si);
            sum += si.weight;
        }

        if (ar.cfg.items.empty()) {
            std::cout << "[RandomItemSpawner] area '" << ar.cfg.id << "' has no items; skipping\n";
            continue;
        }

        rebuildItemPrefix(ar);
        areas_.push_back(std::move(ar));
    }

    std::cout << "[RandomItemSpawner] Loaded " << areas_.size()
              << " areas from " << file << ", checkInterval=" << checkIntervalMs_
              << "ms, actionIdTag=" << actionIdTag_ << "\n";
    return true;
}

// ---------------- lifecycle ----------------

void RandomItemSpawner::setCheckInterval(uint32_t ms) { checkIntervalMs_ = ms; }

void RandomItemSpawner::start() {
    // schedule periodic tick
    g_scheduler.addEvent(createSchedulerTask(checkIntervalMs_, [this]() {
        this->tick();
        this->start(); // reschedule self
    }));
}

void RandomItemSpawner::stop() {
    // If you keep a task id, cancel here
}

// ---------------- tick & core logic ----------------

void RandomItemSpawner::tick() {
    for (auto& ar : areas_) {
        if (ar.active >= ar.cfg.maxActive) {
            continue;
        }

        // chance gate
        int32_t roll = uniform_random(0, 999999);
        const int32_t threshold = static_cast<int32_t>(ar.cfg.spawnChancePerCheck * 1000000.0);
        if (roll > threshold) {
            continue;
        }

        uint32_t attempts = std::max<uint32_t>(1, ar.cfg.attemptsPerCheck);
        for (uint32_t i = 0; i < attempts && ar.active < ar.cfg.maxActive; ++i) {
            trySpawnInArea(ar);
        }
    }

    if (++resyncCounter_ >= kResyncEveryNTicks) {
        resyncCounter_ = 0;
        resyncCountsOccasionally();
    }
}

bool RandomItemSpawner::trySpawnInArea(AreaRuntime& ar) {
    Position pos;
    for (uint16_t tries = 0; tries < kMaxTileAttemptsPerTry; ++tries) {
        if (!pickRandomTile(ar, pos)) continue;
        if (!tileAllowed(ar, pos)) continue;

        const uint16_t itemId = pickRandomItemId(ar);
        if (placeItemAndTrack(ar, pos, itemId)) {
            return true;
        }
    }
    return false;
}

bool RandomItemSpawner::pickRandomTile(const AreaRuntime& ar, Position& out) const {
    const int32_t dx = uniform_random(-static_cast<int32_t>(ar.cfg.radius),
                                       static_cast<int32_t>(ar.cfg.radius));
    const int32_t dy = uniform_random(-static_cast<int32_t>(ar.cfg.radius),
                                       static_cast<int32_t>(ar.cfg.radius));
    out.x = static_cast<uint16_t>(ar.cfg.center.x + dx);
    out.y = static_cast<uint16_t>(ar.cfg.center.y + dy);
    out.z = ar.cfg.center.z;
    return true;
}

void RandomItemSpawner::rebuildItemPrefix(AreaRuntime& ar) {
    ar.itemPrefix.clear();
    ar.itemPrefix.reserve(ar.cfg.items.size());
    uint32_t run = 0;
    for (const auto& si : ar.cfg.items) {
        run += si.weight;
        ar.itemPrefix.push_back(run);
    }
}

uint16_t RandomItemSpawner::pickRandomItemId(const AreaRuntime& ar) const {
    const auto& pref = ar.itemPrefix;
    const int32_t r = uniform_random(1, static_cast<int32_t>(pref.back()));
    const auto it = std::lower_bound(pref.begin(), pref.end(), static_cast<uint32_t>(r));
    const size_t idx = static_cast<size_t>(it - pref.begin());
    return ar.cfg.items[idx].itemId;
}

bool RandomItemSpawner::tileAllowed(const AreaRuntime& ar, const Position& pos) const {
    Tile* tile = g_game.map.getTile(pos);
    if (!tile) return false;

    if (!tile->getGround()) return false;
    if (tile->hasFlag(TILESTATE_BLOCKSOLID)) return false;
    if (tile->hasFlag(TILESTATE_FLOORCHANGE)) return false;

    // require specific ground IDs if provided
    if (!ar.allowedSet.empty()) {
        const uint16_t groundId = tile->getGround()->getID(); // adjust if your API is getServerID()
        if (ar.allowedSet.find(groundId) == ar.allowedSet.end()) return false;
    }

    const Item* top = tile->getTopDownItem(); // adjust to your fork (getTopTopItem etc.)
    if (top && top->isBlocking()) return false;

    return true;
}

bool RandomItemSpawner::placeItemAndTrack(AreaRuntime& ar, const Position& pos, uint16_t itemId) {
    Item* item = Item::CreateItem(itemId);
    if (!item) return false;

    // Tag for lightweight tracking
    item->setActionId(actionIdTag_);

    // Place item
    Tile* tile = g_game.map.getTile(pos);
    if (!tile) { delete item; return false; }
    
    tile->addThing(INDEX_WHEREEVER, item);
    
    ++ar.active;
    return true;
}

// ---------------- tracking hooks ----------------

void RandomItemSpawner::onItemRemoved(const Item* item) {
    if (!item) return;
    if (item->getActionId() != actionIdTag_) return;

    const Position& p = item->getPosition(); // works for items on map / being removed
    for (auto& ar : areas_) {
        if (p.z != ar.cfg.center.z) continue;
        const int32_t dx = static_cast<int32_t>(p.x) - static_cast<int32_t>(ar.cfg.center.x);
        const int32_t dy = static_cast<int32_t>(p.y) - static_cast<int32_t>(ar.cfg.center.y);
        if (std::abs(dx) <= ar.cfg.radius && std::abs(dy) <= ar.cfg.radius) {
            if (ar.active > 0) --ar.active;
            break; // decrement only once; if areas overlap, first match wins
        }
    }
}

// Assign an item to the first area whose square (same Z) contains its position.
// Returns areas_.size() if none match.
size_t RandomItemSpawner::findAreaIndexForPosition(const Position& p) const {
    for (size_t i = 0; i < areas_.size(); ++i) {
        const auto& ar = areas_[i];
        if (p.z != ar.cfg.center.z) continue;
        const int32_t dx = int32_t(p.x) - int32_t(ar.cfg.center.x);
        const int32_t dy = int32_t(p.y) - int32_t(ar.cfg.center.y);
        if (std::abs(dx) <= ar.cfg.radius && std::abs(dy) <= ar.cfg.radius) {
            return i; // first match wins
        }
    }
    return areas_.size();
}

// UID-free resync: recount area.active by scanning only items tagged with actionIdTag_.
// Uses an Item* pointer set to avoid double counting when areas overlap.
void RandomItemSpawner::resyncCountsOccasionally() {
    // reset counts
    for (auto& ar : areas_) {
        ar.active = 0;
    }

    // Track already-accounted items to prevent overlap double-counts
    std::unordered_set<const Item*> visited;
    visited.reserve(1024);

    // Scan each area’s square footprint (union is implicitly covered)
    for (size_t ai = 0; ai < areas_.size(); ++ai) {
        const auto& cfg = areas_[ai].cfg;
        for (int32_t dx = -cfg.radius; dx <= int32_t(cfg.radius); ++dx) {
            for (int32_t dy = -cfg.radius; dy <= int32_t(cfg.radius); ++dy) {
                Position pos{
                    uint16_t(cfg.center.x + dx),
                    uint16_t(cfg.center.y + dy),
                    cfg.center.z
                };
                Tile* tile = g_game.map.getTile(pos);
                if (!tile) continue;

                // Iterate stack; adjust if your fork exposes a different iterator
                const uint32_t n = tile->getThingCount();
                for (uint32_t i = 0; i < n; ++i) {
                    const Thing* th = tile->getThing(i);
                    const Item* it = th ? th->getItem() : nullptr;
                    if (!it) continue;
                    if (it->getActionId() != actionIdTag_) continue;

                    // Avoid double counting across overlapping areas
                    if (!visited.insert(it).second) continue;

                    // Assign this item to *one* area (first matching)
                    const size_t owner = findAreaIndexForPosition(it->getPosition());
                    if (owner < areas_.size()) {
                        ++areas_[owner].active;
                    }
                }
            }
        }
    }
}
