local GamePlayer = {};

function GamePlayer.newState()

    local state = {};

    state.camera = {
        zoom = 10,
        center = {x = 50, y = 50},
        inventory = {
            resources = {}
        }
    };

    GamePlayer.initInventory(state);

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
    playerRes[resourceType] = playerRes[resourceType] + quanity;
end

--Returns number recipe outputs that can be built from resources or 0
function GamePlayer.canBuild(playerState, recipe)

    local playerRes = playerState.inventory.resources;
    local amount = 0;
    local recipeRes = recipe.resources;

    for resourceId, amountNeeded in pairs(recipeRes) do

        if (playerRes[resourceId] == 0) then
            return 0;
        else
            local thisNumber = math.floor(amountNeeded / playerRes[resourceId]);
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