Updated script for my usecase for my server

# Dependency
ox_lib https://github.com/overextended/ox_lib

Mainly used for the command and menu integration with esx_policejob

# Integrate with police job

```lua
function SendToCommunityService(player) 
    local input = lib.inputDialog('Community Service', {'Amount'})
    if input then
        local amount = tonumber(input[1])
        if player then
            TriggerServerEvent("esx_communityservice:policesendCommunityService", player, amount)
        else
            exports['t-notify']:Custom({
                style  =  'error',
                duration  =  5000,
                message  =  'No player nearby',
                sound  =  true
            })
        end     
    end
end
```

I have it like this in police job to trigger the function

```lua
AddEventHandler('LSPD:CommunityService', function(data)
	local closestPlayer, closestPlayerDistance  = ESX.Game.GetClosestPlayer()
	if closestPlayer ~= -1 and closestPlayerDistance <= 2.0 then
		SendToCommunityService(GetPlayerServerId(closestPlayer))
	else
		exports['t-notify']:Custom({
			style  =  'error',
			duration  =  5000,
			message  =  'No Player Nearby!',
			sound  =  true
		})
	end
end)
```

Updated code to use more legacy features but also wanted practice with ox lib stuff since my server is based off of them. What I need help with or want for the future of this script is to make the resmon lower when in community service curently is ~0.20 but when not in use its 0.00. Could potentially add qtarget instead of pressing E but future thing.
