
WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)



function initHookData()
	tbHookByAlly = {}

	tbPlayerFinishedHook = {}
	tbPlayerHookingBack = {}

	tHookElements = tHookElements or {}
	tnHookDamage = {175 , 250 , 350 , 500  }
	tnHookLength = {500 , 700 , 900 , 1200 }
	tnHookRadius = {20  , 30  , 50  , 80   }
	tnHookSpeed  = {0.2 , 0.3 , 0.4 , 0.6  }

	tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
	tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }

	tnPlayerHookDamage  = {}
	tnPlayerHookLength  = {}
	tnPlayerHookRadius  = {}
	tnPlayerHookSpeed   = {}
	tnPlayerHookType    = {}
	tnPlayerHookBDType = {}
	tPlayerPudgeLastFV  = {}
	tnPlayerHookType    = {}
	tnPlayerKillStreak  = {}

	PER_HOOK_BODY_LENGTH = 50

	tnHookTypeString = {
		[1] = "npc_dota2x_pudgewars_unit_pudgehook_lv1",	-- normal hook
		[2] = "npc_dota2x_pudgewars_unit_pudgehook_lv2",	-- black death hook
		[3] = "npc_dota2x_pudgewars_unit_pudgehook_lv3",	-- whale hook
		[4] = "npc_dota2x_pudgewars_unit_pudgehook_lv4"		-- skelton hook
	}

	tnHookParticleString = {
		 --TODO FIND THE PARTICLES
		 [1] = "invoker_quas_orb"
		,[2] = "invoker_wex_orb"
		,[3] = "invoker_exort_orb"
	}

	tPossibleHookTargetName = {
		 "npc_dota2x_pudgewars_pudge"
		,"npc_dota2x_pudgewars_chest"
		,"npc_dota2x_pudgewars_gold"
		--TODO
		-- for test only
		,"npc_dota2x_pudgewars_unit_test"
		,"npc_dota_goodguys_tower1_top"
		--,"npc_dota2x_pudgewars_rune" TODO

	}
	for i = 0,9 do
		tHookElements[i] = {
			Head = {
				unit = nil,
				paIndex = nil
			},
			Target = nil,
			CurrentLength = nil,
			Body = {}
		}
		tnPlayerHookType[i] = tnHookTypeString[1]
		tnPlayerHookBDType[i] = tnHookParticleString[1]
		tnPlayerHookRadius[i] = 100
		tnPlayerHookLength[i] = 1300
		tnPlayerHookSpeed[i] = 0.2
		tnPlayerHookDamage[i] = 200

	end
	PudgeWarsGameMode:CreateTimer("Create_Test_units",{
		endTime = Time(),
		callback = function ()
			print("spawning test units")
			local testUnitTable = {
				 "npc_dota_goodguys_melee_rax_bot"
				,"npc_dota_neutral_blue_dragonspawn_overseer"
				,"npc_dota_necronomicon_warrior_2"
				,"npc_dota_warlock_golem_3"
			}
			for k,v in pairs(testUnitTable) do
				table.insert( tPossibleHookTargetName , #tPossibleHookTargetName + 1 ,v)
				CreateUnitByName(v,Vector(0,0,0) + RandomVector(1000),false,nil,nil,DOTA_TEAM_GOODGUYS)
			end
			PrintTable(tPossibleHookTargetName)
		end
	})
	print("[pudgewars] finish init hook data")
end

local function distance(a, b)
    -- Pythagorian distance
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)

    return math.sqrt(xx*xx + yy*yy)
end



