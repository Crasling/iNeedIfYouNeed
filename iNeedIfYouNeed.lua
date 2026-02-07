-- ═══════════════════════════════════════════════════════════
-- iNeedIfYouNeed (iNIF)
-- A World of Warcraft AddOn
-- Smart looting: Need if someone needs, otherwise Greed
-- ═══════════════════════════════════════════════════════════

local addonName, iNIF = ...

-- Load libraries
local LDBroker = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

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
        minimapButton = {
            hide = false,
            minimapPos = -30
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
    frame:SetSize(280, 120)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
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
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -8)
    title:SetText(Colors.iNIF .. "Active Rolls")

    -- Content area for roll entries
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -25)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)

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
                    frame.rollTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    frame.rollTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
                    frame.rollTexts[count]:SetJustifyH("LEFT")
                    frame.rollTexts[count]:SetWidth(260)
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

                yOffset = yOffset - 16
            end
        end

        -- Adjust frame height based on content
        local newHeight = 35 + (count * 16)
        if newHeight < 60 then newHeight = 60 end
        if newHeight > 300 then newHeight = 300 end
        frame:SetHeight(newHeight)

        -- Show/hide frame based on active rolls
        if count > 0 then
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
        print(Colors.iNIF .. "[iNIF]" .. Colors.Reset .. " " .. msg)
    end
end

-- Debug message with levels (like iWR)
-- Level 1 = ERROR (red)
-- Level 2 = WARNING (yellow)
-- Level 3 = INFO (white)
-- Level 4 = DEBUG (orange) - default
local function Debug(msg, level)
    if iNIFDB.debug then
        level = level or 4 -- Default to DEBUG

        if level == 1 then
            -- ERROR
            print(Colors.iNIF .. "[iNIF] " .. Colors.Red .. "ERROR: " .. Colors.Reset .. msg)
        elseif level == 2 then
            -- WARNING
            print(Colors.iNIF .. "[iNIF] " .. Colors.Yellow .. "WARNING: " .. Colors.Reset .. msg)
        elseif level == 3 then
            -- INFO
            print(Colors.iNIF .. "[iNIF] " .. Colors.White .. "INFO: " .. Colors.Reset .. msg)
        else
            -- DEBUG (default)
            print(Colors.iNIF .. "[iNIF] " .. Colors.Orange .. "DEBUG: " .. Colors.Reset .. msg)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- CHECKBOX CREATION
