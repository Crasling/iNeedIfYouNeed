-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗  ██╗ ███████╗ ██╗   ██╗  ██████╗  ██╗   ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗
-- ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗ ██║ ██╔════╝ ╚██╗ ██╔╝ ██╔═══██╗ ██║   ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗
-- ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║ ██║ █████╗    ╚████╔╝  ██║   ██║ ██║   ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║
-- ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║ ██║ ██╔══╝     ╚██╔╝   ██║   ██║ ██║   ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║
-- ██║ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝ ██║ ██║         ██║    ╚██████╔╝ ╚██████╔╝ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝
-- ╚═╝ ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝  ╚═╝ ╚═╝         ╚═╝     ╚═════╝   ╚═════╝  ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

local addonName, iNIF = ...
local L = iNIF.L or {}

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      iNIF — Event Handling, Menu & Minimap                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
-- Local aliases
local Colors = iNIF.Colors
local Title = iNIF.Title
local Version = iNIF.Version
local activeRolls = iNIF.activeRolls
local AceComm = iNIF.AceComm
local LDBroker = iNIF.LDBroker
local LDBIcon = iNIF.LDBIcon
local Print = function(...) return iNIF.Print(...) end
local Debug = function(...) return iNIF.Debug(...) end
local CountTable = function(...) return iNIF.CountTable(...) end
local UpdateAllCheckboxes = iNIF.UpdateAllCheckboxes

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                             Event Handler                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            -- Backfill new saved variable defaults for upgrading users
            iNIF.ApplyDynamicDefaults()

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

                -- Welcome message (once per version)
                if iNIFDB.WelcomeMessage ~= Version then
                    local playerName = UnitName("player")
                    local _, class = UnitClass("player")
                    local classColor = "|cFFFFFFFF"
                    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
                        local c = RAID_CLASS_COLORS[class]
                        classColor = string.format("|cFF%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
                    end
                    print(L["WelcomeStart"] .. classColor .. playerName .. L["WelcomeEnd"])
                    iNIFDB.WelcomeMessage = Version
                end
            end)
        end

    elseif event == "PLAYER_LOGIN" then
        -- Create options panel after everything is loaded
        C_Timer.After(0.5, function()
            iNIF.CreateOptionsPanel()
        end)

        -- Create timer window (hide unless debug mode or user wants to see it)
        C_Timer.After(0.6, function()
            iNIF.timerWindow = iNIF.CreateTimerWindow()
            if not iNIFDB.debug and iNIFDB.hideMonitorWindow then
                iNIF.timerWindow:Hide()
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
        local texture, name, count, quality = GetLootRollItemInfo(rollID)
        local itemLink = GetLootRollItemLink(rollID)

        Debug("START_LOOT_ROLL got item info: name=" .. tostring(name) .. ", itemLink=" .. tostring(itemLink) .. ", quality=" .. tostring(quality))

        -- QuickLoot check
        local qlAutoToggle = false
        if name and iNIFCharDB and iNIFCharDB.quickLoot and iNIFCharDB.quickLoot[name] ~= nil then
            local qlAction = iNIFCharDB.quickLoot[name]
            if qlAction == 3 then
                -- Auto Toggle: let the normal flow continue, flag for checkbox auto-check
                qlAutoToggle = true
                Debug("QuickLoot: Auto Toggle mode for " .. tostring(name), 3)
            else
                -- Instant roll (Need/Greed/Pass)
                local actionName = qlAction == 1 and "Need" or qlAction == 2 and "Greed" or "Pass"
                RollOnLoot(rollID, qlAction)
                print(L["PrintPrefix"] .. string.format(L["QuickLootAutoRoll"], actionName, itemLink or name))
                Debug("QuickLoot: Rolled " .. actionName .. " on " .. tostring(name), 3)
                return
            end
        end

        -- Count eligible players (connected + visible = in the dungeon/nearby)
        -- Players who are offline or in a different zone won't roll, so don't count them
        local eligibleCount = 0
        local totalMembers = GetNumGroupMembers and GetNumGroupMembers() or (IsInRaid() and GetNumRaidMembers() or (GetNumPartyMembers() + 1))
        for i = 1, totalMembers do
            local unitID
            if IsInRaid() then
                unitID = "raid" .. i
            else
                if i < totalMembers then
                    unitID = "party" .. i
                else
                    unitID = "player"
                end
            end
            if unitID ~= "player" and not UnitIsUnit(unitID, "player") then
                if UnitExists(unitID) and UnitIsConnected(unitID) and UnitIsVisible(unitID) then
                    eligibleCount = eligibleCount + 1
                end
            end
        end
        Debug("Eligible players for roll: " .. eligibleCount .. " out of " .. (totalMembers - 1) .. " group members")

        -- Start tracking this roll immediately with our own timer
        -- Standard loot roll duration in Classic is 60 seconds
        activeRolls[rollID] = {
            startTime = GetTime(),
            initialDuration = 60,
            needDetected = false,
            neededBy = nil,
            processed = false,
            itemLink = itemLink or name or "Unknown Item",
            itemQuality = quality or 0,  -- 0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic
            checkboxEnabled = false,  -- Will be set to true when user clicks Greed with checkbox
            greedClicked = false,     -- Track if user has clicked Greed
            greedRolls = {},          -- Track who has greeded: {playerName = true}
            passRolls = {},           -- Track who has passed: {playerName = true}
            iNIFGreeds = {},          -- Track iNIF users who greeded with checkbox: {playerName = true}
            iNIFCommSent = false,     -- Track if we sent our comm message
            enchanterNeedSent = false, -- Track if Enchanter Mode already Needed this item
            ourDecisionTime = nil,     -- Time when WE clicked Greed+checkbox
            eligibleCount = eligibleCount,  -- How many players can actually roll (connected + visible)
            quickLootAutoToggle = qlAutoToggle  -- QuickLoot Auto Toggle: pre-check checkbox
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
                            -- Update Enchanter Mode label and icons
                            if frame.iNIF_EnchanterLabel then
                                frame.iNIF_EnchanterLabel:SetShown(iNIFDB.enchanterMode)
                            end
                            if frame.iNIF_Checkbox.UpdateMode then
                                frame.iNIF_Checkbox.UpdateMode()
                            end
                        else
                            iNIF.EnhanceRollFrame(frame, rollID)
                        end
                        -- QuickLoot Auto Toggle: pre-check the checkbox
                        if activeRolls[rollID] and activeRolls[rollID].quickLootAutoToggle and frame.iNIF_Checkbox then
                            frame.iNIF_Checkbox:SetChecked(true)
                            if iNIFDB.checkboxRememberState then
                                iNIFDB.checkboxChecked = true
                            end
                            print(L["PrintPrefix"] .. string.format(L["QuickLootAutoToggle"], activeRolls[rollID].itemLink or ""))
                            Debug("QuickLoot: Auto-toggled checkbox for rollID: " .. rollID, 3)
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
            iNIF.OnNeedDetected(playerName, itemLink)
            return
        end

        -- Pattern: "[Loot]: PlayerName has selected Greed for: [Item Link]"
        playerName, itemLink = cleanMessage:match("^(.-)%s+has selected Greed for:%s*(.+)$")
        if playerName and itemLink then
            -- Clean player name from all WoW markup codes AND [Loot]: prefix immediately after parsing
            playerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            Debug("CHAT_MSG_LOOT: " .. playerName .. " greeded " .. itemLink)
            iNIF.OnGreedDetected(playerName, itemLink)
            return
        end

        -- Pattern: "[Loot]: PlayerName passed on: [Item Link]"
        playerName, itemLink = cleanMessage:match("^(.-)%s+passed on:%s*(.+)$")
        if playerName and itemLink then
            -- Clean player name from all WoW markup codes AND [Loot]: prefix immediately after parsing
            playerName = playerName:gsub("^%[.-%]:%s*", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            Debug("CHAT_MSG_LOOT: " .. playerName .. " passed " .. itemLink)
            iNIF.OnPassDetected(playerName, itemLink)
            return
        end

        -- Pattern: "You receive loot: [Item Link]" or "PlayerName receives loot: [Item Link]"
        local selfLootLink = cleanMessage:match("^You receive loot:%s*(.+)%.$")
        if not selfLootLink then
            selfLootLink = cleanMessage:match("^You receive loot:%s*(.+)$")
        end
        if selfLootLink then
            -- Parse count from "xN" suffix
            local matLink, matCount = selfLootLink:match("^(.-)x(%d+)$")
            if not matLink then
                matLink = selfLootLink
                matCount = 1
            else
                matCount = tonumber(matCount) or 1
            end

            -- Check if this is a disenchant result (pending DE within 3 second window)
            if iNIF.pendingDisenchant and (GetTime() - iNIF.pendingDisenchant.timestamp) < 3 then
                iNIF.OnDisenchantResult(matLink, matCount)
            end

            -- Roll win tracking: check if this matches a recently completed roll
            if iNIFDB.rollTracker then
                local myName = UnitName("player")
                iNIF.TrackRollWin(myName, matLink)
            end
        end

        -- Pattern: "PlayerName receives loot: [Item Link]" (other players winning rolls)
        local otherPlayer, otherLootLink = cleanMessage:match("^(.-)%s+receives loot:%s*(.+)%.$")
        if not otherPlayer then
            otherPlayer, otherLootLink = cleanMessage:match("^(.-)%s+receives loot:%s*(.+)$")
        end
        if otherPlayer and otherLootLink then
            otherPlayer = otherPlayer:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
            if iNIFDB.rollTracker then
                iNIF.TrackRollWin(otherPlayer, otherLootLink)
            end
        end

        -- Unmatched message (only log if not a loot receive)
        if not selfLootLink and not otherPlayer then
            Debug("CHAT_MSG_LOOT (not matched): " .. message)
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        -- Disenchant spell ID: 13262
        if unitTarget == "player" and spellID == 13262 then
            iNIF.OnDisenchantCast()
        end

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

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if not isLogin and not isReload then
            local inInstance, instanceType = IsInInstance()
            if inInstance and (instanceType == "party" or instanceType == "raid") then
                local status
                if not iNIFDB.enabled then
                    status = L["StatusDisabled"]
                elseif iNIFDB.enchanterMode then
                    status = L["StatusEnchanterMode"]
                else
                    status = L["StatusEnabled"]
                end
                print(L["PrintPrefix"] .. L["TooltipStatus"] .. status)
            end
        end
    end
end

-- Register events
iNIF.eventFrame:RegisterEvent("ADDON_LOADED")
iNIF.eventFrame:RegisterEvent("PLAYER_LOGIN")
iNIF.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
iNIF.eventFrame:RegisterEvent("START_LOOT_ROLL")
iNIF.eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
iNIF.eventFrame:RegisterEvent("CHAT_MSG_LOOT")
iNIF.eventFrame:RegisterEvent("LOOT_BIND_CONFIRM")
iNIF.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
iNIF.eventFrame:SetScript("OnEvent", OnEvent)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Custom Menu Frame                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Create the main menu panel
local iNIFMenuPanel = iNIF.CreateiNIFStyleFrame(UIParent, 280, 220, {"CENTER", UIParent, "CENTER"})
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
    if iNIF.timerWindow then
        if checked and not iNIFDB.debug then
            iNIF.timerWindow:Hide()
        elseif not checked or iNIFDB.debug then
            iNIF.timerWindow:Show()
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
    if iNIF.timerWindow then
        if checked then
            iNIF.timerWindow:Show()
        elseif iNIFDB.hideMonitorWindow then
            iNIF.timerWindow:Hide()
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
    if iNIF.InCombat then print(L["InCombat"]) return end
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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Menu Toggle Functions                                 │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.MenuToggle()
    if iNIF.InCombat then print(L["InCombat"]) return end
    if iNIFMenuPanel:IsVisible() then
        iNIFMenuPanel:Hide()
    else
        iNIFMenuPanel:Show()
    end
end

function iNIF.MenuClose()
    iNIFMenuPanel:Hide()
end

function iNIF.MenuOpen()
    if iNIF.InCombat then print(L["InCombat"]) return end
    iNIFMenuPanel:Show()
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                       Disenchant Detection Functions                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Called when UNIT_SPELLCAST_SUCCEEDED fires with Disenchant (spellID 13262)
function iNIF.OnDisenchantCast()
    Debug("Disenchant cast completed", 3)
    iNIF.pendingDisenchant = {
        timestamp = GetTime(),
        mats = {},
    }
    -- Clear pending after 3 seconds
    C_Timer.After(3, function()
        if iNIF.pendingDisenchant then
            -- If mats were collected, finalize the record
            if #iNIF.pendingDisenchant.mats > 0 then
                iNIF.RecordDisenchant(iNIF.pendingDisenchant.mats)
            end
            iNIF.pendingDisenchant = nil
        end
    end)
end

-- Called when "You receive loot:" matches within DE window
function iNIF.OnDisenchantResult(matLink, count)
    if not iNIF.pendingDisenchant then return end
    Debug("DE result: " .. count .. "x " .. (matLink or "?"), 3)
    table.insert(iNIF.pendingDisenchant.mats, { matLink = matLink, count = count })
end

-- Record a completed disenchant to history and totals
function iNIF.RecordDisenchant(mats)
    if not mats or #mats == 0 then return end

    -- Add to session history
    table.insert(iNIF.enchanterHistory, {
        itemLink = nil, -- We don't easily know which item was DEd from the event alone
        mats = mats,
        timestamp = GetTime(),
    })

    -- Update running totals
    for _, mat in ipairs(mats) do
        local matName = mat.matLink or "Unknown"
        -- Strip color codes to get clean name for totals key
        local cleanName = matName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
        if not iNIF.enchanterMatTotals[cleanName] then
            iNIF.enchanterMatTotals[cleanName] = { link = mat.matLink, count = 0 }
        end
        iNIF.enchanterMatTotals[cleanName].count = iNIF.enchanterMatTotals[cleanName].count + mat.count
    end

    -- Announce to party/raid if enabled
    if iNIFDB.enchanterAnnounceResults and (IsInGroup() or IsInRaid()) then
        local channel = IsInRaid() and "RAID" or "PARTY"
        local matStr = ""
        for _, mat in ipairs(mats) do
            if matStr ~= "" then matStr = matStr .. ", " end
            matStr = matStr .. mat.count .. "x " .. (mat.matLink or "?")
        end
        local msg = string.format(L["EnchanterResultPartyMsg"] or "[iNIF]: Disenchanted -> %s", matStr)
        C_Timer.After(0.5, function()
            SendChatMessage(msg, channel)
        end)
    end

    -- Chat notification
    local matStr = ""
    for _, mat in ipairs(mats) do
        if matStr ~= "" then matStr = matStr .. ", " end
        matStr = matStr .. mat.count .. "x " .. (mat.matLink or "?")
    end
    Print((L["EnchanterHistoryItemDE"] or "Disenchanted into: ") .. matStr)

    -- Refresh history display if open
    if iNIF.RefreshEnchanterHistory then iNIF.RefreshEnchanterHistory() end

    Debug("Recorded disenchant: " .. #mats .. " material types", 3)
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Split Calculator Window                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

function iNIF.CreateSplitWindow()
    local frame = CreateFrame("Frame", "iNIFSplitWindow", UIParent, "BackdropTemplate")
    frame:SetSize(320, 250)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    frame:SetBackdropBorderColor(1, 0.59, 0.09, 1)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(Colors.iNIF .. (L["EnchanterSplitTitle"] or "Material Split"))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Content area
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)

    frame.contentTexts = {}

    frame.Refresh = function()
        -- Clear old texts
        for _, text in pairs(frame.contentTexts) do
            text:Hide()
        end

        local yOfs = 0
        local count = 0

        if not iNIF.enchanterMatTotals or not next(iNIF.enchanterMatTotals) then
            count = count + 1
            if not frame.contentTexts[count] then
                frame.contentTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                frame.contentTexts[count]:SetWidth(280)
                frame.contentTexts[count]:SetJustifyH("LEFT")
            end
            frame.contentTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
            frame.contentTexts[count]:SetText(L["EnchanterSplitNoMats"] or "No materials recorded this session.")
            frame.contentTexts[count]:Show()
            return
        end

        -- Total header
        count = count + 1
        if not frame.contentTexts[count] then
            frame.contentTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            frame.contentTexts[count]:SetWidth(280)
            frame.contentTexts[count]:SetJustifyH("LEFT")
        end
        frame.contentTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
        frame.contentTexts[count]:SetText(Colors.iNIF .. (L["EnchanterSplitTotal"] or "Total Materials:"))
        frame.contentTexts[count]:Show()
        yOfs = yOfs - 18

        -- List totals
        for matName, data in pairs(iNIF.enchanterMatTotals) do
            count = count + 1
            if not frame.contentTexts[count] then
                frame.contentTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                frame.contentTexts[count]:SetWidth(280)
                frame.contentTexts[count]:SetJustifyH("LEFT")
            end
            frame.contentTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOfs)
            frame.contentTexts[count]:SetText(data.count .. "x " .. (data.link or matName))
            frame.contentTexts[count]:Show()
            yOfs = yOfs - 16
        end

        -- Per player split
        local groupSize = GetNumGroupMembers and GetNumGroupMembers() or 1
        if groupSize > 1 then
            yOfs = yOfs - 8
            count = count + 1
            if not frame.contentTexts[count] then
                frame.contentTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.contentTexts[count]:SetWidth(280)
                frame.contentTexts[count]:SetJustifyH("LEFT")
            end
            frame.contentTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
            frame.contentTexts[count]:SetText(Colors.iNIF .. string.format(L["EnchanterSplitPerPlayer"] or "Per Player (%d members):", groupSize))
            frame.contentTexts[count]:Show()
            yOfs = yOfs - 18

            for matName, data in pairs(iNIF.enchanterMatTotals) do
                local perPlayer = math.floor(data.count / groupSize)
                local remainder = data.count % groupSize
                count = count + 1
                if not frame.contentTexts[count] then
                    frame.contentTexts[count] = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    frame.contentTexts[count]:SetWidth(280)
                    frame.contentTexts[count]:SetJustifyH("LEFT")
                end
                frame.contentTexts[count]:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOfs)
                local splitText = perPlayer .. "x " .. (data.link or matName)
                if remainder > 0 then
                    splitText = splitText .. " (+" .. remainder .. " remainder)"
                end
                frame.contentTexts[count]:SetText(splitText)
                frame.contentTexts[count]:Show()
                yOfs = yOfs - 16
            end
        end

        -- Adjust height
        local newHeight = 55 + math.abs(yOfs)
        if newHeight < 100 then newHeight = 100 end
        if newHeight > 400 then newHeight = 400 end
        frame:SetHeight(newHeight)
    end

    return frame
end

-- Split window toggle
function iNIF.ToggleSplitWindow()
    if not iNIF.splitWindow then
        iNIF.splitWindow = iNIF.CreateSplitWindow()
    end
    if iNIF.splitWindow:IsShown() then
        iNIF.splitWindow:Hide()
    else
        iNIF.splitWindow:Refresh()
        iNIF.splitWindow:Show()
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Luck Meter Window                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

function iNIF.CreateLuckMeterWindow()
    local frame = CreateFrame("Frame", "iNIFLuckMeter", UIParent, "BackdropTemplate")
    frame:SetSize(280, 200)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    frame:SetBackdropBorderColor(1, 0.59, 0.09, 1)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -14)
    title:SetText(Colors.iNIF .. (L["RollTrackerTitle"] or "Roll Luck Tracker"))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Content area
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)

    frame.rows = {}

    frame.Refresh = function()
        -- Clear old rows
        for _, row in pairs(frame.rows) do
            if row.text then row.text:Hide() end
            if row.bar then row.bar:Hide() end
            if row.barBg then row.barBg:Hide() end
        end

        local yOfs = 0
        local count = 0
        local players = iNIF.rollTracker.players

        if not players or not next(players) then
            count = count + 1
            if not frame.rows[count] then frame.rows[count] = {} end
            if not frame.rows[count].text then
                frame.rows[count].text = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                frame.rows[count].text:SetWidth(240)
                frame.rows[count].text:SetJustifyH("LEFT")
            end
            frame.rows[count].text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
            frame.rows[count].text:SetText(L["RollTrackerEmpty"] or "No rolls tracked yet this session.")
            frame.rows[count].text:Show()
            return
        end

        -- Sort players by wins (descending)
        local sorted = {}
        for name, data in pairs(players) do
            table.insert(sorted, { name = name, wins = data.wins, rolls = data.rolls })
        end
        table.sort(sorted, function(a, b) return a.wins > b.wins end)

        -- Header
        count = count + 1
        if not frame.rows[count] then frame.rows[count] = {} end
        if not frame.rows[count].text then
            frame.rows[count].text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            frame.rows[count].text:SetWidth(240)
            frame.rows[count].text:SetJustifyH("LEFT")
        end
        frame.rows[count].text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
        frame.rows[count].text:SetText(Colors.Yellow .. "Player" .. Colors.Reset .. string.rep(" ", 18) .. (L["RollTrackerWins"] or "Wins") .. " / " .. (L["RollTrackerRolls"] or "Rolls"))
        frame.rows[count].text:Show()
        yOfs = yOfs - 18

        local barWidth = 80

        for _, entry in ipairs(sorted) do
            count = count + 1
            if not frame.rows[count] then frame.rows[count] = {} end

            -- Text: "PlayerName  W/R"
            if not frame.rows[count].text then
                frame.rows[count].text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                frame.rows[count].text:SetWidth(150)
                frame.rows[count].text:SetJustifyH("LEFT")
            end
            frame.rows[count].text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOfs)
            frame.rows[count].text:SetText(entry.name .. "  " .. entry.wins .. "/" .. entry.rolls)
            frame.rows[count].text:Show()

            -- Luck bar background
            if not frame.rows[count].barBg then
                frame.rows[count].barBg = content:CreateTexture(nil, "BACKGROUND")
            end
            frame.rows[count].barBg:SetSize(barWidth, 10)
            frame.rows[count].barBg:SetPoint("TOPLEFT", content, "TOPLEFT", 155, yOfs - 2)
            frame.rows[count].barBg:SetColorTexture(0.2, 0.2, 0.2, 0.6)
            frame.rows[count].barBg:Show()

            -- Luck bar fill
            if not frame.rows[count].bar then
                frame.rows[count].bar = content:CreateTexture(nil, "ARTWORK")
            end
            local luck = entry.rolls > 0 and (entry.wins / entry.rolls) or 0
            local fillWidth = math.max(1, barWidth * luck)
            frame.rows[count].bar:SetSize(fillWidth, 10)
            frame.rows[count].bar:SetPoint("TOPLEFT", content, "TOPLEFT", 155, yOfs - 2)

            -- Color: green=lucky, yellow=average, red=unlucky
            if luck > 0.3 then
                frame.rows[count].bar:SetColorTexture(0.2, 0.8, 0.2, 0.8) -- Green
            elseif luck > 0.15 then
                frame.rows[count].bar:SetColorTexture(1, 0.8, 0, 0.8) -- Yellow
            else
                frame.rows[count].bar:SetColorTexture(0.8, 0.2, 0.2, 0.8) -- Red
            end
            frame.rows[count].bar:Show()

            yOfs = yOfs - 18
        end

        -- Adjust height
        local newHeight = 55 + math.abs(yOfs)
        if newHeight < 100 then newHeight = 100 end
        if newHeight > 400 then newHeight = 400 end
        frame:SetHeight(newHeight)
    end

    return frame
