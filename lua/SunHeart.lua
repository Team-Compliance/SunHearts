local mod = ComplianceSun
local game = Game()
local sfx = SFXManager()
local screenHelper = require("lua.screenhelper")
-- API functions --

function ComplianceSun.AddSunHearts(player, amount)
	local index = mod:GetEntityIndex(player)
        player:AddSoulHearts(amount*2)
		--if player:GetSoulHearts() % 2 ~= 0 then
			--player:AddSoulHearts(2) -- if you already have a half heart, a new full sun heart always replaces it instead of adding another heart
		--end
	
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		mod.DataTable[index].SunCharge = mod.DataTable[index].SunCharge + math.ceil(amount)
	else
		mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart + amount
	end
end

function ComplianceSun.GetSunHearts(player)
	local index = mod:GetEntityIndex(player)
	return mod.DataTable[index].ComplianceSunHeart
end

local function CanOnlyHaveSoulHearts(player)
	if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY
	or player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY_B or player:GetPlayerType() == PlayerType.PLAYER_BLACKJUDAS
	or player:GetPlayerType() == PlayerType.PLAYER_JUDAS_B or player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN_B
	or player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B or player:GetPlayerType() == PlayerType.PLAYER_BETHANY_B then
		return true
	end
	return false
end

function mod:SunHeartCollision(entity, collider)
	if collider.Type == EntityType.ENTITY_PLAYER then
		local player = collider:ToPlayer()
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			player = player:GetMainTwin()
		end
		local data = mod.DataTable[mod:GetEntityIndex(player)]
		
		if data.ComplianceSunHeart < (player:GetHeartLimit() - player:GetEffectiveMaxHearts()) then
			if entity.SubType == HeartSubType.HEART_SUN then
				if player:GetPlayerType() ~= PlayerType.PLAYER_THELOST and player:GetPlayerType() ~= PlayerType.PLAYER_THELOST_B then
					ComplianceSun.AddSunHearts(player, 1)
				end
				sfx:Play(492, 1, 2, false, 1, 0)
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

function mod:shouldDeHook()
	local reqs = {
	  not game:GetHUD():IsVisible(),
	  game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD),
	  game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0,
	}
	return reqs[1] or reqs[2] or reqs[3]
end

local pauseColorTimer = 0

local function playersHeartPos(i,hearts,hpOffset,isForgotten)
	if i == 1 then return Options.HUDOffset * Vector(20, 12) + Vector(hearts*6+36+hpOffset, 12) + Vector(0,10) * isForgotten end
	if i == 2 then return screenHelper.GetScreenTopRight(0) + Vector(hearts*6+hpOffset-123,12) + Options.HUDOffset * Vector(-20*1.2, 12) + Vector(0,20) * isForgotten end
	if i == 3 then return screenHelper.GetScreenBottomLeft(0) + Vector(hearts*6+hpOffset+46,-27) + Options.HUDOffset * Vector(20*1.1, -12*0.5) + Vector(0,20) * isForgotten end
	if i == 4 then return screenHelper.GetScreenBottomRight(0) + Vector(hearts*6+hpOffset-131,-27) + Options.HUDOffset * Vector(-20*0.8, -12*0.5) + Vector(0,20) * isForgotten end
	if i == 5 then return screenHelper.GetScreenBottomRight(0) + Vector((-hearts)*6+hpOffset-36,-27) + Options.HUDOffset * Vector(-20*0.8, -12*0.5) end
	return Options.HUDOffset * Vector(20, 12)
end

