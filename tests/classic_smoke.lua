-- Lightweight runtime smoke test for Classic Era legacy tradeskills,
-- Enchanting craft scanning, and OnTooltipSetItem tooltip hooking.
-- Run from the repository root with: lua tests/classic_smoke.lua

unpack = unpack or table.unpack

local frames = {}
local gameTooltipScripts = {}
local itemRefTooltipScripts = {}

function wipe(value)
    for key in pairs(value) do
        value[key] = nil
    end
end

function strtrim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function UnitFullName()
    return "ClassicTester", "ClassicEra"
end

function UnitName()
    return "ClassicTester"
end

function GetRealmName()
    return "ClassicEra"
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

-- Ensure modern APIs are absent (simulating Classic Era)
C_TradeSkillUI = nil
TooltipDataProcessor = nil
Enum = nil

-- Mock GameTooltip and ItemRefTooltip with HookScript
local function CreateClassicTooltipMock(name, scriptsTable)
    local tooltip = { lines = {}, name = name }
    function tooltip:GetName()
        return self.name
    end
    function tooltip:NumLines()
        return #self.lines
    end
    function tooltip:GetItem()
        return self.currentItemName or "Test Item", self.currentItemLink or "item:769"
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
    function tooltip:HookScript(scriptName, handler)
        scriptsTable[scriptName] = handler
    end
    return tooltip
end

GameTooltip = CreateClassicTooltipMock("GameTooltip", gameTooltipScripts)
ItemRefTooltip = CreateClassicTooltipMock("ItemRefTooltip", itemRefTooltipScripts)

function GameTooltip_AddBlankLineToTooltip(tooltip)
    tooltip:AddLine(" ")
end

-- Mock Classic Era legacy TradeSkill APIs (e.g. Cooking)
local mockTradeSkill = {
    name = "Cooking",
    skillLevel = 75,
    maxSkillLevel = 150,
    recipes = {
        {
            name = "Roasted Boar Meat",
            skillType = "optimal",
            icon = "Interface\\Icons\\Spell_Misc_Food",
            description = "Restores 61 health over 18 sec.",
            recipeLink = "enchant:2540",
            reagents = {
                { name = "Chunk of Boar Meat", count = 1, itemID = 769 },
            },
        },
    },
}

function GetNumTradeSkills()
    return mockTradeSkill and #mockTradeSkill.recipes or 0
end

function GetTradeSkillLine()
    if not mockTradeSkill then return nil end
    return mockTradeSkill.name, mockTradeSkill.skillLevel, mockTradeSkill.maxSkillLevel
end

function GetTradeSkillInfo(index)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    if not recipe then return nil end
    return recipe.name, recipe.skillType
end

function GetTradeSkillNumReagents(index)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    return recipe and #recipe.reagents or 0
end

function GetTradeSkillReagentInfo(index, reagentIndex)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    local reagent = recipe and recipe.reagents[reagentIndex]
    if not reagent then return nil end
    return reagent.name, nil, reagent.count, 5
end

function GetTradeSkillReagentItemLink(index, reagentIndex)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    local reagent = recipe and recipe.reagents[reagentIndex]
    if not reagent then return nil end
    return string.format("|cffffffff|Hitem:%d:0:0:0:0:0:0:0:0|h[%s]|h|r", reagent.itemID, reagent.name)
end

function GetTradeSkillRecipeLink(index)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    return recipe and recipe.recipeLink or nil
end

function GetTradeSkillIcon(index)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    return recipe and recipe.icon or nil
end

function GetTradeSkillDescription(index)
    local recipe = mockTradeSkill and mockTradeSkill.recipes[index]
    return recipe and recipe.description or nil
end

-- Mock Classic Era Craft APIs (Enchanting)
local mockCraft = {
    name = "Enchanting",
    skillLevel = 15,
    maxSkillLevel = 75,
    crafts = {
        {
            name = "Enchant Bracer - Minor Health",
            craftType = "medium",
            icon = "Interface\\Icons\\Spell_Holy_GreaterHeal",
            description = "Permanently enchant a bracer so it increases health by 5.",
            craftLink = "spell:7418",
            reagents = {
                { name = "Strange Dust", count = 1, itemID = 10940 },
            },
        },
    },
}

function GetNumCrafts()
    return mockCraft and #mockCraft.crafts or 0
end

function GetCraftDisplaySkillLine()
    if not mockCraft then return nil end
    return mockCraft.name, mockCraft.skillLevel, mockCraft.maxSkillLevel
end

function GetCraftInfo(index)
    local craft = mockCraft and mockCraft.crafts[index]
    if not craft then return nil end
    return craft.name, nil, craft.craftType
end

function GetCraftNumReagents(index)
    local craft = mockCraft and mockCraft.crafts[index]
    return craft and #craft.reagents or 0
end

function GetCraftReagentInfo(index, reagentIndex)
    local craft = mockCraft and mockCraft.crafts[index]
    local reagent = craft and craft.reagents[reagentIndex]
    if not reagent then return nil end
    return reagent.name, nil, reagent.count, 2
