-- Lightweight runtime smoke test for per-character profession options.
-- Run from the repository root with: lua tests/options_smoke.lua

unpack = unpack or table.unpack

local frames = {}

local function CreateRegion()
    local region = {}
    function region:SetPoint() end
    function region:SetSize(width, height) self.width, self.height = width, height end
    function region:SetWidth(width) self.width = width end
    function region:SetJustifyH(justify) self.justify = justify end
    function region:SetText(text) self.text = text end
    function region:SetShown(shown) self.shown = shown end
    function region:Show() self.shown = true end
    function region:Hide() self.shown = false end
    return region
end

function CreateFrame(_, name, _, template)
    local frame = { name = name, shown = true, enabled = true }
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(script, callback) self[script] = callback end
    function frame:SetPoint() end
    function frame:ClearAllPoints() end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:SetHeight(height) self.height = height end
    function frame:SetWidth(width) self.width = width end
    function frame:SetText(text) self.text = text end
    function frame:GetName() return self.name end
    function frame:SetChecked(checked) self.checked = checked end
    function frame:GetChecked() return self.checked end
    function frame:SetEnabled(enabled) self.enabled = enabled end
    function frame:SetShown(shown) self.shown = shown end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:CreateFontString() return CreateRegion() end

    if template == "InterfaceOptionsCheckButtonTemplate" then
        frame.Text = CreateRegion()
    end
    if name then
        _G[name] = frame
    end
    frames[#frames + 1] = frame
    return frame
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

function strtrim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
Settings = {
    RegisterCanvasLayoutCategory = function()
        return { GetID = function() return 7 end }
    end,
    RegisterAddOnCategory = function() end,
}

ReagentTooltipEnhancerDB = {
    settings = {},
    characters = {
        ["Forever-Tester"] = {
            recipes = {},
            professions = {
                ["185"] = { name = "Cooking", recipeCount = 12 },
                ["202"] = { name = "Engineering", recipeCount = 34 },
            },
            professionVisibility = {
                ["185"] = false,
            },
        },
    },
}

local namespace = {}
assert(loadfile("ReagentTooltipEnhancer/Core.lua"))("ReagentTooltipEnhancer", namespace)
assert(loadfile("ReagentTooltipEnhancer/Options.lua"))("ReagentTooltipEnhancer", namespace)

frames[1].OnEvent(frames[1], "ADDON_LOADED", "ReagentTooltipEnhancer")

assert(namespace.optionsPanel, "options panel was not created")
assert(namespace.professionFilterFrame, "profession filter was not created")
assert(RTEProfessionFilter1.Text.text:find("Cooking", 1, true), "professions were not sorted")
assert(RTEProfessionFilter1.checked == false, "saved exclusion was not restored")
assert(RTEProfessionFilter2.checked == true, "new professions should default to included")

RTEProfessionFilter1.checked = true
RTEProfessionFilter1.OnClick(RTEProfessionFilter1)
assert(namespace.charDB.professionVisibility["185"] == true, "checkbox inclusion was not saved")

namespace.professionFilterFrame.excludeAll.OnClick()
assert(namespace.charDB.professionVisibility["185"] == false, "exclude-all missed Cooking")
assert(namespace.charDB.professionVisibility["202"] == false, "exclude-all missed Engineering")

namespace.professionFilterFrame.includeAll.OnClick()
assert(namespace.charDB.professionVisibility["185"] == true, "include-all missed Cooking")
assert(namespace.charDB.professionVisibility["202"] == true, "include-all missed Engineering")

local included, total = namespace:CountIncludedProfessions()
assert(included == 2 and total == 2, "included profession count is incorrect")

print("RTE options smoke test passed")
