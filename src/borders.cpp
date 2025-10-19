#include "borders.h"

#include "item.h"
#include "position.h"

#include <iostream>
#include <stdbool.h>

extern Game g_game;

static const uint16_t grassFrom = 9043;
static const uint16_t grassTo = 9058;

static bool itemIdIsGrass(uint16_t id)
{
    if (id >= grassFrom && id <= grassTo) return true;
    else return false;
}

static bool tileIsGrass(Tile *tile)
{
    if (!tile) return false;
    if (!tile->getGround()) return false;
    return itemIdIsGrass(tile->getGround()->getID());
}

bool addGrassBorders(Map *map, Tile *tile)
{
    const Position centerPos = tile->getPosition();

    if (tileIsGrass(tile)) return false;

    // remove borders
    while(Item *oldBorder = tile->getItemByTopOrder(1)) {
        if (oldBorder) {
            tile->removeThing(oldBorder, 1);
        }
    }

    // remove other grass items
    while (Item *topDownThing = tile->getTopDownItem())
	{
		tile->removeThing(topDownThing, 1);
	}

    std::vector<uint16_t> borders = {};

    bool topLeft =      tileIsGrass(map->getTile(centerPos.x - 1, centerPos.y - 1,  centerPos.z));
    bool top =          tileIsGrass(map->getTile(centerPos.x    , centerPos.y - 1,  centerPos.z));
    bool topRight =     tileIsGrass(map->getTile(centerPos.x + 1, centerPos.y - 1,  centerPos.z));
    bool left =         tileIsGrass(map->getTile(centerPos.x - 1, centerPos.y,      centerPos.z));
    bool right =        tileIsGrass(map->getTile(centerPos.x + 1, centerPos.y,      centerPos.z));
    bool bottomLeft =   tileIsGrass(map->getTile(centerPos.x - 1, centerPos.y + 1,  centerPos.z));
    bool bottom =       tileIsGrass(map->getTile(centerPos.x    , centerPos.y + 1,  centerPos.z));
    bool bottomRight =  tileIsGrass(map->getTile(centerPos.x + 1, centerPos.y + 1,  centerPos.z));

    if (left && !top && !bottom && !right) borders.push_back(7656);
    if (right && !top && !bottom && !left) borders.push_back(7710);
    if (top && !right && !bottom && !left) borders.push_back(7653);
    if (bottom && !right && !top && !left) borders.push_back(7709);

    if (left && top && !right && !bottom) borders.push_back(7661);
    if (right && top && !left && !bottom) borders.push_back(7662);
    if (left && bottom && !right && !top) borders.push_back(7663);
    if (right && bottom && !left && !top) borders.push_back(7664);
    
    if (topLeft && !left && !top) borders.push_back(7657);
    if (topRight && !right && !top) borders.push_back(7658);
    if (bottomLeft && !left && !bottom) borders.push_back(7659);
    if (bottomRight && !right && !bottom) borders.push_back(7660);

   for (auto &borderId : borders) {
        Item* borderItem = Item::CreateItem(borderId);
        if (borderItem) {
            tile->addThing(INDEX_WHEREEVER, borderItem);
        }
    }
    return true;
}