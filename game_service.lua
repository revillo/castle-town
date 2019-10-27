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

    callback();
end

function LocalService:handleMapPlace(placeEvent)
    local mapState = self.gameState.map;
    local playerState = self.gameState.player;

    local building = placeEvent.building;
    local wx, wy = placeEvent.x, placeEvent.y;
    local bProps = GameConfig.BUILDING_PROPERTIES[building.type];

    local recipe = GameConfig.BUILDING_RECIPES[building.type];


    if (GameMap.canPlace(mapState, building, wx, wy) and GamePlayer.canBuild(playerState, recipe) > 0) then
        
        GamePlayer.removeResources(playerState, recipe);
        GameMap.addObject(mapState, {
            type = building.type,
            x = wx,
            y = wy,
            w = bProps.w,
            h = bProps.h
        });

    end
end

function LocalService:update(dt)
    GameMap.update(self.gameState.map, dt);
end

function LocalService:handleMapTap(tapEvent)
    
    local mapState = self.gameState.map;
    local playerState = self.gameState.player;

    GameMap.eachObjectAt(mapState, tapEvent.x, tapEvent.y, function(obj)
    
        obj.health = obj.health or 1.0;
        obj.health = obj.health - 1.0;
        print(obj.health);

        if (obj.health <= 0.0) then
            GameMap.removeObject(mapState, obj);

            local drops = GameConfig.RESOURCE_DROPS[obj.type];

            GamePlayer.addResources(playerState, drops);
        end

    end);
end


local NetworkedService = {}

GameService.LocalService = LocalService;
GameService.NetworkedService = NetworkedService;

return GameService;