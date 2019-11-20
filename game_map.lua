local GameMap = {};

v2 = {};

v2.distance = function(x1, y1, x2, y2)

    local dx = x2-x1;
    local dy = y2-y1;

    return math.sqrt(dx * dx + dy * dy);

end

v2.normalize = function(x, y)

    local mag = math.sqrt(x * x + y * y);

    if (mag > 0) then
        x, y = x / mag, y / mag;
    end

    return x, y;

end

function GameMap.populateResources(mapState, config)

    local size = mapState.size;
    local grid = mapState.grid;

    mapState.objectShash = Shash.new(4);
    mapState.agentShash = Shash.new(4);

    for x = 1, size.x do
        for y = 1, size.y do

            if (grid[x][y] == config.GROUND_TYPES.GRASS) then
            
                local flip = math.random();

                if(flip < 0.02) then

                    GameMap.addAgent(mapState, {
                        type = config.AGENT_TYPES.DEMON,
                        x = x,
                        y = y,
                        w = 1,
                        h = 1
                    });

                elseif (flip < 0.2) then
                    GameMap.addObject(mapState, {
                        type = config.OBJECT_TYPES.TREE,
                        x = x,
                        y = y
                    });
                elseif (flip < 0.4) then
                    GameMap.addObject(mapState, {
                        type = config.OBJECT_TYPES.ROCK,
                        x = x,
                        y = y
                    });
                elseif (flip < 0.45) then
                    GameMap.addObject(mapState, {
                        type = config.OBJECT_TYPES.FRUIT_TREE,
                        x = x,
                        y = y,
                        food = 5
                    });
                end
            end

            --Loop
        end
    end

end

function GameMap.eachObjectAt(mapState, x, y, callback)
    
    local shash = mapState.objectShash;
    x,y = math.floor(x) + 0.5, math.floor(y) + 0.5;

    Shash.each(shash, x, y, 0.01, 0.01, callback);
    Shash.each(mapState.agentShash, x, y, 0.01, 0.01, callback);


end

function GameMap.addRiver(mapState, config)

    local grid = mapState.grid;

    local x = math.random(2, mapState.size.x - 2);
    local y = math.random(2, mapState.size.y - 2);

    local dirX = 1;
    local dirY = 0;

    if ( math.random() < 0.5) then
        dirX, dirY = dirY, dirX;
    end

    if (math.random() < 0.5) then
        dirX, dirY = -dirX, -dirY;
    end


    for i = 1,100 do

        if (not grid[x] or not grid[x][y]) then return end;
        grid[x][y] = config.GROUND_TYPES.WATER;
        
        x = x + dirX;
        y = y + dirY;

        local flip = math.random();

        if (flip < 0.1) then
            dirX, dirY = dirY, dirX;

            if (flip < 0.05) then
                dirX, dirY = -dirX, -dirY;
            end

        end
    end

end

function GameMap.generateMap(mapState, config)
    local size = mapState.size;
    mapState.grid = {}; 
    mapState.lightGrid = {};

    local grid = mapState.grid;
    local lightGrid = mapState.lightGrid;

    for x = 1, size.x do
        grid[x] = {};
        lightGrid[x] = {};

        for y = 1, size.y do
            grid[x][y] = config.GROUND_TYPES.GRASS;
        end
    end

    for i = 1, 20 do
        GameMap.addRiver(mapState, config);
    end
end

function GameMap.genUUID(mapState)

    mapState.uuid = mapState.uuid + 1;
    return mapState.uuid;
    
end

function GameMap.populateAgents(state, config)
    


end

function GameMap.newState(config)
    local state = {};
    state.grid = {};

    state.uuid = 0;

    state.size = {
        x = 100,
        y = 100
    };

    state.objectShash = Shash.new(4);

    GameMap.generateMap(state, config);
    GameMap.populateResources(state, config);
    GameMap.populateAgents(state, config);

    return state;
end

function GameMap.removeObject(mapState, object)
    Shash.removeByUUID(mapState.objectShash, object.uuid);
end

function GameMap.addAgent(mapState, agent)
    agent.uuid = GameMap.genUUID(mapState);
    Shash.add(mapState.agentShash, agent, agent.x + 0.05, agent.y + 0.05, 0.9, 0.9);
end

function GameMap.removeAgent(mapState, agent)
    Shash.removeByUUID(mapState.agentShash, agent.uuid);
end

