local GameConfig = {};

GameConfig.RESOURCE_TYPES = {
    WOOD = 1,
    STONE = 2,
    SEED = 3
};

GameConfig.OBJECT_TYPES = {
    TREE = 0,
    ROCK = 1,
    FRUIT_TREE = 2
};

GameConfig.BUILDING_TYPES = {
    ROAD = 50,
    BRIDGE = 51,
    HOUSE = 52,
    FENCE = 53,
    CROPS = 54,
    TOWER = 55
};

GameConfig.AGENT_TYPES = {
    VILLAGER = 101,
    DEMON = 102,
    ARROW = 103
};

--Useful functions

function getObjCenter(obj)
    return obj.x + (obj.w or 1) * 0.5, obj.y + (obj.h or 1) * 0.5;
end

local function getDirToward(obj, obj2)

    local x2, y2 = getObjCenter(obj2)
    local x1, y1 = getObjCenter(obj)

    return {x = x2 - x1, y = y2 - y1};
end

local function overlap(entityA, entityB)

    --local ax = (math.max(entityA.x, entityB.x) - math.min(entityA.x + (entityA.w or 1), entityB.x + (entityB.w or 1)));
    
    --local ay = (math.max(entityA.y, entityB.y) - math.min(entityA.y + (entityA.h or 1), entityB.y + (entityB.h or 1)));
    
    local l1x, l2x = entityA.x, entityB.x;
    local r1x, r2x = entityA.x + 1.0, entityB.x + 1.0;
    local l1y, l2y = entityA.y, entityB.y;
    local r1y, r2y = entityA.y + 1.0, entityB.y + 1.0;

    local ax = (math.min(r1x, r2x) - math.max(l1x, l2x));
    local ay = (math.min(r1y, r2y) - math.max(l1y, l2y));


    
    --print("total", ax * ay, ax, ay, entityA.x, entityB.x);
    --return ax * ay;

    return math.max(ax, 0) * math.max(ay, 0);
      
end

local function randomDir()
    local x = math.random() - 0.5;
    local y = math.random() - 0.5;

    x,y = v2.normalize(x,y);
    return {x=x,y=y};
end

local reqOnLand = function(grid, x, y)
    if (grid[x] and grid[x][y] and grid[x][y] ~= GameConfig.GROUND_TYPES.WATER) then return true end;
    return false;
end;

GameConfig.BUILDING_REQUIREMENTS = {
    [GameConfig.BUILDING_TYPES.BRIDGE] = function(grid, x, y)
        if (grid[x] and grid[x][y] and grid[x][y] == GameConfig.GROUND_TYPES.WATER) then return true end;
        return false;
    end,

    [GameConfig.BUILDING_TYPES.ROAD] = reqOnLand,

    [GameConfig.BUILDING_TYPES.FENCE] = reqOnLand,

    [GameConfig.BUILDING_TYPES.CROPS] = reqOnLand,

    [GameConfig.BUILDING_TYPES.HOUSE] = function(grid, x, y)

        local function canBuildOn(x, y)
            if (grid[x] and grid[x][y] and grid[x][y] ~= GameConfig.GROUND_TYPES.WATER) then return true end;
            return false;
        end

        return (canBuildOn(x, y) and canBuildOn(x + 1, y) and canBuildOn(x, y + 1) and canBuildOn(x + 1, y + 1));

    end,

    
    [GameConfig.BUILDING_TYPES.TOWER] = function(grid, x, y)

        local function canBuildOn(x, y)
            if (grid[x] and grid[x][y] and grid[x][y] ~= GameConfig.GROUND_TYPES.WATER) then return true end;
            return false;
        end

        local fits = true;

        for oy = 0, 2 do
            fits = fits and (canBuildOn(x, y + oy) and canBuildOn(x + 1, y + oy));
        end

        return fits;
    end,

}


GameConfig.BUILDING_RECIPES = {
    [GameConfig.BUILDING_TYPES.ROAD] = {
        [GameConfig.RESOURCE_TYPES.STONE] = 1
    },

    [GameConfig.BUILDING_TYPES.BRIDGE] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 1
    },

    [GameConfig.BUILDING_TYPES.HOUSE] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 4,
        [GameConfig.RESOURCE_TYPES.STONE] = 4
    },

    [GameConfig.BUILDING_TYPES.TOWER] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 10,
        [GameConfig.RESOURCE_TYPES.STONE] = 20
    },

    [GameConfig.BUILDING_TYPES.FENCE] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 1
    },

    [GameConfig.BUILDING_TYPES.CROPS] = {
        [GameConfig.RESOURCE_TYPES.SEED] = 1
    }
}

