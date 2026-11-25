-- Run from the addon directory. Uses production handlers with a simulated UI.
unpack = unpack or table.unpack
local now, timers, submissions, messages = 100, {}, {}, {}
local hidden = setmetatable({}, { __tostring = function() error("secret converted") end })
function issecretvalue(value) return rawequal(value, hidden) end
local function widget(parent)
    local methods = {}
    function methods:SetScript(event, run) self[event] = run end
    function methods:GetScript(event) return self[event] end
    function methods:GetName() return self.name end
    function methods:GetFontString() return self.fontString end
    function methods:SetFontString(font) self.fontString = font end
    function methods:SetText(text) self.text = text end
    function methods:GetText() return self.text end
    function methods:SetChecked(value) self.checked = value end
    function methods:GetChecked() return self.checked end
    function methods:Show() self.shown = true end
    function methods:Hide()
        if not self.shown then return end
        self.shown = false
        local handler = rawget(self, "OnHide")
        if handler then handler(self) end
    end
    function methods:IsShown() return self.shown == true end
    function methods:SetShown(value) self.shown = value end
    function methods:GetWidth() return 280 end
    function methods:GetHeight() return 20 end
    function methods:GetAlpha() return self.alpha or 1 end
    function methods:SetAlpha(value) self.alpha = value end
    function methods:IsMouseClickEnabled() return self.mouseClicks == true end
    function methods:IsMouseMotionEnabled() return self.mouseMotion == true end
    function methods:IsMouseWheelEnabled() return self.mouseWheel == true end
    function methods:SetMouseClickEnabled(value) self.mouseClicks = value end
    function methods:SetMouseMotionEnabled(value) self.mouseMotion = value end
    function methods:EnableMouseWheel(value) self.mouseWheel = value end
    function methods:GetChildren() return unpack(self.children or {}) end
    function methods:CreateTexture() return widget() end
    function methods:CreateFontString() return widget() end
    function methods:HookScript(event, run)
        local previous = self[event]
        self[event] = function(...) if previous then previous(...) end; run(...) end
    end
    local frame = setmetatable({}, { __index = function(_, key)
        if methods[key] then return methods[key] end
        if key:match("^[A-Z]") then return function() end end
    end })
    if parent then
        parent.children = parent.children or {}
        parent.children[#parent.children + 1] = frame
    end
    return frame
end
UIParent, UISpecialFrames = widget(), {}
NUM_CHAT_WINDOWS = 1
function CreateFrame(kind, name, parent)
    local frame = widget(parent)
    frame.name = name
    if kind == "CheckButton" then
        frame.Text = widget()
        frame.text = frame.Text
        frame.mouseClicks, frame.mouseMotion = true, true
    end
    if name then _G[name] = frame end
    return frame
end
function GetTime() return now end
function tostringall(...) return ... end
function strjoin(separator, ...) return table.concat({ ... }, separator) end
function LibStub() return nil end
function GetBuildInfo() return "1.60.1", "70862", "Nov 6 2026", 16001 end
function UnitName(unit) return unit == "player" and "Local Player" or "Other Player" end
function UnitClass() return "Paladin", "PALADIN" end
function UnitExists() return true end
function UnitIsConnected() return true end
function UnitIsVisible() return true end
function UnitIsUnit(first, second) return first == second end
function UnitGUID() return "Player-Test" end
function IsInRaid() return false end
function IsInGroup() return true end
function GetNumGroupMembers() return 2 end
function InCombatLockdown() return false end
GameFontHighlight = { GetFont = function() return "Fonts/FRIZQT__.TTF", 12 end }
C_Timer = { After = function(delay, run) timers[#timers + 1] = { at = now + delay, run = run } end }
C_AddOns = {
    GetAddOnInfo = function() return "iNeedIfYouNeed", "iNeedIfYouNeed" end,
    GetAddOnMetadata = function(_, key) return key == "Version" and "0.5.3" or "Crasling" end,
    IsAddOnLoaded = function() return false end,
}
C_EventUtils = { IsEventValid = function() return true end }
ChatFrame1 = { AddMessage = function(_, text) messages[#messages + 1] = text end }
DEFAULT_CHAT_FRAME = ChatFrame1
function RollOnLoot(id, choice) submissions[#submissions + 1] = { id = id, choice = choice } end
function SendChatMessage() error("unexpected party announcement") end
function GetLootRollTimeLeft() return 60000 end
local itemLinks = {}
function GetLootRollItemLink(id) return itemLinks[id] end
function GetLootRollItemInfo(id) return 1, "Test Item", 1, 2 end
local iNIF = {}
for _, path in ipairs({ "Localization/enUS.lua", "iNeedIfYouNeed_Main.lua",
    "iNeedIfYouNeed_RollLogic.lua", "iNeedIfYouNeed_RollTracking.lua", "iNeedIfYouNeed_Frames.lua" }) do
    assert(loadfile(path))("iNeedIfYouNeed", iNIF)
end
iNIF.InitializeDatabases()
iNIFDB.partyMessages, iNIFDB.ninjaDetection, iNIFDB.debug = false, false, true
GroupLootContainer = { rollFrames = {} }
local function event(kind, ...) iNIF.eventFrame.OnEvent(iNIF.eventFrame, kind, ...) end
local function start(id, link)
    itemLinks[id] = link
    event("START_LOOT_ROLL", id, 60000)
    local frame = widget()
    frame.rollID, frame.iNIF_Checkbox = id, widget()
    frame.iNIF_NeedCount, frame.iNIF_GreedCount, frame.iNIF_PassCount = widget(), widget(), widget()
    frame:Show()
    GroupLootContainer.rollFrames[id] = frame
    iNIF.activeRolls[id].frame = frame
    iNIF.UpdateRollCounters(id)
    return iNIF.activeRolls[id], frame
end
local function reset()
    for key in pairs(iNIF.activeRolls) do iNIF.activeRolls[key] = nil end
    GroupLootContainer.rollFrames = {}
    iNIF.recentlyCompletedRolls = {}
    iNIF.rollTracker = { players = {}, totalRolls = 0, history = {} }
    submissions, timers = {}, {}
    iNIFDB.enchanterMode = false
    iNIFDB.rollTracker = true
end
local function advance(seconds)
    now = now + seconds
    local pending = timers
    timers = {}
    for _, timer in ipairs(pending) do
        if timer.at <= now then timer.run() else timers[#timers + 1] = timer end
    end
end

local function enhance(frame)
    frame.NeedButton, frame.GreedButton, frame.PassButton = widget(frame), widget(frame), widget(frame)
    frame.GreedButton:SetScript("OnClick", function() RollOnLoot(frame.rollID, 2) end)
    iNIF.EnhanceRollFrame(frame, frame.rollID)
end

local function monitor(frame)
    frame.iNIF_Checkbox:SetChecked(true)
    frame.GreedButton.OnClick(frame.GreedButton, "LeftButton")
end

local link = "|cffffffff|Hitem:123:0:0:0:0:0:0:0|h[Test Item]|h|r"
reset()
local roll, frame = start(1, link)
event("CHAT_MSG_LOOT", "Other Player has selected Greed for: " .. link)
event("CHAT_MSG_SYSTEM", "Other Player has selected Greed for: " .. link)
assert(roll.greedCount == 1 and frame.iNIF_GreedCount.text == "1" and iNIF.rollTracker.totalRolls == 1,
    "repeated loot/system lines count one participant only")
event("CHAT_MSG_LOOT", "Local Player has selected Greed for: " .. link)
assert(roll.greedCount == 2, "the local participant counts once too")
reset()
local first, firstFrame = start(10, link)
enhance(firstFrame)
monitor(firstFrame)
assert(firstFrame:GetAlpha() == 0, "the first roll starts hidden while monitoring")
local second, secondFrame = start(11, link)
assert(first.ambiguousItem and second.ambiguousItem and not first.greedClicked
    and firstFrame:GetAlpha() == 1 and firstFrame.iNIF_Checkbox:IsMouseClickEnabled(),
    "a second indistinguishable copy pauses monitoring and restores the first frame")
assert(firstFrame.iNIF_GreedCount.text == "?" and secondFrame.iNIF_GreedCount.text == "?",
    "both frames show unknown counters rather than a combined total")
for _, who in ipairs({ "Other Player", "Local Player" }) do
    event("CHAT_MSG_LOOT", who .. " has selected Need for: " .. link)
    event("CHAT_MSG_LOOT", who .. " has selected Greed for: " .. link)
    event("CHAT_MSG_LOOT", who .. " passed on: " .. link)
end
assert(first.needCount == 0 and second.needCount == 0 and first.greedCount == 0 and second.greedCount == 0
    and first.passCount == 0 and second.passCount == 0 and #submissions == 0,
    "ambiguous choices never pool counters or roll Need on a guessed copy")
event("CANCEL_LOOT_ROLL", 10)
event("CHAT_MSG_LOOT", "Other Player has selected Need for: " .. link)
assert(second.needCount == 0, "late chat for a closed copy cannot contaminate the remaining copy")
secondFrame.NeedButton, secondFrame.GreedButton, secondFrame.PassButton = widget(), widget(), widget()
secondFrame.GreedButton:SetScript("OnClick", function() RollOnLoot(11, 2) end)
iNIF.EnhanceRollFrame(secondFrame, 11)
secondFrame.iNIF_Checkbox:SetChecked(true)
secondFrame.GreedButton.OnClick(secondFrame.GreedButton, "LeftButton")
assert(not secondFrame.iNIF_Checkbox:GetChecked() and not second.greedClicked and #submissions == 0,
    "trying to monitor an ambiguous copy asks for a manual choice without rolling")
secondFrame.GreedButton.OnClick(secondFrame.GreedButton, "LeftButton")
assert(#submissions == 1 and submissions[1].id == 11 and submissions[1].choice == 2,
    "the next unchecked Greed click still uses Blizzard's manual handler")
event("CHAT_MSG_LOOT", "Other Player won: " .. link)
event("CHAT_MSG_LOOT", "Other Player receives loot: " .. link)
assert(#iNIF.rollTracker.history == 0, "ambiguous win/receipt lines do not invent or double-count a winner")
print("PASS: identical copies stay separate, counters do not merge, monitoring pauses safely, and late chat stays ambiguous")

reset()
iNIFDB.rollTracker = false
first = start(12, link)
event("CANCEL_LOOT_ROLL", 12)
second = start(13, link)
event("CHAT_MSG_LOOT", "Other Player has selected Need for: " .. link)
assert(second.ambiguousItem and second.needCount == 0,
    "a just-closed copy protects a new identical roll even when Luck Tracker is disabled")
event("CANCEL_LOOT_ROLL", 13)
now = now + 16
local fresh = start(14, link)
assert(not fresh.ambiguousItem, "expired context does not permanently block later copies")
print("PASS: local cancellation retains duplicate context independently of Luck Tracker and expires after 15 seconds")

reset()
local variant = link:gsub(":0:0|h", ":5:0|h")
first = start(20, link)
second = start(21, variant)
assert(not first.ambiguousItem and not second.ambiguousItem, "different item payloads are distinguishable")
iNIF.OnNeedDetected("Other Player", link)
iNIF.OnGreedDetected("Other Player", variant)
iNIF.OnNeedDetected("Other Player", link)
assert(first.needCount == 1 and first.greedCount == 0 and second.greedCount == 1 and second.needCount == 0,
    "same item ID with different properties gets independent per-copy choices")
assert(iNIF.rollTracker.totalRolls == 2, "the same player can participate in both copies")
print("PASS: repeated choices deduplicate, full item links separate variants, and participants are counted per roll")

reset()
first = start(30, link)
first.checkboxEnabled, first.greedClicked = true, true
iNIF.OnNeedDetected("Other Player", link)
assert(#submissions == 1 and submissions[1].id == 30 and submissions[1].choice == 1,
    "normal monitored Need still responds to a unique roll")
reset()
first = start(40, link)
first.checkboxEnabled, first.greedClicked = true, true
iNIF.OnGreedDetected("Other Player", link)
assert(#submissions == 1 and submissions[1].id == 40 and submissions[1].choice == 2,
    "normal monitored Greed still submits once every other eligible player greeds")
assert(not iNIF.ResolveLootDecision("Other Player", hidden, "need"), "restricted item values are never read")
print("PASS: unique-roll automatic Need/Greed remains intact and restricted item values are ignored")

reset()
first, firstFrame = start(50, link)
firstFrame:SetAlpha(0.8)
firstFrame:SetMouseClickEnabled(true)
firstFrame:EnableMouseWheel(true)
enhance(firstFrame)
local tooltipDismissed = false
GameTooltip = {
    IsOwned = function(_, control) return control == firstFrame.iNIF_Checkbox end,
    Hide = function() tooltipDismissed = true end,
}
firstFrame.GreedButton:SetMouseMotionEnabled(true)
monitor(firstFrame)
assert(firstFrame:IsShown() and firstFrame:GetAlpha() == 0 and first.greedClicked,
    "monitoring hides the window visually while keeping its native slot reserved")
assert(not firstFrame:IsMouseClickEnabled() and not firstFrame:IsMouseWheelEnabled())
assert(not firstFrame.GreedButton:IsMouseMotionEnabled() and not firstFrame.iNIF_Checkbox:IsMouseClickEnabled()
    and tooltipDismissed, "invisible controls and the roll tooltip cannot block the world")
assert(not iNIF.RestoreLootRollFrame(firstFrame, 51), "one roll cannot reveal another roll's frame")
assert(iNIF.RestoreLootRollFrame(firstFrame, 50) and firstFrame:GetAlpha() == 0.8)
assert(firstFrame:IsMouseClickEnabled() and not firstFrame:IsMouseMotionEnabled()
    and firstFrame.GreedButton:IsMouseMotionEnabled() and firstFrame:IsMouseWheelEnabled(),
    "manual reveal restores the original click, motion, wheel, and alpha settings")

itemLinks[51] = variant
event("START_LOOT_ROLL", 51, 60000)
advance(0.2)
assert(iNIF.activeRolls[51], "queued roll stays active before its frame appears")
event("CANCEL_LOOT_ROLL", 50)
firstFrame:Hide()
GroupLootContainer.rollFrames[50] = nil
firstFrame.rollID = 51
GroupLootContainer.rollFrames[51] = firstFrame
firstFrame:Show()
advance(0.6)
assert(not firstFrame.iNIF_Checkbox:GetChecked(), "a queued roll resets the reused checkbox")
monitor(firstFrame)
local queued = iNIF.activeRolls[51]
assert(queued.frame == firstFrame and firstFrame:GetAlpha() == 0 and not firstFrame:IsMouseClickEnabled())
iNIF.OnGreedDetected("Other Player", variant, 51)
assert(#submissions == 1 and submissions[1].id == 51 and submissions[1].choice == 2)
event("CANCEL_LOOT_ROLL", 51)
firstFrame:Hide()
assert(not firstFrame.iNIF_HiddenRoll and firstFrame:GetAlpha() == 0.8
    and firstFrame:IsMouseClickEnabled() and firstFrame.iNIF_Checkbox:IsMouseClickEnabled()
    and not firstFrame.iNIF_Checkbox:GetChecked(),
    "native completion restores input for reuse and leaves no checked state")
GameTooltip = nil
print("PASS: hidden roll windows release the mouse, preserve reservations, and restore input after reuse")