function OnHookStart(keys)

	-- a player starts a hook
	--PrintTable(keys)
	
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vOrigin = caster:GetOrigin()
	local vForwardVector = caster:GetForwardVector()
	--PrintTable(vForwardVector)
	local nPlayerID = keys.unit:GetPlayerID()

	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerHookingBack[nPlayerID] = false

	print("player "..tostring(nPlayerID).." Start a hook")
	PrintTable(keys)
	print("-------------------------------------------------")
	PrintTable(keys.caster.__self)
	print("-------------------------------------------------")
	PrintTable(keys.ability.__self)
	print("-------------------------------------------------")
	PrintTable(keys.attacker.__self)
	-- create the hook head
	local casterOrigin = caster:GetOrigin()
	casterOrigin.z = casterOrigin.z - 30
	local unit = CreateUnitByName(
		"npc_dota2x_pudgewars_unit_pudgehook_lv1"
		,casterOrigin
		,false
		,nil
		,nil
		,caster:GetTeam()
		)
	
	if unit == nil then 
		print("fail to create the head")
	else
		tHookElements[nPlayerID].Head.unit = unit
		unit:SetForwardVector(vForwardVector)
	end

	local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
	vOrigin.z = vOrigin.z + 150
	ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 1, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 2, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 3, vOrigin )
	AppendToLogFile("log/pudgewars.txt","Particle Index 1"..tostring(nFXIndex).."\n")
	
	tnFXIndex = ParticleManager:CreateParticle( "the_quas_trail" , PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( tnFXIndex, 0, vOrigin )
	AppendToLogFile("log/pudgewars.txt","Particle Index 2"..tostring(tnFXIndex).."\n")
	tHookElements[nPlayerID].Head.paIndex = tnFXIndex
	
	tHookElements[nPlayerID].Body[1] = {
	    index = nFXIndex,
	    vec = vOrigin
	}
end
local function showCenterMessage( msg )
	local m = {
		message= msg,
		duration = 2
	}
	PudgewarsGameMode:FireGameEvent("show_center_message",m)
	-- body
end
-- get the hooked unit
local function GetHookedUnit(caster, head , plyid)
		
	-- find unit in radius within hook radius	
	local tuHookedUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		head:GetOrigin(),		--find position
		nil,					--find entity
		tnPlayerHookRadius[plyid],			--find radius
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL, 
		0, FIND_CLOSEST,
		false
	)

	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			print("unitunitname " .. tostring(k)..":"..v:GetUnitName())

			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetUnitName() == t then
					-- the unit in the table , a valid hook unit
					va = true
				end
			end
			if ( not va ) or ( v == caster ) then
				-- not a valid unit , remove
				print("remove")
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1 then
		-- return the nearest unit
		return tuHookedUnits[1]
	end
	return nil
end

local function dealLastHit( caster,target )
	caster:AddAbility("ability_deal_the_last_hit")
	local ABILITY_LAST_HIT = caster:FindAbilityByName("ability_deal_the_last_hit")
	ABILITY_LAST_HIT:SetLevel(1)
	ExecuteOrderFromTable({
		UnitIndex = caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = ABILITY_LAST_HIT:entindex(),
		TargetIndex = target:entindex()
	})
	caster:RemoveAbility("ability_deal_the_last_hit")
	if target:IsAlive() then
		target:ForceKill(false)
	end
end

