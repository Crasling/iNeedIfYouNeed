-- ═══════════════════════════════════════════════════════════
-- iNeedIfYouNeed (iNIF)
-- A World of Warcraft AddOn
-- Smart looting: Need if someone needs, otherwise Greed
-- ═══════════════════════════════════════════════════════════

local addonName, iNIF = ...
local L = iNIF.L or {}  -- Load localization table with fallback
local Title = select(2, C_AddOns.GetAddOnInfo(addonName)):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%s*v?[%d%.]+$", "")
local Version = C_AddOns.GetAddOnMetadata(addonName, "Version")
local Author = C_AddOns.GetAddOnMetadata(addonName, "Author")

-- Load libraries
local LDBroker = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local AceComm = LibStub("AceComm-3.0", true)

-- ═══════════════════════════════════════════════════════════
-- SAVED VARIABLES & SETTINGS
-- ═══════════════════════════════════════════════════════════
if not iNIFDB then
    iNIFDB = {
        enabled = true,
        checkboxRememberState = true,
        showNotifications = true,
        checkboxChecked = false,
        partyMessages = true,
        debug = false,
        hideLootFrame = true,  -- Hide Blizzard loot frame (GroupLootFrame) after Greed+Checkbox
        hideMonitorWindow = true, -- Hide monitor window (Active Rolls timer) after Greed+Checkbox
        minimapButton = {
            hide = false,
            minimapPos = -30
        },
        monitorWindow = {
            point = "CENTER",
            relativeTo = "CENTER",
            xOffset = 0,
            yOffset = 200
        }
    }
end

-- ═══════════════════════════════════════════════════════════
-- COLORS
-- ═══════════════════════════════════════════════════════════
local Colors = {
    iNIF = "|cffff9716",      -- Orange (same as iWR base color)
    White = "|cFFFFFFFF",
    Green = "|cFF00FF00",
    Red = "|cFFFF0000",
    Orange = "|cFFFFA500",
    Yellow = "|cFFFFFF00",
    Teal = "|cFF00FFFF",
    Reset = "|r"
}

-- ═══════════════════════════════════════════════════════════
-- CORE VARIABLES
-- ═══════════════════════════════════════════════════════════
local activeRolls = {} -- Track active loot rolls
local eventFrame = CreateFrame("Frame")
local timerWindow = nil -- Timer display window

-- Global checkbox registry for live updates
iNIF.CheckboxRegistry = {
    enabled = {},
    showNotifications = {},
    partyMessages = {},
    hideLootFrame = {},
    hideMonitorWindow = {},
    debug = {}
}

-- Function to update all checkboxes for a setting
local function UpdateAllCheckboxes(settingKey, value)
    for _, cb in ipairs(iNIF.CheckboxRegistry[settingKey] or {}) do
        if cb and cb:IsShown() then
            cb:SetChecked(value)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- TIMER WINDOW
-- ═══════════════════════════════════════════════════════════
local function CreateTimerWindow()
    -- Main frame
    local frame = CreateFrame("Frame", "iNIFTimerWindow", UIParent, "BackdropTemplate")
    frame:SetSize(380, 100)

    -- Load saved position or use defaults
    if not iNIFDB.monitorWindow then
        iNIFDB.monitorWindow = {
            point = "CENTER",
            relativeTo = "CENTER",
            xOffset = 0,
            yOffset = 200
        }
    end
    local pos = iNIFDB.monitorWindow
    frame:SetPoint(pos.point, UIParent, pos.relativeTo, pos.xOffset, pos.yOffset)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(1, 0.5, 0, 1)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        iNIFDB.monitorWindow.point = point
        iNIFDB.monitorWindow.relativeTo = relativePoint
        iNIFDB.monitorWindow.xOffset = xOfs
        iNIFDB.monitorWindow.yOffset = yOfs
    end)
    frame:Hide()

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(Colors.iNIF .. L["MonitorWindowTitle"])

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        if iNIFDB.debug then
            print(L["DebugPrefix"] .. L["MonitorWindowHidden"])
        end
    end)

    -- Content area for roll entries
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)

    -- Store text entries
    frame.rollTexts = {}

    -- Update function
    frame.Update = function()
        -- Clear old texts
        for _, text in pairs(frame.rollTexts) do
            text:Hide()
            text:SetText("")
        end

        local yOffset = 0
        local count = 0

        for rollID, roll in pairs(activeRolls) do
            if roll.checkboxEnabled and roll.greedClicked and not roll.processed then
                count = count + 1

                -- Create or reuse text
                if not frame.rollTexts[count] then
                    frame.rollTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    frame.rollTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
                    frame.rollTexts[count]:SetJustifyH("LEFT")
                    frame.rollTexts[count]:SetWidth(350)
                end

                local text = frame.rollTexts[count]
                local elapsed = GetTime() - roll.startTime
                local remaining = roll.initialDuration - elapsed

                if remaining < 0 then remaining = 0 end

                -- Format: [Item] - 45s
                local timeColor = Colors.Green
                if remaining <= 10 then
                    timeColor = Colors.Yellow
                end
                if remaining <= 5 then
                    timeColor = Colors.Red
                end

                text:SetText(roll.itemLink .. " - " .. timeColor .. string.format("%.1f", remaining) .. "s" .. Colors.Reset)
                text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
                text:Show()

                yOffset = yOffset - 20
            end
        end

        -- Adjust frame height based on content
        local newHeight = 45 + (count * 20)
        if newHeight < 60 then newHeight = 60 end
        if newHeight > 300 then newHeight = 300 end
        frame:SetHeight(newHeight)

        -- Show/hide frame based on active rolls AND user setting
        -- Show frame only if: (active rolls exist) AND (debug mode OR user wants it visible)
        if count > 0 and (iNIFDB.debug or not iNIFDB.hideMonitorWindow) then
            frame:Show()
        else
            frame:Hide()
        end
    end

    return frame
end

-- ═══════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function Print(msg)
    if iNIFDB.showNotifications then
        print(L["PrintPrefix"] .. msg)
    end
end

-- Debug message with levels
-- Level 1 = ERROR (red)
-- Level 2 = WARNING (yellow)
-- Level 3 = INFO (white) - default
local function Debug(msg, level)
    if iNIFDB.debug then
        level = level or 3 -- Default to INFO

        if level == 1 then
            print(L["DebugError"] .. msg)
        elseif level == 2 then
            print(L["DebugWarning"] .. msg)
        else
            print(L["DebugInfo"] .. msg)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Count number of entries in a table
local function CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- ═══════════════════════════════════════════════════════════
-- CHECKBOX CREATION
-- ═══════════════════════════════════════════════════════════
local function CreateCheckbox(parent, rollID)
    -- Create checkbox with larger size for better visibility
    local checkbox = CreateFrame("CheckButton", "iNIF_Checkbox_" .. rollID, parent, "UICheckButtonTemplate")
    checkbox:SetSize(32, 32)

    -- Position on the right side of the frame, below the buttons
    checkbox:SetPoint("RIGHT", parent, "RIGHT", -10, -18)

    -- Add background container (fully transparent to blend with any loot frame)
    local bg = checkbox:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetSize(50, 50)
    bg:SetPoint("CENTER", checkbox, "CENTER", 0, 0)
    bg:SetVertexColor(0, 0, 0, 0)  -- Fully transparent (no visible background)
    checkbox.bg = bg

    -- Add small Need icon (dice) - top-left inside
    local needIcon = checkbox:CreateTexture(nil, "ARTWORK")
    needIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")  -- Need button texture
    needIcon:SetSize(14, 14)  -- Slightly smaller to fit nicely inside
    needIcon:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 2, -2)  -- Inside (positive X, negative Y)
    needIcon:SetAlpha(0.8)  -- Slightly more visible
    checkbox.needIcon = needIcon

    -- Add small Greed icon (coin) - bottom-right inside the border
    local greedIcon = checkbox:CreateTexture(nil, "ARTWORK")
    greedIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")  -- Greed button texture
    greedIcon:SetSize(14, 14)  -- Slightly smaller to fit nicely inside
    greedIcon:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", -2, 2)  -- Inside (negative X, positive Y)
    greedIcon:SetAlpha(0.8)  -- Slightly more visible
    checkbox.greedIcon = greedIcon

    -- Set initial state - default unchecked
    checkbox:SetChecked(false)

    -- Add hover effect and tooltip
    checkbox:SetScript("OnEnter", function(self)
        -- No background color change on hover (background is transparent)

        -- Show tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["CheckboxTooltipTitle"], 1, 1, 1, 1, true)
        GameTooltip:AddLine(L["CheckboxTooltipDesc"], nil, nil, nil, true)
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
        -- No background color change (background is transparent)

        -- Hide tooltip
        GameTooltip:Hide()
    end)

    -- Save state when clicked
    checkbox:SetScript("OnClick", function(self)
        if iNIFDB.checkboxRememberState then
            iNIFDB.checkboxChecked = self:GetChecked()
        end
        Debug("Checkbox toggled: " .. tostring(self:GetChecked()))
    end)

    return checkbox
