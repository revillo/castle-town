local GameStage = require("game_stage");
Stage = GameStage.GameStage;
Director = GameStage.GameDirector;
GFX3D = require("gfx3D");
List = require("lib/list")
GameConfig = require("game_config");
GameMap = require("game_map");
GamePlayer = require("game_player");

local cpml = GFX3D.cpml;
local vec3 = cpml.vec3;

local LG = love.graphics;

local MainMenu = Stage.new({

});

local GameInterface = Stage.new({

});

local GameState = {};

GameState.map = GameMap.newState();
GameState.player = GamePlayer.newState();


function GameInterface.resizeCanvas()
    local w, h = LG.getDimensions();
    GameInterface.canvas = GFX3D.createCanvas3D(w,h);
end

function GameInterface.drawMap(playerState, mapState)
    --local objects = GameMap.getNearbyObjects(mapState, playerState.center, playerState.camera.zoom);

    GFX3D.setCanvas3D(GameInterface.canvas);

    local center = player.camera.center;
    GFX3D.setCameraView(vec3(c.x, c.y, playerState.camera.zoom), vec3(c.x, c.y, 0.0), vec3(0.0, 1.0, 0.0));

    GFX3D.setShader(GFX3D.Shader.Default);



end

function GameInterface.draw()

    LG.setColor(1,1,1,1);
    LG.print("Playing da game", 100, 100);

end


function MainMenu.draw()

    LG.setColor(1,1,1,1);
    LG.print("Single Player", 50, 50);
    LG.print("Multiplayer", 50, 150);

end

function MainMenu.mousepressed()

    GameInterface.resizeCanvas();
    Director.push(GameInterface);

end


Director.init(love);
Director.push(MainMenu);