GameConfig.BUILDING_PROPERTIES = {
    [GameConfig.BUILDING_TYPES.ROAD] = {
        w = 1,
        h = 1
    },

    [GameConfig.BUILDING_TYPES.FENCE] = {
        w = 1,
        h = 1
    },

    [GameConfig.BUILDING_TYPES.CROPS] = {
        w = 1,
        h = 1
    },

    [GameConfig.BUILDING_TYPES.BRIDGE] = {
        w = 1,
        h = 1
    },

    [GameConfig.BUILDING_TYPES.HOUSE] = {
        w = 2,
        h = 2,
        lum = 10
    },

    
    [GameConfig.BUILDING_TYPES.TOWER] = {
        w = 2,
        h = 3,
        lum = 15
    }
}

local function objIsFood(object)
    return object.type == GameConfig.OBJECT_TYPES.FRUIT_TREE and object.food > 1;
end

local function objIsHome(object)
    return object.type == GameConfig.BUILDING_TYPES.HOUSE;
end


local function makeGoalFn(fn)
    return function(mapState, node)
        local isGoal = false;

        GameMap.eachObjectAt(mapState, node.x, node.y, function(obj)
            if fn(obj) then
                isGoal = true;
            end
        end);
    
        return isGoal;
    end
end

local goalFnHome = makeGoalFn(objIsHome);
local goalFnFood = makeGoalFn(objIsFood);

local function moveToward(obj1, obj2, speed, mapState)
    local dx, dy = obj2.x - obj1.x, obj2.y - obj1.y;
    
    local distance = math.sqrt(dx * dx + dy * dy);

    local amount = math.min(speed, distance)

    if (distance > 0) then

        local scale = amount / distance;
        
        dx, dy = dx * scale, dy *  scale;

        obj1.x = obj1.x + dx;
        obj1.y = obj1.y + dy;
        
        GameMap.moveAgent(mapState, obj1);

    end

    return amount, dx, dy;

end

local function spreadFood(self, dt, mapState)

    --[[
    local foodDist = self.foodDist or 10000;
    if (foodDist == 1) then
        foodDist = 1000;
    end

    GameMap.objectsAround(mapState, self, function(obj)
        if (objIsFood(obj)) then
            foodDist = 1;
        elseif (obj.foodDist) then
            foodDist = math.min(foodDist, obj.foodDist + 1);
        end
    end);

    self.foodDist = foodDist;
    ]]

    self.foodDist = self.foodDist or 10000;


    local nearFood = false;
    local bestNbr = 10000;
    GameMap.objectsAround(mapState, self, function(obj)
        if (objIsFood(obj)) then
            nearFood = true;
        elseif (obj.foodDist) then
            bestNbr = math.min(bestNbr, obj.foodDist + 1);
        end
    end);


    if (nearFood) then
        self.foodDist = 1;
    elseif self.foodDist < bestNbr then
        self.foodDist = 10000;
    else
        self.foodDist = bestNbr;
    end

end

local function spreadHome(self, dt, mapState)
    local homeDist = self.homeDist or 10000;

    if(homeDist == 1) then
        homeDist = 1000;
    end

    GameMap.objectsAround(mapState, self, function(obj)
        if (objIsHome(obj)) then
            homeDist = 1;
        elseif (obj.homeDist) then
            homeDist = math.min(homeDist, obj.homeDist + 1);
        end
    end);

    self.homeDist = homeDist;
end

local function roadTick(self, dt, mapState)
    spreadFood(self, dt, mapState);
    spreadHome(self, dt, mapState);
end

