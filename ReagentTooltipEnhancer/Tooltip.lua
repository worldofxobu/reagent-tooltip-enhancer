local _, RTE = ...

local SECTION_TITLE = "Used by your recipes"

local DIFFICULTY = {
    [0] = { text = "Orange", r = 1.00, g = 0.50, b = 0.25 },
    [1] = { text = "Yellow", r = 1.00, g = 1.00, b = 0.00 },
    [2] = { text = "Green",  r = 0.25, g = 0.80, b = 0.25 },
    [3] = { text = "Gray",   r = 0.55, g = 0.55, b = 0.55 },
}

local function GetTooltipItemID(tooltip, tooltipData)
    local ok, itemID = pcall(function()
        if tooltipData and type(tooltipData.id) == "number" then
            return tooltipData.id
        end

        local _, itemLink = tooltip:GetItem()
        if itemLink then
            return tonumber(string.match(itemLink, "item:(%d+)"))
        end
    end)

    return ok and itemID or nil
end

local function TooltipAlreadyContainsSection(tooltip)
    local tooltipName = tooltip:GetName()
    if not tooltipName then
        return false
    end

    for lineIndex = 1, tooltip:NumLines() do
        local line = _G[tooltipName .. "TextLeft" .. lineIndex]
        if line and line:GetText() == SECTION_TITLE then
            return true
        end
    end
    return false
end

local function CleanEffectText(text, maxLength)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|n", " ")
    text = text:gsub("\n", " ")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("%s+", " ")
    text = strtrim(text)

    if text == "" then
        return nil
    end
    if #text > maxLength then
        text = text:sub(1, math.max(1, maxLength - 3)):gsub("%s+%S*$", "") .. "..."
    end
    return text
end

local function AddBlankLine(tooltip)
    if GameTooltip_AddBlankLineToTooltip then
        GameTooltip_AddBlankLineToTooltip(tooltip)
    else
        tooltip:AddLine(" ")
    end
end

local function RecipeIcon(recipe)
    if recipe.icon then
        return string.format("|T%s:13:13:0:0|t ", recipe.icon)
    end
    return ""
end

local function DifficultyText(recipe)
    local difficulty = DIFFICULTY[recipe.difficulty]
    if not difficulty then
        return nil
    end
    return string.format(
        "|cff%02x%02x%02x%s|r",
        difficulty.r * 255,
        difficulty.g * 255,
        difficulty.b * 255,
        difficulty.text
    )
end

local function BuildRightText(recipe, itemID, settings)
    local details = {}

    if settings.showQuantity then
        local quantity = recipe.reagents and recipe.reagents[itemID]
        if quantity and quantity > 0 then
            table.insert(details, "x" .. quantity)
        end
    end

    if settings.showDifficulty then
        local difficulty = DifficultyText(recipe)
        if difficulty then
            table.insert(details, difficulty)
        end
    end

    if settings.showItemLevel and recipe.itemLevel and recipe.itemLevel > 0 then
        table.insert(details, "iLvl " .. recipe.itemLevel)
    end

    return table.concat(details, "  ")
end

local function ProfessionSkillText(recipe, settings)
    if not settings.showProfessionSkill then
        return ""
    end

    local current = tonumber(recipe.professionSkill) or 0
    local maximum = tonumber(recipe.professionMaxSkill) or 0
    if maximum > 0 then
        return string.format("%d/%d", current, maximum)
    end
    return current > 0 and tostring(current) or ""
end

function RTE:AddRecipeSection(tooltip, itemID, recipes)
    if TooltipAlreadyContainsSection(tooltip) then
        return
    end

    local settings = self.settings
    local maximum = math.max(1, tonumber(settings.maxRecipes) or 8)
    local shown = math.min(#recipes, maximum)
    local showEffects = settings.showEffects and shown <= 3
    local previousProfession

    AddBlankLine(tooltip)
    tooltip:AddLine(SECTION_TITLE, 1.00, 0.82, 0.00)

    for index = 1, shown do
        local recipe = recipes[index]
        local professionName = recipe.professionName or "Profession"

        if settings.groupByProfession and professionName ~= previousProfession then
            tooltip:AddDoubleLine(
                professionName,
                ProfessionSkillText(recipe, settings),
                0.35, 0.75, 1.00,
                0.65, 0.65, 0.65
            )
            previousProfession = professionName
        end

        local recipeName = RecipeIcon(recipe) .. (recipe.name or "Unknown recipe")
        if settings.groupByProfession then
            recipeName = "  " .. recipeName
        end

        local rightText = BuildRightText(recipe, itemID, settings)
        tooltip:AddDoubleLine(recipeName, rightText, 1, 1, 1, 0.75, 0.75, 0.75)

        if showEffects then
            local effect = CleanEffectText(recipe.effect, settings.effectMaxLength or 96)
            if effect then
                local indent = settings.groupByProfession and "     " or "  "
                tooltip:AddLine(indent .. effect, 0.62, 0.62, 0.62, true)
            end
        end
    end

    if #recipes > shown then
        tooltip:AddLine(string.format("  +%d more", #recipes - shown), 0.55, 0.55, 0.55)
    elseif settings.showEffects and #recipes > 3 then
        tooltip:AddLine("  Effects hidden for a compact tooltip", 0.45, 0.45, 0.45)
    end

    tooltip:Show()
end

function RTE:TooltipInitialize()
    if not TooltipDataProcessor or not Enum or not Enum.TooltipDataType then
        self:Print("Tooltip API unavailable; the addon could not attach to item tooltips.")
        return
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, tooltipData)
        if not RTE.settings or not RTE.settings.enabled then
            return
        end

        local itemID = GetTooltipItemID(tooltip, tooltipData)
        local recipes = itemID and RTE.recipeIndex[itemID]
        if recipes and #recipes > 0 then
            pcall(RTE.AddRecipeSection, RTE, tooltip, itemID, recipes)
        end
    end)
end
