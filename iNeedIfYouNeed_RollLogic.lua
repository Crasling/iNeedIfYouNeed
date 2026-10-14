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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                Chat Output Routing                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.PrintToChat(...)
    local msg = table.concat({tostringall(...)}, " ")
    if ChatFrame1 then ChatFrame1:AddMessage(msg) end
    local frames = iNIFDB and iNIFDB.ChatFrames or {}
    for i = 2, NUM_CHAT_WINDOWS do
        if frames[i] then
            local cf = _G["ChatFrame" .. i]
            if cf then cf:AddMessage(msg) end
        end
    end
end

local print = function(...) iNIF.PrintToChat(...) end

-- Local aliases for frequently accessed namespace values
local Colors = iNIF.Colors
local activeRolls = iNIF.activeRolls
local AceComm = iNIF.AceComm

-- Forward declarations for local functions used across sections
local CheckIfAllGreeded
local CheckEnchanterMode

local function GetRemainingRollSeconds(rollID)
    local milliseconds = GetLootRollTimeLeft(rollID)
    if type(milliseconds) ~= "number" or not iNIF.IsSafeValue(milliseconds) then return nil end
    return milliseconds / 1000
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Timer Window                                      │
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
                local remaining = GetRemainingRollSeconds(rollID) or 0

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
-- │                            Utility Functions                                   │
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
function iNIF:DebugMsg(msg, level)
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

-- All debug-mode entry points use this function so the About page, minimap
-- menu, slash command, checkboxes, and monitor window cannot drift apart.
function iNIF.SetDebugMode(enabled, announce)
    enabled = enabled and true or false
    iNIFDB.debug = enabled
    iNIF.UpdateAllCheckboxes("debug", enabled)

    if iNIF.timerWindow then
        if enabled or not iNIFDB.hideMonitorWindow then
            iNIF.timerWindow:Show()
        else
            iNIF.timerWindow:Hide()
        end
    end

    if announce then
        if enabled then
            print(L["DebugModeActivatedFull"])
        else
            print(L["DebugPrefix"] .. (L["DebugModeDisabled"] or "Debug Mode is disabled."))
        end
    end

    if enabled then iNIF:DebugMsg("Debug output enabled from the settings interface.", 3) end
    return enabled
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Helper Functions                                    │
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
local CountTable = function(...) return iNIF.CountTable(...) end
local HasActiveRolls = function(...) return iNIF.HasActiveRolls(...) end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Ninja Detection Tables                                │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Forever armor proficiencies: what each class can equip.
local CLASS_ARMOR_PROFICIENCY = {
    WARRIOR     = { Cloth = true, Leather = true, Mail = true, Plate = true },
    PALADIN     = { Cloth = true, Leather = true, Mail = true, Plate = true },
    HUNTER      = { Cloth = true, Leather = true, Mail = true },
    ROGUE       = { Cloth = true, Leather = true },
    PRIEST      = { Cloth = true },
    SHAMAN      = { Cloth = true, Leather = true, Mail = true },
    MAGE        = { Cloth = true },
    WARLOCK     = { Cloth = true },
    DRUID       = { Cloth = true, Leather = true },
}

-- GetItemInfo subclassID → armor type name
local ARMOR_SUBCLASS = {
    [1] = "Cloth",
    [2] = "Leather",
    [3] = "Mail",
    [4] = "Plate",
}

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Ninja Detection Functions                                │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Get a group member's english class by name
function iNIF.GetGroupMemberClass(playerName)
    local member = iNIF.GetGroupMember(playerName)
    return member and member.class or nil
end

-- Extract item ID from an item link
local function GetItemIDFromLink(itemLink)
    if type(itemLink) ~= "string" or not iNIF.IsSafeValue(itemLink) then return nil end
    local itemID = itemLink:match("item:(%d+)")
    return tonumber(itemID)
end

function iNIF.LootItemsMatch(firstItem, secondItem)
    if not iNIF.IsSafeValue(firstItem) or not iNIF.IsSafeValue(secondItem) then return false end
    local firstID = GetItemIDFromLink(firstItem)
    local secondID = GetItemIDFromLink(secondItem)
    if firstID and secondID then return firstID == secondID end
    return type(firstItem) == "string" and firstItem == secondItem