end

-- ═══════════════════════════════════════════════════════════
-- ROLL PROCESSING FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function ProcessRoll(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed then
        return
    end

    -- Only auto-roll if the checkbox was enabled and greed was clicked
    if not roll.checkboxEnabled or not roll.greedClicked then
        Debug("Skipping auto-roll for rollID: " .. rollID .. " (checkbox not enabled or greed not clicked)")
        activeRolls[rollID] = nil
        return
    end

    roll.processed = true

    -- Nobody needed, stick with Greed
    RollOnLoot(rollID, 2) -- 2 = Greed
    -- Delay message by 0.5s to appear after WoW's item roll spam
    local itemLink = roll.itemLink -- Capture in closure
    C_Timer.After(0.5, function()
        Print(L["ChatRolledGreed"] .. string.format(L["ChatNobodyNeeded"], itemLink))
    end)

    -- Don't clean up immediately - keep the processed flag to prevent recreation
    -- Will be cleaned up by CANCEL_LOOT_ROLL event
end

-- AceComm message handler
function iNIF:OnCommReceived(prefix, message, distribution, sender)
    -- Only process iNIF prefix
    if prefix ~= "iNIF" then
        return
    end

    -- Clean sender name (remove realm)
    sender = Ambiguate(sender, "short")
    local myName = UnitName("player")

    -- Ignore our own messages
    if sender == myName then
        return
    end

    if iNIFDB.debug then
        Debug("Received comm from " .. sender .. ": " .. message, 3) -- INFO
    end

    -- Parse message: "GREED_CHECKBOX|<rollID>|<itemLink>"
    local msgType, rollIDStr, itemLink = message:match("^([^|]+)|([^|]+)|(.+)$")

    if msgType == "GREED_CHECKBOX" then
        local rollID = tonumber(rollIDStr)
        if not rollID then
            if iNIFDB.debug then
                Debug("Invalid rollID in comm message: " .. (rollIDStr or "nil"), 2) -- WARNING
            end
            return
        end

        local roll = activeRolls[rollID]
        if not roll then
            if iNIFDB.debug then
                Debug("Received comm for unknown rollID: " .. rollID, 2) -- WARNING
            end
            return
        end

        if roll.processed then
            if iNIFDB.debug then
                Debug("Received comm for already-processed rollID: " .. rollID, 3) -- INFO
            end
            return
        end

        -- Track this iNIF user's decision
        if not roll.iNIFGreeds then
            roll.iNIFGreeds = {}
        end

        roll.iNIFGreeds[sender] = true
        if iNIFDB.debug then
            Debug("Tracked iNIF Greed+checkbox from " .. sender .. " for rollID: " .. rollID .. " (total: " .. CountTable(roll.iNIFGreeds) .. ")", 3) -- INFO
        end

        -- Check if we should auto-roll based on iNIF decisions
        if roll.checkboxEnabled and roll.greedClicked then
            CheckIfAllINIFGreeded(rollID)
        end
    end
end

-- Helper function to check if all party members have greeded
local function CheckIfAllGreeded(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed or not roll.checkboxEnabled or not roll.greedClicked then
        return false
    end

    -- Count how many party members there are (excluding ourselves)
    -- Use GetNumGroupMembers for MoP+, fallback to GetNumRaidMembers/GetNumPartyMembers for older versions
    local partySize = 0
    if IsInRaid() then
        if GetNumGroupMembers then
            partySize = GetNumGroupMembers() - 1  -- MoP+ (includes self)
        else
            partySize = GetNumRaidMembers()  -- Classic/TBC/Wrath (excludes self)
        end
    elseif IsInGroup() then
        if GetNumGroupMembers then
            partySize = GetNumGroupMembers() - 1  -- MoP+ (includes self)
        else
            partySize = GetNumPartyMembers()  -- Classic/TBC/Wrath (excludes self)
        end
    end

    -- Count how many have greeded (from CHAT_MSG_LOOT)
    local greedCount = 0
    for _ in pairs(roll.greedRolls) do
        greedCount = greedCount + 1
    end

    -- Count iNIF users who clicked Greed+checkbox (via AceComm)
    -- These won't show in CHAT_MSG_LOOT until they actually roll
    local iNIFGreedCount = 0
    if roll.iNIFGreeds then
        for playerName, _ in pairs(roll.iNIFGreeds) do
            -- Only count if they're NOT already in greedRolls (avoid double-counting)
            if not roll.greedRolls[playerName] then
                iNIFGreedCount = iNIFGreedCount + 1
            end
        end
    end

    -- Count how many have passed
    local passCount = 0
    for _ in pairs(roll.passRolls) do
        passCount = passCount + 1
    end

    Debug("Decision count: " .. greedCount .. " greeds (chat), " .. iNIFGreedCount .. " greeds (iNIF), " .. passCount .. " passes = " .. (greedCount + iNIFGreedCount + passCount) .. "/" .. partySize .. " for rollID " .. rollID)

    -- If everyone else has decided (greeded OR passed), roll Greed immediately
    local decidedCount = greedCount + iNIFGreedCount + passCount
    if partySize > 0 and decidedCount >= partySize then
        Debug("Everyone decided: " .. greedCount .. " greeds, " .. passCount .. " passes. Auto-rolling Greed now.", 3) -- INFO
        ProcessRoll(rollID)
        return true
    end

    return false
end

-- Check if all iNIF users have decided (Greed+checkbox)
-- This allows faster auto-roll when multiple addon users are in the party
local function CheckIfAllINIFGreeded(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed or not roll.checkboxEnabled or not roll.greedClicked then
        return false
    end

    if not roll.iNIFGreeds then
        return false
    end

    local iNIFUserCount = CountTable(roll.iNIFGreeds)

    -- Require at least 1 other iNIF user to have decided
    -- (If iNIFUserCount == 0, means only we have iNIF, so fall back to timer)
    if iNIFUserCount < 1 then
        return false
    end

    -- Don't count until WE have decided
    if not roll.ourDecisionTime then
        return false  -- We haven't clicked yet, messages are buffered
    end

    -- Grace period starts from OUR decision, not first message
    local elapsed = GetTime() - roll.ourDecisionTime
    if elapsed < 2 then
        -- Still in grace period, waiting for other iNIF users to respond
        if iNIFDB.debug and elapsed < 0.1 then
            Debug("Grace period started (2s from our decision). Waiting for other iNIF users...", 3) -- INFO
        end
        return false
    end

    -- Don't auto-roll! Let CheckIfAllGreeded() handle the actual roll when EVERYONE decided
    if iNIFDB.debug then
        Debug("All iNIF users decided (" .. (iNIFUserCount + 1) .. " including self). Waiting for rest of party to decide...", 3) -- INFO
    end
    -- Return true to indicate iNIF coordination is complete, but don't ProcessRoll yet
    return true
end

-- ═══════════════════════════════════════════════════════════
-- LOOT ROLL FRAME ENHANCEMENT
-- ═══════════════════════════════════════════════════════════
local function EnhanceRollFrame(frame, rollID)
    if not frame then
        return
    end

    -- Don't enhance if addon is disabled
    if not iNIFDB.enabled then
        return
    end

    -- If already enhanced, just return (frame.rollID is updated by WoW automatically)
    if frame.iNIF_Enhanced then
        Debug("Frame already enhanced for rollID: " .. tostring(rollID) .. " (using frame.rollID dynamically)")
        return
    end

    Debug("Enhancing roll frame for rollID: " .. tostring(rollID))

    -- Create checkbox
    local checkbox = CreateCheckbox(frame, rollID)
    frame.iNIF_Checkbox = checkbox
    frame.iNIF_Enhanced = true

    -- Store original Greed button click handler
    local greedButton = frame.GreedButton or frame.greedButton
    if greedButton then
        -- Store the original OnClick handler
        local originalOnClick = greedButton:GetScript("OnClick")

        -- Replace with our custom handler
        greedButton:SetScript("OnClick", function(self, button, ...)
            -- Use frame.rollID which WoW updates for each new roll
            local currentRollID = frame.rollID
            if not currentRollID then
                Debug("No rollID on frame, calling original handler", 2) -- WARNING
                if originalOnClick then
                    originalOnClick(self, button, ...)
                end
                return
            end

            local isChecked = checkbox:GetChecked()
            if isChecked then
                -- Mark that checkbox is enabled and greed was clicked for this roll
                local roll = activeRolls[currentRollID]

                -- If roll is already processed, ignore this click (happens when RollOnLoot triggers the button again)
                if roll and roll.processed then
                    Debug("Ignoring Greed click on already-processed rollID: " .. currentRollID)
                    return
                end

                -- If roll doesn't exist, create it now (fallback for missed START_LOOT_ROLL)
                if not roll then
                    Debug("Creating missing roll entry for rollID: " .. currentRollID, 2) -- WARNING
                    local texture, name = GetLootRollItemInfo(currentRollID)
                    local itemLink = GetLootRollItemLink(currentRollID)

                    activeRolls[currentRollID] = {
                        startTime = GetTime(),
                        initialDuration = 60,
                        needDetected = false,
                        neededBy = nil,
                        processed = false,
                        itemLink = itemLink or name or "Unknown Item",
                        checkboxEnabled = false,
                        greedClicked = false,
                        greedRolls = {},
                        passRolls = {},
                        iNIFGreeds = {},
                        iNIFCommSent = false,
                        ourDecisionTime = nil  -- Time when WE clicked Greed+checkbox
                    }
                    roll = activeRolls[currentRollID]
                    Debug("Created roll object, checking if it exists: " .. tostring(roll ~= nil) .. ", rollID=" .. currentRollID)

                    -- Verify it was actually stored
                    if activeRolls[currentRollID] then
                        Debug("Roll successfully stored in activeRolls[" .. currentRollID .. "]", 3) -- INFO
                    else
                        Debug("Roll was NOT stored in activeRolls[" .. currentRollID .. "]!", 1) -- ERROR
                    end
                end

                if roll then
                    roll.checkboxEnabled = true
                    roll.greedClicked = true
                    roll.ourDecisionTime = GetTime()  -- Record when we decided
                    roll.frame = frame
                    roll.checkbox = checkbox

                    Debug("Greed clicked with checkbox enabled for rollID: " .. currentRollID)

                    -- Send AceComm message to notify other iNIF users
                    if AceComm and not roll.iNIFCommSent and (IsInGroup() or IsInRaid()) then
                        roll.iNIFCommSent = true
                        local distribution = IsInRaid() and "RAID" or "PARTY"
                        local message = "GREED_CHECKBOX|" .. currentRollID .. "|" .. roll.itemLink
                        iNIF:SendCommMessage("iNIF", message, distribution, nil, "NORMAL")
                        if iNIFDB.debug then
                            Debug("Sent GREED_CHECKBOX comm: " .. message .. " on " .. distribution, 3) -- INFO
                        end
                    end

                    -- Check if someone already needed BEFORE we clicked Greed+Checkbox
                    if roll.needDetected and roll.neededBy then
                        Debug("Someone already needed this item before Greed+Checkbox: " .. roll.neededBy)
                        -- Roll Need immediately
                        RollOnLoot(currentRollID, 1) -- 1 = Need
                        -- Delay message by 0.5s to appear after WoW's item roll spam
                        local itemLink = roll.itemLink -- Capture in closure
                        local neededBy = roll.neededBy:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                        C_Timer.After(0.5, function()
                            Print(Colors.Orange .. L["ChatRollingNeed"] .. string.format(L["ChatBecauseNeeded"], itemLink, neededBy))
                        end)

                        -- Announce to party/raid if enabled (delayed 0.5s like Print to avoid spam filters)
                        Debug("Party announce check: partyMessages=" .. tostring(iNIFDB.partyMessages) .. ", IsInGroup=" .. tostring(IsInGroup()) .. ", IsInRaid=" .. tostring(IsInRaid()), 3)
                        if iNIFDB.partyMessages and (IsInGroup() or IsInRaid()) then
                            local channel = IsInRaid() and "RAID" or "PARTY"
                            Debug("Preparing party announce on channel: " .. channel, 3)
                            local cleanPlayerName = roll.neededBy:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                            local capturedItemLink = roll.itemLink -- Capture in closure
                            C_Timer.After(0.5, function()
                                Debug("Sending party announce: " .. cleanPlayerName .. " - " .. capturedItemLink, 3)
                                SendChatMessage(string.format(L["ChatPartyAutoNeed"], capturedItemLink, cleanPlayerName), channel)
                            end)
                        else
                            Debug("Party announce skipped - conditions not met", 3)
                        end

                        roll.processed = true
                        return
                    end

                    -- Hide the Blizzard loot frame (GroupLootFrame) (unless debug mode is on or user disabled frame hiding)
                    if not iNIFDB.debug and iNIFDB.hideLootFrame then
                        frame:Hide()
                    end
                    Print(string.format(L["ChatMonitoring"], roll.itemLink))

                    -- Check if everyone has already greeded (handles late Greed+checkbox click)
                    CheckIfAllGreeded(currentRollID)

                    -- DON'T call the original handler - we handle the roll later
                    return
                end
            else
                -- Checkbox not checked, let normal Greed happen
                if originalOnClick then
                    originalOnClick(self, button, ...)
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- ROLL MONITORING (using CHAT_MSG_LOOT)
-- ═══════════════════════════════════════════════════════════
-- GetLootRollItemInfo is broken in Classic - use chat messages instead
-- This function is called when we detect a Need from CHAT_MSG_LOOT
local function OnNeedDetected(playerName, itemLink)
    Debug("CHAT: Need detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            -- Check if this is the same item (compare item links or names)
            local rollItemLink = roll.itemLink

            -- Match by item link or by checking if itemLink contains the roll item
            if itemLink and rollItemLink and (itemLink == rollItemLink or itemLink:find(rollItemLink, 1, true) or rollItemLink:find(itemLink, 1, true)) then
                Debug("Matched Need to rollID: " .. rollID)

                -- Check if it's not us
                local myName = UnitName("player")
                if playerName ~= myName then
                    Debug("Need from OTHER PLAYER: " .. playerName)
                    roll.needDetected = true
                    roll.neededBy = playerName

                    -- Only auto-roll if checkbox is already enabled
                    if roll.checkboxEnabled and roll.greedClicked then
                        -- Roll Need when someone ELSE needs
                        RollOnLoot(rollID, 1) -- 1 = Need
                        -- Delay message by 0.5s to appear after WoW's item roll spam
                        local itemLink = roll.itemLink -- Capture in closure
                        local playerWhoNeeded = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                        C_Timer.After(0.5, function()
                            Print(Colors.Orange .. L["ChatRollingNeed"] .. string.format(L["ChatBecauseNeeded"], itemLink, playerWhoNeeded))
                        end)

                        -- Announce to party/raid if enabled (delayed 0.5s like Print to avoid spam filters)
                        Debug("Party announce check: partyMessages=" .. tostring(iNIFDB.partyMessages) .. ", IsInGroup=" .. tostring(IsInGroup()) .. ", IsInRaid=" .. tostring(IsInRaid()), 3)
                        if iNIFDB.partyMessages and (IsInGroup() or IsInRaid()) then
                            local channel = IsInRaid() and "RAID" or "PARTY"
                            Debug("Preparing party announce on channel: " .. channel, 3)
                            -- Clean player name from [Loot]: prefix, color codes and hyperlinks
                            local cleanPlayerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                            local capturedItemLink = roll.itemLink -- Capture in closure
                            C_Timer.After(0.5, function()
                                Debug("Sending party announce: " .. cleanPlayerName .. " - " .. capturedItemLink, 3)
                                SendChatMessage(string.format(L["ChatPartyAutoNeed"], capturedItemLink, cleanPlayerName), channel)
                            end)
                        else
                            Debug("Party announce skipped - conditions not met", 3)
                        end

                        roll.processed = true
                        -- Don't clean up immediately - will be cleaned up by CANCEL_LOOT_ROLL event
                        return
                    else
                        Debug("Need detected but checkbox not enabled yet - will handle when Greed+Checkbox is clicked")
                    end
                    return
                else
                    Debug("Ignoring my own Need: " .. playerName)
                end
            end
        end
    end
end

-- This function is called when we detect a Greed from CHAT_MSG_LOOT
local function OnGreedDetected(playerName, itemLink)
    Debug("CHAT: Greed detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    local myName = UnitName("player")

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            local rollItemLink = roll.itemLink

            -- Match by item link
            if itemLink and rollItemLink and (itemLink == rollItemLink or itemLink:find(rollItemLink, 1, true) or rollItemLink:find(itemLink, 1, true)) then
                -- Track this greed (ignore our own) - track ALL greeds, not just when monitoring
                if playerName ~= myName then
                    roll.greedRolls[playerName] = true
                    Debug("Tracked Greed from " .. playerName .. " for rollID " .. rollID)

                    -- Only check if everyone greeded if we're actively monitoring
                    if roll.checkboxEnabled and roll.greedClicked then
                        CheckIfAllGreeded(rollID)
                    end
                    return
                end
            end
        end
    end
end

-- This function is called when we detect a Pass from CHAT_MSG_LOOT
local function OnPassDetected(playerName, itemLink)
    Debug("CHAT: Pass detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            -- Check if this is the same item (compare item links or names)
            local rollItemLink = roll.itemLink

            -- Match by item link or by checking if itemLink contains the roll item
            if itemLink and rollItemLink and (itemLink == rollItemLink or itemLink:find(rollItemLink, 1, true) or rollItemLink:find(itemLink, 1, true)) then
                Debug("Matched Pass to rollID: " .. rollID)

                -- Check if it's not us
                local myName = UnitName("player")
                if playerName ~= myName then
                    Debug("Pass from OTHER PLAYER: " .. playerName)

                    -- Track this pass
                    roll.passRolls[playerName] = true
                    Debug("Tracked Pass from " .. playerName .. " for rollID " .. rollID)

                    -- Only check if everyone decided if we're actively monitoring
                    if roll.checkboxEnabled and roll.greedClicked then
                        CheckIfAllGreeded(rollID)
                    end
                    return
                else
                    Debug("Ignoring my own Pass: " .. playerName)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- FRAME UPDATE LOOP
-- ═══════════════════════════════════════════════════════════
local updateTimer = 0
local function OnUpdate(self, elapsed)
    updateTimer = updateTimer + elapsed

    -- Check every 0.5 seconds (reduced from 0.1s to lower CPU usage)
    if updateTimer < 0.5 then
        return
    end
    updateTimer = 0

    local currentTime = GetTime()

    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            -- Check if everyone has decided (periodic check to catch delayed chat events OR iNIF comm messages)
            if roll.checkboxEnabled and roll.greedClicked then
                CheckIfAllGreeded(rollID)
                CheckIfAllINIFGreeded(rollID)
            end

            -- Calculate elapsed time since roll started
            local elapsed = currentTime - roll.startTime
            local remainingTime = roll.initialDuration - elapsed

            -- When 2 seconds or less remaining, process the roll (if checkbox enabled)
            if remainingTime <= 2 and roll.checkboxEnabled and roll.greedClicked then
                Debug("Timer reached 2 seconds for rollID: " .. rollID .. " (remaining: " .. string.format("%.1f", remainingTime) .. "s)")
                ProcessRoll(rollID)
            elseif remainingTime < 0 then
                -- Roll expired - clean up to prevent memory leak
                Debug("Roll expired for rollID: " .. rollID .. (roll.checkboxEnabled and " (was being monitored)" or " (not monitored)"))
                activeRolls[rollID] = nil
            end
        end
    end

    -- Update timer window if it exists
    if timerWindow and timerWindow.Update then
        timerWindow:Update()
    end
end

eventFrame:SetScript("OnUpdate", OnUpdate)

-- ═══════════════════════════════════════════════════════════
-- OPTIONS PANEL
-- ═══════════════════════════════════════════════════════════

-- Helper function to create iWR-style frame
local function CreateiNIFStyleFrame(parent, width, height, anchor)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint(unpack(anchor))
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    return frame
end

-- Helper: Create section header
local function CreateSectionHeader(parent, text, yOffset)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset)
    header:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
    })
    header:SetBackdropColor(0.15, 0.15, 0.2, 0.6)

    local accent = header:CreateTexture(nil, "ARTWORK")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(1, 0.59, 0.09, 0.4)

    local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", header, "LEFT", 8, 0)
    label:SetText(text)

    return header, yOffset - 28
end

-- Helper: Create checkbox
local function CreateSettingsCheckbox(parent, label, descText, yOffset, settingKey)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    cb.Text:SetText(label)
    cb.Text:SetFontObject(GameFontHighlight)
    cb:SetChecked(iNIFDB[settingKey])

    -- Register this checkbox for live updates
    table.insert(iNIF.CheckboxRegistry[settingKey], cb)

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        iNIFDB[settingKey] = checked

        -- Don't show debug message for the debug checkbox itself (handled separately)
        if settingKey ~= "debug" then
            Debug(label .. " " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
        end

        -- Update all other checkboxes for this setting
        UpdateAllCheckboxes(settingKey, checked)
    end)

    local nextY = yOffset - 22
    if descText and descText ~= "" then
        local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        desc:SetPoint("TOPLEFT", parent, "TOPLEFT", 48, nextY)
        desc:SetWidth(480)
        desc:SetJustifyH("LEFT")
        desc:SetText(descText)
        local height = desc:GetStringHeight()
        if height < 12 then height = 12 end
        nextY = nextY - height - 6
    end

    return cb, nextY
end

-- Helper: Create info text
local function CreateInfoText(parent, text, yOffset, fontObj)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObj or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 25, yOffset)
    fs:SetWidth(500)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    local height = fs:GetStringHeight()
    if height < 14 then height = 14 end
    return fs, yOffset - height - 4
end

local function CreateOptionsPanel()
    -- Main frame (750x520) - needs to be named for ESC functionality
    local settingsFrame = CreateFrame("Frame", "iNIFSettingsFrame", UIParent, "BackdropTemplate")
    settingsFrame:SetSize(750, 520)
    settingsFrame:SetPoint("CENTER", UIParent, "CENTER")
    settingsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    settingsFrame:Hide()
    settingsFrame:EnableMouse(true)
    settingsFrame:SetMovable(true)
    settingsFrame:SetFrameStrata("HIGH")
    settingsFrame:SetClampedToScreen(true)
    settingsFrame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    settingsFrame:SetBackdropBorderColor(0.8, 0.8, 0.9, 1)

    -- ESC closes the frame
    table.insert(UISpecialFrames, "iNIFSettingsFrame")

    -- Shadow
    local shadow = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", settingsFrame, -1, 1)
    shadow:SetPoint("BOTTOMRIGHT", settingsFrame, 1, -1)
    shadow:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 5,
    })
    shadow:SetBackdropBorderColor(0, 0, 0, 0.8)

    -- Drag
    settingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settingsFrame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
    settingsFrame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing(); self:SetUserPlaced(true) end)
    settingsFrame:RegisterForDrag("LeftButton", "RightButton")

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    titleBar:SetHeight(31)
    titleBar:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5},
    })
    titleBar:SetBackdropColor(0.07, 0.07, 0.12, 1)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText(Colors.iNIF .. Title .. Colors.Green .. " v" .. Version)

    local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() settingsFrame:Hide() end)

    -- Sidebar (150px)
    local sidebarWidth = 150
    local sidebar = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    sidebar:SetWidth(sidebarWidth)
    sidebar:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -35)
    sidebar:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 10, 10)
    sidebar:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    sidebar:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    sidebar:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, settingsFrame, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 6, 0)
    contentArea:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -10, 10)
    contentArea:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    contentArea:SetBackdropBorderColor(0.6, 0.6, 0.7, 1)
    contentArea:SetBackdropColor(0.08, 0.08, 0.1, 0.95)

    -- Tab content frames with scroll
    local scrollFrames = {}
    local scrollChildren = {}
    local contentWidth = 550

    local function CreateTabContent()
        local container = CreateFrame("Frame", nil, contentArea)
        container:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 5, -5)
        container:SetPoint("BOTTOMRIGHT", contentArea, "BOTTOMRIGHT", -5, 5)
        container:Hide()

        local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -22, 0)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(contentWidth)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)

        container:EnableMouseWheel(true)
        container:SetScript("OnMouseWheel", function(_, delta)
            local current = scrollFrame:GetVerticalScroll()
            local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
            if maxScroll < 0 then maxScroll = 0 end
            local newScroll = current - (delta * 30)
            if newScroll < 0 then newScroll = 0 end
            if newScroll > maxScroll then newScroll = maxScroll end
            scrollFrame:SetVerticalScroll(newScroll)
        end)

        table.insert(scrollFrames, scrollFrame)
        table.insert(scrollChildren, scrollChild)

        return container, scrollChild
    end

    local generalContainer, generalContent = CreateTabContent()
    local aboutContainer, aboutContent = CreateTabContent()

    -- Check if iWR is installed
    local iWRInstalled = iWR ~= nil
    local iWRContainer, iWRContent
    if iWRInstalled then
        iWRContainer, iWRContent = CreateTabContent()
    end

    local tabContents = {generalContainer, aboutContainer}
    if iWRInstalled then
        table.insert(tabContents, iWRContainer)
    end

    local sidebarButtons = {}
    local activeIndex = 1

    local function ShowTab(index)
        activeIndex = index
        for i, content in ipairs(tabContents) do
            content:SetShown(i == index)
        end
        for i, btn in ipairs(sidebarButtons) do
            if i == index then
                btn.bg:SetColorTexture(1, 0.59, 0.09, 0.25)
                btn.text:SetFontObject(GameFontHighlight)
            else
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.text:SetFontObject(GameFontNormal)
            end
        end
    end

    -- Create sidebar buttons
    local sidebarLabels = {L["TabGeneral"], L["TabAbout"]}
    if iWRInstalled then
        table.insert(sidebarLabels, L["TabIWRSettings"])
    end

    for i, label in ipairs(sidebarLabels) do
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(sidebarWidth - 12, 26)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -6 - (i - 1) * 28)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(btn)
        bg:SetColorTexture(0, 0, 0, 0)
        btn.bg = bg

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", btn, "LEFT", 10, 0)
        text:SetText(label)
        btn.text = text

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(btn)
        highlight:SetColorTexture(1, 1, 1, 0.08)

        btn:SetScript("OnClick", function()
            ShowTab(i)
        end)

        sidebarButtons[i] = btn
    end

    -- Show first tab by default
    ShowTab(1)

    -- Track checkboxes for refresh
    local checkboxRefs = {}

    -- ═══════════════════════════════════════════════════════════
    -- GENERAL TAB CONTENT
    -- ═══════════════════════════════════════════════════════════
    local y = -10

    _, y = CreateSectionHeader(generalContent, L["SettingsSectionAddon"], y)

    local cbEnabled
    cbEnabled, y = CreateSettingsCheckbox(generalContent, L["SettingsEnableAddon"],
        L["SettingsEnableAddonDesc"], y, "enabled")
    checkboxRefs.enabled = cbEnabled

    local cbNotify
    cbNotify, y = CreateSettingsCheckbox(generalContent, L["SettingsShowNotifications"],
        L["SettingsShowNotificationsDesc"], y, "showNotifications")
    checkboxRefs.showNotifications = cbNotify

    local cbParty
    cbParty, y = CreateSettingsCheckbox(generalContent, L["SettingsPartyAnnounce"],
        L["SettingsPartyAnnounceDesc"], y, "partyMessages")
    checkboxRefs.partyMessages = cbParty

    local cbHideLootFrame
    cbHideLootFrame, y = CreateSettingsCheckbox(generalContent, L["SettingsHideLootFrame"],
        L["SettingsHideLootFrameDesc"], y, "hideLootFrame")
    checkboxRefs.hideLootFrame = cbHideLootFrame

    local cbHideMonitorWindow
    cbHideMonitorWindow, y = CreateSettingsCheckbox(generalContent, L["SettingsHideMonitor"],
        L["SettingsHideMonitorDesc"], y, "hideMonitorWindow")
    checkboxRefs.hideMonitorWindow = cbHideMonitorWindow

    scrollChildren[1]:SetHeight(math.abs(y) + 20)

    -- ═══════════════════════════════════════════════════════════
    -- ABOUT TAB CONTENT
    -- ═══════════════════════════════════════════════════════════
    y = -10

    _, y = CreateSectionHeader(aboutContent, L["SettingsSectionAbout"], y)

    y = y - 20

    -- Icon
    local iconTexture = aboutContent:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture("Interface\\AddOns\\iNeedIfYouNeed\\images\\Logo_iNIF")
    iconTexture:SetSize(64, 64)
    iconTexture:SetPoint("TOP", aboutContent, "TOP", 0, y)
    y = y - 70

    local aboutTitle = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    aboutTitle:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutTitle:SetText(Colors.iNIF .. Title .. Colors.Reset .. " " .. Colors.Green .. "v" .. Version .. Colors.Reset)
    y = y - 20

    local aboutAuthor = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    aboutAuthor:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutAuthor:SetText(L["AboutCreatedBy"] .. Colors.Teal .. "Crasling")
    y = y - 16

    local aboutGameVer = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    aboutGameVer:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutGameVer:SetText(L["AboutGameVersion"])
    y = y - 30

    local aboutInfo
    aboutInfo, y = CreateInfoText(aboutContent,
        L["AboutDescription1"] .. "\n\n" .. L["AboutDescription2"],
        y, "GameFontHighlight")

    -- Discord Section
    y = y - 10
    _, y = CreateSectionHeader(aboutContent, L["SettingsSectionDiscord"], y)
    y = y - 2

    local discordDesc = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    discordDesc:SetPoint("TOPLEFT", aboutContent, "TOPLEFT", 25, y)
    discordDesc:SetText(L["AboutDiscordDesc"])
    y = y - 16

    local discordBox = CreateFrame("EditBox", nil, aboutContent, "InputBoxTemplate")
    discordBox:SetSize(280, 22)
    discordBox:SetPoint("TOPLEFT", aboutContent, "TOPLEFT", 25, y)
    discordBox:SetAutoFocus(false)
    discordBox:SetText("https://discord.gg/8nnt25aw8B")
    discordBox:SetFontObject(GameFontHighlight)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetText("https://discord.gg/8nnt25aw8B")
    end)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    y = y - 30

    -- Developer Section
    y = y - 8
    _, y = CreateSectionHeader(aboutContent, L["SettingsSectionDeveloper"], y)

    local cbDebug
    cbDebug, y = CreateSettingsCheckbox(aboutContent, L["SettingsDebugMode"],
        L["SettingsDebugModeDesc"], y, "debug")
    checkboxRefs.debug = cbDebug

    -- Override the debug checkbox handler to show activation warning
    cbDebug:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        iNIFDB.debug = checked
        UpdateAllCheckboxes("debug", checked)

        -- Show activation warning (like iWR) - second sentence in red
        if checked then
            print(L["DebugModeActivatedFull"])
        end
    end)

    scrollChildren[2]:SetHeight(math.abs(y) + 20)

    -- ═══════════════════════════════════════════════════════════
    -- iWR SETTINGS TAB (if installed)
    -- ═══════════════════════════════════════════════════════════
    if iWRInstalled and iWRContent then
        y = -10

        _, y = CreateSectionHeader(iWRContent, L["SettingsSectionIWR"], y)

        local iWRInfo
        iWRInfo, y = CreateInfoText(iWRContent,
            L["IWRInstalledDesc1"] .. "\n\n" .. L["IWRInstalledDesc2"],
            y, "GameFontHighlight")

        y = y - 10

        -- Open iWR Settings button
        local iWRButton = CreateFrame("Button", nil, iWRContent, "UIPanelButtonTemplate")
        iWRButton:SetSize(180, 28)
        iWRButton:SetPoint("TOPLEFT", iWRContent, "TOPLEFT", 25, y)
        iWRButton:SetText(L["IWROpenSettingsButton"])
        iWRButton:SetScript("OnClick", function()
            -- Open iWR's settings frame if it exists
            if iWR and iWR.SettingsFrame then
                settingsFrame:Hide()
                iWR.SettingsFrame:Show()
            end
        end)

        scrollChildren[3]:SetHeight(math.abs(y) + 20)
    end

    -- ═══════════════════════════════════════════════════════════
    -- STUB PANEL FOR BLIZZARD INTERFACE OPTIONS
    -- ═══════════════════════════════════════════════════════════
    local stubPanel = CreateFrame("Frame", "iNIFOptionsPanel", UIParent)
    stubPanel.name = "iNeedIfYouNeed"

    local stubTitle = stubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    stubTitle:SetPoint("TOPLEFT", 16, -16)
    stubTitle:SetText(Colors.iNIF .. Title .. " " .. Colors.Green .. "v" .. Version)

    local stubDesc = stubPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    stubDesc:SetPoint("TOPLEFT", stubTitle, "BOTTOMLEFT", 0, -10)
    stubDesc:SetText(L["StubPanelDesc"])

    local stubButton = CreateFrame("Button", nil, stubPanel, "UIPanelButtonTemplate")
    stubButton:SetSize(180, 28)
    stubButton:SetPoint("TOPLEFT", stubDesc, "BOTTOMLEFT", 0, -15)
    stubButton:SetText(L["StubOpenSettingsButton"])
    stubButton:SetScript("OnClick", function() settingsFrame:Show() end)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(stubPanel)
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(stubPanel, "iNeedIfYouNeed")
        Settings.RegisterAddOnCategory(category)
    end

    -- Store reference for opening from minimap/slash
    iNIF.SettingsFrame = settingsFrame

    -- Refresh checkboxes when shown
    settingsFrame:HookScript("OnShow", function()
        for key, cb in pairs(checkboxRefs) do
            if iNIFDB[key] ~= nil then
                cb:SetChecked(iNIFDB[key])
            end
        end
    end)

    return stubPanel
