local _, RTE = ...

local controls = {}
local professionControls = {}

local function SetCheckboxText(checkbox, text)
    if checkbox.Text then
        checkbox.Text:SetText(text)
    else
        local label = _G[checkbox:GetName() .. "Text"]
        if label then
            label:SetText(text)
        end
    end
end

local function CreateCheckbox(panel, key, label, description, anchor)
    local name = "RTEOption" .. key
    local checkbox = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    SetCheckboxText(checkbox, label)
    checkbox.tooltipText = label
    checkbox.tooltipRequirement = description
    checkbox:SetScript("OnClick", function(self)
        RTE.settings[key] = self:GetChecked() and true or false
    end)
    checkbox.settingKey = key
    controls[#controls + 1] = checkbox
    return checkbox
end

local function CreateStepper(panel, key, label, minimum, maximum, step, anchor)
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(420, 28)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)

    local labelText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetText(label)

    local minus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    minus:SetSize(28, 22)
    minus:SetPoint("LEFT", 260, 0)
    minus:SetText("-")

    local value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    value:SetSize(45, 20)
    value:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    value:SetJustifyH("CENTER")

    local plus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    plus:SetSize(28, 22)
    plus:SetPoint("LEFT", value, "RIGHT", 4, 0)
    plus:SetText("+")

    local function Change(delta)
        local current = tonumber(RTE.settings[key]) or minimum
        RTE.settings[key] = math.max(minimum, math.min(maximum, current + delta))
        value:SetText(RTE.settings[key])
    end

    minus:SetScript("OnClick", function() Change(-step) end)
    plus:SetScript("OnClick", function() Change(step) end)

    row.settingKey = key
    row.valueText = value
    controls[#controls + 1] = row
    return row
end

local function GetSortedProfessions()
    local professions = {}

    if RTE.charDB and RTE.charDB.professions then
        for professionKey, profession in pairs(RTE.charDB.professions) do
            professions[#professions + 1] = {
                key = professionKey,
                name = profession.name or "Profession",
                recipeCount = profession.recipeCount or 0,
            }
        end
    end

    table.sort(professions, function(left, right)
        return left.name < right.name
    end)
    return professions
end

local function CreateProfessionFilter(panel, anchor)
    local frame = CreateFrame("Frame", nil, panel)
    frame:SetSize(540, 68)
    frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -22)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("Included professions")

    local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Choose which of this character's discovered professions appear in tooltips.")

    local includeAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    includeAll:SetSize(88, 22)
    includeAll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -94, 3)
    includeAll:SetText("Include all")
    includeAll:SetScript("OnClick", function()
        for professionKey in pairs(RTE.charDB.professions) do
            RTE.charDB.professionVisibility[professionKey] = true
        end
        RTE:RefreshOptions()
    end)

    local excludeAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    excludeAll:SetSize(88, 22)
    excludeAll:SetPoint("LEFT", includeAll, "RIGHT", 6, 0)
    excludeAll:SetText("Exclude all")
    excludeAll:SetScript("OnClick", function()
        for professionKey in pairs(RTE.charDB.professions) do
            RTE.charDB.professionVisibility[professionKey] = false
        end
        RTE:RefreshOptions()
    end)

    local emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    emptyText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 4, -10)
    emptyText:SetText("No professions discovered yet. Open a profession window to add it here.")

    frame.emptyText = emptyText
    frame.includeAll = includeAll
    frame.excludeAll = excludeAll
    return frame
end