local function HookUnit( unit , caster ,plyid )
	print ( "hooked something" )
	print ( "the enemy name "..unit:GetName())

	local casterOrigin = caster:GetOrigin()
	local uOrigin = unit:GetOrigin()
	
	local nFXIndex = ParticleManager:CreateParticle( "necrolyte_scythe", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl(nFXIndex,0,casterOrigin)
	ParticleManager:SetParticleControl(nFXIndex,1,casterOrigin)
	ParticleManager:SetParticleControl(nFXIndex,2,uOrigin)
	ParticleManager:ReleaseParticleIndex(nFXIndex)

	caster:AddAbility("ability_dota2x_pudgewars_hook_applier")
	local ABILITY_HOOK_APPLIER = caster:FindAbilityByName("ability_dota2x_pudgewars_hook_applier")
	ABILITY_HOOK_APPLIER:SetLevel(1)
	ExecuteOrderFromTable({
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ABILITY_HOOK_APPLIER:entindex(),
			TargetIndex = unit:entindex()
	})
	caster:RemoveAbility("ability_dota2x_pudgewars_hook_applier")
	if unit:HasModifier("modifier_pudgewars_hooked") then
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
		print("the unit has the hooked modifier")
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	end
	
	local dmg = tnPlayerHookDamage[plyid]
	print("dmg = "..tostring(dmg).."playerdi"..tostring(plyid))
	local hp = unit:GetHealth()
	print(" hp = "..tostring(hp))
	if dmg < hp then
		-- take away health directly
		unit:SetHealth(hp-dmg)
	else
		-- ADD THE ABILITY "ability_deal_the_last_hit" AND DEAL DAMAGE WITH THE SPELL
		dealLastHit(caster,unit)
	end
	
	--THINK ABOUT HEADSHOT AND DENY
	if unit:HasModifier("dota2x_modifier_hooked") then
		if unit:GetTeam() ~= caster:GetTeam() then
			--HEAD SHOT
			dealLastHit(caster,unit)
			showCenterMessage("#pudgewars_head_shot")
			--TODO
			--EMIT SOUND
		end
		if tbHookByAlly[unit] then
			print("the unit has been hooked by ally")
			if unit:GetTeam() ~= caster:GetTeam() then
				--HEADSHOT
				dealLastHit(caster,unit)
				showCenterMessage("#pudgewars_head_shot")
				--TODO
				--EMIT SOUND
			end
		else
			print("the unit has been hooked by enemy")
			if unit:GetTeam() == caster:GetTeam() then
				--DENIED
				dealLastHit(caster,unit)
				showCenterMessage("#pudgewars_denied")
				--TODO
			    --EMIT SOUND
			end
		end
	end


	
	if unit:GetTeam() == caster:GetTeam() then
		tbHookByAlly[unit] = true
	else
		tbHookByAlly[unit] = false
	end

	
	return 1
end

function OnHookChanneling(keys)


	local caster = EntIndexToHScript(keys.caster_entindex)
	local casterOrigin = caster:GetOrigin()
	local casterForwardVector = caster:GetForwardVector()
	local nPlayerID = caster:GetPlayerID()
	
	if not tbPlayerFinishedHook[nPlayerID] then
		local uHead = tHookElements[nPlayerID].Head.unit
		local paHead = tHookElements[nPlayerID].Head.paIndex
		
		-- if the head exists and not coming back then find units round the head
		if uHead ~= nil 
			and tHookElements[nPlayerID].Target == nil 
			and not tbPlayerHookingBack[nPlayerID]
			then
			tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID )
		end
		
		-- count the length
		if tHookElements[nPlayerID].CurrentLength == nil then
			tHookElements[nPlayerID].CurrentLength = 2
		else
			tHookElements[nPlayerID].CurrentLength = tHookElements[nPlayerID].CurrentLength + 1
		end
		
		-- if not hook anything and not reach the max length continue to longer the hook
		if not tHookElements[nPlayerID].Target and 
			tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] 
				< tnPlayerHookLength[nPlayerID]
			then

			
			tPlayerPudgeLastFV[nPlayerID] = tPlayerPudgeLastFV[nPlayerID] or casterForwardVector


			local angleCurrentRad = nil
			local angleLastRad = nil
			if casterForwardVector.x == 0 then
				if casterForwardVector.y > 0 then
					angleCurrentRad = math.rad(90)
				elseif casterForwardVector.y < 0 then
					angleCurrentRad = math.rad(270)
				end
			else
				angleCurrentRad = math.atan(
					casterForwardVector.y/
					casterForwardVector.x
					)
			end
			if tPlayerPudgeLastFV[nPlayerID].x == 0 then
				if tPlayerPudgeLastFV[nPlayerID].y > 0 then
					angleLastRad = math.rad(90)
				elseif tPlayerPudgeLastFV[nPlayerID].y < 0 then
					angleLastRad = math.rad(270)
				end
			else
				angleLastRad = math.atan(
					tPlayerPudgeLastFV[nPlayerID].y /
					tPlayerPudgeLastFV[nPlayerID].x
					)
			end


			local base = uHead:GetOrigin()
			local baseFV = uHead:GetForwardVector()
			local baseRad = nil
			if baseFV.x == 0 then
				if baseFV.y > 0 then
					baseRad = math.rad(90)
				elseif baseFV.y < 0 then
					baseRad = math.rad(270)
				end
			else
				baseRad = math.atan(
					baseFV.y/
					baseFV.x
					)
			end

			local resultRad = baseRad + ((angleCurrentRad) - angleLastRad ) / 100

			--currently disable it
			local vec3 = Vector(
				 base.x + baseFV.x * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
				,base.y + baseFV.y * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
				,base.z
			)

			uHead:SetOrigin(vec3)
			uHead:SetForwardVector( Vector(math.cos(resultRad), math.sin(resultRad),0))
			local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ], PATTACH_CUSTOMORIGIN, caster )
			tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body + 1] = {
			    index = nFXIndex,
			    vec = vec3
			}

			tvec3 = vec3
			tvec3.z = vec3.z + 150
			ParticleManager:SetParticleControl( nFXIndex, 0, tvec3)
			ParticleManager:SetParticleControl( nFXIndex, 1, tvec3)
			ParticleManager:SetParticleControl( nFXIndex, 2, tvec3)
			ParticleManager:SetParticleControl( nFXIndex, 3, tvec3)
			ParticleManager:SetParticleControl( paHead, 0, tvec3 )
		end
		
		-- if hoooked someone then hook it
		local hooked = nil
		if tHookElements[nPlayerID].Target then
			if not tbPlayerHookingBack[nPlayerID] then
			tbPlayerHookingBack[nPlayerID] = true
				AppendToLogFile("log/pudgewars.txt","fond a target"..tHookElements[nPlayerID].Target:GetName())
				local unit = tHookElements[nPlayerID].Target
				hooked = HookUnit( unit , caster ,nPlayerID)
				AppendToLogFile("log/pudgewars.txt","hookit? "..tostring(hooked).."?")
			end
		end

		--if hooked something or hook reaches the max length then begin to go back
		if (tHookElements[nPlayerID].Target and hooked ) or  
			(tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] 
				> tnPlayerHookLength[nPlayerID])
			then


			local backVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].vec
			local paIndex = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].index

			ParticleManager:SetParticleControl( paIndex, 0, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 1, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 2, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 3, WORLDMAX_VEC)
			ParticleManager:ReleaseParticleIndex( paIndex )

			tbackVec = backVec
			ParticleManager:SetParticleControl( paHead, 0, backVec )
			tbackVec.z = tbackVec.z - 150
			uHead:SetOrigin(backVec)

			tbPlayerHookingBack[nPlayerID] = true
			if tHookElements[nPlayerID].Target then
				tHookElements[nPlayerID].Target:SetOrigin(Vector(backVec.x,backVec.y,tHookElements[nPlayerID].Target:GetOrigin().z))
			end



			table.remove(tHookElements[nPlayerID].Body,#tHookElements[nPlayerID].Body)
			
			if #tHookElements[nPlayerID].Body == 0 then
				if tHookElements[nPlayerID].Target ~= nil then
					if tHookElements[nPlayerID].Target:IsAlive() then
						tHookElements[nPlayerID].Target:AddNewModifier(tHookElements[nPlayerID].Target,nil,"modifier_phased",{})
						tHookElements[nPlayerID].Target:RemoveModifierByName( "dota2x_modifier_hooked" )
						tHookElements[nPlayerID].Target:RemoveModifierByName("modifier_phased")
					end
				end
				
				hooked = false
				tHookElements[nPlayerID].CurrentLength = nil
				uHead:Remove()
				tHookElements[nPlayerID].Head.unit = nil
				ParticleManager:SetParticleControl( paHead, 0, WORLDMAX_VEC)
				ParticleManager:ReleaseParticleIndex(paHead)
				tHookElements[nPlayerID].Body = {}
				tHookElements[nPlayerID].Target = nil
				tbPlayerFinishedHook[nPlayerID] = true
			end
		end
	end
end

function OnUpgradeHookDamage(keys)

	tPrint(keys)
	local caster    = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_damage_not_enough_gold",caster:GetTeam())
	end

end

function OnUpgradeHookRadius( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	
	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_radius_not_enough_gold",caster:GetTeam())
	end

end

function OnUpgradeHookLength( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookLengthCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_length_not_enough_gold",caster:GetTeam())
	end
	
end

function OnUpgradeHookSpeed( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]
	local nCurrentGold  = PlayerResource:GetGold(nPlayerID)

	-- if the player has not enough gold then stop him from channeling
	if nUpgradeCost > nCurrentGold then
		caster:Stop()
		Say(caster:GetOwner(),"#Upgrading_hook_speed_not_enough_gold",caster:GetTeam())
	end
	
end

function OnUpgradeHookDamageFinished( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_damage_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookDamage[ nPlayerID ] =  tnHookDamage[ nCurrentLevel + 1 ]
	end
end

function OnUpgradeHookRadiusFinished( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_radius_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookRadius[ nPlayerID ] =  tnHookRadius[ nCurrentLevel + 1 ]
	end
	
end

function OnUpgradeHookLengthFinished( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeLengthCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_length_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookLength[ nPlayerID ] =  tnHookLength[ nCurrentLevel + 1 ]
	end
	
end

function OnUpgradeHookSpeedFinished( keys )

	PrintTable(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	

	if nUpgradeCost > PlayerResource:GetGold(nPlayerID) then
		Say(caster:GetOwner(),"#Upgrading_hook_speed_fail_to_spend_gold",caster:GetTeam())
	else
		-- upgrade the hook data and spend gold
		hHookAbility:SetLevel( nCurrentLevel + 1 )
		PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
		tnPlayerHookSpeed[ nPlayerID ] =  tnHookSpeed[ nCurrentLevel + 1 ]
	end
	
end
