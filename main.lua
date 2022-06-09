ComplianceSun = RegisterMod("Compliance Sun Hearts", 1)
local mod = ComplianceSun
local game = Game()
local json = require("json") 

HeartSubType.HEART_SUN = 910

mod.DataTable = {}
mod.SunSplash = Sprite()
mod.SunSplash:Load("gfx/ui/ui_remix_hearts.anm2",true)

if EID then
	EID:setModIndicatorName("Sun Heart")
	local iconSprite = Sprite()
	iconSprite:Load("gfx/eid_icon_sun_hearts.anm2", true)
	EID:addIcon("SunHeart", "Sun Heart Icon", 0, 10, 9, 0, 1, iconSprite)
	EID:setModIndicatorIcon("SunHeart")
end

include("lua/ModConfigMenu.lua")
include("lua/SunHeart.lua")
include("lua/SunClot.lua")

if MinimapAPI then
    local frame = 1
    local SunSprite = Sprite()
    SunSprite:Load("gfx/ui/sunheart_icon.anm2", true)
    MinimapAPI:AddIcon("SunIcon", SunSprite, "SunHeart", 0)
	MinimapAPI:AddPickup(HeartSubType.HEART_SUN, "SunIcon", EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SUN, MinimapAPI.PickupNotCollected, "hearts", 13000)
end

function onStart(_, bool)
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local index = mod:GetEntityIndex(player)
		if bool == false or mod.DataTable[index].ComplianceSunHeart == nil then
			mod.DataTable[index].ComplianceSunHeart = 0
		end
	end
end

--mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, onStart)

function mod:OnSave(isSaving)
	local save = {}
	if isSaving then
		save.PlayerData = {}
		for key,value in pairs(mod.DataTable) do
			if value ~= nil and key ~= nil then
				save.PlayerData[tostring(key)] = value
			end
		end
	end
	save.SpriteStyle = mod.optionNum
	save.AppearanceChance = mod.optionChance
	save.ActOfContritionChance = mod.optionContrition
	save.showAchievement = true
	mod:SaveData(json.encode(save))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.OnSave)

function mod:OnLoad(isLoading)
	mod.DataTable = {}
	if mod:HasData() then
		local save = json.decode(mod:LoadData())
		if isLoading then
			for key,value in pairs(save.PlayerData) do
				if key ~= nil then
					mod.DataTable[tonumber(key)] = value
				end
			end
		end
		mod.optionNum = save.SpriteStyle and save.SpriteStyle or 1
		mod.optionChance = save.AppearanceChance and save.AppearanceChance or 20
		mod.optionContrition = save.ActOfContritionChance and save.ActOfContritionChance or 1
		
		if EID then
			if mod.optionContrition == 1 then -- Has to be here because of save data
				EID:addCollectible(601, "↑ {{Tears}} +0.7 Tears up#{{SunHeart}} +1 Sun Heart#{{AngelChance}} Allows Angel Rooms to spawn even if you've taken a Devil deal#Taking Red Heart damage doesn't reduce Devil/Angel Room chance as much", "Act of Contrition", "en_us")
				EID:addCollectible(601, "↑ {{Tears}} Lágrimas +0.7#{{SunHeart}} +1 corazón inmortal#{{AngelChance}} Permite que aparezcan salas del ángel aunque hayas hecho pactos con el diablo antes", "Acto de contrición", "spa")
				EID:addCollectible(601, "↑ {{Tears}} +0.7 к скорострельности#{{SunHeart}} +1 бессмертное сердце#{{AngelChance}} Позволяет Ангельским комнатам появляться даже в том случае, если ранее была заключена сделка с Дьяволом#Получение урона красными сердцами не так сильно снижает шанс сделки", "Покаяние", "ru")
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnLoad)

function mod:PostUpdateAchiv()
	local showAchievement
	if not showAchievement then
		showAchievement = mod:HasData() and json.decode(mod:LoadData()).showAchievement or false
		if Isaac.GetPlayer().ControlsEnabled and showAchievement ~= true then
			showAchievement = true
			mod:OnSave(true)
			CCO.AchievementDisplayAPI.PlayAchievement("gfx/ui/achievements/achievement_sunheart.png")
		end	
	end
end

--mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.PostUpdateAchiv)

-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

