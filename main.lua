ComplianceSun = RegisterMod("Compliance Sun Hearts", 1)
local mod = ComplianceSun
local game = Game()
local json = require("json") 

HeartSubType.HEART_SUN = 910

mod.savedata = {DataTable = {}, DSS = {}, Pickups = {}}
mod.savedata.CustomHealthAPISave = mod.savedata.CustomHealthAPISave or {}
mod.SunSplash = Sprite()
mod.SunSplash:Load("gfx/ui/ui_remix_hearts.anm2",true)

if EID then
	EID:setModIndicatorName("Sun Heart")
	local iconSprite = Sprite()
	iconSprite:Load("gfx/eid_icon_sun_hearts.anm2", true)
	EID:addIcon("SunHeart", "Sun Heart Icon", 0, 10, 9, 0, 1, iconSprite)
	EID:setModIndicatorIcon("SunHeart")
end

function mod:GetEntityData(entity)
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
			local index = tostring(player:GetCollectibleRNG(id):GetSeed())
			if not mod.savedata.DataTable[index] then
				mod.savedata.DataTable[index] = {}
			end
			if not mod.savedata.DataTable[index].lastEternalHearts or not mod.savedata.DataTable[index].lastMaxHearts then
				mod.savedata.DataTable[index].lastEternalHearts = 0
				mod.savedata.DataTable[index].lastMaxHearts = 0
			end
			return mod.savedata.DataTable[index]
		elseif entity.Type == EntityType.ENTITY_FAMILIAR then
			local index = entity:ToFamiliar().InitSeed
			if not mod.savedata.DataTable[index] then
				mod.savedata.DataTable[index] = {}
			end
			return mod.savedata.DataTable[index]
		end
	end
	return nil
end

local function loadscripts(list)
	for _,name in pairs(list) do
		include("lua."..name)
	end
end

local scriptList = {
	"customhealthapi.core",
	"SunHeart",
	"SunClot",
	"deadseascrolls",
}

loadscripts(scriptList)

if MinimapAPI then
    local frame = 1
    local SunSprite = Sprite()
    SunSprite:Load("gfx/ui/sunheart_icon.anm2", true)
    MinimapAPI:AddIcon("SunIcon", SunSprite, "SunHeart", 0)
	MinimapAPI:AddPickup(HeartSubType.HEART_SUN, "SunIcon", EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SUN, MinimapAPI.PickupNotCollected, "hearts", 13000)
end

function mod:OnSave(isSaving)
	local save = {}
	if isSaving then
		save.PlayerData = mod.savedata.DataTable
		save.Pickups = mod.savedata.Pickups
	end
	CustomHealthAPI.Helper.SaveData(isSaving)
	save.CustomHealthAPISave = mod.savedata.CustomHealthAPISave
	save.DSS = mod.savedata.DSS
	save.SpriteStyle = mod.optionNum
	save.AppearanceChance = mod.optionChance
	save.ActOfContrition = mod.optionContrition
	save.showAchievement = true
	mod:SaveData(json.encode(save))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.OnSave)

function mod:GetLoadData(isLoading)
	if mod:HasData() then
		local save = json.decode(mod:LoadData())
		if isLoading then
			if save.PlayerData then
				mod.savedata.DataTable = save.PlayerData
			end
			if save.Pickups then
				mod.savedata.Pickups = save.Pickups
			end
		else
			mod.savedata.DataTable = {}
			mod.savedata.Pickups = {}
		end
		mod.savedata.CustomHealthAPISave = save.CustomHealthAPISave or {}
		CustomHealthAPI.Helper.LoadData()
		mod.savedata.DSS = save.DSS and save.DSS or {}
		mod.optionNum = save.SpriteStyle and save.SpriteStyle or 1
		mod.optionChance = save.AppearanceChance and save.AppearanceChance or 20
	else
		mod.savedata.CustomHealthAPISave = {}
		mod.savedata.DataTable = {}
		mod.savedata.Pickups = {}
		mod.optionNum = 1
		mod.optionChance = 20
		mod.savedata.DSS = {}
	end
end
function mod:OnLoad(isLoading)	
	mod:GetLoadData(isLoading)
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnLoad)