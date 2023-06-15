local mod = ComplianceSun
local game = Game()
local sfx = SFXManager()
local sunSFX = Isaac.GetSoundIdByName("PickupSun")
-- API functions --

if CustomHealthAPI and CustomHealthAPI.Library and CustomHealthAPI.Library.UnregisterCallbacks then
    CustomHealthAPI.Library.UnregisterCallbacks("ComplianceSun")
end

CustomHealthAPI.Library.RegisterSoulHealth(
    "HEART_SUN",
    {
        AnimationFilename = "gfx/ui/ui_remix_hearts.anm2",
        AnimationName = {"SunHeartFull"},
        SortOrder = 100,
        AddPriority = 125,
        HealFlashRO = 240/255, 
        HealFlashGO = 240/255,
        HealFlashBO = 240/255,
        MaxHP = 1,
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

CustomHealthAPI.Library.AddCallback("ComplianceSun", CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED, 0, function(player, flags, key, hpDamaged, wasDepleted, wasLastDamaged)
	if key == "HEART_SUN" then
		if wasDepleted then
			sfx:Play(Isaac.GetSoundIdByName("SunBreak"),1,0)
			--local shatterSPR = Isaac.Spawn(EntityType.ENTITY_EFFECT, 904, 0, player.Position + Vector(0, 1), Vector.Zero, nil):ToEffect():GetSprite()
			--shatterSPR.PlaybackSpeed = 2
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

local function IsLost(player)
	return player:GetPlayerType() == PlayerType.PLAYER_THELOST or player:GetPlayerType() == PlayerType.PLAYER_THELOST_B
end

function mod:CanCollectCustomShopPickup(player, pickup)
	if pickup:IsShopItem() and (pickup.Price > 0 and player:GetNumCoins() < pickup.Price or not player:IsExtraAnimationFinished())  then
		return false
	end
	return true
end

function mod:CollectCustomPickup(player,pickup)
	if not pickup:IsShopItem() then
		pickup:GetSprite():Play("Collect")
		pickup:Die()
	else
		if pickup.Price >= 0 or pickup.Price == PickupPrice.PRICE_FREE or pickup.Price == PickupPrice.PRICE_SPIKES then
			if pickup.Price == PickupPrice.PRICE_SPIKES and not IsLost(player) then
				local tookDamage = player:TakeDamage(2.0, 268435584, EntityRef(nil), 30)
				if not tookDamage then
					return pickup:IsShopItem()
				end
			end
			if pickup.Price >= 0 then
				player:AddCoins(-pickup.Price)
			end
			CustomHealthAPI.Library.TriggerRestock(pickup)
			CustomHealthAPI.Helper.TryRemoveStoreCredit(player)
			pickup:Remove()
			player:AnimatePickup(pickup:GetSprite(), true)
		end
	end
	if pickup.OptionsPickupIndex ~= 0 then
		local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP)
		for _, entity in ipairs(pickups) do
			if entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex and
			(entity.Index ~= pickup.Index or entity.InitSeed ~= pickup.InitSeed)
			then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
				entity:Remove()
			end
		end
	end
	return nil
end

function mod:SunHeartCollision(pickup, collider)
	if collider.Type == EntityType.ENTITY_PLAYER and pickup.SubType == HeartSubType.HEART_SUN then
		local player = collider:ToPlayer()
		if not mod:CanCollectCustomShopPickup(player, pickup) then
			return true
		end
		if ComplianceSun.CanPickSunHearts(player) then
			local collect = mod:CollectCustomPickup(player,pickup)
			if collect ~= nil then
				return collect
			end
			if not IsLost(player) then
				ComplianceSun.AddSunHearts(player, 2)
			end
			sfx:Play(sunSFX,1,0)
			game:GetLevel():SetHeartPicked()
			game:ClearStagesWithoutHeartsPicked()
			game:SetStateFlag(GameStateFlag.STATE_HEART_BOMB_COIN_PICKED, true)
			return true
		else
			return pickup:IsShopItem()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.SunHeartCollision, PickupVariant.PICKUP_HEART)

local grng = RNG()
function mod:PreEternalSpawn(id, var, subtype, pos, vel, spawner, seed)
	if id == EntityType.ENTITY_PICKUP and var == PickupVariant.PICKUP_HEART and subtype == HeartSubType.HEART_ETERNAL and not mod.savedata.Pickups[tostring(seed)] then
		mod.savedata.Pickups[tostring(seed)] = true
		grng:SetSeed(seed, 0)
		if grng:RandomFloat() >= (1 - mod.optionChance / 100) then
			return {id, var, HeartSubType.HEART_SUN, seed }
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.PreEternalSpawn)

function mod:SunClear(rng, pos)
	for i=0, Game():GetNumPlayers()-1 do
		local player = Isaac.GetPlayer(i)
		if ComplianceSun.GetSunHeartsNum(player) > 0 then
			for slot = 0,2 do
				if player:GetActiveItem(slot) ~= nil and player:GetActiveItem(slot) ~= CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					local itemConfig = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot))
					if itemConfig and itemConfig.ChargeType ~= 2 then
						local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
						local battery = itemConfig.MaxCharges * (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1)
						local tocharge = math.min(ComplianceSun.GetSunHeartsNum(player) / 2, battery - charge)
						local newcharge = 0
						for j = 1, tocharge do
							if rng:RandomInt(2) == 1 then
								newcharge = newcharge + 1
							end
						end
						if charge < battery and newcharge > 0 then
							player:SetActiveCharge(charge + newcharge, slot)
							game:GetHUD():FlashChargeBar(player, slot)
							sfx:Play(sunSFX,1,0)
							break
						end
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
		if mod.optionNum == 5 then
			spritename = spritename.."_flashy"
		end
		if mod.optionNum == 6 then
			spritename = spritename.."_bettericons"
		end
		if mod.optionNum == 8 then
			spritename = spritename.."_duxi"
		end
		if mod.optionNum == 9 then
			spritename = spritename.."_sussy" 
		end
		spritename = spritename..".png"
		
		sprite:ReplaceSpritesheet(0,spritename)
		
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_RENDER, mod.SpriteChange, PickupVariant.PICKUP_HEART)