function mod:GetPlayers(functionCheck, ...)

	local args = {...}
	local players = {}
	
	local game = Game()
	
	for i=1, game:GetNumPlayers() do
	
		local player = Isaac.GetPlayer(i-1)
		
		local argsPassed = true
		
		if type(functionCheck) == "function" then
		
			for j=1, #args do
			
				if args[j] == "player" then
					args[j] = player
				elseif args[j] == "currentPlayer" then
					args[j] = i
				end
				
			end
			
			if not functionCheck(table.unpack(args)) then
			
				argsPassed = false
				
			end
			
		end
		
		if argsPassed then
			players[#players+1] = player
		end
		
	end
	
	return players
	
end

function mod:GetPlayerFromTear(tear)
	for i=1, 3 do
		local check = nil
		if i == 1 then
			check = tear.Parent
		elseif i == 2 then
			check = mod:GetSpawner(tear)
		elseif i == 3 then
			check = tear.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return mod:GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
				local data = mod:GetData(tear)
				data.IsIncubusTear = true
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

function mod:GetSpawner(entity)
	if entity and entity.GetData then
		local spawnData = mod:GetSpawnData(entity)
		if spawnData and spawnData.SpawnerEntity then
			local spawner = mod:GetPtrHashEntity(spawnData.SpawnerEntity)
			return spawner
		end
	end
	return nil
end

function mod:GetSpawnData(entity)
	if entity and entity.GetData then
		local data = mod:GetData(entity)
		return data.SpawnData
	end
	return nil
end

function mod:GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end

function mod:GetEntityIndex(entity)
	if entity then
		if entity.Type == EntityType.ENTITY_PLAYER then
			local player = entity:ToPlayer()
			if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
				player = player:GetOtherTwin()
			end
			local id = 1
			if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
				id = 2
			end
			local index = player:GetCollectibleRNG(id):GetSeed()
			if not mod.DataTable[index] then
				mod.DataTable[index] = {}
			end
			if not mod.DataTable[index].ComplianceSunHeart then
				mod.DataTable[index].ComplianceSunHeart = 0
			end
			if not mod.DataTable[index].lastEternalHearts or not mod.DataTable[index].lastMaxHearts then
				mod.DataTable[index].lastEternalHearts = 0
				mod.DataTable[index].lastMaxHearts = 0
			end
			if player:GetPlayerType() == PlayerType.PLAYER_BETHANY and not mod.DataTable[index].SunCharge then
				mod.DataTable[index].SunCharge = 0
			end
			return index
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			if not mod.DataTable[index] then
				mod.DataTable[index] = {}
			end
			return index
		end
	end
	return nil
end

function mod:GetData(entity)
	if entity and entity.GetData then	
		local data = entity:GetData()
		if not data.SunHeart then
			data.SunHeart = {}
		end
		return data.SunHeart
	end
	return nil
end

function mod:DidPlayerCollectibleCountJustChange(player)
	local index = mod:GetEntityIndex(player)
	if mod.DataTable[index].didCollectibleCountJustChange then
		return true
	end
	return false
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local index = mod:GetEntityIndex(player)
	local currentCollectibleCount = player:GetCollectibleCount()
	if not mod.DataTable[index].lastCollectibleCount then
		mod.DataTable[index].lastCollectibleCount = currentCollectibleCount
	end
	mod.DataTable[index].didCollectibleCountJustChange = false
	if mod.DataTable[index].lastCollectibleCount ~= currentCollectibleCount then
		mod.DataTable[index].didCollectibleCountJustChange = true
	end
	mod.DataTable[index].lastCollectibleCount = currentCollectibleCount
end)

--[[mod.entitySpawnData = {}
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subType, position, velocity, spawner, seed)
	mod.entitySpawnData[seed] = {
		Type = type,
		Variant = variant,
		SubType = subType,
		Position = position,
		Velocity = velocity,
		SpawnerEntity = spawner,
		InitSeed = seed
	}
end)
mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(_, entity)
	local seed = entity.InitSeed
	local data = mod:GetData(entity)
	data.SpawnData = mod.entitySpawnData[seed]
end)
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
	local data = mod:GetData(entity)
	data.SpawnData = nil
end)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	mod.entitySpawnData = {}
end)]]

function mod:Contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

function mod:GetRandomNumber(numMin, numMax, rng)
	if not numMax then
		numMax = numMin
		numMin = nil
	end
	
	rng = rng or RNG()

	if type(rng) == "number" then
		local seed = rng
		rng = RNG()
		rng:SetSeed(seed, 1)
	end
	
	if numMin and numMax then
		return rng:Next() % (numMax - numMin + 1) + numMin
	elseif numMax then
		return rng:Next() % numMin
	end
	return rng:Next()
end

OnRenderCounter = 0
IsEvenRender = true
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	OnRenderCounter = OnRenderCounter + 1
	
	IsEvenRender = false
	if Isaac.GetFrameCount()%2 == 0 then
		IsEvenRender = true
	end
end)

--ripairs stuff from revel
function ripairs_it(t,i)
	i=i-1
	local v=t[i]
	if v==nil then return v end
	return i,v
end
function ripairs(t)
	return ripairs_it, t, #t+1
end

--delayed functions
DelayedFunctions = {}

function mod:DelayFunction(func, delay, args, removeOnNewRoom, useRender)
	local delayFunctionData = {
		Function = func,
		Delay = delay,
		Args = args,
		RemoveOnNewRoom = removeOnNewRoom,
		OnRender = useRender
	}
	table.insert(DelayedFunctions, delayFunctionData)
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	for i, delayFunctionData in ripairs(DelayedFunctions) do
		if delayFunctionData.RemoveOnNewRoom then
			table.remove(DelayedFunctions, i)
		end
	end
end)

local function delayFunctionHandling(onRender)
	if #DelayedFunctions ~= 0 then
		for i, delayFunctionData in ripairs(DelayedFunctions) do
			if (delayFunctionData.OnRender and onRender) or (not delayFunctionData.OnRender and not onRender) then
				if delayFunctionData.Delay <= 0 then
					if delayFunctionData.Function then
						if delayFunctionData.Args then
							delayFunctionData.Function(table.unpack(delayFunctionData.Args))
						else
							delayFunctionData.Function()
						end
					end
					table.remove(DelayedFunctions, i)
				else
					delayFunctionData.Delay = delayFunctionData.Delay - 1
				end
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	delayFunctionHandling(false)
end)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	delayFunctionHandling(true)
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	DelayedFunctions = {}
end)

function mod:EsauCheck(player)
	if not player or (player and not player.GetData) then
		return nil
	end
	local currentPlayer = 1
	for i=1, Game():GetNumPlayers() do
		local otherPlayer = Isaac.GetPlayer(i-1)
		local searchPlayer = i
		--added GetPlayerType() to get Jacob and Easu seperatly
		if otherPlayer.ControllerIndex == player.ControllerIndex and otherPlayer:GetPlayerType() == player:GetPlayerType() then
			currentPlayer = searchPlayer
		end
	end
	return currentPlayer
end