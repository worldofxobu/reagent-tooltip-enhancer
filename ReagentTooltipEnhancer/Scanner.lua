local _, RTE = ...

RTE.recipeIndex = {}

local function NormalizedProfessionKey(info)
    local professionID = info.parentProfessionID or info.professionID
    if professionID then
        return tostring(professionID)
    end
    return info.parentProfessionName or info.professionName or "Unknown"
end

local function AddReagent(reagents, itemID, quantity)
    if type(itemID) ~= "number" then
        return
    end

    quantity = tonumber(quantity) or 1
    reagents[itemID] = math.max(reagents[itemID] or 0, quantity)
end

local function CollectReagents(schematic)
    local reagents = {}
    local slots = schematic and schematic.reagentSlotSchematics

    if type(slots) ~= "table" then
        return reagents
    end

    for _, slot in ipairs(slots) do
        local quantity = slot.quantityRequired or 1

        if type(slot.reagents) == "table" then
            for _, reagent in ipairs(slot.reagents) do
                AddReagent(reagents, reagent.itemID, quantity)
            end
        end

        if type(slot.variableQuantities) == "table" then
            for _, variable in ipairs(slot.variableQuantities) do
                local reagent = variable.reagent
                AddReagent(reagents, reagent and reagent.itemID, variable.quantity or quantity)
            end
        end
    end

    return reagents
end

local function GetRecipeDescription(recipeID)
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeDescription then
        return nil
    end

    local description = RTE:SafeCall(C_TradeSkillUI.GetRecipeDescription, recipeID, {})
    if not description then
        -- Some client branches retain the older one-argument signature.
        description = RTE:SafeCall(C_TradeSkillUI.GetRecipeDescription, recipeID)
    end

    if type(description) == "string" and description ~= "" then
        return description
    end
    return nil
end

function RTE:RebuildRecipeIndex()
    local index = {}

    for _, recipe in pairs(self.charDB.recipes) do
        if type(recipe.reagents) == "table" then
            for itemID in pairs(recipe.reagents) do
                index[itemID] = index[itemID] or {}
                table.insert(index[itemID], recipe)
            end
        end
    end

    for _, recipes in pairs(index) do
        table.sort(recipes, function(left, right)
            local leftProfession = left.professionName or ""
            local rightProfession = right.professionName or ""
            if leftProfession ~= rightProfession then
                return leftProfession < rightProfession
            end
            return (left.name or "") < (right.name or "")
        end)
    end

    self.recipeIndex = index
end

function RTE:ClearCache(quiet)
    wipe(self.charDB.recipes)
    wipe(self.charDB.professions)
    wipe(self.recipeIndex)

    if not quiet then
        self:Print("Recipe cache cleared. Open each profession to rebuild it.")
    end
    if self.RefreshOptions then
        self:RefreshOptions()
    end
end

function RTE:ScanCurrentProfession(manual)
    if not C_TradeSkillUI
        or not C_TradeSkillUI.GetBaseProfessionInfo
        or not C_TradeSkillUI.GetAllRecipeIDs
        or not C_TradeSkillUI.GetRecipeInfo
        or not C_TradeSkillUI.GetRecipeSchematic then
        if manual then
            self:Print("The profession API is not available on this client.")
        end
        return false
    end

    local professionInfo = self:SafeCall(C_TradeSkillUI.GetBaseProfessionInfo)
    local recipeIDs = self:SafeCall(C_TradeSkillUI.GetAllRecipeIDs)

    if type(professionInfo) ~= "table"
        or not professionInfo.professionName
        or type(recipeIDs) ~= "table"
        or #recipeIDs == 0 then
        if manual then
            self:Print("Open a profession window, then run |cffffffff/rte scan|r again.")
        end
        return false
    end

    local professionKey = NormalizedProfessionKey(professionInfo)
    local professionName = professionInfo.parentProfessionName or professionInfo.professionName
    local skillLevel = professionInfo.skillLevel or 0
    local maxSkillLevel = professionInfo.maxSkillLevel or 0
    local scannedRecipes = {}
    local learnedCount = 0
    local recipeCount = 0

    for _, recipeID in ipairs(recipeIDs) do
        local info = self:SafeCall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if type(info) == "table" and info.learned and not info.isDummyRecipe then
            learnedCount = learnedCount + 1
            local schematic = self:SafeCall(
                C_TradeSkillUI.GetRecipeSchematic,
                recipeID,
                info.isRecraft and true or false
            )
            local reagents = CollectReagents(schematic)

            if next(reagents) then
                scannedRecipes[recipeID] = {
                    recipeID = recipeID,
                    name = info.name or (schematic and schematic.name) or ("Recipe " .. recipeID),
                    icon = info.icon or (schematic and schematic.icon),
                    professionKey = professionKey,
                    professionName = professionName,
                    professionSkill = skillLevel,
                    professionMaxSkill = maxSkillLevel,
                    difficulty = info.relativeDifficulty,
                    maxTrivialLevel = info.maxTrivialLevel,
                    itemLevel = info.itemLevel,
                    effect = GetRecipeDescription(recipeID),
                    reagents = reagents,
                }
                recipeCount = recipeCount + 1
            end
        end
    end

    -- A profession can briefly report an empty recipe list while its data is
    -- still arriving. Preserve the last good cache and let the next list-update
    -- event try again instead of replacing valid data with an empty scan.
    if learnedCount == 0 then
        if manual then
            self:Print("Recipe data is still loading. Try the scan again in a moment.")
        end
        return false
    end

    local oldCount = 0
    for recipeID, recipe in pairs(self.charDB.recipes) do
        if recipe.professionKey == professionKey then
            self.charDB.recipes[recipeID] = nil
            oldCount = oldCount + 1
        end
    end
    for recipeID, recipe in pairs(scannedRecipes) do
        self.charDB.recipes[recipeID] = recipe
    end

    self.charDB.professions[professionKey] = {
        name = professionName,
        skillLevel = skillLevel,
        maxSkillLevel = maxSkillLevel,
        recipeCount = recipeCount,
        lastScan = time(),
    }

    self:RebuildRecipeIndex()

    if manual or oldCount ~= recipeCount then
        self:Print("Indexed %d known %s recipes.", recipeCount, professionName)
    end
    if self.RefreshOptions then
        self:RefreshOptions()
    end
    return true
end

function RTE:ScheduleProfessionScan(delay, manual)
    if self.scanScheduled then
        return
    end

    self.scanScheduled = true
    C_Timer.After(delay or 0.25, function()
        RTE.scanScheduled = false
        RTE:ScanCurrentProfession(manual)
    end)
end

function RTE:ScannerInitialize()
    self:RebuildRecipeIndex()

    local scannerFrame = CreateFrame("Frame")
    scannerFrame:RegisterEvent("TRADE_SKILL_SHOW")
    scannerFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
    scannerFrame:RegisterEvent("NEW_RECIPE_LEARNED")
    scannerFrame:SetScript("OnEvent", function(_, event)
        local delay = event == "TRADE_SKILL_SHOW" and 0.35 or 0.15
        RTE:ScheduleProfessionScan(delay, false)
    end)

    self.scannerFrame = scannerFrame
end
