-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
--					Created By: apoiat   				  --
--			 Protected By: ATG-Github AKA ATG             --
--			    Updated by JohnnyS                        --
-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --

lib.addCommand('group.admin', {'comserv'}, function(source, args)
    local src = source
	local tgt = args.target
	local actions = args.actions

	if tgt and GetPlayerName(tgt) ~= nil and actions then
		local legit = checkIfLegit(src, tgt);
		if legit["legit"] == true then
			sendToComServ(src, tgt, actions)
		else
			print(
				string.format(
					"^2%s^7 -> [^1%s^7] ^1%s^7 has attempted to place [^5%s^7] ^5%s^7 into community service via the ^2comserv^7 command. The legitimacy check returned ^1false^7 with the reason of ^2%s^7.",
					GetCurrentResourceName(), src, GetPlayerName(src), tgt, GetPlayerName(tgt), legit["reason"]
				)
			)
		end
	else
		--TriggerClientEvent('chat:addMessage', src, { args = { _U('system_msn'), _U('invalid_player_id_or_actions') } } )
		TriggerClientEvent('t-notify:client:Custom', src, {
			style  =  'error',
			duration  =  5000,
			message  =  _U('invalid_player_id_or_actions'),
			sound  =  true
		})
	end

end, {'target:number', 'actions:number'})

lib.addCommand('group.admin', {'comservend'}, function(source, args)
	local src = source
	local tgt = args.target

	if tgt then
		if GetPlayerName(tgt) ~= nil then
			local legit = checkIfLegit(src, tgt);
			if legit["legit"] == true then
				releaseFromCommunityService(tgt)
			else
				print(
					string.format(
						"^2%s^7 -> [^1%s^7] ^1%s^7 has attempted to remove [^5%s^7] ^5%s^7 from community service via the ^2endcomserv^7 command. The legitimacy check returned ^1false^7 with the reason of ^2%s^7.",
						GetCurrentResourceName(), src, GetPlayerName(src), tgt, GetPlayerName(tgt), legit["reason"]
					)
				)
			end
		else
			--TriggerClientEvent('chat:addMessage', src, { args = { _U('system_msn'), _U('invalid_player_id')  } } )
			TriggerClientEvent('t-notify:client:Custom', src, {
				style  =  'error',
				duration  =  5000,
				message  =  _U('invalid_player_id'),
				sound  =  true
			})
		end
	else
		local legit = checkIfLegit(src, src);
		if legit["legit"] == true then
			releaseFromCommunityService(src)
		else
			print(
				string.format(
					"^2%s^7 -> [^1%s^7] ^1%s^7 has attempted to remove theirself from community service via the ^2endcomserv^7 command. The legitimacy check returned ^1false^7 with the reason of ^2%s^7.",
					GetCurrentResourceName(), src, GetPlayerName(src), legit["reason"]
				)
			)
		end
	end
end, {'target:number'})


RegisterServerEvent('esx_communityservice:checkIfSentenced')
AddEventHandler('esx_communityservice:checkIfSentenced', function()
	local _source = source -- cannot parse source to client trigger for some weird reason
	local xPlayer = ESX.GetPlayerFromId(_source)
	print("Checking")
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		if result[1] ~= nil and result[1].actions_remaining > 0 then
			--TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('jailed_msg', GetPlayerName(_source), ESX.Math.Round(result[1].jail_time / 60)) }, color = { 147, 196, 109 } })
			TriggerClientEvent('esx_communityservice:inCommunityService', _source, tonumber(result[1].actions_remaining))
		end
	end)
end)

function sendToComServ(src, tgt, actions)
	if src ~= nil and tgt ~= nil then
		local legit = checkIfLegit(src, tgt);
		if legit["legit"] == true then
			local xSrc, xTgt = ESX.GetPlayerFromId(src), ESX.GetPlayerFromId(tgt);
			if xSrc ~= nil and xTgt ~= nil then
				local srcIdent, tgtIdent = xSrc.identifier, xTgt.identifier;

				MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
					['@identifier'] = tgtIdent
				}, function(result)
					if result[1] then
						MySQL.Async.execute('UPDATE communityservice SET actions_remaining = @actions_remaining WHERE identifier = @identifier', {
							['@identifier'] = tgtIdent,
							['@actions_remaining'] = actions
						})
					else
						MySQL.Async.execute('INSERT INTO communityservice (identifier, actions_remaining) VALUES (@identifier, @actions_remaining)', {
							['@identifier'] = tgtIdent,
							['@actions_remaining'] = actions
						})
					end
				end)

				--TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_msg', GetPlayerName(tgt), actions) }, color = { 147, 196, 109 } })
				TriggerClientEvent('chat:addMessage', -1 , {
					templateId =  'ccChat',
					multiline =  false,
					args = {
						'#e74c3c',
						'fa-solid fa-gavel',
						'Judge',
						'',
						xTgt.getName()..' has been sentenced to '..actions..' months of community service.'
					} 
				})
				TriggerClientEvent('esx_policejob:unrestrain', tgt)
				TriggerClientEvent('esx_communityservice:inCommunityService', tgt, actions)
			end
		else
			print(
				string.format(
					"^2%s^7 -> [^1%s^7] ^1%s^7 has attempted to remove [^5%s^7] ^5%s^7 from community service via the ^2sendToCommunityService^7 event. The legitimacy check returned ^1false^7 with the reason of ^2%s^7.",
					GetCurrentResourceName(), src, GetPlayerName(src), tgt, GetPlayerName(tgt), legit["reason"]
				)
			)
		end
	end
