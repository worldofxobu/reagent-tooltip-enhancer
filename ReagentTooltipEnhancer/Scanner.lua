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

local LEGACY_DIFFICULTY = {
    optimal = 0,
    medium = 1,
    easy = 2,
    trivial = 3,
}

local function CommitScannedProfession(self, professionKey, professionName, skillLevel, maxSkillLevel, scannedRecipes, recipeCount)
    local addedCount = 0
    for recipeID in pairs(scannedRecipes) do
        if not self.charDB.recipes[recipeID] then
            addedCount = addedCount + 1
        end
    end

    for recipeID, recipe in pairs(self.charDB.recipes) do
        if recipe.professionKey == professionKey then
            self.charDB.recipes[recipeID] = nil
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

    if addedCount > 0 then
        self:Print("Added %d new %s recipes to the index.", addedCount, professionName)
    end
    if self.RefreshOptions then
        self:RefreshOptions()
    end
    return true
end

function RTE:ScanLegacyCraft(manual)
    if not GetNumCrafts or not GetCraftDisplaySkillLine or not GetCraftInfo then
        return false
    end

    local skillName, skillLevel, maxSkillLevel = self:SafeCall(GetCraftDisplaySkillLine)
    local numCrafts = self:SafeCall(GetNumCrafts) or 0

    if not skillName or skillName == "" or numCrafts == 0 then
        return false
    end

    local professionKey = skillName
    local professionName = skillName
    local scannedRecipes = {}
    local recipeCount = 0

    for craftIndex = 1, numCrafts do
        local craftName, _, craftType = self:SafeCall(GetCraftInfo, craftIndex)
        if craftName and craftType ~= "header" then
            local reagents = {}
            local numReagents = self:SafeCall(GetCraftNumReagents, craftIndex) or 0
            for reagentIndex = 1, numReagents do
                local _, _, count = self:SafeCall(GetCraftReagentInfo, craftIndex, reagentIndex)
                local reagentLink = self:SafeCall(GetCraftReagentItemLink, craftIndex, reagentIndex)
                local reagentID = reagentLink and tonumber(string.match(reagentLink, "item:(%d+)"))
                if reagentID then
                    AddReagent(reagents, reagentID, count or 1)
                end
            end

            if next(reagents) then
                local icon = GetCraftIcon and self:SafeCall(GetCraftIcon, craftIndex) or nil
                local effect = GetCraftDescription and self:SafeCall(GetCraftDescription, craftIndex) or nil
                local craftItemLink = GetCraftItemLink and self:SafeCall(GetCraftItemLink, craftIndex) or nil
                local recipeID = craftItemLink and tonumber(string.match(craftItemLink, ":(%d+)")) or ("craft:" .. craftName)

                scannedRecipes[recipeID] = {
                    recipeID = recipeID,
                    name = craftName,
                    icon = icon,
                    professionKey = professionKey,
                    professionName = professionName,
                    professionSkill = tonumber(skillLevel) or 0,
                    professionMaxSkill = tonumber(maxSkillLevel) or 0,
                    difficulty = LEGACY_DIFFICULTY[craftType] or craftType,
                    effect = effect,
                    reagents = reagents,
                }
                recipeCount = recipeCount + 1
            end
        end
    end

    if recipeCount == 0 then
        return false
    end

    return CommitScannedProfession(self, professionKey, professionName, tonumber(skillLevel) or 0, tonumber(maxSkillLevel) or 0, scannedRecipes, recipeCount)
end