end

-- Check if a Need roll is a ninja (wrong armor type)
function iNIF.CheckNinjaForItem(playerName, playerClass, itemLink, itemDataLoaded)
    if not iNIFDB.ninjaDetection then return end

    local itemID = GetItemIDFromLink(itemLink)
    if not itemID then return end

    local name, link, quality, itemLevel, reqLevel, itemType, itemSubType,
          stackCount, equipLoc, texture, sellPrice, classID, subclassID = C_Item.GetItemInfo(itemID)

    if not iNIF.IsSafeValue(classID) or not iNIF.IsSafeValue(subclassID) then return end

    if not classID then
        if not itemDataLoaded then
            Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                iNIF.CheckNinjaForItem(playerName, playerClass, itemLink, true)
            end)
        end
        return
    end

    -- Only check armor items (classID 4, subclassID 1-4: Cloth/Leather/Mail/Plate)
    if type(classID) ~= "number" or type(subclassID) ~= "number" then return end
    if classID ~= 4 or subclassID < 1 or subclassID > 4 then
        return
    end

    local armorType = ARMOR_SUBCLASS[subclassID]
    local proficiency = CLASS_ARMOR_PROFICIENCY[playerClass]

    if proficiency and armorType and not proficiency[armorType] then
        -- NINJA DETECTED
        iNIF.OnNinjaDetected(playerName, playerClass, itemLink, armorType)
    end
end

-- Handle a detected ninja
function iNIF.OnNinjaDetected(playerName, playerClass, itemLink, armorType)
    playerName = iNIF.CleanPlayerName(playerName)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerName or not playerKey then return end
    iNIF:DebugMsg("NINJA DETECTED: " .. playerName .. " (" .. playerClass .. ") rolled Need on " .. armorType .. " armor: " .. (itemLink or "?"), 2)

    -- Record incident
    if not iNIF.ninjaIncidents[playerKey] then
        iNIF.ninjaIncidents[playerKey] = { name = playerName, count = 0, incidents = {} }
    end
    iNIF.ninjaIncidents[playerKey].name = playerName
    iNIF.ninjaIncidents[playerKey].count = iNIF.ninjaIncidents[playerKey].count + 1
    table.insert(iNIF.ninjaIncidents[playerKey].incidents, {
        itemLink = itemLink,
        armorType = armorType,
        timestamp = GetTime(),
    })

    -- Print local warning
    local warningMsg = string.format(
        L["NinjaDetected"] or (Colors.Red .. "NINJA: " .. Colors.Reset .. "%s (%s) rolled Need on %s — cannot equip %s armor!"),
        playerName, playerClass, itemLink or "?", armorType
    )
    print(L["PrintPrefix"] .. warningMsg)

    -- Announce to party/raid if enabled
    if iNIFDB.ninjaAnnounce and (IsInGroup() or IsInRaid()) then
        local channel = IsInRaid() and "RAID" or "PARTY"
        local partyMsg = string.format(
            L["NinjaPartyMsg"] or "[iNIF]: Warning: %s rolled Need on %s - this class cannot equip %s armor",
            playerName, itemLink or "?", armorType
        )
        C_Timer.After(0.5, function()
            SendChatMessage(partyMsg, channel)
        end)
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                       Roll Fairness Tracking                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Track that a player participated in a roll
function iNIF.TrackRollParticipation(playerName, rollID, rollType)
    if not iNIFDB.rollTracker then return end
    playerName = iNIF.CleanPlayerName(playerName)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerName or not playerKey then return end

    -- The game can repeat loot chat lines. Count each player only once per roll.
    local roll = iNIF.activeRolls[rollID]
    if roll then
        roll.trackerParticipants = roll.trackerParticipants or {}
        if roll.trackerParticipants[playerKey] then return end
        roll.trackerParticipants[playerKey] = rollType or true
    end

    if not iNIF.rollTracker.players[playerKey] then
        iNIF.rollTracker.players[playerKey] = { name = playerName, wins = 0, rolls = 0, needWins = 0, greedWins = 0 }
    end
    iNIF.rollTracker.players[playerKey].name = playerName
    iNIF.rollTracker.players[playerKey].rolls = iNIF.rollTracker.players[playerKey].rolls + 1
    iNIF.rollTracker.totalRolls = iNIF.rollTracker.totalRolls + 1