-- ═══════════════════════════════════════════════════════════
local function CreateCheckbox(parent, rollID)
    -- Create checkbox
    local checkbox = CreateFrame("CheckButton", "iNIF_Checkbox_" .. rollID, parent, "UICheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, -15)

    -- Create label
    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(Colors.iNIF .. "Need if someone needs" .. Colors.Reset)
    checkbox.label = label

    -- Set initial state - default unchecked
    checkbox:SetChecked(false)

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
    Print(Colors.Green .. "Rolled GREED" .. Colors.Reset .. " on " .. roll.itemLink .. " (nobody needed)")

    -- Don't clean up immediately - keep the processed flag to prevent recreation
    -- Will be cleaned up by CANCEL_LOOT_ROLL event
end

-- Helper function to check if all party members have greeded
local function CheckIfAllGreeded(rollID)
    local roll = activeRolls[rollID]
    if not roll or roll.processed or not roll.checkboxEnabled or not roll.greedClicked then
        return false
    end

    -- Count how many party members there are (excluding ourselves)
    local partySize = 0
    if IsInRaid() then
        partySize = GetNumGroupMembers() - 1  -- -1 for ourselves
    elseif IsInGroup() then
        partySize = GetNumGroupMembers() - 1  -- -1 for ourselves
    end

    -- Count how many have greeded
    local greedCount = 0
    for _ in pairs(roll.greedRolls) do
        greedCount = greedCount + 1
    end

    Debug("Greed count: " .. greedCount .. "/" .. partySize .. " for rollID " .. rollID)

    -- If everyone else has greeded, roll Greed immediately
    if partySize > 0 and greedCount >= partySize then
        Debug("All party members have greeded! Auto-rolling Greed now.", 3) -- INFO
        ProcessRoll(rollID)
        return true
    end

    return false
end

-- ═══════════════════════════════════════════════════════════
-- LOOT ROLL FRAME ENHANCEMENT
-- ═══════════════════════════════════════════════════════════
local function EnhanceRollFrame(frame, rollID)
    if not frame then
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
                        greedRolls = {}
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
                    roll.frame = frame
                    roll.checkbox = checkbox

                    Debug("Greed clicked with checkbox enabled for rollID: " .. currentRollID)

                    -- Hide the frame (unless debug mode is on)
                    if not iNIFDB.debug then
                        frame:Hide()
                    end
                    Print("Monitoring " .. roll.itemLink .. "... Will Need if someone Needs, otherwise Greed at end of timer.")

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
        if roll.checkboxEnabled and not roll.processed then
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

                    -- Roll Need when someone ELSE needs
                    RollOnLoot(rollID, 1) -- 1 = Need
                    Print(Colors.Orange .. "Rolling NEED" .. Colors.Reset .. " on " .. roll.itemLink .. " because " .. Colors.Yellow .. playerName .. Colors.Reset .. " needed it")

                    -- Announce to party/raid if enabled
                    if iNIFDB.partyMessages and (IsInGroup() or IsInRaid()) then
                        local channel = IsInRaid() and "RAID" or "PARTY"
                        -- Extract item name from link (strip color codes)
                        local itemName = roll.itemLink:match("%[(.+)%]") or "item"
                        -- playerName is already clean from the CHAT_MSG_LOOT parsing
                        SendChatMessage("[iNIF] Automatically needed on " .. itemName .. " because " .. playerName .. " needed.", channel)
                    end

                    roll.processed = true
                    -- Don't clean up immediately - will be cleaned up by CANCEL_LOOT_ROLL event
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

-- ═══════════════════════════════════════════════════════════
-- FRAME UPDATE LOOP
-- ═══════════════════════════════════════════════════════════
local updateTimer = 0
local function OnUpdate(self, elapsed)
    updateTimer = updateTimer + elapsed

    -- Check every 0.1 seconds
    if updateTimer < 0.1 then
        return
    end
    updateTimer = 0

    local currentTime = GetTime()

    for rollID, roll in pairs(activeRolls) do
        if not roll.processed then
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
        Debug(label .. " " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
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
    titleText:SetText(Colors.iNIF .. "iNeedIfYouNeed" .. Colors.Green .. " v0.1.4")

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
    local sidebarLabels = {"General", "About"}
    if iWRInstalled then
        table.insert(sidebarLabels, "iWR Settings")
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

    _, y = CreateSectionHeader(generalContent, Colors.iNIF .. "Addon Settings", y)

    local cbEnabled
    cbEnabled, y = CreateSettingsCheckbox(generalContent, "Enable Addon",
        "When disabled, the addon will not add checkboxes to loot windows.", y, "enabled")
    checkboxRefs.enabled = cbEnabled

    local cbNotify
    cbNotify, y = CreateSettingsCheckbox(generalContent, "Show Chat Notifications",
        "Display messages in chat when rolling on items.", y, "showNotifications")
    checkboxRefs.showNotifications = cbNotify

    local cbParty
    cbParty, y = CreateSettingsCheckbox(generalContent, "Announce Needs to Party/Raid",
        "Announce to party or raid chat when you need an item because someone else needed it.", y, "partyMessages")
    checkboxRefs.partyMessages = cbParty

    scrollChildren[1]:SetHeight(math.abs(y) + 20)

    -- ═══════════════════════════════════════════════════════════
    -- ABOUT TAB CONTENT
    -- ═══════════════════════════════════════════════════════════
    y = -10

    _, y = CreateSectionHeader(aboutContent, Colors.iNIF .. "About", y)

    y = y - 20

    -- Icon
    local iconTexture = aboutContent:CreateTexture(nil, "ARTWORK")
    iconTexture:SetTexture("Interface\\AddOns\\iNeedIfYouNeed\\images\\Logo_iNIF")
    iconTexture:SetSize(64, 64)
    iconTexture:SetPoint("TOP", aboutContent, "TOP", 0, y)
    y = y - 70

    local aboutTitle = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    aboutTitle:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutTitle:SetText(Colors.iNIF .. "iNeedIfYouNeed" .. Colors.Reset .. " " .. Colors.Green .. "v0.1.4" .. Colors.Reset)
    y = y - 20

    local aboutAuthor = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    aboutAuthor:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutAuthor:SetText("Created by: " .. Colors.Yellow .. "Crasling")
    y = y - 16

    local aboutGameVer = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    aboutGameVer:SetPoint("TOP", aboutContent, "TOP", 0, y)
    aboutGameVer:SetText("Classic TBC")
    y = y - 30

    local aboutInfo
    aboutInfo, y = CreateInfoText(aboutContent,
        Colors.iNIF .. "iNeedIfYouNeed" .. Colors.Reset .. " is an addon designed to help you with smart looting.\n\n" ..
        Colors.iNIF .. "iNIF" .. Colors.Reset .. " is in early development. Join the Discord for help with issues, questions, or suggestions.",
        y, "GameFontHighlight")

    -- Discord Section
    y = y - 10
    _, y = CreateSectionHeader(aboutContent, "Discord", y)
    y = y - 2

    local discordDesc = aboutContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    discordDesc:SetPoint("TOPLEFT", aboutContent, "TOPLEFT", 25, y)
    discordDesc:SetText("Copy this link to join our Discord for support and updates")
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

    -- Alpha Version Warning
    _, y = CreateSectionHeader(aboutContent, Colors.iNIF .. "Alpha Version Warning", y)

    local alphaWarning
    alphaWarning, y = CreateInfoText(aboutContent,
        Colors.Red .. "This is an alpha version (0.x.x.x) and may be unstable or cause issues.\n\n" .. Colors.Reset ..
        "If you experience problems, please report them or downgrade to the latest stable release.",
        y, "GameFontDisableSmall")

    -- Developer Section
    y = y - 8
    _, y = CreateSectionHeader(aboutContent, Colors.iNIF .. "Developer", y)

    local cbDebug
    cbDebug, y = CreateSettingsCheckbox(aboutContent, "Enable Debug Mode",
        "Enables verbose debug messages in chat. Not recommended for normal use.", y, "debug")
    checkboxRefs.debug = cbDebug

    scrollChildren[2]:SetHeight(math.abs(y) + 20)

    -- ═══════════════════════════════════════════════════════════
    -- iWR SETTINGS TAB (if installed)
    -- ═══════════════════════════════════════════════════════════
    if iWRInstalled and iWRContent then
        y = -10

        _, y = CreateSectionHeader(iWRContent, Colors.iNIF .. "iWillRemember Settings", y)

        local iWRInfo
        iWRInfo, y = CreateInfoText(iWRContent,
            Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " is installed! You can access iWR settings from here.\n\n" ..
            "Note: These settings are managed by iWR and will affect the iWR addon.",
            y, "GameFontHighlight")

        y = y - 10

        -- Open iWR Settings button
        local iWRButton = CreateFrame("Button", nil, iWRContent, "UIPanelButtonTemplate")
        iWRButton:SetSize(180, 28)
        iWRButton:SetPoint("TOPLEFT", iWRContent, "TOPLEFT", 25, y)
        iWRButton:SetText("Open iWR Settings")
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
    stubTitle:SetText(Colors.iNIF .. "iNeedIfYouNeed " .. Colors.Green .. "v0.1.4")

    local stubDesc = stubPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    stubDesc:SetPoint("TOPLEFT", stubTitle, "BOTTOMLEFT", 0, -10)
    stubDesc:SetText("Left-click the minimap button or type " .. Colors.Yellow .. "/inif settings" .. Colors.Reset .. " to open the full settings panel.")

    local stubButton = CreateFrame("Button", nil, stubPanel, "UIPanelButtonTemplate")
    stubButton:SetSize(180, 28)
    stubButton:SetPoint("TOPLEFT", stubDesc, "BOTTOMLEFT", 0, -15)
    stubButton:SetText("Open Settings")
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
            -- Delayed startup message (like IWR)
            C_Timer.After(2, function()
                print(Colors.iNIF .. "[iNIF]: iNeedIfYouNeed Classic TBC " .. Colors.Green .. "v0.1.4" .. Colors.iNIF .. " Loaded.")

                -- Alpha version warning
                local version = "0.1.4"
                if version:match("^0%.%d+%.%d+%.%d+$") then
                    print(Colors.iNIF .. "[iNIF]: " .. Colors.Yellow .. "WARNING" .. Colors.iNIF .. ": This is an alpha version and can be unstable and cause issues. If you do not want to run this version, please downgrade to the latest release.")
                end
            end)
        end

    elseif event == "PLAYER_LOGIN" then
        -- Create options panel after everything is loaded
        C_Timer.After(0.5, function()
            CreateOptionsPanel()
        end)

        -- Create timer window
        C_Timer.After(0.6, function()
            timerWindow = CreateTimerWindow()
        end)

    elseif event == "START_LOOT_ROLL" then
        local rollID = ...
        Debug("START_LOOT_ROLL: " .. tostring(rollID))

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
            greedRolls = {}           -- Track who has greeded: {playerName = true}
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
        local message = ...

        -- Pattern: "[Loot]: PlayerName has selected Need for: [Item Link]"
        -- Strip the [Loot]: prefix if present
        local cleanMessage = message:match("%[Loot%]: (.+)") or message

        local playerName, itemLink = cleanMessage:match("(.+) has selected Need for: (.+)")
        if playerName and itemLink then
            Debug("CHAT_MSG_LOOT: " .. playerName .. " needed " .. itemLink)
            OnNeedDetected(playerName, itemLink)
            return
        end

        -- Pattern: "[Loot]: PlayerName has selected Greed for: [Item Link]"
        playerName, itemLink = cleanMessage:match("(.+) has selected Greed for: (.+)")
        if playerName and itemLink then
            Debug("CHAT_MSG_LOOT: " .. playerName .. " greeded " .. itemLink)
            OnGreedDetected(playerName, itemLink)
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
titleText:SetText(Colors.iNIF .. "iNIF Menu" .. Colors.Green .. " v0.1.4")

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
enableCheck.text:SetText(Colors.iNIF .. "Enable Addon")
enableCheck:SetChecked(iNIFDB.enabled)
table.insert(iNIF.CheckboxRegistry.enabled, enableCheck)
enableCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.enabled = checked
    Debug("Addon " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
    UpdateAllCheckboxes("enabled", checked)
end)
yOffset = yOffset - 30

-- Show notifications checkbox
local notifyCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
notifyCheck:SetPoint("TOPLEFT", 20, yOffset)
notifyCheck.text:SetText(Colors.iNIF .. "Show Notifications")
notifyCheck:SetChecked(iNIFDB.showNotifications)
table.insert(iNIF.CheckboxRegistry.showNotifications, notifyCheck)
notifyCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.showNotifications = checked
    Debug("Notifications " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
    UpdateAllCheckboxes("showNotifications", checked)
end)
yOffset = yOffset - 30

-- Party announcements checkbox
local partyCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
partyCheck:SetPoint("TOPLEFT", 20, yOffset)
partyCheck.text:SetText(Colors.iNIF .. "Party Announcements")
partyCheck:SetChecked(iNIFDB.partyMessages)
table.insert(iNIF.CheckboxRegistry.partyMessages, partyCheck)
partyCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.partyMessages = checked
    Debug("Party announcements " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
    UpdateAllCheckboxes("partyMessages", checked)
end)
yOffset = yOffset - 30

-- Debug mode checkbox
local debugCheck = CreateFrame("CheckButton", nil, iNIFMenuPanel, "UICheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", 20, yOffset)
debugCheck.text:SetText(Colors.iNIF .. "Debug Mode")
debugCheck:SetChecked(iNIFDB.debug)
table.insert(iNIF.CheckboxRegistry.debug, debugCheck)
debugCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    iNIFDB.debug = checked
    Debug("Debug mode " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
    UpdateAllCheckboxes("debug", checked)
end)
yOffset = yOffset - 40

-- Settings button
local settingsButton = CreateFrame("Button", nil, iNIFMenuPanel, "UIPanelButtonTemplate")
settingsButton:SetSize(120, 26)
settingsButton:SetPoint("TOPLEFT", 20, yOffset)
settingsButton:SetText("Full Settings")
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
                -- Toggle enable/disable
                iNIFDB.enabled = not iNIFDB.enabled
                -- Show status message in chat
                Print("Addon " .. (iNIFDB.enabled and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
                -- Update all checkboxes
                UpdateAllCheckboxes("enabled", iNIFDB.enabled)
            elseif button == "RightButton" then
                -- Open custom settings frame
                if iNIF.SettingsFrame then
                    iNIF.SettingsFrame:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then return end
            tooltip:SetText(Colors.iNIF .. "iNeedIfYouNeed" .. Colors.Green .. " v0.1.4", 1, 1, 1)
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine("Left Click: Enable/Disable addon", 1, 1, 1)
            tooltip:AddLine("Right Click: Open settings", 1, 1, 1)
            tooltip:AddLine(" ", 1, 1, 1)
            tooltip:AddLine("Status: " .. (iNIFDB.enabled and (Colors.Green .. "Enabled") or (Colors.Red .. "Disabled")), 1, 1, 1)
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
        Print("Addon " .. (iNIFDB.enabled and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))

    elseif msg == "notifications" or msg == "notify" then
        iNIFDB.showNotifications = not iNIFDB.showNotifications
        Print("Notifications " .. (iNIFDB.showNotifications and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))

    elseif msg == "party" then
        iNIFDB.partyMessages = not iNIFDB.partyMessages
        Print("Party messages " .. (iNIFDB.partyMessages and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))

    elseif msg == "remember" then
        iNIFDB.checkboxRememberState = not iNIFDB.checkboxRememberState
        Print("Remember checkbox state " .. (iNIFDB.checkboxRememberState and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))

    elseif msg == "debug" then
        iNIFDB.debug = not iNIFDB.debug
        Print("Debug mode " .. (iNIFDB.debug and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))

    elseif msg == "test" then
        -- Test if START_LOOT_ROLL event is being caught
        print(Colors.iNIF .. "[iNIF TEST]" .. Colors.Reset)
        print("Active rolls count: " .. Colors.Yellow .. tostring(#activeRolls) .. Colors.Reset)
        print("Registered events:")
        print("  - ADDON_LOADED: " .. (eventFrame:IsEventRegistered("ADDON_LOADED") and Colors.Green .. "YES" or Colors.Red .. "NO") .. Colors.Reset)
        print("  - PLAYER_LOGIN: " .. (eventFrame:IsEventRegistered("PLAYER_LOGIN") and Colors.Green .. "YES" or Colors.Red .. "NO") .. Colors.Reset)
        print("  - START_LOOT_ROLL: " .. (eventFrame:IsEventRegistered("START_LOOT_ROLL") and Colors.Green .. "YES" or Colors.Red .. "NO") .. Colors.Reset)
        print("  - CANCEL_LOOT_ROLL: " .. (eventFrame:IsEventRegistered("CANCEL_LOOT_ROLL") and Colors.Green .. "YES" or Colors.Red .. "NO") .. Colors.Reset)

        -- List all active rolls
        local count = 0
        for rollID, roll in pairs(activeRolls) do
            count = count + 1
            print("  Roll #" .. count .. ": ID=" .. rollID .. ", item=" .. roll.itemLink .. ", checkbox=" .. tostring(roll.checkboxEnabled))
        end
        if count == 0 then
            print("  " .. Colors.Yellow .. "No active rolls" .. Colors.Reset)
        end

    else
        print(Colors.iNIF .. "iNeedIfYouNeed v0.1.4" .. Colors.Reset)
        print(Colors.Yellow .. "Commands:" .. Colors.Reset)
        print("  /inif config - Open settings panel")
        print("  /inif toggle - Enable/disable addon")
        print("  /inif notifications - Toggle chat notifications")
        print("  /inif party - Toggle party/raid announcements")
        print("  /inif remember - Toggle checkbox state memory")
        print("  /inif debug - Toggle debug mode")
        print("  /inif test - Show addon status and active rolls")
    end
end