end

-- ═══════════════════════════════════════════════════════════
-- EVENT HANDLING
-- ═══════════════════════════════════════════════════════════
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            -- Initialize AceComm
            if AceComm then
                AceComm:Embed(iNIF)
                iNIF:RegisterComm("iNIF", "OnCommReceived")
                if iNIFDB.debug then
                    Debug("AceComm initialized and registered prefix 'iNIF'", 3) -- INFO
                end
            else
                Debug("AceComm-3.0 not found! Cross-addon communication disabled.", 1) -- ERROR
            end

            -- Delayed startup message (like iWR) - always shows, no severity prefix
            C_Timer.After(2, function()
                print(L["DebugPrefix"] .. string.format(L["StartupMessage"], Title, Colors.Green .. "v" .. Version .. Colors.iNIF))
            end)
        end

    elseif event == "PLAYER_LOGIN" then
        -- Create options panel after everything is loaded
        C_Timer.After(0.5, function()
            CreateOptionsPanel()
        end)

        -- Create timer window (hide unless debug mode or user wants to see it)
        C_Timer.After(0.6, function()
            timerWindow = CreateTimerWindow()
            if not iNIFDB.debug and iNIFDB.hideMonitorWindow then
                timerWindow:Hide()
            end
        end)

    elseif event == "START_LOOT_ROLL" then
        local rollID = ...
        Debug("START_LOOT_ROLL: " .. tostring(rollID))

        -- Don't process if addon is disabled
        if not iNIFDB.enabled then
            Debug("Addon disabled, ignoring loot roll", 3) -- INFO
            return
        end

        -- Only process loot rolls when in a group or raid
        if not IsInGroup() and not IsInRaid() then
            Debug("Not in group or raid, ignoring loot roll", 3) -- INFO
            return
        end

        -- Get item info immediately
        local texture, name = GetLootRollItemInfo(rollID)
        local itemLink = GetLootRollItemLink(rollID)

        Debug("START_LOOT_ROLL got item info: name=" .. tostring(name) .. ", itemLink=" .. tostring(itemLink))

        -- Start tracking this roll immediately with our own timer
        -- Standard loot roll duration in Classic is 60 seconds
        activeRolls[rollID] = {
            startTime = GetTime(),
            initialDuration = 60,
            needDetected = false,
            neededBy = nil,
            processed = false,
            itemLink = itemLink or name or "Unknown Item",
            checkboxEnabled = false,  -- Will be set to true when user clicks Greed with checkbox
            greedClicked = false,     -- Track if user has clicked Greed
            greedRolls = {},          -- Track who has greeded: {playerName = true}
            passRolls = {},           -- Track who has passed: {playerName = true}
            iNIFGreeds = {},          -- Track iNIF users who greeded with checkbox: {playerName = true}
            iNIFCommSent = false,     -- Track if we sent our comm message
            ourDecisionTime = nil      -- Time when WE clicked Greed+checkbox
        }

        Debug("Started timer for rollID: " .. rollID .. ", stored itemLink: " .. tostring(activeRolls[rollID].itemLink) .. ", duration: 60s")

        -- Find and enhance the roll frame
        C_Timer.After(0.1, function()
            -- Try to find the frame (different Classic versions have different frame names)
            for i = 1, 4 do
                local frame = _G["GroupLootFrame" .. i] or _G["LootRollFrame" .. i]
                if frame and frame:IsShown() then
                    local frameRollID = frame.rollID
                    if frameRollID == rollID then
                        -- If already enhanced, reset checkbox for new roll
                        if frame.iNIF_Enhanced and frame.iNIF_Checkbox then
                            Debug("Resetting checkbox to UNCHECKED for new rollID: " .. rollID, 3) -- INFO
                            -- Always reset to unchecked for new rolls
                            frame.iNIF_Checkbox:SetChecked(false)
                            -- Also update saved state if remember state is enabled
                            if iNIFDB.checkboxRememberState then
                                iNIFDB.checkboxChecked = false
                            end
                        else
                            EnhanceRollFrame(frame, rollID)
                        end
                        break
                    end
                end
            end
        end)

    elseif event == "CANCEL_LOOT_ROLL" then
        local rollID = ...
        Debug("CANCEL_LOOT_ROLL: " .. tostring(rollID))
        if activeRolls[rollID] then
            activeRolls[rollID] = nil
        end

    elseif event == "CHAT_MSG_LOOT" then
        -- Don't process if addon is disabled
        if not iNIFDB.enabled then
            return
        end

        local message = ...

        -- Pattern: "[Loot]: PlayerName has selected Need for: [Item Link]"
        -- Strip the [Loot]: prefix if present
        local cleanMessage = message:gsub("^%[.-%]:%s*", "")

        local playerName, itemLink = cleanMessage:match("^(.-)%s+has selected Need for:%s*(.+)$")
        if playerName and itemLink then
            -- Clean player name from all WoW markup codes AND [Loot]: prefix immediately after parsing
            playerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            Debug("CHAT_MSG_LOOT: " .. playerName .. " needed " .. itemLink)
            OnNeedDetected(playerName, itemLink)
            return
        end

        -- Pattern: "[Loot]: PlayerName has selected Greed for: [Item Link]"
        playerName, itemLink = cleanMessage:match("^(.-)%s+has selected Greed for:%s*(.+)$")
        if playerName and itemLink then
            -- Clean player name from all WoW markup codes AND [Loot]: prefix immediately after parsing
            playerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            Debug("CHAT_MSG_LOOT: " .. playerName .. " greeded " .. itemLink)
            OnGreedDetected(playerName, itemLink)
            return
        end

        -- Pattern: "[Loot]: PlayerName passed on: [Item Link]"
        playerName, itemLink = cleanMessage:match("^(.-)%s+passed on:%s*(.+)$")
        if playerName and itemLink then
            -- Clean player name from all WoW markup codes AND [Loot]: prefix immediately after parsing
            playerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            Debug("CHAT_MSG_LOOT: " .. playerName .. " passed " .. itemLink)
            OnPassDetected(playerName, itemLink)
            return
        end

        -- Unmatched message
        Debug("CHAT_MSG_LOOT (not matched): " .. message)

    elseif event == "LOOT_BIND_CONFIRM" then
        local slot = ...
        Debug("LOOT_BIND_CONFIRM for slot: " .. tostring(slot))

        -- Check if we have an active monitored roll
        local hasMonitoredRoll = false
        for rollID, roll in pairs(activeRolls) do
            if roll.checkboxEnabled and roll.greedClicked and not roll.processed then
                hasMonitoredRoll = true
                Debug("Found monitored roll: " .. rollID .. ", auto-confirming BoP")
                break
            end
        end

        -- Only auto-confirm if we have a monitored roll (user clicked Greed+checkbox)
        if hasMonitoredRoll then
            Debug("Auto-confirming BoP bind", 3) -- INFO
            ConfirmLootSlot(slot)
            StaticPopup_Hide("LOOT_BIND")
        else
            Debug("No monitored roll, not auto-confirming BoP")
        end
    end