function GameMap.damageAgent(mapState, agent, amount)
    agent.health = (agent.health or 1.0) - amount;
    if (agent.health <= 0.0) then

        if (agent.house) then
            local house = Shash.getForUUID(mapState.objectShash, agent.house);
            
            if (house) then
                house.numOccupants = house.numOccupants - 1;
            end
        end

        GameMap.removeAgent(mapState, agent);
    end
end

function GameMap.getAgent(mapState, agentUUID)
    return Shash.getForUUID(mapState.agentShash, agentUUID);
end

function GameMap.moveAgent(mapState, agent)

    if (agent.x < 0) then
        agent.x = mapState.size.x + agent.x;
    elseif (agent.x > mapState.size.x) then
        agent.x = agent.x - mapState.size.x;
    end
    
    if (agent.y < 0) then
        agent.y = mapState.size.y + agent.y;
    elseif (agent.y > mapState.size.y) then
        agent.y = agent.y - mapState.size.y;
    end

    Shash.update(mapState.agentShash, agent, agent.x + 0.05, agent.y + 0.05, 0.9, 0.9);
end

function GameMap.setGround(mapState, type, x, y)
    mapState.grid[x][y] = type;
end

function GameMap.getGrid(mapState, x, y)
    if (mapState.grid[x]) then
        return mapState.grid[x][y];
    end
end

function GameMap.clearArea(mapState, groundType, x, y, w, h)

    for ix = x, (x+w) do
    for iy = y, (y+h) do        
            GameMap.setGround(mapState, groundType, ix, iy);
    end
    end

    local toRemove = {};

    Shash.each(mapState.objectShash, x, y, w, h, function(obj)
        toRemove[obj.uuid] = obj;
    end);

    for uuid, obj in pairs(toRemove) do
        GameMap.removeObject(mapState, obj);
    end

    toRemove = {};

    Shash.each(mapState.agentShash, x, y, w, h, function(obj)
        toRemove[obj.uuid] = obj;
    end);

    for uuid, obj in pairs(toRemove) do
        GameMap.removeObject(mapState, obj);
    end

end

function GameMap.addLight(mapState, x, y, amount)
    mapState.lightGrid[x][y] = (mapState.lightGrid[x][y] or 0) + amount;
end

function GameMap.addLum(mapState, x, y, lum)

    x,y = math.floor(x), math.floor(y);
    
    for ix = x - lum, x + lum do
        for iy = y - lum, y + lum do

            local dist = v2.distance(x, y, ix, iy) / (lum * 1.5);
            local amount = math.max(0.0, 1.0 - dist);
            GameMap.addLight(mapState, ix, iy, amount);
        end
    end
end

function GameMap.addObject(mapState, object)
    object.uuid = GameMap.genUUID(mapState);

    local bProps = GameConfig.BUILDING_PROPERTIES[object.type] or {w = 1, h = 1};

    object.w = object.w or bProps.w;
    object.h = object.h or bProps.h;

    Shash.add(mapState.objectShash, object, object.x + 0.05, object.y + 0.05, object.w - 0.1, object.h - 0.1);


    if (bProps.lum) then
        local x, y = getObjCenter(object);
        GameMap.addLum(mapState, x, y, bProps.lum);
    end
end

function GameMap.canPlace(mapState, building, x, y)

    local grid = mapState.grid;
    local objectShash = mapState.objectShash;


    if (not building.w) then

        local bProps = GameConfig.BUILDING_PROPERTIES[building.type];
        building.w = bProps.w;
        building.h = bProps.h;

    end

    if (grid[x] and grid[x][y]) then
        if (not Shash.overlapsAny(objectShash, x, y, building.w, building.h)) then
            return GameConfig.BUILDING_REQUIREMENTS[building.type](grid, x, y);
        end
    end

    return false;

end

function GameMap.isRoad(object)
    return object.type == GameConfig.BUILDING_TYPES.ROAD or object.type == GameConfig.BUILDING_TYPES.BRIDGE;
end

local function invertPath(node)

    if (not node) then return nil end;
    
    while(node.parent) do   
        node.parent.next = node;
        node = node.parent;
    end

    return node;

end

local d_bfs = function(...)
    --print(...);
end

