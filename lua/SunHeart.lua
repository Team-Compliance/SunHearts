local mod = ComplianceSun
local game = Game()
local sfx = SFXManager()
local screenHelper = require("lua.screenhelper")
-- API functions --

if CustomHealthAPI and CustomHealthAPI.Library and CustomHealthAPI.Library.UnregisterCallbacks then
    CustomHealthAPI.Library.UnregisterCallbacks("ComplianceSun")
end

CustomHealthAPI.Library.RegisterSoulHealth(
    "HEART_SUN",
    {
        AnimationFilename = "gfx/ui/ui_remix_hearts.anm2",
        AnimationName = {"SunHeartHalf", "SunHeartFull"},
        SortOrder = 149,
        AddPriority = 175,
        HealFlashRO = 240/255, 
        HealFlashGO = 240/255,
        HealFlashBO = 240/255,
        MaxHP = 2,
        PrioritizeHealing = true,
        PickupEntities = {
            {ID = EntityType.ENTITY_PICKUP, Var = PickupVariant.PICKUP_HEART, Sub = HeartSubType.HEART_SUN}
        },
        SumptoriumSubType = 30,  -- immortal heart clot
        SumptoriumSplatColor = Color(1.00, 1.00, 1.00, 1.00, 0.00, 0.00, 0.00),
        SumptoriumTrailColor = Color(1.00, 1.00, 1.00, 1.00, 0.00, 0.00, 0.00),
        SumptoriumCollectSoundSettings = {
            ID = SoundEffect.SOUND_MEAT_IMPACTS,
            Volume = 1.0,
            FrameDelay = 0,
            Loop = false,
            Pitch = 1.0,
            Pan = 0
        }
    }
)

CustomHealthAPI.Library.AddCallback("ComplianceSun",CustomHealthAPI.Enums.Callbacks.ON_SAVE,0,function (savedata,isPreGameExit)
    mod.savedata.CustomHealthAPISave = savedata
end)

CustomHealthAPI.Library.AddCallback("ComplianceSun", CustomHealthAPI.Enums.Callbacks.ON_LOAD, 0, function()
	return mod.savedata.CustomHealthAPISave
end)

CustomHealthAPI.Library.AddCallback("ComplianceSun", CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, otherKey, otherHPDamaged, amountToRemove)
	if otherKey == "HEART_SUN" then
		return 1
	end
end)

CustomHealthAPI.Library.AddCallback("ComplianceSun", CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
	if key == "HEART_SUN" then
		if wasDepleted then
			sfx:Play(Isaac.GetSoundIdByName("SunHeartBreak"),1,0)
			local shatterSPR = Isaac.Spawn(EntityType.ENTITY_EFFECT, 904, 0, player.Position + Vector(0, 1), Vector.Zero, nil):ToEffect():GetSprite()
			shatterSPR.PlaybackSpeed = 2
		else
			player:GetData().SunHeartDamage = true
		end
	end
end)

function ComplianceSun.GetSunHeartsNum(player)
	return CustomHealthAPI.Library.GetHPOfKey(player, "HEART_SUN")
end

function ComplianceSun.AddSunHearts(player, hp)
	CustomHealthAPI.Library.AddHealth(player, "HEART_SUN", hp)
end

function ComplianceSun.CanPickSunHearts(player)
	return CustomHealthAPI.Library.CanPickKey(player, "HEART_SUN")
end

function mod:SunHeartCollision(entity, collider)
	if collider.Type == EntityType.ENTITY_PLAYER then
		local player = collider:ToPlayer()
		if player.Parent ~= nil then return entity:IsShopItem() end
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			player = player:GetMainTwin()
		end
		if ComplianceSun.CanPickSunHearts(player) then
			if entity.SubType == HeartSubType.HEART_SUN then
				if player:GetPlayerType() ~= PlayerType.PLAYER_THELOST and player:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B then
					ComplianceSun.AddSunHearts(player, 2)
				end
				entity.Velocity = Vector.Zero
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity:GetSprite():Play("Collect", true)
				entity:Die()
				return true
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.SunHeartCollision, PickupVariant.PICKUP_HEART)

local grng = RNG()
function mod:PreEternalSpawn(id, var, subtype, pos, vel, spawner, seed)
	if id == EntityType.ENTITY_PICKUP and var == PickupVariant.PICKUP_HEART and subtype == HeartSubType.HEART_ETERNAL then
		grng:SetSeed(seed, 0)
		if grng:RandomFloat() >= (1 - mod.optionChance / 100) then
			return {id, var, HeartSubType.HEART_SUN, seed }
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.PreEternalSpawn)

function mod:SunHeartIFrames(player)
	if player:GetData().SunHeartDamage then
		local cd = 20
		player:ResetDamageCooldown()
		player:SetMinDamageCooldown(cd)
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B or player:GetPlayerType() == PlayerType.PLAYER_ESAU
		or player:GetPlayerType() == PlayerType.PLAYER_JACOB then
			player:GetOtherTwin():ResetDamageCooldown()
			player:GetOtherTwin():SetMinDamageCooldown(cd)
		end
		player:GetData().SunHeartDamage = nil
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.SunHeartIFrames)

function mod:SunClear(rng, pos)
	for i=0, Game():GetNumPlayers()-1 do
		local player = Isaac.GetPlayer(i)
		for slot = 0,2 do
			if player:GetActiveItem(slot) ~= nil then
				local itemConfig = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot))
				if itemConfig and itemConfig.ChargeType ~= 2 then
					local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
					local battery = itemConfig.MaxCharges * (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1)
					local tocharge = ComplianceSun.GetSunHeartsNum(player) <= (battery - charge) and ComplianceSun.GetSunHeartsNum(player) or (battery - charge)
					if charge < battery then
						player:SetActiveCharge(charge+tocharge,slot)
						game:GetHUD():FlashChargeBar(player,slot)
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.SunClear)

function mod:SpriteChange(entity)
	if entity.SubType == HeartSubType.HEART_SUN then
		local sprite = entity:GetSprite()
		local spritename = "gfx/items/pick ups/pickup_001_remix_heart"
		if mod.optionNum == 2 then
			spritename = spritename.."_aladar"
		end
		if mod.optionNum == 3 then
			spritename = spritename.."_peas"
		end
		if mod.optionNum == 6 then
			spritename = spritename.."_flashy"
		end
		if mod.optionNum == 7 then
			spritename = spritename.."_bettericons"
		end
		if mod.optionNum == 9 then
			spritename = spritename.."_duxi"
		end
		if mod.optionNum == 10 then
			spritename = spritename.."_sussy" 
		end
		spritename = spritename..".png"
		
		sprite:ReplaceSpritesheet(0,spritename)
		
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, mod.SpriteChange, PickupVariant.PICKUP_HEART)