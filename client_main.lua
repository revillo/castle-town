-- file://C:\castle\castle-town\client_main.lua

local GameStage = require("game_stage");
Stage = GameStage.GameStage;
Director = GameStage.GameDirector;
GFX3D = require("gfx3D");
List = require("lib/list");
Shash = require("lib/shash");
GameConfig = require("game_config");
GameMap = require("game_map");
GamePlayer = require("game_player");
GameService = require("game_service");

local cpml = GFX3D.cpml;
local vec3 = cpml.vec3;

local LG = love.graphics;

local MainMenu = Stage.new({

});

local GameInterface = Stage.new({

});

local MOUSE_STATE = {
    DRAGGING = 0,
    TAPPING = 1
};

local BUILD_MENU_STATE = {
    CLOSED = 0,
    OPEN = 1,
    BUILDING = 2
}

local GameState = {
    playing = false
};

function GameInterface.init()
    GameInterface.buildMenuState =  BUILD_MENU_STATE.CLOSED;
    GameInterface.paused = false;
end

function GameInterface.setService(service)
    GameInterface.service = service;
    
    service:requestStart(function()
        GameState.map = service:getMapState();
        GameState.player = service:getPlayerState();
        GameState.playing = true;
    end);

    
end

function GameInterface.resizeCanvas()
    local w, h = LG.getDimensions();
    GameInterface.canvas = GFX3D.createCanvas3D(w,h);

    GameInterface.tilePixelSize = 40;
    GameInterface.tilePixelOffset = {
        x = w * 0.5,
        y = h * 0.5
    }
end


local TILE_COLORS = {
    [GameConfig.GROUND_TYPES.GRASS] = {0.3, 0.7, 0.1, 1.0},
    [GameConfig.GROUND_TYPES.SAND] = {0.93, 0.9, 0.8, 1.0},
    [GameConfig.GROUND_TYPES.DIRT] = {0.6, 0.3, 0.0, 1.0}
};

local loadImg = function(name)
    local img = LG.newImage("img/"..name..".png");
    img:setFilter("nearest", "nearest");
    return img;
end

local TILE_IMG = {
    [GameConfig.GROUND_TYPES.GRASS] = loadImg("grass"),
    [GameConfig.GROUND_TYPES.SAND] = loadImg("sand"),
    [GameConfig.GROUND_TYPES.DIRT] = loadImg("dirt"),
    [GameConfig.GROUND_TYPES.WATER] = loadImg("water")
}

local OBJECT_IMG = {
    [GameConfig.OBJECT_TYPES.TREE] = loadImg('tree'),
    [GameConfig.OBJECT_TYPES.ROCK] = loadImg('rock'),
    [GameConfig.OBJECT_TYPES.FRUIT_TREE] = loadImg('fruit_tree'),

    [GameConfig.BUILDING_TYPES.ROAD] = loadImg("road"),
    [GameConfig.BUILDING_TYPES.BRIDGE] = loadImg("bridge"),
    [GameConfig.BUILDING_TYPES.HOUSE] = loadImg("house"),
    [GameConfig.BUILDING_TYPES.FENCE] = loadImg("fence"),
    [GameConfig.BUILDING_TYPES.CROPS] = loadImg("crops"),

    [GameConfig.AGENT_TYPES.VILLAGER] = loadImg("villager")
}

local SPROUT_IMG = {
    [1] = loadImg("sprout_1"),
    [2] = loadImg("sprout_2"),
    [3] = loadImg("sprout_3"),
    [4] = loadImg("sprout_4")
}

local DRAW_SPECIAL = {

    --[[
    [GameConfig.BUILDING_TYPES.HOUSE] = function()

    end,
    ]]

    [GameConfig.OBJECT_TYPES.FRUIT_TREE] = function(tree)
        if(tree.food <= 0) then
            GameInterface.drawSprite(SPROUT_IMG[4], tree.x, tree.y);
        else
            GameInterface.drawSprite(OBJECT_IMG[tree.type], tree.x, tree.y);
        end
    end
}


function GameInterface.drawMapTile(tile, wx, wy)

    --LG.setColor(TILE_COLORS[tile]);
    LG.setColor(1,1,1,1);
    local size = GameInterface.tilePixelSize;
    local offset = GameInterface.tilePixelOffset;

    --LG.rectangle("fill", dx * size + offset, dy * size + offset, size, size);
    local px, py = GameInterface.mapToPixel(wx, wy);

    LG.draw(TILE_IMG[tile], px, py, 0, size / 16, size / 16);