GameConfig.OBJECT_TICK = {
    [GameConfig.BUILDING_TYPES.CROPS] = function(self, dt)
        self.growth = (self.growth or 0) + dt;
        self.fromCrop = true;

        if (self.growth >= 10) then
            self.type = GameConfig.OBJECT_TYPES.FRUIT_TREE;
            self.food = 5;
        end
    end,

    [GameConfig.OBJECT_TYPES.FRUIT_TREE] = function(self, dt)

        self.food = math.min(self.food + dt * 0.03, 5);

    end,

    [GameConfig.BUILDING_TYPES.ROAD] = roadTick,

    [GameConfig.BUILDING_TYPES.BRIDGE] = roadTick,

    [GameConfig.BUILDING_TYPES.HOUSE] = function(self, dt, mapState)

        self.occupants = self.occupants or {};
        self.numOccupants = self.numOccupants or 0;

        if (self.numOccupants == 0) then

            local house = self;

            GameMap.objectsAround(mapState, house, function(obj)
                if (obj.type == GameConfig.BUILDING_TYPES.ROAD and house.numOccupants == 0) then
                    house.numOccupants = house.numOccupants + 1;
                    GameMap.addAgent(mapState, {
                        x = obj.x,
                        y = obj.y,
                        w = 1,
                        h = 1,
                        type = GameConfig.AGENT_TYPES.VILLAGER,
                        house = house.uuid
                    });
                    print("adding villager", house.numOccupants);
                end
            end);

        end


    end,


    [GameConfig.AGENT_TYPES.VILLAGER] = function(self, dt, mapState)
        self.hunger = (self.hunger or 0) + dt;
        self.hunger = math.min(self.hunger, 50);
        self.tired = (self.tired or 0) + dt;
        self.age = (self.age or 0) + dt;
        self.health = math.min((self.health or 1.0) + dt * 0.02, 1.0);

        self.aiCountdown = (self.aiCountdown or 0) + dt;

        local villager = self;

        local nearFood = false;

        local nearHome = false;

        if (true) then
            --return
        end;

        GameMap.objectsAround(mapState, villager, function(obj)

            if (objIsFood(obj) and villager.hunger > 5) then
                --villager.hunger = math.max(0, villager.hunger - dt * 10);
                --obj.food = obj.food - dt;
                local foodAmount = obj.food;
                if (foodAmount > 1.0) then
                    obj.food = 0.0;
                    villager.hunger = villager.hunger - 10 * foodAmount;
                end
                
                nearFood = true;
                --print("eating", villager.hunger);
            end

            if (objIsHome(obj)) then
                villager.tired = 0;
                nearHome = true;
                --print('isHome', villager.tired);
            end

        end);


        if (villager.aiCountdown < 4.0) then
            if (villager.path) then
                local next = villager.path;
                local d = moveToward(villager, next, 1.0 * dt, mapState);

                if (d < 1.0 * dt and next.next) then
                    villager.path = next.next;
                end
            end
        else
            if (villager.tired > 15) then
                --print("search road for home");
                villager.path = GameMap.searchRoadPath(mapState, villager.x, villager.y, goalFnHome, 30);
            elseif (villager.hunger > 3) then
                --print("search road for food");
                villager.path = GameMap.searchRoadPath(mapState, villager.x, villager.y, goalFnFood, 30);
            end    

            villager.aiCountdown = 0.0;
        end

       
    end,


    [GameConfig.BUILDING_TYPES.TOWER] = function(self, dt, mapState)


        self.shootTime = (self.shootTime or 0) + dt;

        if (self.shootTime > 2.0) then
            self.shootTime = 0.0;
        else
            return;
        end

        local demon = GameMap.findNearestAgent(mapState, self, 10, function(obj)

            return obj.type == GameConfig.AGENT_TYPES.DEMON

        end);

        local fx, fy = self.x + self.w * 0.5, self.y + 0.1;


        if (demon) then

            local dcx, dcy = getObjCenter(demon);
            local dx = dcx - fx;
            local dy = dcy - fy;

            dx, dy = v2.normalize(dx, dy);

            GameMap.addAgent(mapState, {
                type = GameConfig.AGENT_TYPES.ARROW,
                x = fx,
                y = fy,
                dx = dx,
                dy = dy,
                tUUID = demon.uuid,
                w = 1,
                h = 1
            });
        end

    end,

    [GameConfig.AGENT_TYPES.DEMON] = function(self, dt, mapState)

        self.dir = self.dir or randomDir();
        self.x = self.x + self.dir.x * dt;
        self.y = self.y + self.dir.y * dt;

        GameMap.moveAgent(mapState, self);

        self.retargetTime = (self.retargetTime or 0) + dt;

        if (self.retargetTime > 5) then

            local villager = GameMap.findNearestAgent(mapState, self, 6, function(obj)
                return obj.type == GameConfig.AGENT_TYPES.VILLAGER;
            end);

            if (villager) then
                if (overlap(villager, self) > 0.2)  then
                    GameMap.damageAgent(mapState, villager, dt * 0.1);
                else
                    self.dir = getDirToward(self, villager);
                end
            else
                self.dir = randomDir();
                self.retargetTime = 0.0;
            end
        end



    end,

    [GameConfig.AGENT_TYPES.ARROW] = function(self, dt, mapState)

        local target = GameMap.getAgent(mapState, self.tUUID);

        if (target) then

            local tx, ty = getObjCenter(target);

            local amt, dx, dy = moveToward(self, {x = tx, y = ty},  4 * dt, mapState);
            self.dx, self.dy = v2.normalize(dx, dy);
            
            if (overlap(self, target) > 0.2) then
                GameMap.removeAgent(mapState, self);
                GameMap.damageAgent(mapState, target, 0.5);
            end

        else

            GameMap.removeAgent(mapState, self);

        end

    end

    --[[
    [GameConfig.AGENT_TYPES.VILLAGER] = function(self, dt, mapState)
        self.hunger = (self.hunger or 0) + dt;
        self.tired = (self.tired or 0) + dt;
        local villager = self;

        --if (self.hunger > 60) then

            local bestFoodRoad = nil;
            local bestHomeRoad = nil;
            local lowestFoodDist = 100000;
            local lowestHomeDist = 100000;
            local nearFood = false;

            GameMap.objectsAround(mapState, villager, function(obj)
                
                if (objIsFood(obj) and villager.hunger > 5) then
                    villager.hunger = math.max(0, villager.hunger - dt * 10);
                    --obj.food = obj.food - dt;
                    obj.food = 0;
                    villager.hunger = 0;
                    nearFood = villager;
                    print("eating", villager.hunger);
                end

                if (objIsHome(obj)) then
                    villager.tired = 0;
                    print('isHome', villager.tired);
                end

                if (obj.foodDist and obj.foodDist < lowestFoodDist) then
                    bestFoodRoad = obj;
                    lowestFoodDist = obj.foodDist;
                end
                
                if (obj.homeDist and obj.homeDist < lowestHomeDist) then
                    bestHomeRoad = obj;
                    lowestHomeDist = obj.homeDist;
                end

            end);

            if (villager.tired > 10 and villager.tired > villager.hunger and bestHomeRoad) then
                moveToward(villager, bestHomeRoad, dt * 2, mapState);
                print("going home", villager.tired, villager.hunger);
            elseif (villager.hunger > 5) then
                moveToward(villager, bestFoodRoad, dt, mapState);
                print("getting food", villager.tired * 2, villager.hunger);
                print(bestFoodRoad.x, bestFoodRoad.y);
            end

        --end

    end]]
}

