-- Lightweight runtime smoke test for the scanner-to-tooltip path.
-- Run from the repository root with: lua tests/smoke.lua

unpack = unpack or table.unpack

local frames = {}
local tooltipCallback

function wipe(value)
    for key in pairs(value) do
        value[key] = nil
    end
end

function strtrim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function UnitFullName()
    return "Tester", "Forever"
end

function UnitName()
    return "Tester"
end

function GetRealmName()
    return "Forever"
end

function time()
    return 123456
end

local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, message)
    messages[#messages + 1] = message
end }

function CreateFrame()
    local frame = { events = {} }
    function frame:RegisterEvent(event)
        self.events[event] = true
    end
    function frame:SetScript(script, callback)
        self[script] = callback
    end
    frames[#frames + 1] = frame
    return frame
end

C_Timer = {
    After = function(_, callback)
        callback()
    end,
}

C_TradeSkillUI = {
    GetBaseProfessionInfo = function()
        return {
            professionID = 185,
            professionName = "Cooking",
            skillLevel = 75,
            maxSkillLevel = 150,
        }
    end,
    GetAllRecipeIDs = function()
        return { 2540 }
    end,
    GetRecipeInfo = function(recipeID)
        return {
            recipeID = recipeID,
            name = "Roasted Boar Meat",
            icon = 133974,
            learned = true,
            relativeDifficulty = 1,
            itemLevel = 5,
        }
    end,
    GetRecipeSchematic = function()
        return {
            name = "Roasted Boar Meat",
            icon = 133974,
            reagentSlotSchematics = {
                {
                    quantityRequired = 1,
                    reagents = { { itemID = 769 } },
                    variableQuantities = {},
                },
            },
        }
    end,
    GetRecipeDescription = function()
        return "Restores health over 18 sec. Must remain seated while eating."
    end,
}

Enum = { TooltipDataType = { Item = 0 } }
TooltipDataProcessor = {
    AddTooltipPostCall = function(_, callback)
        tooltipCallback = callback
    end,
}

function GameTooltip_AddBlankLineToTooltip(tooltip)
    tooltip:AddLine(" ")
end

local namespace = {}
assert(loadfile("ReagentTooltipEnhancer/Core.lua"))("ReagentTooltipEnhancer", namespace)
assert(loadfile("ReagentTooltipEnhancer/Scanner.lua"))("ReagentTooltipEnhancer", namespace)
assert(loadfile("ReagentTooltipEnhancer/Tooltip.lua"))("ReagentTooltipEnhancer", namespace)

frames[1].OnEvent(frames[1], "ADDON_LOADED", "ReagentTooltipEnhancer")
assert(tooltipCallback, "tooltip callback was not registered")
wipe(messages)
assert(namespace:ScanCurrentProfession(false), "profession scan failed")
assert(namespace.recipeIndex[769], "reagent index was not created")
assert(#messages == 1 and messages[1]:find("Added 1 new Cooking recipes", 1, true),
    "initial scan did not announce the added recipe")
wipe(messages)
assert(namespace:ScanCurrentProfession(false), "repeat scan failed")
assert(namespace:ScanCurrentProfession(true), "manual repeat scan failed")
assert(#messages == 0, "unchanged scans printed a message")

C_TradeSkillUI.GetAllRecipeIDs = function() return { 2540, 2541 } end
assert(namespace:ScanCurrentProfession(false), "scan with a new recipe failed")
assert(#messages == 1 and messages[1]:find("Added 1 new Cooking recipes", 1, true),
    "scan did not report only the newly added recipe")
wipe(messages)
C_TradeSkillUI.GetAllRecipeIDs = function() return { 2540 } end
assert(namespace:ScanCurrentProfession(false), "scan with a removed recipe failed")
assert(#messages == 0, "removing a recipe printed an addition message")
C_TradeSkillUI.GetAllRecipeIDs = function() return { 2541 } end
assert(namespace:ScanCurrentProfession(false), "replacement recipe scan failed")
assert(#messages == 1 and messages[1]:find("Added 1 new Cooking recipes", 1, true),
    "same-count replacement did not announce the new recipe")

local function CreateMockTooltip(name)
    local tooltip = { lines = {}, name = name }
    function tooltip:GetName()
        return self.name
    end
    function tooltip:NumLines()
        return #self.lines
    end
    function tooltip:GetItem()
        return "Chunk of Boar Meat", "item:769"
    end
    function tooltip:AddLine(left)
        self.lines[#self.lines + 1] = { left = left }
        local line = self.lines[#self.lines]
        _G[self:GetName() .. "TextLeft" .. #self.lines] = {
            GetText = function()
                return line.left
            end,
        }
    end
    function tooltip:AddDoubleLine(left, right)
        self.lines[#self.lines + 1] = { left = left, right = right }
        local line = self.lines[#self.lines]
        _G[self:GetName() .. "TextLeft" .. #self.lines] = {
            GetText = function()
                return line.left
            end,
        }
    end
    function tooltip:Show()
        self.shown = true
    end
    return tooltip
end

local tooltip = CreateMockTooltip("RTESmokeTooltip")

tooltipCallback(tooltip, { id = 769 })

local output = {}
for _, line in ipairs(tooltip.lines) do
    output[#output + 1] = line.left or ""
end
output = table.concat(output, "\n")

assert(output:find("Used by your recipes", 1, true), "section heading is missing")
assert(output:find("Cooking", 1, true), "profession heading is missing")
assert(output:find("Roasted Boar Meat", 1, true), "recipe is missing")
assert(output:find("Restores health", 1, true), "effect summary is missing")
assert(tooltip.shown, "tooltip was not refreshed")

namespace.charDB.professionVisibility["185"] = false
local filteredTooltip = CreateMockTooltip("RTEFilteredTooltip")
tooltipCallback(filteredTooltip, { id = 769 })
assert(#filteredTooltip.lines == 0, "excluded profession still appeared in the tooltip")
assert(not filteredTooltip.shown, "excluded profession refreshed the tooltip")

print("RTE smoke test passed")
