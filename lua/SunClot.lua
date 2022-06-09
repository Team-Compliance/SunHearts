local mod = ComplianceSun
local game = Game()

function mod:StaticHP(clot)
	if clot.SubType == 20 then
		local data = clot:GetData()
		if not data.TC_HP then
			data.TC_HP = clot.HitPoints
		else
			data.TC_HP = data.TC_HP <= clot.MaxHitPoints and data.TC_HP or clot.MaxHitPoints
			clot.HitPoints = data.TC_HP
		end
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.StaticHP, 238)

function mod:UseSumptorium(boi, rng, player, slot, data)
	local index = mod:GetEntityIndex(player)
	if player:GetPlayerType() == PlayerType.PLAYER_EVE_B then
		local amount = 0
		for _, entity in pairs(Isaac.FindByType(3, 238, 30)) do
			amount = amount + 1
			entity:Kill()
		end
		if amount > 0 then
			player:AddSoulHearts(amount)
			mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart + amount
		end
	end
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseSumptorium, CollectibleType.COLLECTIBLE_SUMPTORIUM)

function mod:UseSumptoriumNoTEve(boi, rng, player, useFlags, slot, data)
	local index = mod:GetEntityIndex(player)
	if mod.DataTable[index].ComplianceSunHeart > 0 and player:GetHearts() == 0 and player:GetPlayerType() ~= PlayerType.PLAYER_EVE_B then
		if mod.DataTable[index].ComplianceSunHeart % 2 ~= 0 then
			SFXManager():Play(Isaac.GetSoundIdByName("SunHeartBreak"),1,0)
			local shatterSPR = Isaac.Spawn(EntityType.ENTITY_EFFECT, 904, 0, player.Position + Vector(0, 1), Vector.Zero, nil):ToEffect():GetSprite()
			shatterSPR.PlaybackSpeed = 2
			local NumSoulHearts = player:GetSoulHearts() - (1 - player:GetSoulHearts() % 2) - mod.DataTable[index].ComplianceSunHeart - 1
			player:RemoveBlackHeart(NumSoulHearts)
		else
			SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS,1,0)
		end
		local clot
		for _, s_clot in ipairs(Isaac.FindByType(3,238,20)) do
			s_clot = s_clot:ToFamiliar()
			if GetPtrHash(s_clot.Player) == GetPtrHash(player) then
				clot = s_clot
				break
			end
		end
		if clot == nil then
			clot = Isaac.Spawn(3, 238, 30, player.Position, Vector(0, 0), player):ToFamiliar()
			local clotData = clot:GetData()
			clotData.TC_HP = 3
			clot.HitPoints = clotData.TC_HP
		else
			local clotData = clot:GetData()
			clotData.TC_HP = clotData.TC_HP + 1
			local SunEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, 903, 0, clot.Position + Vector(0, 1), Vector.Zero, nil):ToEffect()
			SunEffect:GetSprite().Offset = Vector(0, -10)
		end
		player:AddSoulHearts(-1)
		mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart - 1
		player:AnimateCollectible(CollectibleType.COLLECTIBLE_SUMPTORIUM, "UseItem")
		return true
	end
	return nil
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, mod.UseSumptoriumNoTEve, CollectibleType.COLLECTIBLE_SUMPTORIUM)


--SPAWNING
--t eve's ability
function mod:TEveSpawn(baby)
	local player = baby.Player
	local index = mod:GetEntityIndex(player)
	if (player:GetPlayerType() == PlayerType.PLAYER_EVE_B) and (mod.DataTable[index].ComplianceSunHeart > 0) and (baby.SubType == 2) then
		if mod.DataTable[index].ComplianceSunHeart % 2 ~= 0 then
			SFXManager():Play(Isaac.GetSoundIdByName("SunHeartBreak"),1,0)
			local shatterSPR = Isaac.Spawn(EntityType.ENTITY_EFFECT, 904, 0, player.Position + Vector(0, 1), Vector.Zero, nil):ToEffect():GetSprite()
			shatterSPR.PlaybackSpeed = 2
			local NumSoulHearts = player:GetSoulHearts() - (1 - player:GetSoulHearts() % 2) - mod.DataTable[index].ComplianceSunHeart - 1
			player:RemoveBlackHeart(NumSoulHearts)
		end
		local clot
		for _, s_clot in ipairs(Isaac.FindByType(3,238,20)) do
			s_clot = s_clot:ToFamiliar()
			if GetPtrHash(s_clot.Player) == GetPtrHash(player) then
				clot = s_clot
				break
			end
		end
		if clot == nil then
			clot = Isaac.Spawn(3, 238, 30, player.Position, Vector(0, 0), player):ToFamiliar()
			local clotData = clot:GetData()
			clotData.TC_HP = 3
			clot.HitPoints = clotData.TC_HP
		else
			local clotData = clot:GetData()
			clotData.TC_HP = clotData.TC_HP + 1
			local SunEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, 903, 0, clot.Position + Vector(0, 1), Vector.Zero, nil):ToEffect()
			SunEffect:GetSprite().Offset = Vector(0, -10)
		end
		mod.DataTable[index].ComplianceSunHeart = mod.DataTable[index].ComplianceSunHeart - 1
		baby:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.TEveSpawn, 238)