end

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("START_LOOT_ROLL")
eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("LOOT_BIND_CONFIRM")
eventFrame:SetScript("OnEvent", OnEvent)

-- ═══════════════════════════════════════════════════════════
-- CUSTOM MENU FRAME
-- ═══════════════════════════════════════════════════════════

-- Helper function to create iWR-style frame
local function CreateiNIFStyleFrame(parent, width, height, anchor)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint(unpack(anchor))
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    frame:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.8, 0.8, 0.9, 1)
    return frame
end

-- Create the main menu panel
local iNIFMenuPanel = CreateiNIFStyleFrame(UIParent, 280, 220, {"CENTER", UIParent, "CENTER"})
iNIFMenuPanel:Hide()
iNIFMenuPanel:EnableMouse(true)
iNIFMenuPanel:SetMovable(true)
iNIFMenuPanel:SetFrameStrata("HIGH")
iNIFMenuPanel:SetClampedToScreen(true)

-- Shadow effect
local shadow = CreateFrame("Frame", nil, iNIFMenuPanel, "BackdropTemplate")
shadow:SetPoint("TOPLEFT", iNIFMenuPanel, -1, 1)
shadow:SetPoint("BOTTOMRIGHT", iNIFMenuPanel, 1, -1)
shadow:SetBackdrop({
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 5,
})
shadow:SetBackdropBorderColor(0, 0, 0, 0.8)

