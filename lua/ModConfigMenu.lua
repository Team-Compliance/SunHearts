--#region Mod Config Menu
local mod = ComplianceSun

mod.optionNum = 1
mod.optionChance = 20
mod.optionContrition = 1
    local Options = {
        [1] = "Vanilla",
        [2] = "Aladar",
		[3] = "Lifebar",
		[4] = "Beautiful",
		[5] = "Goncholito",
		[6] = "Flashy", 
		[7] = "Better Icons", 
		[8] = "Eternal Update",
		[9] = "Re-color",
		[10] = "Sussy",
    }

if ModConfigMenu then
    
    local SunMCM = "Sun Hearts"
	ModConfigMenu.UpdateCategory(SunMCM, {
		Info = {"Configuration for Sun Hearts mod.",}
	})

    ModConfigMenu.AddSetting(SunMCM, "Settings",
    {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return mod.optionNum
        end,
        Minimum = 1,
        Maximum = 10,
        Display = function()
            return 'Use sprites: ' .. Options[mod.optionNum]
        end,
        OnChange = function(currentNum)
            mod.optionNum = currentNum
            local spritename = "gfx/ui/ui_remix_hearts"
            if mod.optionNum == 2 then
                spritename = spritename.."_aladar"
            end
            if mod.optionNum == 3 then
                spritename = spritename.."_peas"
            end
            if mod.optionNum == 4 then
                spritename = spritename.."_beautiful"
            end
            if mod.optionNum == 5 then 
                spritename = spritename.."_goncholito"
            end
            if mod.optionNum == 6 then
                spritename = spritename.."_flashy"
            end
            if mod.optionNum == 7 then
                spritename = spritename.."_bettericons"
            end
            if mod.optionNum == 8 then
                spritename = spritename.."_eternalupdate"
            end
            if mod.optionNum == 9 then
                spritename = spritename.."_duxi"
            end
            spritename = spritename..".png"
            for j = 0,4 do
                mod.SunSplash:ReplaceSpritesheet(j,spritename)
            end
            mod.SunSplash:LoadGraphics()
        end,
        Info = "Change appearance of sun hearts."
    })

    ModConfigMenu.AddSetting(SunMCM, "Settings",
    {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return mod.optionChance
        end,
        Default = 20,
        Minimum = 0,
        Maximum = 100,
        Display = function()
            return 'Chance to replace Eternal Heart: '..mod.optionChance..'%'
        end,
        OnChange = function(currentNum)
            mod.optionChance = currentNum
        end,
        Info = "Sun heart's rarity."
    })
	
end