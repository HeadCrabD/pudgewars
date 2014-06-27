tbPlayerFinishedHook = {}
tbPlayerReachesMaxLength = {}

tHookElements = tHookElements or {}

WORLDMAX_VEC = Vector(GetWorldMaxX(),GetWorldMaxY(),0)

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
	,"dota_goodguys_tower1_top"
	--,"npc_dota2x_pudgewars_rune" TODO

}

local function distance(a, b)
    -- Pythagorian distance
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)

    return math.sqrt(xx*xx + yy*yy)
end

for i = 0,9 do
	tHookElements[i] = {
		Head = nil,
		Target = nil,
		CurrentLength = nil,
		Body = {}
	}
	tnPlayerHookType[i] = tnHookTypeString[1]
	tnPlayerHookBDType[i] = tnHookParticleString[3]
	tnPlayerHookRadius[i] = 50
	tnPlayerHookLength[i] = 1200
	tnPlayerHookSpeed[i] = 0.2

end

print("[pudgewars] finish init hook data")



function OnHookStart(keys)

	-- a player starts a hook
	--PrintTable(keys)
	
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vOrigin = caster:GetOrigin()
	local vForwardVector = caster:GetForwardVector()
	--PrintTable(vForwardVector)
	local nPlayerID = keys.unit:GetPlayerID()

	tbPlayerFinishedHook[nPlayerID] = false
	tbPlayerReachesMaxLength[nPlayerID] = false

	print("player "..tostring(nPlayerID).." Start a hook")
	
	-- create the hook head
	local casterOrigin = caster:GetOrigin()
	casterOrigin.z = casterOrigin.z - 30
	local unit = CreateUnitByName("npc_dota2x_pudgewars_unit_pudgehook_lv1",casterOrigin,false,nil,nil,caster:GetTeam())
	
	
	if unit == nil then 
		print("fail to create the head")
	else
		tHookElements[nPlayerID].Head = unit
		unit:SetForwardVector(vForwardVector)
		-- TODO change the model scale to the correct hook radiu
		--unit:SetModelScele(40 / tnPlayerHookRadius[nPlayerID] , -1 )
	end

	casterOrigin.x= casterOrigin.x + 300
	local unit = CreateUnitByName("npc_dota2x_pudgewars_unit_test",Vector(vOrigin.x + 200 ,vOrigin.y,vOrigin.z),false,nil,nil,caster:GetTeam())
	
	-- TODO replace "veil of discord" with correct particle， or even a table of effect 
	-- defined by units killed by the caster
	
	--local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, caster )
	
	local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ] , PATTACH_CUSTOMORIGIN, caster )
	vOrigin.z = vOrigin.z + 150
	ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 1, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 2, vOrigin )
	ParticleManager:SetParticleControl( nFXIndex, 3, vOrigin )
	tHookElements[nPlayerID].Body[1] = {
	    index = nFXIndex,
	    vec = vOrigin
	}
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
			print("unit" .. tostring(k)..":"..v:GetName())
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetName() == t then
					-- the unit in the table , a valid hook unit
					va = true
				end
			end
			if not va then
				-- not a valid unit , remove
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1  and tuHookedUnits[1] ~= caster then
		-- return the nearest unit
		return tuHookedUnits[1]
	end
	return nil
end

