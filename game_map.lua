local GameMap = {};



function GameMap.newState()
    local state = {};
    state.grid = {};

    for x = 1, 100 do
        state.grid[x] = {}
        for y = 1, 100 do
            state.grid[x][y] = math.random(0, 3);    
        end
    end

    state.objectShash = Shash:new(4);

    return state;
end

function GameMap.addObject(mapState, object)

end

function GameMap.getNearbyObjects(mapState, center, distance)

    local objectList = List.new();
    local grid = mapState.grid;
    local shash = mapState.objectShash;

    for x = -distance, distance do
        for y = -distance, distance do

            local ox = x + center.x;
            local oy = y + center.y;

            local obj = shash[ox][oy];

            if (obj) then
                List.pushright(objectList, {
                    object = obj,
                    x = ox,
                    y = oy
                });
            end
        end
    end

    return objectList;
end

return GameMap;