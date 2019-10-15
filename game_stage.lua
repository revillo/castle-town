local GameStage = {};

function GameStage:new(o)
    o = o or {};
    self.__index = self;
    setmetatable(o, self);
    return o;
end
    
 

local loveCbs = {
    load = { server = true, client = true },
    lowmemory = { server = true, client = true },
    quit = { server = true, client = true },
    threaderror = { server = true, client = true },
    update = { server = true, client = true },
    directorydropped = { client = true },
    draw = { client = true },
    --    errhand = { client = true },
    --    errorhandler = { client = true },
    filedropped = { client = true },
    focus = { client = true },
    keypressed = { client = true },
    keyreleased = { client = true },
    mousefocus = { client = true },
    mousemoved = { client = true },
    mousepressed = { client = true },
    mousereleased = { client = true },
    resize = { client = true },
    --    run = { client = true },
    textedited = { client = true },
    textinput = { client = true },
    touchmoved = { client = true },
    touchpressed = { client = true },
    touchreleased = { client = true },
    visible = { client = true },
    wheelmoved = { client = true },
    gamepadaxis = { client = true },
    gamepadpressed = { client = true },
    gamepadreleased = { client = true },
    joystickadded = { client = true },
    joystickaxis = { client = true },
    joystickhat = { client = true },
    joystickpressed = { client = true },
    joystickreleased = { client = true },
    joystickremoved = { client = true },
}

local GameDirector = {

    stack = {},
    stackIndex = 0,

}

function GameDirector.init(loveProxy)

    for name, _ in pairs(loveCbs) do

        loveProxy[name] = function(...)
            
            local index = GameDirector.stackIndex;
            local stack = GameDirector.stack;

            while (index >=1 ) do
                local stage = stack[index];
                if (stage[name]) then
                    stage[name](...);
                    break;
                end
                index = index - 1;
            end
        end
    end
end

function GameDirector.push(stage) 
    GameDirector.stackIndex = GameDirector.stackIndex + 1;
    GameDirector.stack[GameDirector.stackIndex] = stage;
end

function GameDirector.pop()
    GameDirector.stack[GameDirector.stackIndex] = nil;
    GameDirector.stackIndex = GameDirector.stackIndex - 1;
end


return {
    GameStage = GameStage,
    GameDirector = GameDirector
};