end

-- Luck meter toggle
function iNIF.ToggleLuckMeter()
    if not iNIF.luckMeterWindow then
        iNIF.luckMeterWindow = iNIF.CreateLuckMeterWindow()
    end
    if iNIF.luckMeterWindow:IsShown() then
        iNIF.luckMeterWindow:Hide()
    else
        iNIF.luckMeterWindow:Refresh()
        iNIF.luckMeterWindow:Show()
    end
end

-- Update luck meter (called when a win is tracked)
function iNIF.UpdateLuckMeter()
    if iNIF.luckMeterWindow and iNIF.luckMeterWindow:IsShown() then
        iNIF.luckMeterWindow:Refresh()
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Minimap Icon                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

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
                    if iNIFDB.enabled and iNIFDB.enchanterMode then
                        Print(L["StatusEnchanterMode"])
                    else
                        Print(iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"])
                    end
                    -- Update all checkboxes
                    UpdateAllCheckboxes("enabled", iNIFDB.enabled)
                end
            elseif button == "RightButton" then
                -- Open custom settings frame
                if iNIF.InCombat then print(L["InCombat"]) return end
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
            if iNIFDB.enchanterMode and iNIFDB.enabled then
                tooltip:AddLine(L["TooltipStatus"] .. L["StatusEnchanterMode"], 1, 1, 1)
            else
                tooltip:AddLine(L["TooltipStatus"] .. (iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"]), 1, 1, 1)
            end
            tooltip:Show()
        end,
    })

    LDBIcon:Register("iNeedIfYouNeed", minimapButton, iNIFDB.minimapButton)
end