end

-- Track that a player won a roll
function iNIF.TrackRollWin(playerName, itemLink)
    if not iNIFDB.rollTracker then return end
    playerName = iNIF.CleanPlayerName(playerName)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerName or not playerKey then return end

    if not iNIF.rollTracker.players[playerKey] then
        iNIF.rollTracker.players[playerKey] = { name = playerName, wins = 0, rolls = 0, needWins = 0, greedWins = 0 }
    end
    iNIF.rollTracker.players[playerKey].name = playerName
    iNIF.rollTracker.players[playerKey].wins = iNIF.rollTracker.players[playerKey].wins + 1

    table.insert(iNIF.rollTracker.history, {
        itemLink = itemLink,
        winner = playerName,
        timestamp = GetTime(),
    })

    iNIF:DebugMsg("Roll win tracked: " .. playerName .. " won " .. (itemLink or "?"), 3)

    -- Update luck meter if visible
    if iNIF.UpdateLuckMeter then iNIF.UpdateLuckMeter() end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Checkbox Creation                                   │
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
        iNIF:DebugMsg("Checkbox toggled: " .. tostring(self:GetChecked()))
    end)

    return checkbox
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Roll Processing Functions                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local function ProcessRoll(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed then
        return
    end

    -- Only auto-roll if the checkbox was enabled and greed was clicked
    if not roll.checkboxEnabled or not roll.greedClicked then
        iNIF:DebugMsg("Skipping auto-roll for rollID: " .. rollID .. " (checkbox not enabled or greed not clicked)")
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
-- │                           AceComm Handler                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF:OnCommReceived(prefix, message, distribution, sender)
    -- Only process iNIF prefix
    if prefix ~= "iNIF" then
        return
    end

    sender = iNIF.CleanPlayerName(sender)
    local senderKey = iNIF.GetPlayerKey(sender)
    if not sender or not senderKey then return end
    local myName = iNIF.GetUnitPlayerName("player")

    -- Ignore our own messages
    if iNIF.PlayerNamesMatch(sender, myName) then
        return
    end

    if iNIFDB.debug then
        iNIF:DebugMsg("Received comm from " .. sender .. ": " .. message, 3) -- INFO
    end

    -- Parse message: "GREED_CHECKBOX|<rollID>|<itemLink>"
    local msgType, rollIDStr, itemLink = message:match("^([^|]+)|([^|]+)|(.+)$")

    if msgType == "GREED_CHECKBOX" then
        local rollID = tonumber(rollIDStr)
        if not rollID then
            if iNIFDB.debug then
                iNIF:DebugMsg("Invalid rollID in comm message: " .. (rollIDStr or "nil"), 2) -- WARNING
            end
            return
        end

        local roll = activeRolls[rollID]
        if not roll then
            if iNIFDB.debug then
                iNIF:DebugMsg("Received comm for unknown rollID: " .. rollID, 2) -- WARNING
            end
            return
        end

        if roll.processed then
            if iNIFDB.debug then
                iNIF:DebugMsg("Received comm for already-processed rollID: " .. rollID, 3) -- INFO
            end
            return
        end

        -- Track this iNIF user's decision
        if not roll.iNIFGreeds then
            roll.iNIFGreeds = {}
        end

        roll.iNIFGreeds[senderKey] = sender
        if iNIFDB.debug then
            iNIF:DebugMsg("Tracked iNIF Greed+checkbox from " .. sender .. " for rollID: " .. rollID .. " (total: " .. CountTable(roll.iNIFGreeds) .. ")", 3) -- INFO
        end

        -- Check if we should auto-roll based on iNIF decisions
        if roll.checkboxEnabled and roll.greedClicked then
            CheckIfAllGreeded(rollID)
        end

    elseif msgType == "ENCHANTER_MODE" then
        local rollID = tonumber(rollIDStr)
        if not rollID then return end

        local roll = activeRolls[rollID]
        if not roll or roll.processed then return end

        -- Track that another iNIF user is using Enchanter Mode on this roll
        roll.enchanterNeedSent = true -- Prevent us from also needing for disenchant
        iNIF:DebugMsg("Received ENCHANTER_MODE from " .. sender .. " for rollID: " .. rollID .. " - skipping our enchanter need", 3)
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Decision Logic                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Submit the held Greed as soon as every other eligible player has also chosen
-- Greed. If anyone passes, keep waiting so a late Need can still be mirrored.
CheckIfAllGreeded = function(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed or not roll.checkboxEnabled or not roll.greedClicked then
        return false
    end

    -- START_LOOT_ROLL stores only the other connected and visible players who
    -- can participate. The local player is deliberately not part of this count.
    local eligibleOtherCount = roll.eligibleCount or 0

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

    local otherGreedCount = greedCount + iNIFGreedCount
    local decidedCount = otherGreedCount + passCount

    local decisionSignature = table.concat({ greedCount, iNIFGreedCount, passCount, eligibleOtherCount }, ":")
    if roll.lastDecisionDebugSignature ~= decisionSignature then
        roll.lastDecisionDebugSignature = decisionSignature
        iNIF:DebugMsg("Other-player decisions: " .. greedCount .. " greeds (chat), "
            .. iNIFGreedCount .. " greeds (iNIF), " .. passCount .. " passes = "
            .. decidedCount .. "/" .. eligibleOtherCount
            .. " for rollID " .. rollID)
    end

    if eligibleOtherCount > 0 and otherGreedCount >= eligibleOtherCount and passCount == 0 then
        iNIF:DebugMsg("Every other eligible player chose Greed; submitting monitored Greed for rollID " .. rollID .. ".", 3)
        ProcessRoll(rollID)
        return true
    end

    return false
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                             Enchanter Mode                                     │
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

    iNIF:DebugMsg("Enchanter Mode check: " .. decidedCount .. "/" .. partySize .. " decided, needDetected=" .. tostring(roll.needDetected) .. ", quality=" .. tostring(roll.itemQuality))

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
-- │                          Roll Count Label Update                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
-- Format a roll count for display: shows 0-39, then "39+" for anything higher
local function FormatRollCount(n)
    n = n or 0
    if n > 39 then return "39+" end
    return tostring(n)
end

-- Forever's group-loot template uses lower-camel button keys, while newer
-- templates use upper-camel keys. Resolve either layout in one place.
local function GetRollButton(frame, kind)
    if not frame or type(kind) ~= "string" then return nil end
    local lowerKind = kind:lower()
    local function Find(container)
        if not container then return nil end
        return container[kind .. "Button"] or container[lowerKind .. "Button"]
            or container[kind] or container[lowerKind]
    end
    return Find(frame) or Find(frame.LootButtonContainer)
end

-- Forever owns group-roll frames through the modern GroupLootContainer.
function iNIF.GetLootRollFrames()
    local frames, seen = {}, {}
    local function Add(frame)
        if frame and not seen[frame] then
            seen[frame] = true
            frames[#frames + 1] = frame
        end
    end

    local container = _G.GroupLootContainer
    if container then
        for _, frame in pairs(container.rollFrames) do Add(frame) end
    end
    return frames
end

-- Show or hide all count labels on currently visible roll frames.
-- Called when the showRollCounts setting is toggled.
function iNIF.RefreshRollCountLabels()
    local visible = iNIFDB.showRollCounts and true or false
    for _, frame in ipairs(iNIF.GetLootRollFrames()) do
        if frame then
            if frame.iNIF_NeedCount  then frame.iNIF_NeedCount:SetShown(visible)  end
            if frame.iNIF_GreedCount then frame.iNIF_GreedCount:SetShown(visible) end
            if frame.iNIF_PassCount  then frame.iNIF_PassCount:SetShown(visible)  end
        end
    end
end

function iNIF.UpdateRollCounters(rollID)
    if not iNIFDB.showRollCounts then return end
    local roll = activeRolls[rollID]
    if not roll then return end

    -- Try stored frame reference first (works for both real and test frames)
    local frame = roll.frame
    if frame and (not frame:IsShown() or frame.rollID ~= rollID) then
        frame = nil
    end

    -- Fall back to scanning Blizzard GroupLootFrames
    if not frame then
        for _, f in ipairs(iNIF.GetLootRollFrames()) do
            if f and f:IsShown() and f.rollID == rollID then
                frame = f
                break
            end
        end
    end

    if frame then
        if frame.iNIF_NeedCount  then frame.iNIF_NeedCount:SetText(FormatRollCount(roll.needCount))  end
        if frame.iNIF_GreedCount then frame.iNIF_GreedCount:SetText(FormatRollCount(roll.greedCount)) end
        if frame.iNIF_PassCount  then frame.iNIF_PassCount:SetText(FormatRollCount(roll.passCount))  end
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Loot Roll Frame Enhancement                             │
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
        iNIF:DebugMsg("Frame already enhanced for rollID: " .. tostring(rollID) .. " (using frame.rollID dynamically)")
        return
    end

    iNIF:DebugMsg("Enhancing roll frame for rollID: " .. tostring(rollID))

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

    -- Roll count labels (Need / Greed / Pass counters)
    -- Positioned bottom-right of the button icon, matching default WoW roll count style
    if iNIFDB.showRollCounts ~= false then
        local needBtn = GetRollButton(frame, "Need")
        local greedBtn = GetRollButton(frame, "Greed")
        local passBtn = GetRollButton(frame, "Pass")

        if iNIFDB.debug and (not needBtn or not greedBtn or not passBtn) then
            local childNames = {}
            for k, v in pairs(frame) do
                if type(v) == "table" and type(k) == "string" then
                    table.insert(childNames, k)
                end
            end
            local containerNames = {}
            if frame.LootButtonContainer then
                for k, v in pairs(frame.LootButtonContainer) do
                    if type(v) == "table" and type(k) == "string" then
                        table.insert(containerNames, k)
                    end
                end
            end
            iNIF:DebugMsg("Loot frame button lookup incomplete. Frame keys: "
                .. table.concat(childNames, ", ") .. "; LootButtonContainer keys: "
                .. table.concat(containerNames, ", "), 2)
        end

        local function MakeCountLabel(anchorBtn, r, g, b)
            local anchor = anchorBtn.icon or anchorBtn.Icon or anchorBtn
            -- Create on the button itself, not the parent frame — children always
            -- render on top of their parent, so attaching to the button ensures
            -- the number draws above all of the button's own textures.
            local lbl = anchorBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight", 7)
            lbl:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 1, 1)
            lbl:SetWidth(26)
            lbl:SetJustifyH("RIGHT")
            lbl:SetText("0")
            lbl:SetTextColor(r, g, b, 1)
            local fontPath = GameFontHighlight:GetFont()
            lbl:SetFont(fontPath, 13, "OUTLINE")
            lbl:SetShadowOffset(1, -1)
            lbl:SetShadowColor(0, 0, 0, 0.9)
            return lbl
        end

        if needBtn  then frame.iNIF_NeedCount  = MakeCountLabel(needBtn,  1,    0.2,  0.2)  end
        if greedBtn then frame.iNIF_GreedCount = MakeCountLabel(greedBtn, 0.2,  0.9,  0.2)  end
        if passBtn  then frame.iNIF_PassCount  = MakeCountLabel(passBtn,  0.65, 0.65, 0.65) end
    end

    -- Forever routes clicks straight to its loot button even when an addon
    -- child overlays it, so replace this one handler and retain the original
    -- for ordinary unchecked Greed clicks.
    local greedButton = GetRollButton(frame, "Greed")
    if greedButton then
        local originalOnClick = greedButton:GetScript("OnClick")
        greedButton:SetScript("OnClick", function(self, button, ...)
            -- Use frame.rollID which WoW updates for each new roll
            local currentRollID = frame.rollID
            if not currentRollID then
                iNIF:DebugMsg("No rollID on frame, calling original handler", 2) -- WARNING
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
                    iNIF:DebugMsg("Ignoring Greed click on already-processed rollID: " .. currentRollID)
                    return
                end

                -- Some Forever button templates can emit more than one click
                -- callback for a single press. Monitoring is armed only once.
                if roll and roll.checkboxEnabled and roll.greedClicked then
                    return
                end

                -- If roll doesn't exist, create it now (fallback for missed START_LOOT_ROLL)
                if not roll then
                    iNIF:DebugMsg("Creating missing roll entry for rollID: " .. currentRollID, 2) -- WARNING
                    local texture, name, count, quality = GetLootRollItemInfo(currentRollID)
                    local itemLink = GetLootRollItemLink(currentRollID)

                    local remaining = GetRemainingRollSeconds(currentRollID) or 0
                    activeRolls[currentRollID] = {
                        startTime = GetTime(),
                        initialDuration = remaining,
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
                        ourDecisionTime = nil,  -- Time when WE clicked Greed+checkbox
                        needCount = 0,
                        greedCount = 0,
                        passCount = 0,
                    }
                    roll = activeRolls[currentRollID]
                    iNIF:DebugMsg("Created roll object, checking if it exists: " .. tostring(roll ~= nil) .. ", rollID=" .. currentRollID)

                    -- Verify it was actually stored
                    if activeRolls[currentRollID] then
                        iNIF:DebugMsg("Roll successfully stored in activeRolls[" .. currentRollID .. "]", 3) -- INFO
                    else
                        iNIF:DebugMsg("Roll was NOT stored in activeRolls[" .. currentRollID .. "]!", 1) -- ERROR
                    end
                end

                if roll then
                    roll.checkboxEnabled = true
                    roll.greedClicked = true
                    roll.ourDecisionTime = GetTime()  -- Record when we decided
                    roll.frame = frame
                    roll.checkbox = checkbox

                    iNIF:DebugMsg("Greed clicked with checkbox enabled for rollID: " .. currentRollID)

                    -- Send AceComm message to notify other iNIF users
                    if AceComm and not roll.iNIFCommSent and (IsInGroup() or IsInRaid()) then
                        roll.iNIFCommSent = true
                        local distribution = IsInRaid() and "RAID" or "PARTY"
                        local message = "GREED_CHECKBOX|" .. currentRollID .. "|" .. roll.itemLink
                        iNIF:SendCommMessage("iNIF", message, distribution, nil, "NORMAL")
                        if iNIFDB.debug then
                            iNIF:DebugMsg("Sent GREED_CHECKBOX comm: " .. message .. " on " .. distribution, 3) -- INFO
                        end
                    end

                    -- Check if someone already needed BEFORE we clicked Greed+Checkbox
                    -- In Enchanter Mode (green+ only): someone needed → skip (don't need back)
                    if roll.needDetected and roll.neededBy and not iNIFDB.enchanterMode then
                        iNIF:DebugMsg("Someone already needed this item before Greed+Checkbox: " .. roll.neededBy)
                        -- Roll Need immediately
                        RollOnLoot(currentRollID, 1) -- 1 = Need
                        -- Delay message by 0.5s to appear after WoW's item roll spam
                        local itemLink = roll.itemLink -- Capture in closure
                        local neededBy = roll.neededBy:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                        C_Timer.After(0.5, function()
                            Print(Colors.Orange .. L["ChatRollingNeed"] .. string.format(L["ChatBecauseNeeded"], itemLink, neededBy))
                        end)

                        -- Announce to party/raid if enabled (delayed 0.5s like Print to avoid spam filters)
                        iNIF:DebugMsg("Party announce check: partyMessages=" .. tostring(iNIFDB.partyMessages) .. ", IsInGroup=" .. tostring(IsInGroup()) .. ", IsInRaid=" .. tostring(IsInRaid()), 3)
                        if iNIFDB.partyMessages and (IsInGroup() or IsInRaid()) then
                            local channel = IsInRaid() and "RAID" or "PARTY"
                            iNIF:DebugMsg("Preparing party announce on channel: " .. channel, 3)
                            local cleanPlayerName = roll.neededBy:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                            local capturedItemLink = roll.itemLink -- Capture in closure
                            C_Timer.After(0.5, function()
                                iNIF:DebugMsg("Sending party announce: " .. cleanPlayerName .. " - " .. capturedItemLink, 3)
                                SendChatMessage(string.format(L["ChatPartyAutoNeed"], capturedItemLink, cleanPlayerName), channel)
                            end)
                        else
                            iNIF:DebugMsg("Party announce skipped - conditions not met", 3)
                        end

                        roll.processed = true
                        return
                    end

                    -- Hiding the Blizzard roll frame is a user preference, not a
                    -- debug-mode behavior. Keep monitoring in the background even
                    -- while Debug Mode is enabled for live testing.
                    if iNIFDB.hideLootFrame and not iNIF.ElvUILoaded then
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
                elseif RollOnLoot then
                    RollOnLoot(currentRollID, 2)
                end
            end
        end)
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                     Roll Monitoring (CHAT_MSG_LOOT)                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
-- Called when Forever's localized loot chat reports a Need selection.
function iNIF.OnNeedDetected(playerName, itemLink)
    playerName = iNIF.CleanPlayerName(playerName)
    if not playerName then return end
    iNIF:DebugMsg("CHAT: Need detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            -- Check if this is the same item (compare item links or names)
            local rollItemLink = roll.itemLink

            -- Match by item link or by checking if itemLink contains the roll item
            if iNIF.LootItemsMatch(itemLink, rollItemLink) then
                iNIF:DebugMsg("Matched Need to rollID: " .. rollID)

                -- Increment Need counter (count all players including self)
                roll.needCount = (roll.needCount or 0) + 1
                iNIF.UpdateRollCounters(rollID)

                -- Track every participant, including the local player.
                iNIF.TrackRollParticipation(playerName, rollID, "need")

                -- Check if it's not us
                local myName = iNIF.GetUnitPlayerName("player")
                if not iNIF.PlayerNamesMatch(playerName, myName) then
                    iNIF:DebugMsg("Need from OTHER PLAYER: " .. playerName)
                    roll.needDetected = true
                    roll.neededBy = playerName

                    -- Ninja detection: check if this player can equip the item
                    if iNIFDB.ninjaDetection then
                        local playerClass = iNIF.GetGroupMemberClass(playerName)
                        if playerClass then
                            iNIF.CheckNinjaForItem(playerName, playerClass, roll.itemLink)
                        end
                    end

                    -- Enchanter Mode: someone needs → skip (don't need back, let them have it)
                    if iNIFDB.enchanterMode then
                        iNIF:DebugMsg("Enchanter Mode: someone needed, skipping this item")
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
                        iNIF:DebugMsg("Party announce check: partyMessages=" .. tostring(iNIFDB.partyMessages) .. ", IsInGroup=" .. tostring(IsInGroup()) .. ", IsInRaid=" .. tostring(IsInRaid()), 3)
                        if iNIFDB.partyMessages and (IsInGroup() or IsInRaid()) then
                            local channel = IsInRaid() and "RAID" or "PARTY"
                            iNIF:DebugMsg("Preparing party announce on channel: " .. channel, 3)
                            -- Clean player name from [Loot]: prefix, color codes and hyperlinks
                            local cleanPlayerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                            local capturedItemLink = roll.itemLink -- Capture in closure
                            C_Timer.After(0.5, function()
                                iNIF:DebugMsg("Sending party announce: " .. cleanPlayerName .. " - " .. capturedItemLink, 3)
                                SendChatMessage(string.format(L["ChatPartyAutoNeed"], capturedItemLink, cleanPlayerName), channel)
                            end)
                        else
                            iNIF:DebugMsg("Party announce skipped - conditions not met", 3)
                        end

                        roll.processed = true
                        -- Don't clean up immediately - will be cleaned up by CANCEL_LOOT_ROLL event
                        return
                    else
                        iNIF:DebugMsg("Need detected but checkbox not enabled yet - will handle when Greed+Checkbox is clicked")
                    end
                    return
                else
                    iNIF:DebugMsg("Ignoring my own Need: " .. playerName)
                end
            end
        end
    end
end

-- This function is called when we detect a Greed from CHAT_MSG_LOOT
function iNIF.OnGreedDetected(playerName, itemLink)
    playerName = iNIF.CleanPlayerName(playerName)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerName or not playerKey then return end
    iNIF:DebugMsg("CHAT: Greed detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    local myName = iNIF.GetUnitPlayerName("player")

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            local rollItemLink = roll.itemLink

            -- Match by item link
            if iNIF.LootItemsMatch(itemLink, rollItemLink) then
                -- Increment Greed counter (count all players including self)
                roll.greedCount = (roll.greedCount or 0) + 1
                iNIF.UpdateRollCounters(rollID)

                -- Track every participant, including the local player.
                iNIF.TrackRollParticipation(playerName, rollID, "greed")

                -- Track this greed (ignore our own) - track ALL greeds, not just when monitoring
                if not iNIF.PlayerNamesMatch(playerName, myName) then
                    roll.greedRolls[playerKey] = playerName
                    iNIF:DebugMsg("Tracked Greed from " .. playerName .. " for rollID " .. rollID)

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
    playerName = iNIF.CleanPlayerName(playerName)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerName or not playerKey then return end
    iNIF:DebugMsg("CHAT: Pass detected from " .. playerName .. " for " .. (itemLink or "unknown item"), 3) -- INFO

    -- Find the matching active roll
    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
            -- Check if this is the same item (compare item links or names)
            local rollItemLink = roll.itemLink

            -- Match by item link or by checking if itemLink contains the roll item
            if iNIF.LootItemsMatch(itemLink, rollItemLink) then
                iNIF:DebugMsg("Matched Pass to rollID: " .. rollID)

                -- Increment Pass counter (count all players including self)
                roll.passCount = (roll.passCount or 0) + 1
                iNIF.UpdateRollCounters(rollID)

                -- Track every participant, including the local player.
                iNIF.TrackRollParticipation(playerName, rollID, "pass")

                -- Check if it's not us
                local myName = iNIF.GetUnitPlayerName("player")
                if not iNIF.PlayerNamesMatch(playerName, myName) then
                    iNIF:DebugMsg("Pass from OTHER PLAYER: " .. playerName)

                    -- Track this pass
                    roll.passRolls[playerKey] = playerName
                    iNIF:DebugMsg("Tracked Pass from " .. playerName .. " for rollID " .. rollID)

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
                    iNIF:DebugMsg("Ignoring my own Pass: " .. playerName)
                end
            end
        end
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Frame Update Loop                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local updateTimer = 0
local function OnUpdate(self, elapsed)
    updateTimer = updateTimer + elapsed

    -- Check every 0.5 seconds (reduced from 0.1s to lower CPU usage)
    if updateTimer < 0.5 then
        return
    end
    updateTimer = 0

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
                end
            end

            local remainingTime = GetRemainingRollSeconds(rollID)
            -- One stale/secret roll timer must not stop the other active rolls or
            -- the monitor window from updating during this pass.
            if remainingTime ~= nil then
                -- Timer fallback at 2 seconds remaining
                if remainingTime <= 2 and roll.checkboxEnabled and roll.greedClicked then
                    if iNIFDB.enchanterMode then
                        -- Enchanter Mode: Need for disenchant if nobody needed
                        if not roll.enchanterNeedSent and not roll.needDetected and not roll.processed then
                            iNIF:DebugMsg("Enchanter Mode timer fallback for rollID: " .. rollID)
                            CheckEnchanterMode(rollID)
                        end
                    else
                        -- Normal iNIF (or Enchanter Mode with quality < green): Greed (nobody needed)
                        iNIF:DebugMsg("Timer reached 2 seconds for rollID: " .. rollID .. " (remaining: " .. string.format("%.1f", remainingTime) .. "s)")
                        ProcessRoll(rollID)
                    end

                elseif remainingTime < 0 then
                    -- Roll expired - clean up to prevent memory leak
                    iNIF:DebugMsg("Roll expired for rollID: " .. rollID .. (roll.checkboxEnabled and " (was being monitored)" or " (not monitored)"))
                    activeRolls[rollID] = nil
                end
            end
        end
    end

    -- Update timer window if it exists
    if iNIF.timerWindow and iNIF.timerWindow.Update then
        iNIF.timerWindow:Update()
    end
end

iNIF.eventFrame:SetScript("OnUpdate", OnUpdate)