end

function GetCraftReagentItemLink(index, reagentIndex)
    local craft = mockCraft and mockCraft.crafts[index]
    local reagent = craft and craft.reagents[reagentIndex]
    if not reagent then return nil end
    return string.format("|cffffffff|Hitem:%d:0:0:0:0:0:0:0:0|h[%s]|h|r", reagent.itemID, reagent.name)
end

function GetCraftIcon(index)
    local craft = mockCraft and mockCraft.crafts[index]
    return craft and craft.icon or nil
end

function GetCraftDescription(index)
    local craft = mockCraft and mockCraft.crafts[index]
    return craft and craft.description or nil
end

function GetCraftItemLink(index)
    local craft = mockCraft and mockCraft.crafts[index]
    return craft and craft.craftLink or nil
end

-- Load the addon files into a test namespace
local namespace = {}
assert(loadfile("ReagentTooltipEnhancer/Core.lua"))("ReagentTooltipEnhancer", namespace)
assert(loadfile("ReagentTooltipEnhancer/Scanner.lua"))("ReagentTooltipEnhancer", namespace)
assert(loadfile("ReagentTooltipEnhancer/Tooltip.lua"))("ReagentTooltipEnhancer", namespace)

-- Initialize addon via ADDON_LOADED
frames[1].OnEvent(frames[1], "ADDON_LOADED", "ReagentTooltipEnhancer")
assert(gameTooltipScripts["OnTooltipSetItem"], "GameTooltip OnTooltipSetItem was not hooked")
assert(itemRefTooltipScripts["OnTooltipSetItem"], "ItemRefTooltip OnTooltipSetItem was not hooked")

-- 1. Scan Legacy TradeSkill (Cooking)
-- Disable mockCraft temporarily so trade skill window is active
local savedCraft = mockCraft
mockCraft = nil

wipe(messages)
assert(namespace:ScanCurrentProfession(false), "legacy trade skill scan failed")
assert(namespace.recipeIndex[769], "Cooking reagent (item 769) was not indexed")
assert(#messages == 1 and messages[1]:find("Added 1 new Cooking recipes", 1, true),
    "initial legacy scan did not announce added recipe")

-- 2. Scan Legacy Craft (Enchanting)
-- Restore craft window and disable trade skill window
mockCraft = savedCraft
local savedTradeSkill = mockTradeSkill
mockTradeSkill = nil

wipe(messages)
assert(namespace:ScanCurrentProfession(false), "legacy craft scan failed")
assert(namespace.recipeIndex[10940], "Enchanting reagent (item 10940) was not indexed")
assert(#messages == 1 and messages[1]:find("Added 1 new Enchanting recipes", 1, true),
    "initial craft scan did not announce added recipe")

-- 3. Verify Tooltip for Cooking reagent (Chunk of Boar Meat)
GameTooltip.lines = {}
GameTooltip.currentItemName = "Chunk of Boar Meat"
GameTooltip.currentItemLink = "item:769"
gameTooltipScripts["OnTooltipSetItem"](GameTooltip)

local output = {}
for _, line in ipairs(GameTooltip.lines) do
    output[#output + 1] = line.left or ""
end
output = table.concat(output, "\n")

assert(output:find("Used by your recipes", 1, true), "tooltip section heading missing for Cooking")
assert(output:find("Cooking", 1, true), "profession heading Cooking missing")
assert(output:find("Roasted Boar Meat", 1, true), "recipe Roasted Boar Meat missing")
assert(output:find("Restores 61 health", 1, true), "effect description missing")
assert(GameTooltip.shown, "tooltip was not displayed")

-- 4. Verify Tooltip for Enchanting reagent (Strange Dust)
GameTooltip.lines = {}
GameTooltip.shown = false
GameTooltip.currentItemName = "Strange Dust"
GameTooltip.currentItemLink = "item:10940"
gameTooltipScripts["OnTooltipSetItem"](GameTooltip)

local enchantOutput = {}
for _, line in ipairs(GameTooltip.lines) do
    enchantOutput[#enchantOutput + 1] = line.left or ""
end
enchantOutput = table.concat(enchantOutput, "\n")

assert(enchantOutput:find("Used by your recipes", 1, true), "tooltip section heading missing for Enchanting")
assert(enchantOutput:find("Enchanting", 1, true), "profession heading Enchanting missing")
assert(enchantOutput:find("Minor Health", 1, true), "recipe Minor Health missing")
assert(GameTooltip.shown, "enchanting tooltip was not displayed")

-- 5. Test profession exclusion filter in Classic Era
namespace.charDB.professionVisibility["Enchanting"] = false
GameTooltip.lines = {}
GameTooltip.shown = false
gameTooltipScripts["OnTooltipSetItem"](GameTooltip)
assert(#GameTooltip.lines == 0, "excluded Enchanting profession still appeared in tooltip")
assert(not GameTooltip.shown, "excluded Enchanting profession refreshed tooltip")

print("RTE classic smoke test passed")
