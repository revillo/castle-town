local GameService = {};


function GameService:new(o)
    o = o or {};
    setmetatable(o, self);
    return o;
end

function GameService:getMapState()
    return self.gameState.map;
end

function GameService:getPlayerState()
    return self.gameState.player;
end

GameService.__index = GameService;

local LocalService = GameService:new();

function LocalService:requestStart(callback)

    self.gameState = {};
    self.gameState.map = GameMap.newState(GameConfig);
    self.gameState.player = GamePlayer.newState(GameConfig);

    --GameMap.addObject({})
    self:initBuildings();

    callback();
end

function LocalService:initBuildings()

    GameMap.clearArea(self.gameState.map, GameConfig.GROUND_TYPES.GRASS, 47, 47, 6, 6);
    GameMap.addObject(self.gameState.map, {
        type = GameConfig.BUILDING_TYPES.HOUSE,  
        x = 49,
        y = 49
    });

end

function LocalService:handleMapPlace(placeEvent)
    local mapState = self.gameState.map;
    local playerState = self.gameState.player;

    local building = placeEvent.building;
    local wx, wy = placeEvent.x, placeEvent.y;

    local recipe = GameConfig.BUILDING_RECIPES[building.type];


    if (GameMap.canPlace(mapState, building, wx, wy) and GamePlayer.canBuild(playerState, recipe) > 0) then
        
        GamePlayer.removeResources(playerState, recipe);

        GameMap.addObject(mapState, {
            type = building.type,
            x = wx,
            y = wy
        });

    end
end

function LocalService:update(dt)
    GameMap.update(self.gameState.map, dt);
end

function LocalService:handleMapTap(tapEvent)
    
    local mapState = self.gameState.map;
    local playerState = self.gameState.player;
    local bestObj = nil;

    GameMap.eachObjectAt(mapState, tapEvent.x, tapEvent.y, function(obj)

        if (obj.type == GameConfig.AGENT_TYPES.VILLAGER) then
            return;
        end

        if (obj.type == GameConfig.AGENT_TYPES.DEMON) then
            bestObj = obj;
        else
            if (not bestObj or bestObj.type ~= GameConfig.AGENT_TYPES.DEMON) then
                bestObj = obj;
            end
        end

    end);

    if (bestObj) then
        local obj = bestObj;
        obj.health = obj.health or 1.0;
        obj.health = obj.health - 0.25;

        if (obj.health <= 0.0) then
            GameMap.removeObject(mapState, obj);
            GameMap.removeAgent(mapState, obj);

            local drops = GameConfig.RESOURCE_DROPS[obj.type];

            if (drops) then
                GamePlayer.addResources(playerState, drops);
            end
        end
    end
end


local NetworkedService = {}

GameService.LocalService = LocalService;
GameService.NetworkedService = NetworkedService;

return GameService;