local ADDON_NAME, RTE = ...

RTE.ADDON_NAME = ADDON_NAME
RTE.DISPLAY_NAME = "Reagent Tooltip Enhancer"
RTE.VERSION = "0.1.0"

local DEFAULT_SETTINGS = {
    enabled = true,
    groupByProfession = true,
    showProfessionSkill = true,
    showDifficulty = true,
    showQuantity = true,
    showItemLevel = false,
    showEffects = true,
    maxRecipes = 8,
    effectMaxLength = 96,
}

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = value
        end
    end
end

local function GetCharacterKey()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "Unknown"
    realm = realm or GetRealmName() or "Unknown"
    return realm .. "-" .. name
end

function RTE:Print(message, ...)
    if select("#", ...) > 0 then
        message = string.format(message, ...)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffRTE:|r " .. message)
end

function RTE:SafeCall(func, ...)
    if type(func) ~= "function" then
        return nil
    end

    local results = { pcall(func, ...) }
    if not results[1] then
        return nil
    end

    return unpack(results, 2)
end

function RTE:CountCachedRecipes()
    local recipeCount = 0
    local professionCount = 0

    if self.charDB and self.charDB.recipes then
        for _ in pairs(self.charDB.recipes) do
            recipeCount = recipeCount + 1
        end
    end

    if self.charDB and self.charDB.professions then
        for _ in pairs(self.charDB.professions) do
            professionCount = professionCount + 1
        end
    end

    return recipeCount, professionCount
end

function RTE:InitializeDatabase()
    if type(ReagentTooltipEnhancerDB) ~= "table" then
        ReagentTooltipEnhancerDB = {}
    end

    local database = ReagentTooltipEnhancerDB
    database.schema = 1
    database.settings = type(database.settings) == "table" and database.settings or {}
    database.characters = type(database.characters) == "table" and database.characters or {}
    ApplyDefaults(database.settings, DEFAULT_SETTINGS)

    local characterKey = GetCharacterKey()
    database.characters[characterKey] = type(database.characters[characterKey]) == "table"
        and database.characters[characterKey]
        or {}

    local character = database.characters[characterKey]
    character.recipes = type(character.recipes) == "table" and character.recipes or {}
    character.professions = type(character.professions) == "table" and character.professions or {}

    self.db = database
    self.settings = database.settings
    self.charDB = character
    self.characterKey = characterKey
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= ADDON_NAME then
        return
    end

    RTE:InitializeDatabase()

    if RTE.ScannerInitialize then
        RTE:ScannerInitialize()
    end
    if RTE.TooltipInitialize then
        RTE:TooltipInitialize()
    end
    if RTE.OptionsInitialize then
        RTE:OptionsInitialize()
    end
end)