end

function GameInterface.drawSprite(img, wx, wy)
    LG.setColor(1,1,1,1);

    local size = GameInterface.tilePixelSize;

    local px, py = GameInterface.mapToPixel(wx, wy);

    LG.draw(img, px, py, 0, size / 16, size / 16);

end

function GameInterface.drawCrop(object, wx, wy)
    
    GameInterface.drawSprite(OBJECT_IMG[GameConfig.BUILDING_TYPES.CROPS], wx, wy);

    if (object.growth < 2) then
        GameInterface.drawSprite(SPROUT_IMG[1], wx, wy);
    elseif (object.growth < 4) then
        GameInterface.drawSprite(SPROUT_IMG[2], wx, wy);   
    elseif (object.growth < 6) then
        GameInterface.drawSprite(SPROUT_IMG[3], wx, wy);   
    elseif (object.growth < 10) then
        GameInterface.drawSprite(SPROUT_IMG[4], wx, wy);   
    else
        --[[
        if (object.food <= 0) then
            GameInterface.drawSprite(SPROUT_IMG[4], wx, wy);   
        else
            GameInterface.drawSprite(OBJECT_IMG[object.type], wx, wy);
        end
        ]]

        DRAW_SPECIAL[object.type](object);
    end

end

function GameInterface.drawMapObject(object, wx, wy)

    LG.setColor(1,1,1,1);

    local size = GameInterface.tilePixelSize;

    local px, py = GameInterface.mapToPixel(wx, wy);

    --LG.rectangle("fill", dx * size + offset + 2, dy * size + offset + 2, size * 0.5, size * 0.5);

    if (object.fromCrop) then
        GameInterface.drawCrop(object, wx, wy);
    else

        if (DRAW_SPECIAL[object.type]) then
            DRAW_SPECIAL[object.type](object);  
        else
            GameInterface.drawSprite(OBJECT_IMG[object.type], wx, wy);
        end
       --
        --        LG.draw(OBJECT_IMG[object.type], px, py, 0, size / 16, size / 16);
    end


    if (object.health and object.health < 1.0)  then
       LG.setColor(0,0,0,1);
       LG.rectangle("line", px, py, size, 5);
       LG.rectangle("fill", px, py, size * object.health, 5);
    end
    --[[

    LG.setColor(1,1,1,1);

    if (object.foodDist) then
        LG.print(object.foodDist, px, py);
    end

    if (object.homeDist) then
        LG.setColor(0, 1,1,1);
        LG.print(object.homeDist, px, py + 20);
    end

]]
    LG.setColor(1, 0, 1, 1);

    if (object.hunger) then
        LG.print(object.hunger, px + 10, py + 10);
        LG.setColor(1, 1, 1, 1);
        LG.print(object.hunger, px + 8, py + 8);
    end

    LG.setColor(1, 0, 1, 1);

    if (object.tired) then
        LG.print(object.tired, px + 20, py + 20);
        LG.setColor(1, 1, 1, 1);
        LG.print(object.tired, px + 18, py + 18);
    end
end


function GameInterface.drawMap(playerState, mapState)
    --local objects = GameMap.getNearbyObjects(mapState, playerState.center, playerState.camera.zoom);

    --[[
    GFX3D.setCanvas3D(GameInterface.canvas);

    local c = playerState.camera.center;
    GFX3D.setCameraView(vec3(c.x, c.y, playerState.camera.zoom), vec3(c.x, c.y, 0.0), vec3(0.0, 1.0, 0.0));

    GFX3D.setShader(GFX3D.Shader.Default);
]]


    GameMap.iterateNearbyGrid(mapState, playerState.camera.center, playerState.camera.zoom, GameInterface.drawMapTile)
    GameMap.iterateNearbyObjects(mapState, playerState.camera.center, playerState.camera.zoom, GameInterface.drawMapObject);
    GameMap.iterateNearbyAgents(mapState, playerState.camera.center, playerState.camera.zoom, GameInterface.drawMapObject);

end