end

function checkIfLegit(source, target)
	-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
	--				Let's grab our data...					  --
	-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
	local src, tgt = source, target;
	--print("checkIfLegit function || Source = "..src)
	--print("checkIfLegit function || Target = "..tgt)
	if src ~= nil and tgt ~= nil then
		local xSrc, xTgt = ESX.GetPlayerFromId(src), ESX.GetPlayerFromId(tgt);

		if xSrc ~= nil and xTgt ~= nil then
			local srcIdent, tgtIdent = xSrc.identifier, xTgt.identifier;
			local srcJob = xSrc.job.name;
			local tgtJob = xTgt.job.name;
			local srcGroup = xSrc.getGroup();
			--print("xSrc or xTgt is not = to nil")
			--print(srcJob)
			--print(tgtJob)
			--print(srcGroup)
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			--				Let's define legitimacy...			      --
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			local legit = {
				["legit"] = true,
				["reason"] = "No flags found."
			};
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			--				Let's test for legitimacy!			      --
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			if srcJob ~= "police" then
				if srcGroup ~= "admin" and srcGroup ~= "superadmin" then
					legit = {
						["legit"] = false,
						["reason"] = "Source does not have the police job, and is not staff."
					}
					return legit
				end
			end
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			--		     If we've made it here, it's legit!           --
			-- ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~= --
			return legit
		else
			legit = {
				["legit"] = false,
				["reason"] = "xSrc or xTgt == nil."
			}
			return legit
		end
	else
		legit = {
			["legit"] = false,
			["reason"] = "Source or Target == nil."
		}
		return legit
	end
end

function getRemainingActions(t)
	--print("This function getRemainingActions was called")
	local tgt = t;
	if tgt ~= nil then
		local xTgt = ESX.GetPlayerFromId(tgt);
		if xTgt ~= nil then
			local identifier = xTgt.identifier;
			local sql = MySQL.Sync.fetchScalar("SELECT actions_remaining FROM communityservice WHERE identifier = @identifier", {["identifier"] = identifier});
			if sql == '' or sql == nil then
				return 0
			else
				return tonumber(sql)
			end
		else
			return 69
		end
	else
		return 69
	end
end

function releaseFromCommunityService(tgt)
	local xPlayer = ESX.GetPlayerFromId(tgt)

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('DELETE from communityservice WHERE identifier = @identifier', {
				['@identifier'] = xPlayer.identifier
			})
			--print(json.encode(result))
			--TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_finished', GetPlayerName(tgt)) }, color = { 147, 196, 109 } })
			TriggerClientEvent('chat:addMessage', -1 , {
				templateId =  'ccChat',
				multiline =  false,
				args = {
					'#e74c3c',
					'fa-solid fa-gavel',
					'Judge',
					'',
					xPlayer.getName()..' has finished their community service!'
				} 
			})
		end
	end)
	TriggerClientEvent('esx_communityservice:finishCommunityService', tgt)
end

RegisterServerEvent('esx_communityservice:escapemsg', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerClientEvent('chat:addMessage', source, {
		templateId =  'ccChat',
		multiline =  false,
		args = {
			'#e74c3c',
			'fa-solid fa-gavel',
			'Judge',
			'',
			_U('escape_attempt')
		} 
	})
end)

--Trigger from Police Job 
RegisterServerEvent('esx_communityservice:policesendCommunityService')
AddEventHandler('esx_communityservice:policesendCommunityService', function(player, amount)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local tgt = player
	local actions = amount

	if xPlayer.job.name == 'police' then
		sendToComServ(src, tgt, actions)
	else
		print(('esx_communityservice: %s attempted to put in vehicle (not cop)!'):format(xPlayer.identifier))
		TriggerEvent("EasyAdmin:addBan", src, '[#JL-P] The pigs caught you oinking')
	end
end)

-- unjail after time served
RegisterServerEvent('esx_communityservice:finishCommunityService')
AddEventHandler('esx_communityservice:finishCommunityService', function()
	local src = source;
	local actions = getRemainingActions(src);
	if actions <= 1 then
		releaseFromCommunityService(src)
	else
		print(
			string.format(
				"^2%s^7 -> [^1%s^7] ^1%s^7 has attempted to remove theirself from community service via the ^2finishCommunityService^7 event. The remaining actions were not low enough for the player to be released.",
				GetCurrentResourceName(), src, GetPlayerName(src)
			)
		)
	end
end)

RegisterServerEvent('esx_communityservice:completeService')
AddEventHandler('esx_communityservice:completeService', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)

		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining - 1 WHERE identifier = @identifier', {
				['@identifier'] = xPlayer.identifier
			})
		else
			print ("ESX_CommunityService :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)

RegisterServerEvent('esx_communityservice:extendService')
AddEventHandler('esx_communityservice:extendService', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)

		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining + @extension_value WHERE identifier = @identifier', {
				['@identifier'] = xPlayer.identifier,
				['@extension_value'] = Config.ServiceExtensionOnEscape
			})
		else
			print("ESX_CommunityService :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)