local function renderingHearts(player,playeroffset)
	local index = mod:GetEntityIndex(player)
	local pType = player:GetPlayerType()
	local isForgotten = pType == PlayerType.PLAYER_THEFORGOTTEN and 1 or 0
	local transperancy = 1
	local isTotalEven = mod.DataTable[index].ComplianceSunHeart == 0
	local level = game:GetLevel()
	if pType == PlayerType.PLAYER_JACOB2_B or player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or isForgotten == 1 then
		transperancy = 0.3
	end
	if isForgotten == 1 then
		player = player:GetSubPlayer()
	end
	local heartIndex = math.ceil(mod.DataTable[index].ComplianceSunHeart) - 1
	local goldHearts = player:GetGoldenHearts()
	local getMaxHearts = player:GetEffectiveMaxHearts() + (player:GetSoulHearts() + player:GetSoulHearts() % 2)
	local eternalHeart = player:GetEternalHearts()
	for i=0, heartIndex do

		local hearts = ((CanOnlyHaveSoulHearts(player) and player:GetBoneHearts() or player:GetEffectiveMaxHearts()) + player:GetSoulHearts()) - (i * 2)
		local hpOffset = hearts%2 ~= 0 and (playeroffset == 5 and -6 or 6) or 0
		--[[local playersHeartPos = {
			[1] = Options.HUDOffset * Vector(20, 12) + Vector(hearts*6+36+hpOffset, 12) + Vector(0,10) * isForgotten,
			[2] = screenHelper.GetScreenTopRight(0) + Vector(hearts*6+hpOffset-123,12) + Options.HUDOffset * Vector(-20*1.2, 12) + Vector(0,20) * isForgotten,
			[3] = screenHelper.GetScreenBottomLeft(0) + Vector(hearts*6+hpOffset+46,-27) + Options.HUDOffset * Vector(20*1.1, -12*0.5) + Vector(0,20) * isForgotten,
			[4] = screenHelper.GetScreenBottomRight(0) + Vector(hearts*6+hpOffset-131,-27) + Options.HUDOffset * Vector(-20*0.8, -12*0.5) + Vector(0,20) * isForgotten,
			[5] = screenHelper.GetScreenBottomRight(0) + Vector((-hearts)*6+hpOffset-36,-27) + Options.HUDOffset * Vector(-20*0.8, -12*0.5)
		}]]
		local offset = playersHeartPos(playeroffset,hearts,hpOffset,isForgotten)--playersHeartPos[playeroffset]
		local offsetCol = (playeroffset == 1 or playeroffset == 5) and 13 or 7
		offset.X = offset.X  - math.floor(hearts / offsetCol) * (playeroffset == 5 and (-72) or (playeroffset == 1 and 72 or 36))
		offset.Y = offset.Y + math.floor(hearts / offsetCol) * 10
		local anim = "SunHeartFull"
		if player:GetEffectiveMaxHearts() == 0 and i == (math.ceil(player:GetSoulHearts()/2) - 1)
		and eternalHeart > 0 then
			anim = anim.."Eternal"
		end
		if goldHearts - i > 0 then
			anim = anim.."Gold"
		end
		if i == 0 and player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
		and getMaxHearts == player:GetHeartLimit() and not player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
		and pType ~= PlayerType.PLAYER_JACOB2_B then
			anim = anim.."Mantle"
		end
		mod.SunSplash.Color = Color(1,1,1,transperancy)
		--[[local rendering = mod.SunSplash.Color.A > 0.1 or game:GetFrameCount() < 1
		if game:IsPaused() then
			pauseColorTimer = pauseColorTimer + 1
			if pauseColorTimer >= 40 and pauseColorTimer <= 60 and rendering then
				mod.SunSplash.Color = Color.Lerp(mod.SunSplash.Color,Color(1,1,1,0.1),0.1)
			end
		else
			pauseColorTimer = 0
			mod.SunSplash.Color = Color.Lerp(mod.SunSplash.Color,Color(1,1,1,1),0.1)--Color(1,1,1,transperancy)
		end]]
		if not mod.SunSplash:IsPlaying(anim) then 
			mod.SunSplash:Play(anim, true)
		end
		mod.SunSplash.FlipX = playeroffset == 5
		mod.SunSplash:Render(Vector(offset.X, offset.Y), Vector(0,0), Vector(0,0))
	end
end