function RTE:RefreshProfessionControls()
    local frame = self.professionFilterFrame
    if not frame then
        return
    end

    local professions = GetSortedProfessions()
    for index, profession in ipairs(professions) do
        local checkbox = professionControls[index]
        if not checkbox then
            checkbox = CreateFrame(
                "CheckButton",
                "RTEProfessionFilter" .. index,
                frame,
                "InterfaceOptionsCheckButtonTemplate"
            )
            checkbox:SetScript("OnClick", function(control)
                RTE.charDB.professionVisibility[control.professionKey] = control:GetChecked() and true or false
                RTE:RefreshOptions()
            end)
            professionControls[index] = checkbox
        end

        checkbox:ClearAllPoints()
        checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -42 - ((index - 1) * 24))
        checkbox.professionKey = profession.key
        checkbox.tooltipText = profession.name
        checkbox.tooltipRequirement = "Include recipes from this profession in reagent tooltips."
        SetCheckboxText(checkbox, string.format("%s  |cff888888(%d recipes)|r", profession.name, profession.recipeCount))
        checkbox:SetChecked(self:IsProfessionEnabled(profession.key))
        checkbox:Show()
    end

    for index = #professions + 1, #professionControls do
        professionControls[index]:Hide()
    end

    local hasProfessions = #professions > 0
    frame.emptyText:SetShown(not hasProfessions)
    frame.includeAll:SetEnabled(hasProfessions)
    frame.excludeAll:SetEnabled(hasProfessions)
    frame:SetHeight(hasProfessions and (48 + (#professions * 24)) or 68)
end

function RTE:RefreshOptions()
    for _, control in ipairs(controls) do
        if control.SetChecked then
            control:SetChecked(self.settings[control.settingKey])
        elseif control.valueText then
            control.valueText:SetText(self.settings[control.settingKey])
        end
    end

    self:RefreshProfessionControls()

    if self.optionsStatus then
        local recipes, professions = self:CountCachedRecipes()
        local included = self:CountIncludedProfessions()
        self.optionsStatus:SetText(string.format(
            "Cached for this character: %d recipes from %d professions (%d included)",
            recipes,
            professions,
            included
        ))
    end
end

function RTE:OpenOptions()
    if Settings and Settings.OpenToCategory and self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    elseif C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel and self.settingsCategoryID then
        C_SettingsUtil.OpenSettingsPanel(self.settingsCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory and self.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    else
        self:Print("Options are unavailable. Use |cffffffff/rte help|r for commands.")
    end
end

function RTE:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "ReagentTooltipEnhancerOptions")
    panel.name = self.DISPLAY_NAME

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(self.DISPLAY_NAME)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Known-recipe information in item tooltips")

    local enabled = CreateCheckbox(
        panel,
        "enabled",
        "Enable tooltip additions",
        "Show known recipes that use the item under the cursor.",
        subtitle
    )
    local grouped = CreateCheckbox(
        panel,
        "groupByProfession",
        "Group recipes by profession",
        "Adds a compact profession heading above each group.",
        enabled
    )
    local professionSkill = CreateCheckbox(
        panel,
        "showProfessionSkill",
        "Show profession skill",
        "Shows your current and maximum skill beside each profession heading.",
        grouped
    )
    local difficulty = CreateCheckbox(
        panel,
        "showDifficulty",
        "Show recipe difficulty",
        "Shows the familiar orange, yellow, green, or gray recipe difficulty.",
        professionSkill
    )
    local quantity = CreateCheckbox(
        panel,
        "showQuantity",
        "Show reagent quantity",
        "Shows how many of the hovered reagent the recipe consumes.",
        difficulty
    )
    local itemLevel = CreateCheckbox(
        panel,
        "showItemLevel",
        "Show crafted item level when available",
        "Useful for equipment; disabled by default to keep classic recipes compact.",
        quantity
    )
    local effects = CreateCheckbox(
        panel,
        "showEffects",
        "Show short recipe or food-effect text",
        "Effect text appears only when three or fewer recipes match.",
        itemLevel
    )

    local professionFilter = CreateProfessionFilter(panel, effects)
    self.professionFilterFrame = professionFilter

    local maximum = CreateStepper(panel, "maxRecipes", "Maximum recipes shown", 1, 20, 1, professionFilter)
    local effectLength = CreateStepper(panel, "effectMaxLength", "Maximum effect-text length", 40, 160, 8, maximum)

    local status = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", effectLength, "BOTTOMLEFT", 0, -22)
    self.optionsStatus = status

    local scan = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    scan:SetSize(150, 24)
    scan:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -12)
    scan:SetText("Scan open profession")
    scan:SetScript("OnClick", function()
        RTE:ScanCurrentProfession(true)
    end)

    local clear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clear:SetSize(110, 24)
    clear:SetPoint("LEFT", scan, "RIGHT", 8, 0)
    clear:SetText("Clear cache")
    clear:SetScript("OnClick", function()
        RTE:ClearCache(false)
    end)

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", scan, "BOTTOMLEFT", 0, -12)
    hint:SetWidth(540)
    hint:SetJustifyH("LEFT")
    hint:SetText("Open each profession once so the addon can index its learned recipes. New recipes are picked up automatically.")

    panel:SetScript("OnShow", function()
        RTE:RefreshOptions()
    end)

    self.optionsPanel = panel

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        self.settingsCategoryID = category:GetID()
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    self:RefreshOptions()
end

function RTE:OptionsInitialize()
    self:CreateOptionsPanel()

    SLASH_REAGENTTOOLTIPENHANCER1 = "/rte"
    SlashCmdList.REAGENTTOOLTIPENHANCER = function(message)
        message = strtrim(string.lower(message or ""))

        if message == "scan" then
            RTE:ScanCurrentProfession(true)
        elseif message == "clear" then
            RTE:ClearCache(false)
        elseif message == "status" then
            local recipes, professions = RTE:CountCachedRecipes()
            RTE:Print("%d recipes cached from %d professions.", recipes, professions)
        elseif message == "help" then
            RTE:Print("Commands: /rte, /rte scan, /rte status, /rte clear")
        else
            RTE:OpenOptions()
        end
    end
end
