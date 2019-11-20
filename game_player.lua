local GamePlayer = {};

function GamePlayer.newState()

    local state = {};

    state.camera = {
        zoom = 20,
        center = {x = 50, y = 50},
    };
    
    state.inventory = {
        resources = {}
    };

    GamePlayer.initInventory(state, GameConfig);

    return state;

end

function GamePlayer.getResources(playerState)
    return playerState.inventory.resources;
end

function GamePlayer.initInventory(playerState, config)
    
    local playerRes = GamePlayer.getResources(playerState);

    for name, resourceId in pairs(config.RESOURCE_TYPES) do
        playerRes[resourceId] = 0;
    end

end

--Add, or remove, resources from a player
function GamePlayer.addResource(playerState, resourceType, quantity)
    local playerRes = GamePlayer.getResources(playerState);
    playerRes[resourceType] = playerRes[resourceType] + quantity;
end

function GamePlayer.addResources(playerState, resources)

    for resourceId, amount in pairs(resources) do
        GamePlayer.addResource(playerState, resourceId, amount);
    end

end

function GamePlayer.removeResources(playerState, resources)

    for resourceId, amount in pairs(resources) do
        GamePlayer.addResource(playerState, resourceId, -amount);
    end

end

--Returns number recipe outputs that can be built from resources or 0
function GamePlayer.canBuild(playerState, recipe)

    local playerRes = playerState.inventory.resources;
    local amount = 0;

    for resourceId, amountNeeded in pairs(recipe) do

        if (playerRes[resourceId] < amountNeeded) then
            return 0;
        else
            local thisNumber = math.floor(playerRes[resourceId] / amountNeeded);
            if (amount == 0) then
                amount = thisNumber;
            else
                amount = math.min(thisNumber, amount);
            end
        end
    end
    return amount;
end






return GamePlayer;