-- Drag functionality
iNIFMenuPanel:SetScript("OnDragStart", function(self) self:StartMoving() end)
iNIFMenuPanel:SetScript("OnMouseDown", function(self) self:StartMoving() end)
iNIFMenuPanel:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing(); self:SetUserPlaced(true) end)
iNIFMenuPanel:RegisterForDrag("LeftButton", "RightButton")

-- Title bar
local titleBar = CreateFrame("Frame", nil, iNIFMenuPanel, "BackdropTemplate")
titleBar:SetSize(iNIFMenuPanel:GetWidth(), 31)
titleBar:SetPoint("TOP", iNIFMenuPanel, "TOP", 0, 0)
titleBar:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16,
    insets = {left = 5, right = 5, top = 5, bottom = 5},
})
titleBar:SetBackdropColor(0.07, 0.07, 0.12, 1)

-- Title text
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
titleText:SetText(L["MenuTitle"] .. Colors.Green .. " v" .. Version)

-- Close button
local closeButton = CreateFrame("Button", nil, iNIFMenuPanel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", iNIFMenuPanel, "TOPRIGHT", 0, 0)
closeButton:SetScript("OnClick", function()
    iNIFMenuPanel:Hide()
end)

-- Menu content
local yOffset = -45

-- Enable/Disable checkbox
local enableCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
enableCheck:SetPoint("TOPLEFT", 20, yOffset)
enableCheck.text:SetText(Colors.iNIF .. L["MenuEnableAddon"])
enableCheck:SetChecked(iNIFDB.enabled)
table.insert(iNIF.CheckboxRegistry.enabled, enableCheck)
enableCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.enabled = checked
    Debug(checked and L["StatusEnabled"] or L["StatusDisabled"])
    UpdateAllCheckboxes("enabled", checked)
end)
yOffset = yOffset - 30

