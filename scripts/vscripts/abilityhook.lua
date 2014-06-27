tHookElements = tHookElements or {}


tHookLastPos = nil
tnHookDamage = {175 , 250 , 350 , 500  }
tnHookLength = {500 , 700 , 900 , 1200 }
tnHookRadius = {20  , 30  , 50  , 80   }
tnHookSpeed  = {400 , 450 , 520 , 600  }
tnUpgradeHookDamageCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookLengthCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookRadiusCost = {500 , 1000 , 1500 , 2000  }
tnUpgradeHookSpeedCost  = {500 , 1000 , 1500 , 2000  }
tnPlayerHookDamage  = {}
tnPlayerHookLength  = {}
tnPlayerHookRadius  = {}
tnPlayerHookSpeed   = {}

tPudgeLastForwardVec = {}
tnPlayerHookType    = {}
tbHookedNothing     = {}

PER_HOOK_BODY_LENGTH = 50

tnHookTypeString = {
	[1] = "npc_dota2x_pudgewars_unit_pudgehook_lv1",
	[2] = "npc_dota2x_pudgewars_unit_pudgehook_lv2",
	[3] = "npc_dota2x_pudgewars_unit_pudgehook_lv3",
	[4] = "npc_dota2x_pudgewars_unit_pudgehook_lv4"
}
tPossibleHookTargetName = {
	 "npc_dota2x_pudgewars_pudge"
	,"npc_dota2x_pudgewars_chest"
	,"npc_dota2x_pudgewars_gold"
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
		Body = {}
	}
	tnPlayerHookType[i] = {tnHookTypeString[1]}
	tnPlayerHookRadius[i] = 20
	tnPlayerHookLength[i] = 500
	tnHookMovedDistance[i] = 0
	tHookLastPos[i] = nil
	tHookCurrentPos[i] = nil
	tbHookedNothing[i] = false
end

print("[pudgewars] finish init hook data")



function OnHookStart(keys)

	PrintTable(keys)
	local caster = EntIndexToHScript(keys.caster_entindex)
	local vOrifin = caster:GetOrigin
	local vForwardVector = caster:GetForwardVector()
	PrintTable(vForwardVector)
	local nPlayerID = keys.unit:GetPlayerID()
	print("player "..tostring(nPlayerID).." Start a hook")
	local unit = CreateUnitByName("npc_dota2x_pudgewars_unit_pudgehook_lv1",caster:GetOrigin(),false,nil,nil,caster:GetTeam())
	if unit == nil then 
		print("fail to create the head")
	else
		tHookElements[nPlayerID].Head = unit
		unit:SetForwardVector(vForwardVector)
	end
	
	local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( nFXIndex, 0, vOrigin())
	tHookElements[nPlayerID].Body[1] = nFXIndex
end
local function GetHookedUnit(caster, head , plyid)
	
	local tuHookedUnits = FindUnitsInRadius(
		caster:GetTeam(),		--caster team
		head:GetOrigin(),		--find position
		nil,					--find entity
		tnPlayerHookRadius[plyid],			--find radius
		DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER, 
		0, FIND_CLOSEST,
		false
	)
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetName() == t then
					va = true
				end
			end
			if not va then
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1 then
		return tuHookedUnits[1]
	end
	return nil