function GameMap.searchRoadPath(mapState, sx, sy, goalFn, maxDist)
    
    local startNode = {
        x = math.floor(sx + 0.5),
        y = math.floor(sy + 0.5),
        d = 0
    };

    local searchList = List.new(0);
    local seenAlready = {};


    local function addNode(node)
        local hash = node.x.."+"..node.y;

        if (not seenAlready[hash]) then
            List.pushright(searchList, node);
            seenAlready[hash] = 1;
        end
    end

    local function addPos(x, y, d, parent)
        addNode({x = x, y= y, d=d, parent = parent});
    end

    addNode(startNode);

    d_bfs("start", sx, sy, List.length(searchList));


    while(List.length(searchList) > 0) do

        local node = List.popleft(searchList);


        local x, y = node.x, node.y;
        local d = node.d + 1;

                
        if (goalFn(mapState, node)) then
            d_bfs("found at", node.x, node.y);
            return invertPath(node.parent);
        end

        local isRoad = false;

        GameMap.eachObjectAt(mapState, x, y, function(obj)

            if (GameMap.isRoad(obj)) then
                isRoad = true;
            end
        end);

        d_bfs("rd", node.x, node.y, d, isRoad);

        if (d < maxDist and isRoad) then
            addPos(x + 1, y, d, node);
            addPos(x - 1, y, d, node);
            addPos(x, y + 1, d, node);
            addPos(x, y - 1, d, node);
        end

    end

end

function GameMap.iterateNearbyGrid(mapState, center, distance, callback)

    local grid = mapState.grid;
    local lightGrid = mapState.lightGrid;

    local fx = math.floor(center.x);
    local fy = math.floor(center.y);

    for x = -distance, distance do
        for y = -distance, distance do

            local ox = x + fx;
            local oy = y + fy;

            
            if (grid[ox] and grid[ox][oy]) then
                local light = lightGrid[ox][oy] or 0;
                callback(grid[ox][oy], ox, oy, light);
            end

        end
    end

end

function GameMap.objectsAround(mapState, object, callback)

    --[[
    local border = 0.3;
    
    Shash.each(mapState.objectShash, object.x - border, object.y - border, object.w + (border*2), object.h + (border*2), function(obj)
        if (obj.uuid ~= object.uuid) then
            callback(obj);
        end
    end);
    ]]

    local s = 0.05;
    local os = 1.0 - s;
    local s2 = 2 * s;
    local sw = 1.0 - s2;

    Shash.each(mapState.objectShash, object.x + s, object.y - os, object.w - s2, sw, callback);
    Shash.each(mapState.objectShash, object.x + s, object.y + object.h + s, object.w - s2, sw, callback);

    Shash.each(mapState.objectShash, object.x - os, object.y + s, sw, object.h - s2, callback);
    Shash.each(mapState.objectShash, object.x + object.w + s, object.y, sw, object.h - s2, callback);


end

function GameMap.iterateNearbyObjects(mapState, center, distance, callback)
    local shash = mapState.objectShash;

    Shash.each(shash, center.x - distance, center.y - distance, distance * 2, distance * 2, function(object)
        
        --callback(object, object.x - center.x, object.y - center.y);
        callback(object, object.x, object.y);

    end);
end

function GameMap.iterateNearbyAgents(mapState, center, distance, callback)
    local shash = mapState.agentShash;

    Shash.each(shash, center.x - distance, center.y - distance, distance * 2, distance * 2, function(object)
        
        --callback(object, object.x - center.x, object.y - center.y);
        callback(object, object.x, object.y);

    end);
end


function GameMap.findNearestAgent(mapState, center, distance, searchFn)

    local nearestObject = nil;
    local nearestDistance = 100000;

    GameMap.iterateNearbyAgents(mapState, center, distance, function(obj, x, y)
        
        if (searchFn(obj)) then
            local thisDist = v2.distance(x, y, center.x, center.y);

            if (thisDist < nearestDistance) then
                nearestObject = obj;
                nearestDistance = thisDist;
            end
        end

    end);

    return nearestObject;
end


function GameMap.update(mapState, dt)

    local objectShash = mapState.objectShash;
    local agentShash = mapState.agentShash;
    local tickFns = GameConfig.OBJECT_TICK;

    mapState.timeToTick = (mapState.timeToTick or 1.0) - dt;

    if (mapState.timeToTick <= 0.0) then

        Shash.all(objectShash, function(object)
            if (tickFns[object.type]) then
                tickFns[object.type](object, 1.0, mapState);
            end
        end);

        mapState.timeToTick = nil;
    end

    mapState.timeToTickAgent = (mapState.timeToTickAgent or 0.1) - dt;

    if (mapState.timeToTickAgent <= 0.0) then

        Shash.all(agentShash, function(object)
            if (tickFns[object.type]) then
                tickFns[object.type](object, 0.1, mapState);
            end
        end);

        mapState.timeToTickAgent = nil;
    end


end

return GameMap;