--[[
GameConfig.OBJECT_EVENTS = {
    [GameConfig.OBJECT_TYPES.FRUIT_TREE] = {
        onDie = function(object, mapState)
            
        end
    }
}
]]

GameConfig.RESOURCE_DROPS = {

    [GameConfig.OBJECT_TYPES.TREE] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 2
    },

    [GameConfig.OBJECT_TYPES.FRUIT_TREE] = {
        [GameConfig.RESOURCE_TYPES.SEED] = 6,
        [GameConfig.RESOURCE_TYPES.WOOD] = 2
    },

    [GameConfig.OBJECT_TYPES.ROCK] = {
        [GameConfig.RESOURCE_TYPES.STONE] = 2
    },

    [GameConfig.BUILDING_TYPES.ROAD] = {
        [GameConfig.RESOURCE_TYPES.STONE] = 1
    },

    [GameConfig.BUILDING_TYPES.BRIDGE] = {
        [GameConfig.RESOURCE_TYPES.WOOD] = 1
    },

    [GameConfig.BUILDING_TYPES.CROPS] = {
        [GameConfig.RESOURCE_TYPES.SEED] = 1
    },

    [GameConfig.BUILDING_TYPES.FENCE] = {
        [GameConfig.RESOURCE_TYPES.SEED] = 1
    }

}

GameConfig.GROUND_TYPES = {
    GRASS = 1,
    SAND = 2,
    DIRT = 3,
    WATER = 4,
    SNOW = 5
};

return GameConfig;