-- Show notifications checkbox
local notifyCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
notifyCheck:SetPoint("TOPLEFT", 20, yOffset)
notifyCheck.text:SetText(Colors.iNIF .. L["MenuShowNotifications"])
notifyCheck:SetChecked(iNIFDB.showNotifications)
table.insert(iNIF.CheckboxRegistry.showNotifications, notifyCheck)
notifyCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.showNotifications = checked
    Debug(L["SlashNotifications"] .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
    UpdateAllCheckboxes("showNotifications", checked)
end)
yOffset = yOffset - 30

-- Party announcements checkbox
local partyCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
partyCheck:SetPoint("TOPLEFT", 20, yOffset)
partyCheck.text:SetText(Colors.iNIF .. L["MenuPartyAnnouncements"])
partyCheck:SetChecked(iNIFDB.partyMessages)
table.insert(iNIF.CheckboxRegistry.partyMessages, partyCheck)
partyCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.partyMessages = checked
    Debug(L["SlashPartyMessages"] .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
    UpdateAllCheckboxes("partyMessages", checked)
end)
yOffset = yOffset - 30

-- Hide loot frame checkbox
local hideLootCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
hideLootCheck:SetPoint("TOPLEFT", 20, yOffset)
hideLootCheck.text:SetText(Colors.iNIF .. L["MenuHideLootFrame"])
hideLootCheck:SetChecked(iNIFDB.hideLootFrame)
table.insert(iNIF.CheckboxRegistry.hideLootFrame, hideLootCheck)
hideLootCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.hideLootFrame = checked
    Debug("Hide loot frame " .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
    UpdateAllCheckboxes("hideLootFrame", checked)
end)
yOffset = yOffset - 30