function mod:onRender(shadername)
	if shadername ~= "Sun Hearts" then return end
	if mod:shouldDeHook() then return end
	local isJacobFirst = false
	local pNum = 1
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if player.Parent == nil then
			local index = mod:GetEntityIndex(player)
			if i == 0 and player:GetPlayerType() == PlayerType.PLAYER_JACOB then
				isJacobFirst = true
			end
			
			if (player:GetPlayerType() == PlayerType.PLAYER_LAZARUS_B or player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B) then
				if player:GetOtherTwin() then
					if mod.DataTable[index].i and mod.DataTable[index].i == i then
						mod.DataTable[index].i = nil
					end
					if not mod.DataTable[index].i then
						local otherIndex = mod:GetEntityIndex(player:GetOtherTwin())
						mod.DataTable[otherIndex].i = i
					end
				elseif mod.DataTable[index].i then
					mod.DataTable[index].i = nil
				end
			end
			if player:GetPlayerType() ~= PlayerType.PLAYER_THESOUL_B and not mod.DataTable[index].i then
				if player:GetPlayerType() == PlayerType.PLAYER_ESAU and isJacobFirst then
					renderingHearts(player,5)	
				elseif player:GetPlayerType() ~= PlayerType.PLAYER_ESAU then
					renderingHearts(player,pNum)
					pNum = pNum + 1
				end
				if pNum > 4 then break end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.onRender)

function mod:SunBlock(entity, damage, flag, source, cooldown)
	local player = entity:ToPlayer()
	if player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then return nil end
	local index = mod:GetEntityIndex(player)
	player = player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN_B and player:GetOtherTwin() or player
	if mod.DataTable[index].ComplianceSunHeart > 0 and damage > 0 then
		if not mod.DataTable[index].SunTakeDmg and source.Type ~= EntityType.ENTITY_DARK_ESAU then
			if flag & DamageFlag.DAMAGE_FAKE == 0 then
				if not ((flag & DamageFlag.DAMAGE_RED_HEARTS == DamageFlag.DAMAGE_RED_HEARTS or player:HasTrinket(TrinketType.TRINKET_CROW_HEART)) and player:GetHearts() > 0) then
					local isLastSunEternal = mod.DataTable[index].ComplianceSunHeart == 1 and player:GetSoulHearts() == 1 and player:GetEffectiveMaxHearts() == 0 and player:GetEternalHearts() > 0
					if (mod.DataTable[index].ComplianceSunHeart ~= 0) and not isLastSunEternal then
					--local NumSoulHearts = player:GetSoulHearts() - (1 - player:GetSoulHearts() % 2)
					--if damage == 1 then
					player:AddSoulHearts(-1)
					--end
					end
					--Checking for Half Sun and Eternal heart
					if not isLastSunEternal  then
						mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart - 1
					end
					mod.DataTable[index].SunTakeDmg = true
					player:TakeDamage(1,flag | DamageFlag.DAMAGE_NO_MODIFIERS,source,cooldown)
					if mod.DataTable[index].ComplianceSunHeart > 0 then
						local cd = isLastSunEternal and cooldown or 20
						player:ResetDamageCooldown()
						player:SetMinDamageCooldown(cd)
						if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B or player:GetPlayerType() == PlayerType.PLAYER_ESAU
						or player:GetPlayerType() == PlayerType.PLAYER_JACOB then
							player:GetOtherTwin():ResetDamageCooldown()
							player:GetOtherTwin():SetMinDamageCooldown(cd)		
						end
					end
					return false
				end
			end
		else
			mod.DataTable[index].SunTakeDmg = nil
		end
	else
		mod.DataTable[index].SunTakeDmg = nil
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SunBlock, EntityType.ENTITY_PLAYER)

