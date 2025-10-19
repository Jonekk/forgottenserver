#pragma once
#include <cstdint>
#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>

#include "position.h"

class QTreeNode;      // not used; leftover if your tree exists elsewhere
class QTreeLeafNode;  // not used here

class Tile;
class Item;

// Your RNG helper; or use TFS Tools::uniform_random if you have one.
int32_t uniform_random(int32_t minNumber, int32_t maxNumber);

struct SpawnItemDef {
    uint16_t itemId = 0;
    uint32_t weight = 1;
};

struct SpawnAreaConfig {
    std::string id;
    Position center;
    uint16_t radius = 0;
    double spawnChancePerCheck = 0.10; // 0..1
    uint32_t attemptsPerCheck = 1;     // >=1
    uint32_t maxActive = 10;           // area cap
    std::vector<uint16_t> allowedGroundIds; // accepted ground tile IDs (server IDs). empty = any valid ground
    std::vector<SpawnItemDef> items;        // weighted pool
};

class RandomItemSpawner {
public:
    bool loadFromXml(const std::string& file);
    void setCheckInterval(uint32_t ms);
    void start();
    void stop();

    void tick(); // called by scheduler

    // Lightweight tracking: call this from your central item-removal path
    // whenever an item may be removed/picked up/decayed.
    void onItemRemoved(const Item* item);

private:
    struct AreaRuntime {
        SpawnAreaConfig cfg;
        uint32_t active = 0;                        // currently tracked active items
        std::vector<uint32_t> itemPrefix;           // prefix sums of weights
        std::unordered_set<uint16_t> allowedSet;    // faster lookups for allowed ground ids
    };

    // helpers
    void rebuildItemPrefix(AreaRuntime& ar);
    bool trySpawnInArea(AreaRuntime& ar);
    bool pickRandomTile(const AreaRuntime& ar, Position& out) const;
    uint16_t pickRandomItemId(const AreaRuntime& ar) const;
    bool tileAllowed(const AreaRuntime& ar, const Position& pos) const;
    bool placeItemAndTrack(AreaRuntime& ar, const Position& pos, uint16_t itemId);
    void resyncCountsOccasionally();
    size_t findAreaIndexForPosition(const Position& p) const;

private:
    uint32_t checkIntervalMs_ = 10000;
    uint16_t actionIdTag_ = 65000; // reserved actionid used to mark spawned items

    std::vector<AreaRuntime> areas_;

    uint32_t resyncCounter_ = 0;
};