-- Hide monitor window checkbox
local hideMonitorWindowCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
hideMonitorWindowCheck:SetPoint("TOPLEFT", 20, yOffset)
hideMonitorWindowCheck.text:SetText(Colors.iNIF .. L["MenuHideMonitor"])
hideMonitorWindowCheck:SetChecked(iNIFDB.hideMonitorWindow)
table.insert(iNIF.CheckboxRegistry.hideMonitorWindow, hideMonitorWindowCheck)
hideMonitorWindowCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.hideMonitorWindow = checked
    Debug("Hide monitor window " .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
    UpdateAllCheckboxes("hideMonitorWindow", checked)

    -- Show/hide timer window immediately
    if timerWindow then
        if checked and not iNIFDB.debug then
            timerWindow:Hide()
        elseif not checked or iNIFDB.debug then
            timerWindow:Show()
        end
    end
end)
yOffset = yOffset - 30

-- Debug mode checkbox
local debugCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", 20, yOffset)
debugCheck.text:SetText(Colors.iNIF .. L["MenuDebugMode"])
debugCheck:SetChecked(iNIFDB.debug)
table.insert(iNIF.CheckboxRegistry.debug, debugCheck)
debugCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.debug = checked
    UpdateAllCheckboxes("debug", checked)

    -- Show activation warning (like iWR) - second sentence in red
    if checked then
        print(Colors.iNIF .. "[iNIF]: " .. Colors.White .. "INFO: " .. Colors.Reset .. Colors.iNIF .. L["DebugModeActivated"] .. Colors.Red .. L["DebugModeWarning"] .. Colors.Reset)
    end

    -- Show/hide timer window based on debug mode
    if timerWindow then
        if checked then
            timerWindow:Show()
        elseif iNIFDB.hideMonitorWindow then
            timerWindow:Hide()
        end
    end
end)
yOffset = yOffset - 40

-- Settings button
local settingsButton = CreateFrame("Button", nil, iNIFMenuPanel, "UIPanelButtonTemplate")
settingsButton:SetSize(120, 26)
settingsButton:SetPoint("TOPLEFT", 20, yOffset)
settingsButton:SetText(L["MenuFullSettings"])
settingsButton:SetScript("OnClick", function()
    iNIFMenuPanel:Hide()
    if iNIF.SettingsFrame then
        iNIF.SettingsFrame:Show()
    end
end)

-- Refresh checkboxes when menu opens
iNIFMenuPanel:SetScript("OnShow", function()
    enableCheck:SetChecked(iNIFDB.enabled)
    notifyCheck:SetChecked(iNIFDB.showNotifications)
    partyCheck:SetChecked(iNIFDB.partyMessages)
    hideLootCheck:SetChecked(iNIFDB.hideLootFrame)
    hideMonitorWindowCheck:SetChecked(iNIFDB.hideMonitorWindow)
    debugCheck:SetChecked(iNIFDB.debug)
end)