function GameInterface.drawResources(playerState)

    local w, h = LG.getDimensions();

    LG.setColor(0,0,0,0.8);
    LG.rectangle('fill', 0, 0, w, GameInterface.tilePixelSize * 0.5);

    local playerRes = GamePlayer.getResources(playerState);

    --[[
    LG.printf({
        {0.5, 0.3, 0.0, 1.0},
        "Wood: "..playerRes[GameConfig.RESOURCE_TYPES.WOOD],
        {0.4, 0.4, 0.4, 1.0},
        "Stone: "..playerRes[GameConfig.RESOURCE_TYPES.STONE]
    }, 0, 0, w);
    ]]


    LG.setColor(1,1,1,1);

    local xo = 0;
    for resourceName, resourceId in pairs(GameConfig.RESOURCE_TYPES) do
        LG.print(resourceName..": "..playerRes[resourceId], xo + 4, 2);
        xo = xo + 100;
    end

end

function GameInterface.drawButton(x, y, w, h, text, onClick, img)

    LG.setColor(0.7, 0.5, 0.2, 1.0);
    LG.rectangle('fill', x, y, w, h);

    LG.setScissor(x, y, w, h);
    LG.setColor(1,1,1,1);

    if (img) then
        LG.draw(img, x + w / 2, y + 2, 0, h/16, h/16);
    end

    LG.setColor(0,0,0,0.5);
    LG.rectangle("fill", x, y, (#text) * 10, 20);

    LG.setColor(0.0, 0.0, 0.0, 1.0);
    LG.print(text, x + 2, y + 2);
   -- LG.setColor(0.5, 0.3, 0.0, 1.0);
    LG.setColor(1.0, 1.0, 1.0, 1.0);
    LG.print(text, x + 1, y + 1);
    LG.setScissor();


    List.pushright(GameInterface.buildButtons, {
        x = x,
        y = y,
        w = w,
        h = h,
        onClick = onClick
    });


end


function GameInterface.requestBuildMode(buildingId, buildingName)

    local recipe = GameConfig.BUILDING_RECIPES[buildingId];

    local numBuild = GamePlayer.canBuild(GameState.player, recipe);

    if (numBuild > 0) then
        GameInterface.buildMenuState = BUILD_MENU_STATE.BUILDING;
        GameInterface.buildType = buildingId;
        GameInterface.buildName = buildingName;
    end

end

function GameInterface.drawBuildMenu()

    GameInterface.buildButtons = List.new();

    local w, h = LG.getDimensions();
    local buttonSize = GameInterface.tilePixelSize * 1;

    
    local buttonSizeX = buttonSize * 2;
    local ox = w - buttonSizeX * 1.1;


    if (GameInterface.buildMenuState == BUILD_MENU_STATE.OPEN) then

        GameInterface.drawButton(ox, h - buttonSize, buttonSizeX, buttonSize, "CLOSE", function()
            GameInterface.buildMenuState = BUILD_MENU_STATE.CLOSED;
        end);
        
        local oy = buttonSize * 2.5;

        for buildingName, buildingId in pairs(GameConfig.BUILDING_TYPES) do
            GameInterface.drawButton(ox, h - oy, buttonSizeX, buttonSize, buildingName, function()
                GameInterface.requestBuildMode(buildingId, buildingName);
            end, OBJECT_IMG[buildingId]);

            oy = oy + buttonSize * 1.5;
        end

    elseif (GameInterface.buildMenuState == BUILD_MENU_STATE.CLOSED) then
        GameInterface.drawButton(ox, h - buttonSize, buttonSizeX, buttonSize, "BUILD", function()
            GameInterface.buildMenuState = BUILD_MENU_STATE.OPEN;
        end);
    else -- BUILDING

        GameInterface.drawButton(ox, h - buttonSize, buttonSizeX, buttonSize, "Cancel "..GameInterface.buildName, function()
            GameInterface.buildMenuState = BUILD_MENU_STATE.OPEN;
        end);

        local mx, my = love.mouse.getPosition();
        local wx, wy = GameInterface.pixelToMap(mx, my);
        wx, wy = math.floor(wx), math.floor(wy);
        local bProps = GameConfig.BUILDING_PROPERTIES[GameInterface.buildType];

        if (GameMap.canPlace(GameState.map, {
            type = GameInterface.buildType,
            w = bProps.w,
            h = bProps.h
        }, wx, wy)) then

            GameInterface.drawMapObject({
                type = GameInterface.buildType
            }, wx, wy);

        end

    end

end

function GameInterface.mousemoved(x, y, dx, dy)

    if (GameInterface.mouseState == MOUSE_STATE.DRAGGING) then
        GameInterface.cameraDragEvent = {
            x = dx,
            y = dy
        };
    end

end

function GameInterface.updateCamera(dt)

    local playerState = GameState.player;

    if (GameInterface.cameraDragEvent) then
        local c = playerState.camera.center;
        c.x = c.x - GameInterface.cameraDragEvent.x / GameInterface.tilePixelSize;
        c.y = c.y - GameInterface.cameraDragEvent.y / GameInterface.tilePixelSize;
        GameInterface.cameraDragEvent = nil;
    end
end

function GameInterface.pixelToMap(x, y)
    local playerState = GameState.player;
    local center = playerState.camera.center;

    return (x -  GameInterface.tilePixelOffset.x) / GameInterface.tilePixelSize + center.x,
           (y -  GameInterface.tilePixelOffset.y) / GameInterface.tilePixelSize + center.y;
end

function GameInterface.mapToPixel(x, y)
    local size = GameInterface.tilePixelSize;
    local offset = GameInterface.tilePixelOffset;
    local playerState = GameState.player;
    local center = playerState.camera.center;

    return (x-center.x) * size + offset.x, (y-center.y) * size + offset.y;
end

function GameInterface.handleTaps()
    if (GameInterface.tapEvent) then
        
        local x, y = GameInterface.tapEvent.x, GameInterface.tapEvent.y;

        x, y = GameInterface.pixelToMap(x, y);

        local service = GameInterface.service;

        service:handleMapTap({
           x = x,
           y = y 
        });

        GameInterface.tapEvent = nil;
    end
end

function GameInterface.update(dt)


    if (not GameState.playing or GameInterface.paused) then
        return;
    end

    GameInterface.updateCamera(dt);
    GameInterface.handleTaps();

    GameInterface.service:update(dt);
end

function GameInterface.mousereleased()
    GameInterface.mouseState = nil;
end

function GameInterface.keypressed(key)

    if (key == "p") then
        GameInterface.paused = not GameInterface.paused;
    end

end

function GameInterface.mousepressed(x, y, button, isTouch, presses)

    local finished = false;

    List.each(GameInterface.buildButtons, function(button)
        
        if (x > button.x and y > button.y and x < (button.x + button.w) and y < (button.y + button.h)) then
            button.onClick();
            finished = true;
        end
    
    end);

    if finished then return end;

    if (GameInterface.buildMenuState == BUILD_MENU_STATE.BUILDING) then

        local wx, wy = GameInterface.pixelToMap(x, y);
        wx, wy = math.floor(wx), math.floor(wy);

        GameInterface.service:handleMapPlace({
            building = {
                type = GameInterface.buildType
            },
            x = wx,
            y = wy
        });

        return;
    end

    if (presses == 1) then
        GameInterface.mouseState = MOUSE_STATE.DRAGGING;

        local wx, wy = GameInterface.pixelToMap(x, y);
        print("tap ", wx, wy);

    elseif (presses > 1) then
        GameInterface.mouseState = MOUSE_STATE.TAPPING;
        GameInterface.tapEvent = {
            x = x,
            y = y,
            p = presses
        };
    end

end

function GameInterface.draw()

    if (not GameState.playing) then
        LG.print("One Moment", 100, 100);
        return;
    end

    LG.setColor(1,1,1,1);
    LG.print("Playing da game", 100, 100);

    GameInterface.drawMap(GameState.player, GameState.map);
    GameInterface.drawResources(GameState.player);
    GameInterface.drawBuildMenu();

end


function MainMenu.draw()

    LG.setColor(1,1,1,1);
    LG.print("Single Player", 50, 50);
    LG.print("Multiplayer", 50, 150);

end

function MainMenu.launchSinglePlayer()
    --Start Local Mode
    GameInterface.init();
    GameInterface.resizeCanvas();
    GameInterface.setService(GameService.LocalService);
    Director.push(GameInterface);
end

function MainMenu.mousepressed()

    MainMenu.launchSinglePlayer();

end


Director.init(love);
Director.push(MainMenu);