end
function OnHookChanneling(keys)


	local caster = EntIndexToHScript(keys.caster_entindex)
	local casterOrigin = caster:GetOrigin()
	local casterForwardVector = caster:GetFowardVecotr()
	local nPlayerID = caster:GetPlayerID()
	local uHead = tHookElements[nPlayerID].Head
	tHookElements[nPlayerID].Target = GetHookUnit(caster , uHead , nPlayerID )
	
	if tHookElements[nPlayerID].CurrentLength == nil then
		tHookElements[nPlayerID].CurrentLength = 2
	end
	
	if tHookElements[nPlayerID].Target and 
		tHookElements[nPlayerID].CurrentLength * PER_HOOK_BODY_LENGTH < tnPlayerHookLength[nPlayerID]
		then
		if tPudgeLastForwardVec[nPlayerID] == nil then
			tPudgeLastForwardVec[nPlayerID] = casterForwardVector
		end
		
		local aChangedFV = math.acos(casterForwardVector.x) - math.acos((tPudgeLastForwardVec[nPlayerID].x)
		local aChangedFV = aChangedFV / 10
		local x = (math.sin(aChangedFV)) * 1
		local y = (math.cos(aChangedFV)) * 1
		local base = uHead:GetOrigin()
		local vec = (base.x + x * PER_HOOK_BODY_LENGTH , base.y + y * PER_HOOK_BODY_LENGTH , base.z )
		local nFXIndex = ParticleManager:CreateParticle( "veil_of_discord", PATTACH_CUSTOMORIGIN, caster )
		articleManager:SetParticleControl( nFXIndex, 0, vec)
		HookElements[nPlayerID].Body[tHookElements[nPlayerID].CurrentLength] = nFXIndex
		
		uHead:SetOrigin(vec)
		uHead:SetForwardVector(x,y,base.z)
		
		tPudgeLastForwardVec[nPlayerID] = casterForwardVector
	end
	--[[
	--print("********* TRYING TO CATCH UNIT *** *********")
	--PrintTable(tuHookedUnits)
	--print("********************************************")
	--PrintTable(caster)
	--print("********************************************")
	
	tHookElements[nPlayerID].Target = nil
	-- if find any unit then think about it
	if #tuHookedUnits >= 1 then
		for k,v in pairs(tuHookedUnits) do
			local va = false
			for s,t in pairs (tPossibleHookTargetName) do
				if v:GetName == t then
					va = true
				end
			end
			if not va then
				table.remove(tuHookedUnits , k)
			end
		end
	end
	
	if #tuHookedUnits >= 1 then
		tHookElements[nPlayerID].Target = tuHookedUnits[1]
	end


	-- 没有钩中任何单位，也没达到最大距离，继续延长
	if tHookElements[nPlayerID].Target == nil and not tbHookedNothing[nPlayerID] then
		local vHeadOrigin = uHead:GetOrigin()
		local vDirection = caster:GetForwardVector()
		print("print forward vector************************")
		print("x  "..vDirection.x)
		print("y  "..vDirection.y)
		print("z  "..vDirection.z)
		print("********************************************")


		--TODO think about earth shaker's totem
		local vHeadMoveTarget = Vector(vHeadOrigin.x + 200 * vDirection.x , vHeadOrigin.y + 200 * vDirection.y , vHeadOrigin.z)

              -- Begin to rewrite hook
              --better sleep first
              -- Todo 2014 06 27 00 49

		--order the head to move
		local moveOrder = {
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vHeadMoveTarget,
			Queue = false
		}
		ExecuteOrderFromTable(moveOrder)

		-- check the head moved distance
		tHookCurrentPos[nPlayerID] = vHeadOrigin
		if tHookLastPos[nPlayerID] == nil then 
			tHookLastPos[nPlayerID] = tHookCurrentPos[nPlayerID]
		end
		tnHookMovedDistance[nPlayerID] = tnHookMovedDistance[nPlayerID]  + distance( tHookCurrentPos[nPlayerID] , tHookLastPos[nPlayerID])
		tHookLastPos[nPlayerID] = tHookCurrentPos[nPlayerID]
		print("moved_length**************************")
		print(tostring(tnHookMovedDistance[nPlayerID]))

		--[[
		if tnHookMovedDistance[nPlayerID] >= tnPlayerHookLength[nPlayerID] then
			tbHookedNothing[nPlayerID] = true
		end
		

		if #tHookElements[nPlayerID].Body == 0 then
			latestedCreateBody[nPlayerID] = caster
		else
			latestedCreateBody[nPlayerID] = tHookElements[nPlayerID].Body[#tHookElements[nPlayerID].Body]
		end

		if distance(tHookCurrentPos[nPlayerID] , latestedCreateBody[nPlayerID]:GetOrigin()) > 70 then
			local unit = CreateUnitByName(
				"npc_dota2x_pudgewars_unit_pudgehook_body",
				uHead:GetOrigin(),
				false,nil,nil,
				caster:GetTeam()
			)
			if unit == nil then 
				print("fail to create the head")
			else
				table.insert( tHookElements[nPlayerID].Body , #tHookElements[nPlayerID].Body + 1 , unit )
			end
		end

	end
	--[[ if hook someone then catch it
	if tHookElements[nPlayerID].Target ~= nil then
		
		print("tHookElements[nPlayerID].Target ~= nil" )
		print(type(tHookElements[nPlayerID].Target))
		for k,v in pairs(tHookElements[nPlayerID].Target) do
			print(k,v)
		end
		local lassoAbility = uHead:FindAbilityByName("ability_dota2x_pudgewars_lasso")
		if lassoAbility == nil then
			uHead:AddAbility("ability_dota2x_pudgewars_lasso")
		end
		lassoAbility = uHead:FindAbilityByName("ability_dota2x_pudgewars_lasso")
		lassoAbility:SetLevel(1)
		--[[
		ExecuteOrderFromTable({
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			Ability = lassoAbility,
			Target = tHookElements[nPlayerID].Target,
			Queue = false
		})
	end
	-- if max length then call the elements back
	if tbHookedNothing[nPlayerID] or tHookElements[nplayerID].Target then

		local uHead = tHookElements[nPlayerID].Head
		local nBodyCount = #tHookElements[nPlayerID].Body
		local nearestUnit = tHookElements[nPlayerID].Body[nBodyCount]

		local moveOrder = {
			UnitIndex = uHead:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = nearestUnit:GetOrigin(),
			Queue = false
		}
		ExecuteOrderFromTable(moveOrder)
		
		
		if distance(nearestUnit:GetOrigin() , uHead:GetOrigin()) < 30 then
			local unitToRemove = tHookElements[nPlayerID].Body[nBodyCount]
			unitToRemove:Remove()
			table.remove( tHookElements[nPlayerID].Body , nBodyCount )
		end
	end
	--]]
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

	tPrint(keys)
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

	tPrint(keys)
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

	tPrint(keys)
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

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
	local nCurrentLevel = hHookAbility:GetLevel()
	local nUpgradeCost  = tnUpgradeHookDamageCost[nCurrentLevel]
	
	-- upgrade the hook data and spend gold
	hHookAbility:SetLevel( nCurrentLevel + 1 )
	PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
	tnPlayerHookDamage[ nPlayerID ] =  tnHookDamage[ nCurrentLevel + 1 ]

end

function OnUpgradeHookRadiusFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookRadiusCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	-- upgrade the hook data and spend gold
	hHookAbility:SetLevel( nCurrentLevel + 1 )
	PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
	tnPlayerHookRadius[ nPlayerID ] =  tnHookRadius[ nCurrentLevel + 1 ]
	
end

function OnUpgradeHookLengthFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeLengthCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	-- upgrade the hook data and spend gold
	hHookAbility:SetLevel( nCurrentLevel + 1 )
	PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
	tnPlayerHookLength[ nPlayerID ] =  tnHookLength[ nCurrentLevel + 1 ]
	
end

function OnUpgradeHookSpeedFinished( keys )

	tPrint(keys)
	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()

	local caster = keys.Caster
	local nPlayerID = caster:GetPlayerID()
	local nUpgradeCost  = tnUpgradeHookSpeedCost[nCurrentLevel]

	local hHookAbility  = caster:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
	local nCurrentLevel = hHookAbility:GetLevel()
	
	-- upgrade the hook data and spend gold
	hHookAbility:SetLevel( nCurrentLevel + 1 )
	PlayerResource:SpendGold( nPlayerID , nUpgradeCost , 0 )
	tnPlayerHookSpeed[ nPlayerID ] =  tnHookSpeed[ nCurrentLevel + 1 ]
	
end