function RTE:ScanLegacyTradeSkill(manual)
    if not GetNumTradeSkills or not GetTradeSkillLine or not GetTradeSkillInfo then
        return false
    end

    local skillName, skillLevel, maxSkillLevel = self:SafeCall(GetTradeSkillLine)
    local numTradeSkills = self:SafeCall(GetNumTradeSkills) or 0

    if not skillName or skillName == "" or numTradeSkills == 0 then
        return false
    end

    local professionKey = skillName
    local professionName = skillName
    local scannedRecipes = {}
    local recipeCount = 0

    for skillIndex = 1, numTradeSkills do
        local skillInfoName, skillType = self:SafeCall(GetTradeSkillInfo, skillIndex)
        if skillInfoName and skillType ~= "header" then
            local reagents = {}
            local numReagents = self:SafeCall(GetTradeSkillNumReagents, skillIndex) or 0
            for reagentIndex = 1, numReagents do
                local _, _, count = self:SafeCall(GetTradeSkillReagentInfo, skillIndex, reagentIndex)
                local reagentLink = self:SafeCall(GetTradeSkillReagentItemLink, skillIndex, reagentIndex)
                local reagentID = reagentLink and tonumber(string.match(reagentLink, "item:(%d+)"))
                if reagentID then
                    AddReagent(reagents, reagentID, count or 1)
                end
            end

            if next(reagents) then
                local icon = GetTradeSkillIcon and self:SafeCall(GetTradeSkillIcon, skillIndex) or nil
                local effect = GetTradeSkillDescription and self:SafeCall(GetTradeSkillDescription, skillIndex) or nil
                local recipeLink = GetTradeSkillRecipeLink and self:SafeCall(GetTradeSkillRecipeLink, skillIndex)
                    or (GetTradeSkillItemLink and self:SafeCall(GetTradeSkillItemLink, skillIndex))
                local recipeID = recipeLink and tonumber(string.match(recipeLink, ":(%d+)")) or ("ts:" .. skillInfoName)

                scannedRecipes[recipeID] = {
                    recipeID = recipeID,
                    name = skillInfoName,
                    icon = icon,
                    professionKey = professionKey,
                    professionName = professionName,
                    professionSkill = tonumber(skillLevel) or 0,
                    professionMaxSkill = tonumber(maxSkillLevel) or 0,
                    difficulty = LEGACY_DIFFICULTY[skillType] or skillType,
                    effect = effect,
                    reagents = reagents,
                }
                recipeCount = recipeCount + 1
            end
        end
    end

    if recipeCount == 0 then
        return false
    end

    return CommitScannedProfession(self, professionKey, professionName, tonumber(skillLevel) or 0, tonumber(maxSkillLevel) or 0, scannedRecipes, recipeCount)
end

function RTE:ScanModernProfession(manual)
    if not C_TradeSkillUI
        or not C_TradeSkillUI.GetBaseProfessionInfo
        or not C_TradeSkillUI.GetAllRecipeIDs
        or not C_TradeSkillUI.GetRecipeInfo
        or not C_TradeSkillUI.GetRecipeSchematic then
        return false, false
    end

    local professionInfo = self:SafeCall(C_TradeSkillUI.GetBaseProfessionInfo)
    local recipeIDs = self:SafeCall(C_TradeSkillUI.GetAllRecipeIDs)

    if type(professionInfo) ~= "table"
        or not professionInfo.professionName
        or type(recipeIDs) ~= "table"
        or #recipeIDs == 0 then
        return false, true
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

    if learnedCount == 0 then
        if manual then
            self:Print("Recipe data is still loading. Try the scan again in a moment.")
        end
        return false, true
    end

    return CommitScannedProfession(self, professionKey, professionName, skillLevel, maxSkillLevel, scannedRecipes, recipeCount), true
end

function RTE:ScanCurrentProfession(manual)
    local success, handled = self:ScanModernProfession(manual)
    if success then
        return true
    end

    if GetNumCrafts and (not handled or (GetNumCrafts() or 0) > 0) then
        if self:ScanLegacyCraft(manual) then
            return true
        end
    end

    if GetNumTradeSkills and (not handled or (GetNumTradeSkills() or 0) > 0) then
        if self:ScanLegacyTradeSkill(manual) then
            return true
        end
    end

    if manual and not handled then
        if not C_TradeSkillUI and not GetNumTradeSkills and not GetNumCrafts then
            self:Print("The profession API is not available on this client.")
        else
            self:Print("Open a profession window, then run |cffffffff/rte scan|r again.")
        end
    end
    return false
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
    pcall(function() scannerFrame:RegisterEvent("NEW_RECIPE_LEARNED") end)
    pcall(function() scannerFrame:RegisterEvent("CRAFT_SHOW") end)
    pcall(function() scannerFrame:RegisterEvent("CRAFT_UPDATE") end)
    scannerFrame:SetScript("OnEvent", function(_, event)
        local delay = (event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW") and 0.35 or 0.15
        RTE:ScheduleProfessionScan(delay, false)
    end)

    self.scannerFrame = scannerFrame
end