local function HookUnit( unit , caster )
	print ( "hooking enemy" )

	local casterOrigin = caster:GetOrigin()
	local uOrigin = unit:GetOrigin()
	
	local nFXIndex = ParticleManager:CreateParticle( "necrolyte_scythe", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl(nFXIndex,0,casterOrigin)
	ParticleManager:SetParticleControl(nFXIndex,1,casterOrigin)
	ParticleManager:SetParticleControl(nFXIndex,2,uOrigin)
	ParticleManager:ReleaseParticleIndex(nFXIndex)

	unit:AddNewModifier(caster,nil,"dota2x_modifier_hooked",{})

	local dmg = tnPlayerHookDamage[plyid]
	local hp = unit:GetHealth()
	if dmg > hp then
		-- take away health directly
		unit:SetHealth(hp-dmg)
	else
		-- ADD THE ABILITY "ability_deal_the_last_hit" AND DEAL DAMAGE WITH THE SPELL
		caster:AddAbility("ability_deal_the_last_hit")
		local ABILITY_LAST_HIT = caster:FindAbilityByName("ability_deal_the_last_hit")
		ABILITY_LAST_HIT:SetLevel(1)
		ExecuteOrderFromTable({
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = ABILITY_LAST_HIT:entindex(),
			TargetIndex = unit:entindex()
		})
		caster:RemoveAbility("ability_deal_the_last_hit")
	end
	if unit:HasModifier(" dota2x_modifier_hooked ") then
		return 1
	else
		return nil
	end




end

function OnHookChanneling(keys)


	local caster = EntIndexToHScript(keys.caster_entindex)
	local casterOrigin = caster:GetOrigin()
	local casterForwardVector = caster:GetForwardVector()
	local nPlayerID = caster:GetPlayerID()
	
	if not tbPlayerFinishedHook[nPlayerID] then
		local uHead = tHookElements[nPlayerID].Head
		if uHead ~= nil 
			and tHookElements[nPlayerID].Target == nil 
			and not tbPlayerReachesMaxLength[nPlayerID]
			then
			tHookElements[nPlayerID].Target = GetHookedUnit(caster , uHead , nPlayerID )
		end
		
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

			
			if tPlayerPudgeLastFV[nPlayerID] == nil then
				tPlayerPudgeLastFV[nPlayerID] = casterForwardVector
			end


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

			local resultRad = baseRad + ((angleCurrentRad) - angleLastRad ) / 10

			local vec3 = Vector(
				 base.x + math.cos(resultRad) * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
				,base.y + math.sin(resultRad) * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID]
				,base.z
			)
			uHead:SetOrigin(vec3)
			uHead:SetForwardVector( Vector(math.cos(resultRad), math.sin(resultRad),0))
			local nFXIndex = ParticleManager:CreateParticle( tnPlayerHookBDType[ nPlayerID ], PATTACH_CUSTOMORIGIN, caster )
			
			tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body + 1] = {
			    index = nFXIndex,
			    vec = vec3
			}

			vec3.z = vec3.z + 150
			ParticleManager:SetParticleControl( nFXIndex, 0, vec3)
			ParticleManager:SetParticleControl( nFXIndex, 1, vec3 )
			ParticleManager:SetParticleControl( nFXIndex, 2, vec3)
			ParticleManager:SetParticleControl( nFXIndex, 3, vec3)
			
			tPlayerPudgeLastFV[nPlayerID] = casterForwardVector
		end
		-- if hoooked someone then hook it
		
		local hooked = nil
		if tHookElements[nPlayerID].Target then
			AppendToLogFile("log/pudgewars.txt","fond a target"..tHookElements[nPlayerID].Target:GetName())
			local unit = tHookElements[nPlayerID].Target
			hooked = HookUnit( unit , caster )
			AppendToLogFile("log/pudgewars.txt",tostring(hooked))

		end
		

		--if hooked something or hook reaches the max length then begin to go back
		if (tHookElements[nPlayerID].Target and hooked ) or  
			(tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH * tnPlayerHookSpeed[nPlayerID] 
				> tnPlayerHookLength[nPlayerID])
			then

			tbPlayerReachesMaxLength[nPlayerID] = true

			local backVec = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].vec
			local paIndex = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body].index
			
			ParticleManager:SetParticleControl( paIndex, 0, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 1, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 2, WORLDMAX_VEC)
			ParticleManager:SetParticleControl( paIndex, 3, WORLDMAX_VEC)

			ParticleManager:ReleaseParticleIndex( paIndex )

			uHead:SetOrigin(backVec)
			
			if tHookElements[nPlayerID].Target then
				tHookElements[nPlayerID].Target:SetOrigin(Vector(backVec.x,backVec.y,tHookElements[nPlayerID].Target:GetOrigin().z))
			end

			table.remove(tHookElements[nPlayerID].Body,#tHookElements[nPlayerID].Body)
			
			if #tHookElements[nPlayerID].Body == 0 then
				if tHookElements[nPlayerID].Target ~= nil then
					if tHookElements[nPlayerID].Target:IsAlive() then
						tHookElements[nPlayerID].Target:RemoveModifierByName( "dota2x_modifier_hooked" )
					end
				end
				
				hooked = false
				tHookElements[nPlayerID].CurrentLength = nil
				uHead:Remove()
				tHookElements[nPlayerID].Head = nil
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
