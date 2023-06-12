local mod = ComplianceSun
local game = Game()
local sunSFX = Isaac.GetSoundIdByName("PickupSun")

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

---@param clot Entity
function mod:SunClotDeath(clot)
	if clot.Variant == FamiliarVariant.BLOOD_BABY and clot.SubType == 30 then
		local player = clot:ToFamiliar().Player
		for slot = 0,2 do
			if player:GetActiveItem(slot) ~= nil and player:GetActiveItem(slot) ~= CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				local itemConfig = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(slot))
				if itemConfig and itemConfig.ChargeType ~= 2 then
					local charge = player:GetActiveCharge(slot) + player:GetBatteryCharge(slot)
					local battery = itemConfig.MaxCharges * (player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and 2 or 1)
					if charge < battery then
						if itemConfig.ChargeType == 1 then
							player:FullCharge(slot)
						else
							player:SetActiveCharge(charge + 1, slot)
							game:GetHUD():FlashChargeBar(player, slot)
						end
						SFXManager():Play(sunSFX,1,0)
						break
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.SunClotDeath, EntityType.ENTITY_FAMILIAR)