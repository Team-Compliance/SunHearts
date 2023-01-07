local mod = ComplianceSun
local game = Game()

function mod:StaticHP(clot)
	if clot.SubType == 30 then
		local clotData = clot:GetData()
		if (clotData.TC_HP == nil) then
			clotData.TC_HP = clot.HitPoints
		else
			local damageTaken = clotData.TC_HP - clot.HitPoints
			if (damageTaken > 0.19 and damageTaken < 0.21) then
				clot.HitPoints = clot.HitPoints + damageTaken
			elseif (damageTaken > 1.19 and damageTaken < 1.21) then
				clot.HitPoints = clot.HitPoints - 1.0
			else
				clotData.TC_HP = clot.HitPoints
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, mod.StaticHP, 238)

--SPAWNING
--t eve's ability
function mod:SunClotSpawn(baby)
	local player = baby.Player
	if baby.SubType == 30 then
		if ComplianceSun.GetSunHeartsNum(player) % 2 == 0 then
			SFXManager():Play(Isaac.GetSoundIdByName("SunHeartBreak"),1,0)
			local shatterSPR = Isaac.Spawn(EntityType.ENTITY_EFFECT, 904, 0, player.Position + Vector(0, 1), Vector.Zero, nil):ToEffect():GetSprite()
			shatterSPR.PlaybackSpeed = 2
		end
		local clot
		for _, s_clot in ipairs(Isaac.FindByType(3,238,30)) do
			s_clot = s_clot:ToFamiliar()
			if GetPtrHash(s_clot.Player) == GetPtrHash(player) and GetPtrHash(baby) ~= GetPtrHash(s_clot) then
				clot = s_clot
				break
			end
		end
		if clot ~= nil then
			local clotData = clot:GetData()
			clotData.TC_HP = clotData.TC_HP + 1
			local SunEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, 903, 0, clot.Position + Vector(0, 1), Vector.Zero, nil):ToEffect()
			SunEffect:GetSprite().Offset = Vector(0, -10)
			baby:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.SunClotSpawn, 238)

function mod:SunClotClear(rng, pos)
	if #Isaac.FindByType(3,238,30) > 0 then	
		for i=0, game:GetNumPlayers()-1 do
			local player = Isaac.GetPlayer(i)
			for slot = 0,2 do
				if player:GetActiveItem(slot) ~= nil then
					local item = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot))
					if item.ChargeType ~= 2 and ComplianceSun.GetSunHeartsNum(player) == 0 then
						local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
						local battery = item.MaxCharges * (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1)
						if charge < battery then
							player:SetActiveCharge(charge+1,slot)
							game:GetHUD():FlashChargeBar(player,slot)
						end
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.SunClotClear)