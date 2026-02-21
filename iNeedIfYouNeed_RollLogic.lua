-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗  ██╗ ███████╗ ██╗   ██╗  ██████╗  ██╗   ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗
-- ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗ ██║ ██╔════╝ ╚██╗ ██╔╝ ██╔═══██╗ ██║   ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗
-- ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║ ██║ █████╗    ╚████╔╝  ██║   ██║ ██║   ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║
-- ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║ ██║ ██╔══╝     ╚██╔╝   ██║   ██║ ██║   ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║
-- ██║ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝ ██║ ██║         ██║    ╚██████╔╝ ╚██████╔╝ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝
-- ╚═╝ ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝  ╚═╝ ╚═╝         ╚═╝     ╚═════╝   ╚═════╝  ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

local addonName, iNIF = ...
local L = iNIF.L or {}  -- Load localization table with fallback

-- Local aliases for frequently accessed namespace values
local Colors = iNIF.Colors
local activeRolls = iNIF.activeRolls
local AceComm = iNIF.AceComm

-- Forward declarations for local functions used across sections
local CheckIfAllINIFGreeded
local CheckIfAllGreeded
local CheckEnchanterMode

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Timer Window                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.CreateTimerWindow()
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Utility Functions                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.Print(msg)
    if iNIFDB.showNotifications then
        print(L["PrintPrefix"] .. msg)
    end
end

-- Debug message with levels
-- Level 1 = ERROR (red)
-- Level 2 = WARNING (yellow)
-- Level 3 = INFO (white) - default
function iNIF.Debug(msg, level)
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Helper Functions                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Count number of entries in a table
function iNIF.CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Check if any loot roll is still active (not yet processed)
function iNIF.HasActiveRolls()
    for _, roll in pairs(activeRolls) do
        if not roll.processed then
            return true
        end
    end
    return false
end