-- Menu toggle functions
local function MenuToggle()
    if iNIFMenuPanel:IsVisible() then
        iNIFMenuPanel:Hide()
    else
        iNIFMenuPanel:Show()
    end
end

local function MenuClose()
    iNIFMenuPanel:Hide()
end

local function MenuOpen()
    iNIFMenuPanel:Show()
end

-- ═══════════════════════════════════════════════════════════
-- MINIMAP ICON
-- ═══════════════════════════════════════════════════════════

-- Create minimap button (following iWR pattern)
if LDBroker and LDBIcon then
    local minimapButton = LDBroker:NewDataObject("iNeedIfYouNeed", {
        type = "data source",
        text = "iNIF",
        icon = "Interface\\AddOns\\iNeedIfYouNeed\\images\\Logo_iNIF",
        OnClick = function(self, button)
            if button == "LeftButton" then
                -- Check for Shift modifier
                if IsShiftKeyDown() then
                    -- Shift+Left: Show all hidden loot frames
                    local framesShown = 0
                    for rollID, roll in pairs(activeRolls) do
                        if roll.frame and roll.checkboxEnabled and not roll.frame:IsShown() then
                            roll.frame:Show()
                            framesShown = framesShown + 1
                            Debug("Showing hidden loot frame for rollID: " .. rollID, 3) -- INFO
                        end
                    end

                    if framesShown > 0 then
                        local msg = framesShown == 1 and L["ShowingFramesSingular"] or L["ShowingFramesPlural"]
                        print(string.format(msg, framesShown))
                    else
                        print(L["NoHiddenFrames"])
                    end
                else
                    -- Regular Left: Toggle enable/disable
                    iNIFDB.enabled = not iNIFDB.enabled
                    -- Show status message in chat
                    Print(iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"])
                    -- Update all checkboxes
                    UpdateAllCheckboxes("enabled", iNIFDB.enabled)
                end
            elseif button == "RightButton" then
                -- Open custom settings frame
                if iNIF.SettingsFrame then
                    iNIF.SettingsFrame:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then return end
            tooltip:SetText(Colors.iNIF .. Title .. Colors.Green .. " v" .. Version, 1, 1, 1)
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine(L["TooltipLeftClick"] .. L["TooltipToggleAddon"], 1, 1, 1)
            tooltip:AddLine(L["TooltipRightClick"] .. L["TooltipOpenSettings"], 1, 1, 1)
            tooltip:AddLine(L["TooltipShiftLeftClick"] .. L["TooltipShowFrames"], 1, 1, 1)
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine(L["TooltipStatus"] .. (iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"]), 1, 1, 1)
            tooltip:Show()
        end,
    })

    LDBIcon:Register("iNeedIfYouNeed", minimapButton, iNIFDB.minimapButton)
end

-- ═══════════════════════════════════════════════════════════
-- SLASH COMMANDS
-- ═══════════════════════════════════════════════════════════
SLASH_iNIF1 = "/inif"
SlashCmdList["iNIF"] = function(msg)
    msg = string.lower(string.trim(msg or ""))

    if msg == "config" or msg == "settings" or msg == "options" then
        -- Open custom settings frame
        if iNIF.SettingsFrame then
            iNIF.SettingsFrame:Show()
        end

    elseif msg == "toggle" then
        iNIFDB.enabled = not iNIFDB.enabled
        Print(iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"])

    elseif msg == "notifications" or msg == "notify" then
        iNIFDB.showNotifications = not iNIFDB.showNotifications
        Print(L["SlashNotifications"] .. (iNIFDB.showNotifications and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "party" then
        iNIFDB.partyMessages = not iNIFDB.partyMessages
        Print(L["SlashPartyMessages"] .. (iNIFDB.partyMessages and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "remember" then
        iNIFDB.checkboxRememberState = not iNIFDB.checkboxRememberState
        Print(L["SlashRememberState"] .. (iNIFDB.checkboxRememberState and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "debug" then
        iNIFDB.debug = not iNIFDB.debug
        UpdateAllCheckboxes("debug", iNIFDB.debug)

        -- Show activation warning (like iWR) - second sentence in red
        if iNIFDB.debug then
            print(L["DebugModeActivatedFull"])
        end

    elseif msg == "test" then
        -- Test if START_LOOT_ROLL event is being caught
        print(L["TestHeader"])
        print(L["TestActiveRollsCount"] .. Colors.Yellow .. tostring(#activeRolls) .. Colors.Reset)
        print(L["TestRegisteredEvents"])
        print(L["TestEventAddonLoaded"] .. (eventFrame:IsEventRegistered("ADDON_LOADED") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventPlayerLogin"] .. (eventFrame:IsEventRegistered("PLAYER_LOGIN") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventStartLootRoll"] .. (eventFrame:IsEventRegistered("START_LOOT_ROLL") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventCancelLootRoll"] .. (eventFrame:IsEventRegistered("CANCEL_LOOT_ROLL") and L["TestYes"] or L["TestNo"]))

        -- List all active rolls
        local count = 0
        for rollID, roll in pairs(activeRolls) do
            count = count + 1
            print(string.format(L["TestRollInfo"], count, rollID, roll.itemLink, tostring(roll.checkboxEnabled)))
        end
        if count == 0 then
            print("  " .. Colors.Yellow .. L["TestNoActiveRolls"] .. Colors.Reset)
        end

    elseif msg == "testcomm" then
        -- Test AceComm message reception
        print(L["TestCommHeader"])

        -- Check if AceComm is loaded
        if not AceComm then
            print(L["TestCommNotLoaded"])
            return
        end

        -- Find an active roll to test with
        local testRollID = nil
        local testItemLink = nil
        for rollID, roll in pairs(activeRolls) do
            if not roll.processed and roll.checkboxEnabled and roll.greedClicked then
                testRollID = rollID
                testItemLink = roll.itemLink
                break
            end
        end

        if not testRollID then
            print(L["TestCommNoRoll"])
            print(L["TestCommInstructions"])
            return
        end

        -- Enable debug mode temporarily to see output
        local debugWasOff = not iNIFDB.debug
        if debugWasOff then
            iNIFDB.debug = true
            print(L["TestDebugTempEnabled"])
        end

        -- Simulate receiving message from fake player
        local fakePlayer = "TestPlayer"
        local fakeMessage = "GREED_CHECKBOX|" .. testRollID .. "|" .. testItemLink

        print(L["TestCommSimulating"] .. Colors.Yellow .. fakePlayer .. Colors.Reset)
        print(L["TestCommMessage"] .. Colors.Yellow .. fakeMessage .. Colors.Reset)

        -- Call OnCommReceived directly (this is what AceComm would call)
        iNIF:OnCommReceived("iNIF", fakeMessage, "PARTY", fakePlayer)

        -- Check if it was tracked
        local roll = activeRolls[testRollID]
        if roll and roll.iNIFGreeds and roll.iNIFGreeds[fakePlayer] then
            print(L["TestCommSuccess1"])
            print(L["TestCommSuccess2"])
            print(L["TestCommTotalUsers"] .. Colors.Yellow .. (CountTable(roll.iNIFGreeds) + 1) .. L["TestCommIncludingYou"] .. Colors.Reset)
            print(L["TestCommGracePeriod"])
        else
            print(L["TestCommFailed"])
        end

        -- Restore debug mode if it was off
        if debugWasOff then
            C_Timer.After(3, function()
                iNIFDB.debug = false
                print(L["TestDebugRestored"])
            end)
        end

    else
        print(Colors.iNIF .. string.format(L["SlashVersionInfo"], Title, Version) .. Colors.Reset)
        print(L["SlashCommandsHeader"])
        print("  " .. L["SlashHelpConfig"])
        print("  " .. L["SlashHelpToggle"])
        print("  " .. L["SlashHelpNotifications"])
        print("  " .. L["SlashHelpParty"])
        print("  " .. L["SlashHelpRemember"])
        print("  " .. L["SlashHelpDebug"])
        print("  " .. L["SlashHelpTest"])
        print("  " .. L["SlashHelpTestComm"])
    end
end