function mod:HeartHandling(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		player = player:GetSubPlayer()
	end
	local index = mod:GetEntityIndex(player)
	if mod.DataTable[index].ComplianceSunHeart > 0 then
		if ComplianceSun.GetSunHearts(player) > player:GetSoulHearts()/2 or ComplianceSun.GetSunHearts(player) * 2 > player:GetHeartLimit() then
			ComplianceSun.AddSunHearts(player,-1)
			player:AddSoulHearts(2)
		end
		mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart > player:GetSoulHearts() and player:GetSoulHearts() or mod.DataTable[index].ComplianceSunHeart
		local heartIndex = math.ceil(mod.DataTable[index].ComplianceSunHeart)
		for i=0, heartIndex do
			local ExtraHearts = math.ceil(player:GetSoulHearts()) + player:GetBoneHearts() - i
			local sunHeartLastIndex = player:GetSoulHearts() - (player:GetSoulHearts())
			if player:IsBoneHeart(ExtraHearts - 1) or player:IsBlackHeart(ExtraHearts - 1) then
				for j = sunHeartLastIndex , (sunHeartLastIndex - heartIndex * 1), -1 do
					--player:AddSoulHearts(-j)
				end
				local complh = ComplianceSun.GetSunHearts(player)
				ComplianceSun.AddSunHearts(player,-complh)
				if ComplianceSun.GetSunHearts(player) > (player:GetHeartLimit() - player:GetEffectiveMaxHearts()) then
					ComplianceSun.AddSunHearts(player,complh) 
				else
					ComplianceSun.AddSunHearts(player,complh-1) 
				end
				break
				--player:AddSoulHearts(-mod.DataTable[index].ComplianceSunHeart)
				--player:AddBlackHearts(mod.DataTable[index].ComplianceSunHeart)
			end
		end
		
		--if player:GetEffectiveMaxHearts() + player:GetSoulHearts() == player:GetHeartLimit() and mod.DataTable[index].ComplianceSunHeart == 1 then
		--	player:AddSoulHearts(-1)
		--end
		if player:GetSoulHearts() == 0 then
			if ComplianceSun.GetSunHearts(player) ~= 0 then
				mod.DataTable[index].ComplianceSunHeart = 0
			end
		end

	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.HeartHandling)

function mod:PreSunSpawn(heart)
	local rng = RNG()
	if heart.SubType == HeartSubType.HEART_SOUL and heart:GetSprite():IsPlaying("Appear") then
		rng:SetSeed(heart.InitSeed, 35)
		if rng:RandomFloat() >= (95 / 100) then
			heart:Morph(heart.Type,heart.Variant,HeartSubType.HEART_SUN,true,true)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.PreSunSpawn, PickupVariant.PICKUP_HEART)

--hud and sfx reactions in all slots
local function ChargeItem(player)
	
end

function mod:SunClear(rng, pos)
	for i=0, Game():GetNumPlayers()-1 do
		local player = Isaac.GetPlayer(i)
		for slot = 0,2 do
			if player:GetActiveItem(slot) ~= nil then
				local item = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot))
				local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
				local battery = item.MaxCharges * (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1)
				local tocharge = Compliance.GetSunHearts(player) <= (battery - charge) and Compliance.GetSunHearts(player) or (battery - charge)
				player:SetActiveCharge(charge+tocharge,slot)
				Game():GetHUD():FlashChargeBar(player,slot)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.SunClear)

function mod:DefaultWispInit(wisp)
	local player = wisp.Player
	local index = mod:GetEntityIndex(player)
	local wispIndex = mod:GetEntityIndex(wisp)
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		if mod.DataTable[index].SunCharge > 0 then
			wisp:SetColor(Color(1, 213/255, 0, 1, 255/700, 213/700, 0), -1, 1, false, false)
			mod.DataTable[index].SunCharge = mod.DataTable[index].SunCharge - 1
			mod.DataTable[wispIndex].IsSun = 1
		else
			mod.DataTable[wispIndex].IsSun = 0
		end
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.DefaultWispInit, FamiliarVariant.WISP)

function mod:SunWispUpdate(wisp)
	local wispIndex = mod:GetEntityIndex(wisp)
	local wispData = mod:GetData(wisp)
	if not wispData.IsSun then
		wispData.IsSun = 0
	end
	if mod.DataTable[wispIndex].IsSun and wispData.IsSun ~= mod.DataTable[wispIndex].IsSun then
		if mod.DataTable[wispIndex].IsSun > 0 then
			wisp:SetColor(Color(1, 213/255, 0, 1, 255/700, 213/700, 0), -1, 1, false, false)
		end
		wispData.IsSun = mod.DataTable[wispIndex].IsSun
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.SunWispUpdate, FamiliarVariant.WISP)

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