-- Local aliases for internal use in this file
local Print = function(...) return iNIF.Print(...) end
local Debug = function(...) return iNIF.Debug(...) end
local CountTable = function(...) return iNIF.CountTable(...) end
local HasActiveRolls = function(...) return iNIF.HasActiveRolls(...) end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Checkbox Creation                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
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

    -- Need icon (dice) - top-left inside (always visible)
    local needIcon = checkbox:CreateTexture(nil, "ARTWORK")
    needIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    needIcon:SetSize(14, 14)
    needIcon:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 2, -2)
    needIcon:SetAlpha(0.8)
    checkbox.needIcon = needIcon

    -- Greed icon (coin) - bottom-right inside (always visible)
    local greedIcon = checkbox:CreateTexture(nil, "ARTWORK")
    greedIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
    greedIcon:SetSize(14, 14)
    greedIcon:SetPoint("BOTTOMRIGHT", checkbox, "BOTTOMRIGHT", -2, 2)
    greedIcon:SetAlpha(0.8)
    checkbox.greedIcon = greedIcon

    -- Disenchant overlay - centered, 50% opacity (only visible in Enchanter Mode)
    local deOverlay = checkbox:CreateTexture(nil, "OVERLAY")
    deOverlay:SetTexture("Interface\\Icons\\INV_Enchant_Disenchant")
    deOverlay:SetSize(16, 16)
    deOverlay:SetPoint("CENTER", checkbox, "CENTER", 0, 0)
    deOverlay:SetAlpha(0.5)
    deOverlay:SetShown(iNIFDB.enchanterMode)
    checkbox.deOverlay = deOverlay

    -- Update visuals based on mode
    local function UpdateCheckboxMode()
        deOverlay:SetShown(iNIFDB.enchanterMode)
    end
    checkbox.UpdateMode = UpdateCheckboxMode

    -- Set initial state - default unchecked
    checkbox:SetChecked(false)

    -- Add hover effect and tooltip
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if iNIFDB.enchanterMode then
            GameTooltip:SetText(L["CheckboxTooltipTitleEnchanter"], 1, 1, 1, 1, true)
            GameTooltip:AddLine(L["CheckboxTooltipDescEnchanter"], nil, nil, nil, true)
        else
            GameTooltip:SetText(L["CheckboxTooltipTitle"], 1, 1, 1, 1, true)
            GameTooltip:AddLine(L["CheckboxTooltipDesc"], nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)

    checkbox:SetScript("OnLeave", function(self)
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Roll Processing Functions                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           AceComm Handler                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
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

    elseif msgType == "ENCHANTER_MODE" then
        local rollID = tonumber(rollIDStr)
        if not rollID then return end

        local roll = activeRolls[rollID]
        if not roll or roll.processed then return end

        -- Track that another iNIF user is using Enchanter Mode on this roll
        roll.enchanterNeedSent = true -- Prevent us from also needing for disenchant
        Debug("Received ENCHANTER_MODE from " .. sender .. " for rollID: " .. rollID .. " - skipping our enchanter need", 3)
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Decision Logic                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Helper function to check if all party members have greeded
CheckIfAllGreeded = function(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed or not roll.checkboxEnabled or not roll.greedClicked then
        return false
    end

    -- Use the eligible count captured at START_LOOT_ROLL (only connected + visible players)
    -- This avoids counting players who are offline or in a different zone
    local partySize = roll.eligibleCount or 0

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
CheckIfAllINIFGreeded = function(rollID)
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                             Enchanter Mode                                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
CheckEnchanterMode = function(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed then return end
    if not iNIFDB.enchanterMode then return end
    if not iNIFDB.enabled then return end

    -- Require checkbox + greed click (same as normal iNIF)
    if not roll.checkboxEnabled or not roll.greedClicked then return end

    -- Don't act if someone needed
    if roll.needDetected then return end

    -- Use the eligible count captured at START_LOOT_ROLL (only connected + visible players)
    local partySize = roll.eligibleCount or 0

    local greedCount = CountTable(roll.greedRolls)
    local passCount = CountTable(roll.passRolls)

    -- Count iNIF users (avoid double-counting)
    local iNIFGreedCount = 0
    if roll.iNIFGreeds then
        for playerName, _ in pairs(roll.iNIFGreeds) do
            if not roll.greedRolls[playerName] then
                iNIFGreedCount = iNIFGreedCount + 1
            end
        end
    end

    local decidedCount = greedCount + iNIFGreedCount + passCount

    Debug("Enchanter Mode check: " .. decidedCount .. "/" .. partySize .. " decided, needDetected=" .. tostring(roll.needDetected) .. ", quality=" .. tostring(roll.itemQuality))

    if partySize > 0 and decidedCount >= partySize then
        -- Everyone decided, nobody needed → Need for disenchant!
        roll.processed = true
        roll.enchanterNeedSent = true
        RollOnLoot(rollID, 1) -- 1 = Need

        -- Send AceComm notification to other iNIF users
        if AceComm and (IsInGroup() or IsInRaid()) then
            local distribution = IsInRaid() and "RAID" or "PARTY"
            local message = "ENCHANTER_MODE|" .. rollID .. "|" .. roll.itemLink
            iNIF:SendCommMessage("iNIF", message, distribution, nil, "NORMAL")
        end

        -- Chat notification
        local itemLink = roll.itemLink
        C_Timer.After(0.5, function()
            Print(L["EnchanterModeNeeded"] .. itemLink)
        end)

        -- Party/Raid announcement (FORCED — always announce enchanter needs for transparency)
        if IsInGroup() or IsInRaid() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            local capturedItemLink = roll.itemLink
            C_Timer.After(0.5, function()
                SendChatMessage(string.format(L["EnchanterModePartyMsg"], capturedItemLink), channel)
            end)
        end
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Loot Roll Frame Enhancement                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.EnhanceRollFrame(frame, rollID)
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

    -- Enchanter Mode label
    local enchanterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    enchanterLabel:SetPoint("TOP", frame, "TOP", 0, -4)
    enchanterLabel:SetText("|cFFAA55FF" .. L["EnchanterModeLabel"] .. "|r")
    enchanterLabel:SetShadowOffset(2, -2)
    enchanterLabel:SetShadowColor(0, 0, 0, 1)
    enchanterLabel:SetShown(iNIFDB.enchanterMode)
    frame.iNIF_EnchanterLabel = enchanterLabel

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
                    local texture, name, count, quality = GetLootRollItemInfo(currentRollID)
                    local itemLink = GetLootRollItemLink(currentRollID)

                    activeRolls[currentRollID] = {
                        startTime = GetTime(),
                        initialDuration = 60,
                        needDetected = false,
                        neededBy = nil,
                        processed = false,
                        itemLink = itemLink or name or "Unknown Item",
                        itemQuality = quality or 0,
                        checkboxEnabled = false,
                        greedClicked = false,
                        greedRolls = {},
                        passRolls = {},
                        iNIFGreeds = {},
                        iNIFCommSent = false,
                        enchanterNeedSent = false,
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
                    -- In Enchanter Mode (green+ only): someone needed → skip (don't need back)
                    if roll.needDetected and roll.neededBy and not iNIFDB.enchanterMode then
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
                    if iNIFDB.enchanterMode then
                        Print(string.format(L["ChatMonitoringEnchanter"], roll.itemLink))
                    else
                        Print(string.format(L["ChatMonitoring"], roll.itemLink))
                    end

                    -- Check if everyone has already greeded (handles late Greed+checkbox click)
                    if iNIFDB.enchanterMode then
                        CheckEnchanterMode(currentRollID)
                    else
                        CheckIfAllGreeded(currentRollID)
                    end

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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                     Roll Monitoring (CHAT_MSG_LOOT)                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
-- GetLootRollItemInfo is broken in Classic - use chat messages instead
-- This function is called when we detect a Need from CHAT_MSG_LOOT
function iNIF.OnNeedDetected(playerName, itemLink)
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

                    -- Enchanter Mode: someone needs → skip (don't need back, let them have it)
                    if iNIFDB.enchanterMode then
                        Debug("Enchanter Mode: someone needed, skipping this item")
                        return
                    end

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
function iNIF.OnGreedDetected(playerName, itemLink)
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

                    -- Only check if everyone greeded/decided if we're actively monitoring
                    if roll.checkboxEnabled and roll.greedClicked then
                        if iNIFDB.enchanterMode then
                            CheckEnchanterMode(rollID)
                        else
                            CheckIfAllGreeded(rollID)
                        end
                    end
                    return
                end
            end
        end
    end
end

-- This function is called when we detect a Pass from CHAT_MSG_LOOT
function iNIF.OnPassDetected(playerName, itemLink)
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
                        if iNIFDB.enchanterMode then
                            CheckEnchanterMode(rollID)
                        else
                            CheckIfAllGreeded(rollID)
                        end
                    end
                    return
                else
                    Debug("Ignoring my own Pass: " .. playerName)
                end
            end
        end
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Frame Update Loop                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
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
                if iNIFDB.enchanterMode then
                    -- Enchanter Mode: Need if everyone decided and nobody needed
                    if not roll.enchanterNeedSent then
                        CheckEnchanterMode(rollID)
                    end
                else
                    -- Normal iNIF (or Enchanter Mode with quality < green): Greed if everyone decided, Need if someone needed
                    CheckIfAllGreeded(rollID)
                    CheckIfAllINIFGreeded(rollID)
                end
            end

            -- Calculate elapsed time since roll started
            local elapsed = currentTime - roll.startTime
            local remainingTime = roll.initialDuration - elapsed

            -- Timer fallback at 2 seconds remaining
            if remainingTime <= 2 and roll.checkboxEnabled and roll.greedClicked then
                if iNIFDB.enchanterMode then
                    -- Enchanter Mode: Need for disenchant if nobody needed
                    if not roll.enchanterNeedSent and not roll.needDetected and not roll.processed then
                        Debug("Enchanter Mode timer fallback for rollID: " .. rollID)
                        CheckEnchanterMode(rollID)
                    end
                else
                    -- Normal iNIF (or Enchanter Mode with quality < green): Greed (nobody needed)
                    Debug("Timer reached 2 seconds for rollID: " .. rollID .. " (remaining: " .. string.format("%.1f", remainingTime) .. "s)")
                    ProcessRoll(rollID)
                end

            elseif remainingTime < 0 then
                -- Roll expired - clean up to prevent memory leak
                Debug("Roll expired for rollID: " .. rollID .. (roll.checkboxEnabled and " (was being monitored)" or " (not monitored)"))
                activeRolls[rollID] = nil
            end
        end
    end

    -- Update timer window if it exists
    if iNIF.timerWindow and iNIF.timerWindow.Update then
        iNIF.timerWindow:Update()
    end
end

iNIF.eventFrame:SetScript("OnUpdate", OnUpdate)
