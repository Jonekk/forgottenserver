#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <optional>
#include <unordered_set>

#include "position.h"

// Forward declarations to avoid heavy includes in header
class Item;
class Tile;

// The spawner supports: sunrise, sunset, night, day
// XML uses these names (case-insensitive), e.g. timeOfDay="sunrise,day"

enum class RISTime : uint8_t { Sunrise=1, Sunset=2, Night=4, Day=8 };
using RISTimeMask = uint8_t;

struct RISCustomAttr {
    std::string key;    // "aid"/"uid" => native setters, else custom attribute
    std::string type;   // "string" | "number" | "boolean"
    std::string value;  // raw text
};

struct RISDecayCfg {
    bool enabled = false;
    bool useNative = false;        // true => use items.xml decay; false => manual replace
    uint32_t timeMs = 0;           // duration before decay/replace
    std::optional<uint16_t> toId;  // manual replacement target (ignored if useNative)
};

struct RISSpawnCfg {
    uint16_t itemId = 0;
    uint16_t countMin = 1, countMax = 1;
    uint8_t  chancePct = 100;      // 0..100
    RISTimeMask timeMask = 0;      // 0==any time; else bitmask of RISTime
    RISDecayCfg decay;
    std::vector<RISCustomAttr> attrs;
};

struct SpawnItemDef {
    uint16_t itemId = 0;
    uint32_t weight = 0;
};

struct AreaCfg {
    std::string id;
    Position* centerPtr = nullptr; // optional external center (unused if nullptr)
    Position  centerFallback{};     // used when centerPtr==nullptr
    uint16_t radius = 1;

    double   spawnChancePerCheck = 0.10; // probability per tick
    uint32_t attemptsPerCheck    = 1;    // how many tries per tick
    uint32_t maxActive           = 10;   // cap of active spawned items in area

    std::vector<uint16_t> allowedGroundIds; // optional allowed ground IDs
    std::vector<SpawnItemDef> items;        // weighted pool (optional)
    std::vector<RISSpawnCfg>  spawns;       // explicit spawns (optional)

    RISTimeMask timeMask = 0;               // default time-of-day for this area
};

struct AreaRuntime {
    AreaCfg cfg;
    std::unordered_set<uint16_t> allowedSet;
    std::vector<uint32_t> itemPrefix; // prefix sums for weighted pick
    uint32_t active = 0;              // active spawned items
};

class RandomItemSpawner {
public:
    RandomItemSpawner() = default;
    ~RandomItemSpawner() = default;

    // Load full configuration from XML file
    bool loadFromXml(const std::string& path);

    // Control
    void setCheckIntervalMs(uint32_t ms) { intervalMs_ = ms; }
    void start();
    void stop();
    void runOnce();  // call manually or let scheduler call periodically

    // Must be called by the game core when an Item is removed from the map
    void onItemRemoved(Item* item);

    // Utility: whether an item belongs to this spawner (has our token)
    static bool isRISItem(const Item* item);

private:
    bool tileAllowed(const AreaRuntime& ar, const Position& pos) const;
    uint16_t pickRandomItemId(const AreaRuntime& ar) const;
    bool trySpawnInArea(AreaRuntime& ar);
    void scheduleTick();
    void resyncCountsOccasionally();
    size_t findAreaForItem(const Item *it) const;

    // helpers
    static void applyCustomAttributes(Item* item, const std::vector<RISCustomAttr>& attrs);
    static void startNativeDecay(Item* item, uint32_t durationMs);
    static void manualDecayReplace(const Position pos, uint16_t toItemId,
                                   const std::vector<RISCustomAttr> attrs);
    static void maybeStartDecay(Tile* where, Item* item, const RISSpawnCfg& cfg);

private:
    std::vector<AreaRuntime> areas_;
    uint32_t intervalMs_ = 15000;
    bool running_ = false;
};
