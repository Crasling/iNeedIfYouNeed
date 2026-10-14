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
local print = function(...) iNIF.PrintToChat(...) end

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
local CountTable = function(...) return iNIF.CountTable(...) end
local UpdateAllCheckboxes = iNIF.UpdateAllCheckboxes

-- Match Blizzard's localized loot strings used by the Forever client.
local function MatchGlobalFormat(message, formatString)
    if type(message) ~= "string" or type(formatString) ~= "string" then return nil end
    if not iNIF.IsSafeValue(message) or not iNIF.IsSafeValue(formatString) then return nil end
    local stringMarker = "\001"
    local numberMarker = "\002"
    local pattern = formatString:gsub("%%[%d%$]*s", stringMarker)
    pattern = pattern:gsub("%%[%d%$]*d", numberMarker)
    pattern = pattern:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = pattern:gsub(stringMarker, "(.-)")
    pattern = pattern:gsub(numberMarker, "(%%d+)")
    return message:match("^" .. pattern .. "$")
end

local function LootItemsMatch(firstItem, secondItem)
    return iNIF.LootItemsMatch(firstItem, secondItem)
end

local function ResolveLootPlayerName(name)
    local cleanName = iNIF.CleanPlayerName(name)
    if not cleanName then return nil end
    if cleanName:lower() == tostring(_G.YOU or "You"):lower() then
        return iNIF.GetUnitPlayerName("player")
    end
    return cleanName
end

local function HasActiveRollForItem(itemLink)
    for _, roll in pairs(activeRolls) do
        if roll and not roll.processed and LootItemsMatch(itemLink, roll.itemLink) then
            return true
        end
    end
    return false
end

-- Forever's roll-selection and roll-result global strings can overlap. Accept
-- a parsed selection only when it names a current group member and live item.
local function MatchRollSelection(message, formatString, action)
    local selfItem = message:match("^You%s+have selected " .. action .. " for:%s*(.+)$")
    if selfItem then
        return iNIF.GetUnitPlayerName("player"), selfItem
    end

    local playerName, itemLink = message:match("^(.-)%s+has selected " .. action .. " for:%s*(.+)$")
    if playerName then
        return ResolveLootPlayerName(playerName), itemLink
    end

    playerName, itemLink = MatchGlobalFormat(message, formatString)
    playerName = ResolveLootPlayerName(playerName)
    if not playerName or not itemLink or not iNIF.GetGroupMember(playerName)
        or not HasActiveRollForItem(itemLink) then
        return nil
    end
    return playerName, itemLink
end

local function MatchPassSelection(message)
    local playerName, itemLink = message:match("^(.-)%s+passed on:%s*(.+)$")
    if playerName then
        return ResolveLootPlayerName(playerName), itemLink
    end


    playerName, itemLink = MatchGlobalFormat(message, _G.LOOT_ROLL_PASSED)
    playerName = ResolveLootPlayerName(playerName)
    if not playerName or not itemLink or not iNIF.GetGroupMember(playerName)
        or not HasActiveRollForItem(itemLink) then
        return nil
    end
    return playerName, itemLink
end

local function PruneCompletedRolls()
    local completedRolls = iNIF.recentlyCompletedRolls
    local now = GetTime()
    for index = #completedRolls, 1, -1 do
        if now - completedRolls[index].endTime > 15 then
            table.remove(completedRolls, index)
        end
    end
end

-- The winner chat message may arrive after CANCEL_LOOT_ROLL. Retain completed
-- rolls briefly so the Luck Tracker can always record the result exactly once.
local function TrackLootRollWin(playerName, itemLink)
    if not iNIFDB.rollTracker then return false end

    local function TrackForRoll(roll)
        if not roll or roll.trackerWinnerRecorded then return false end
        if not LootItemsMatch(roll.itemLink, itemLink) then return false end

        roll.trackerWinnerRecorded = true
        iNIF.TrackRollWin(playerName, itemLink)
        return true
    end

    for _, roll in pairs(activeRolls) do
        if TrackForRoll(roll) then return true end
    end

    PruneCompletedRolls()
    for index = #iNIF.recentlyCompletedRolls, 1, -1 do
        if TrackForRoll(iNIF.recentlyCompletedRolls[index].roll) then return true end
    end

    return false
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                             Event Handler                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            iNIF.InitializeDatabases()

            -- Register minimap icon with saved position (must happen after SavedVars load)
            if LDBIcon and iNIF.MinimapDataObject then
                if not iNIFDB.minimapButton then
                    iNIFDB.minimapButton = { hide = false, minimapPos = -30 }
                end
                LDBIcon:Register("iNeedIfYouNeed", iNIF.MinimapDataObject, iNIFDB.minimapButton)
            end

            -- Initialize AceComm
            if AceComm then
                AceComm:Embed(iNIF)
                iNIF:RegisterComm("iNIF", "OnCommReceived")
                if iNIFDB.debug then
                    iNIF:DebugMsg("AceComm initialized and registered prefix 'iNIF'", 3) -- INFO
                end
            else
                iNIF:DebugMsg("AceComm-3.0 not found! Cross-addon communication disabled.", 1) -- ERROR
            end

            -- Delayed startup message (like iWR) - always shows, no severity prefix
            C_Timer.After(2, function()
                local gameName = iNIF.GameVersionName or "Unknown Version"
                print(L["DebugPrefix"] .. string.format(L["StartupMessage"], Title, gameName, Colors.Green .. "v" .. Version .. Colors.iNIF))
                if iNIF.ElvUILoaded then
                    iNIF:DebugMsg("ElvUI detected — frame hide suppressed, extended frame search delay active", 3)
                end

                -- Welcome message (once per version)
                if iNIFDB.WelcomeMessage ~= Version then
                    local playerName = iNIF.GetUnitPlayerName("player")
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
        iNIF.RefreshGroupRoster()
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

    elseif event == "GROUP_ROSTER_UPDATE" then
        iNIF.RefreshGroupRoster()

    elseif event == "START_LOOT_ROLL" then
        local rollID, rollTime = ...
        if type(rollID) ~= "number" or type(rollTime) ~= "number" then return end
        if not iNIF.IsSafeValue(rollID) or not iNIF.IsSafeValue(rollTime) then return end
        iNIF:DebugMsg("START_LOOT_ROLL: " .. tostring(rollID))

        -- Don't process if addon is disabled
        if not iNIFDB.enabled then
            iNIF:DebugMsg("Addon disabled, ignoring loot roll", 3) -- INFO
            return
        end

        -- Only process loot rolls when in a group or raid
        if not IsInGroup() and not IsInRaid() then
            iNIF:DebugMsg("Not in group or raid, ignoring loot roll", 3) -- INFO
            return
        end

        -- Get item info immediately
        local texture, name, count, quality = GetLootRollItemInfo(rollID)
        local itemLink = GetLootRollItemLink(rollID)
        if not iNIF.IsSafeValue(name) then name = nil end
        if not iNIF.IsSafeValue(itemLink) then itemLink = nil end
        if not iNIF.IsSafeValue(quality) then quality = nil end

        iNIF:DebugMsg("START_LOOT_ROLL got item info: name=" .. tostring(name) .. ", itemLink=" .. tostring(itemLink) .. ", quality=" .. tostring(quality))

        -- QuickLoot check
        local qlAutoToggle = false
        if name and iNIFCharDB and iNIFCharDB.quickLoot and iNIFCharDB.quickLoot[name] ~= nil then
            local qlAction = iNIFCharDB.quickLoot[name]
            if qlAction == 3 then
                -- Auto Toggle: let the normal flow continue, flag for checkbox auto-check
                qlAutoToggle = true
                iNIF:DebugMsg("QuickLoot: Auto Toggle mode for " .. tostring(name), 3)
            else
                -- Instant roll (Need/Greed/Pass)
                local actionName = qlAction == 1 and "Need" or qlAction == 2 and "Greed" or "Pass"
                RollOnLoot(rollID, qlAction)
                print(L["PrintPrefix"] .. string.format(L["QuickLootAutoRoll"], actionName, itemLink or name))
                iNIF:DebugMsg("QuickLoot: Rolled " .. actionName .. " on " .. tostring(name), 3)
                return
            end
        end

        -- Count eligible players (connected + visible = in the dungeon/nearby)
        -- Players who are offline or in a different zone won't roll, so don't count them
        local eligibleCount = 0
        iNIF.RefreshGroupRoster()
        local totalMembers = GetNumGroupMembers()
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
        iNIF:DebugMsg("Eligible players for roll: " .. eligibleCount .. " out of " .. (totalMembers - 1) .. " group members")

        -- Forever supplies the roll duration in milliseconds with the event.
        local rollDuration = rollTime / 1000
        activeRolls[rollID] = {
            startTime = GetTime(),
            initialDuration = rollDuration,
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
            quickLootAutoToggle = qlAutoToggle,  -- QuickLoot Auto Toggle: pre-check checkbox
            needCount = 0,   -- Running tally of Need presses
            greedCount = 0,  -- Running tally of Greed presses
            passCount = 0,   -- Running tally of Pass presses
        }

        iNIF:DebugMsg("Started timer for rollID: " .. rollID .. ", stored itemLink: " .. tostring(activeRolls[rollID].itemLink) .. ", duration: " .. string.format("%.1fs", rollDuration))

        -- Find and enhance the roll frame (give ElvUI extra time to skin the frame)
        local frameSearchDelay = iNIF.ElvUILoaded and 0.3 or 0.1
        C_Timer.After(frameSearchDelay, function()
            -- Forever places active roll frames in GroupLootContainer.rollFrames.
            for _, frame in ipairs(iNIF.GetLootRollFrames()) do
                if frame and frame:IsShown() then
                    local frameRollID = frame.rollID
                    if frameRollID == rollID then
                        -- If already enhanced, reset checkbox for new roll
                        if frame.iNIF_Enhanced and frame.iNIF_Checkbox then
                            iNIF:DebugMsg("Resetting checkbox to UNCHECKED for new rollID: " .. rollID, 3) -- INFO
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
                            -- Reset roll count labels for the new roll
                            if frame.iNIF_NeedCount then frame.iNIF_NeedCount:SetText("0") end
                            if frame.iNIF_GreedCount then frame.iNIF_GreedCount:SetText("0") end
                            if frame.iNIF_PassCount then frame.iNIF_PassCount:SetText("0") end
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
                            iNIF:DebugMsg("QuickLoot: Auto-toggled checkbox for rollID: " .. rollID, 3)
                        end
                        break
                    end
                end
            end
        end)

    elseif event == "CANCEL_LOOT_ROLL" then
        local rollID = ...
        if type(rollID) ~= "number" or not iNIF.IsSafeValue(rollID) then return end
        iNIF:DebugMsg("CANCEL_LOOT_ROLL: " .. tostring(rollID))
        if activeRolls[rollID] then
            if iNIFDB.rollTracker then
                PruneCompletedRolls()
                table.insert(iNIF.recentlyCompletedRolls, {
                    roll = activeRolls[rollID],
                    endTime = GetTime(),
                })
            end
            activeRolls[rollID] = nil
        end

    elseif event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_SYSTEM" then
        -- Don't process if addon is disabled
        if not iNIFDB.enabled then
            return
        end

        local message = ...
        if type(message) ~= "string" or not iNIF.IsSafeValue(message) then return end

        -- Strip either a plain or hyperlink-wrapped channel prefix.
        local cleanMessage = message
        local linkedPrefixEnd = cleanMessage:find("|h:", 1, true)
        if linkedPrefixEnd then
            cleanMessage = cleanMessage:sub(linkedPrefixEnd + 3):gsub("^%s*", "")
        else
            cleanMessage = cleanMessage:gsub("^%[[^%]]+%]:%s*", "")
        end

        local playerName, itemLink = MatchRollSelection(
            cleanMessage, _G.LOOT_ROLL_ROLLED_NEED, "Need")
        if playerName and itemLink then
            iNIF:DebugMsg(event .. ": " .. playerName .. " needed " .. itemLink)
            iNIF.OnNeedDetected(playerName, itemLink)
            return
        end

        playerName, itemLink = MatchRollSelection(
            cleanMessage, _G.LOOT_ROLL_ROLLED_GREED, "Greed")
        if playerName and itemLink then
            iNIF:DebugMsg(event .. ": " .. playerName .. " greeded " .. itemLink)
            iNIF.OnGreedDetected(playerName, itemLink)
            return
        end

        playerName, itemLink = MatchPassSelection(cleanMessage)
        if playerName and itemLink then
            iNIF:DebugMsg(event .. ": " .. playerName .. " passed " .. itemLink)
            iNIF.OnPassDetected(playerName, itemLink)
            return
        end

        -- Forever announces the winner before the normal loot receipt.
        local winnerName, winningItem = cleanMessage:match("^(.-)%s+won:%s*(.+)$")
        if winnerName and winningItem then
            winnerName = ResolveLootPlayerName(winnerName)
            TrackLootRollWin(winnerName, winningItem)
            return
        end

        winningItem = MatchGlobalFormat(cleanMessage, _G.LOOT_ROLL_YOU_WON)
        if winningItem then
            TrackLootRollWin(iNIF.GetUnitPlayerName("player"), winningItem)
            return
        end

        winnerName, winningItem = MatchGlobalFormat(cleanMessage, _G.LOOT_ROLL_WON)
        if winnerName and winningItem then
            winnerName = ResolveLootPlayerName(winnerName)
            TrackLootRollWin(winnerName, winningItem)
            return
        end

        -- Only continue with loot-receive tracking for CHAT_MSG_LOOT
        if event == "CHAT_MSG_SYSTEM" then return end

        local selfLootLink, matCount = MatchGlobalFormat(cleanMessage, _G.LOOT_ITEM_SELF_MULTIPLE)
        if not selfLootLink then selfLootLink = MatchGlobalFormat(cleanMessage, _G.LOOT_ITEM_SELF) end
        if selfLootLink then
            local matLink = selfLootLink
            matCount = tonumber(matCount) or 1

            -- Check if this is a disenchant result (pending DE within 3 second window)
            if iNIF.pendingDisenchant and (GetTime() - iNIF.pendingDisenchant.timestamp) < 3 then
                iNIF.OnDisenchantResult(matLink, matCount)
            end

            TrackLootRollWin(iNIF.GetUnitPlayerName("player"), matLink)
        end

        local otherPlayer, otherLootLink = MatchGlobalFormat(cleanMessage, _G.LOOT_ITEM_MULTIPLE)
        if not otherPlayer then
            otherPlayer, otherLootLink = MatchGlobalFormat(cleanMessage, _G.LOOT_ITEM)
        end
        if otherPlayer and otherLootLink then
            otherPlayer = ResolveLootPlayerName(otherPlayer)
            TrackLootRollWin(otherPlayer, otherLootLink)
        end

        -- Unmatched message (only log if not a loot receive)
        local routineRollResult = cleanMessage:find(" Roll - ", 1, true)
            and cleanMessage:find(" for ", 1, true)
        if not selfLootLink and not otherPlayer and not routineRollResult then
            iNIF:DebugMsg("CHAT_MSG_LOOT (not matched): " .. message)
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, castGUID, spellID = ...
        if not iNIF.IsSafeValue(spellID) then return end
        -- Disenchant spell ID: 13262
        if unitTarget == "player" and spellID == 13262 then
            iNIF.OnDisenchantCast()
        end

    elseif event == "CONFIRM_LOOT_ROLL" then
        local rollID, rollType = ...
        if type(rollID) ~= "number" or type(rollType) ~= "number" then return end
        if not iNIF.IsSafeValue(rollID) or not iNIF.IsSafeValue(rollType) then return end
        iNIF:DebugMsg("CONFIRM_LOOT_ROLL for roll: " .. tostring(rollID))

        -- Check if we have an active monitored roll
        local hasMonitoredRoll = false
        local roll = activeRolls[rollID]
        if roll and roll.checkboxEnabled and roll.greedClicked then
            hasMonitoredRoll = true
            iNIF:DebugMsg("Found monitored roll: " .. tostring(rollID) .. ", confirming BoP roll")
        end

        -- Only auto-confirm if we have a monitored roll (user clicked Greed+checkbox)
        if hasMonitoredRoll then
            iNIF:DebugMsg("Confirming BoP group roll", 3) -- INFO
            ConfirmLootRoll(rollID, rollType)
        else
            iNIF:DebugMsg("No monitored roll, not auto-confirming BoP")
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
local function RegisterForeverEvent(event)
    if C_EventUtils.IsEventValid(event) then
        iNIF.eventFrame:RegisterEvent(event)
    end
end

RegisterForeverEvent("ADDON_LOADED")
RegisterForeverEvent("PLAYER_LOGIN")
RegisterForeverEvent("PLAYER_ENTERING_WORLD")
RegisterForeverEvent("GROUP_ROSTER_UPDATE")
RegisterForeverEvent("START_LOOT_ROLL")
RegisterForeverEvent("CANCEL_LOOT_ROLL")
RegisterForeverEvent("CHAT_MSG_LOOT")
RegisterForeverEvent("CHAT_MSG_SYSTEM")
RegisterForeverEvent("CONFIRM_LOOT_ROLL")
if C_EventUtils.IsEventValid("UNIT_SPELLCAST_SUCCEEDED") then
    iNIF.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end
iNIF.eventFrame:SetScript("OnEvent", OnEvent)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Custom Menu Frame                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

-- Create the main menu panel
local function StyleMenuButton(button)
    if not button:GetFontString() then
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        button:SetFontString(text)
    end
    button:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    button:SetBackdropColor(0.035, 0.030, 0.022, 0.99)
    button:SetBackdropBorderColor(0.62, 0.39, 0.10, 1)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(1, 0.59, 0.09, 0.15)
        self:SetBackdropBorderColor(1, 0.59, 0.09, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.035, 0.030, 0.022, 0.99)
        self:SetBackdropBorderColor(0.62, 0.39, 0.10, 1)
    end)
end

local iNIFMenuPanel = iNIF.CreateiNIFStyleFrame(UIParent, 280, 310, {"CENTER", UIParent, "CENTER"})
_G.iNIFMenuPanel = iNIFMenuPanel
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
iNIFMenuPanel:RegisterForDrag("LeftButton", "RightButton")
iNIFMenuPanel:SetScript("OnDragStart", function(self) self:StartMoving() end)
iNIFMenuPanel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); self:SetUserPlaced(true) end)

-- Title bar
local titleBar = CreateFrame("Frame", nil, iNIFMenuPanel, "BackdropTemplate")
titleBar:SetSize(iNIFMenuPanel:GetWidth(), 31)
titleBar:SetPoint("TOP", iNIFMenuPanel, "TOP", 0, 0)
titleBar:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3},
})
titleBar:SetBackdropColor(0.055, 0.043, 0.025, 1)
titleBar:SetBackdropBorderColor(0.58, 0.35, 0.08, 0.95)

-- Title text
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
titleText:SetText(L["MenuTitle"] .. Colors.Green .. " v" .. Version)

local titleAccent = titleBar:CreateTexture(nil, "ARTWORK")
titleAccent:SetHeight(1)
titleAccent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 8, 2)
titleAccent:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", -8, 2)
titleAccent:SetColorTexture(1, 0.59, 0.09, 0.70)

-- Close button
local closeButton = CreateFrame("Button", nil, iNIFMenuPanel, "BackdropTemplate")
closeButton:SetSize(24, 22)
closeButton:SetPoint("TOPRIGHT", iNIFMenuPanel, "TOPRIGHT", -7, -5)
StyleMenuButton(closeButton)
closeButton:SetText("X")
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
    iNIF:DebugMsg(checked and L["StatusEnabled"] or L["StatusDisabled"])
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
    iNIF:DebugMsg(L["SlashNotifications"] .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
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
    iNIF:DebugMsg(L["SlashPartyMessages"] .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
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
    iNIF:DebugMsg("Hide loot frame " .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
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
    iNIF:DebugMsg("Hide monitor window " .. (checked and L["SlashEnabled"] or L["SlashDisabled"]))
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
    iNIF.SetDebugMode(self:GetChecked(), true)
end)
yOffset = yOffset - 40

-- Settings button
local settingsButton = CreateFrame("Button", nil, iNIFMenuPanel, "BackdropTemplate")
settingsButton:SetSize(120, 26)
settingsButton:SetPoint("TOPLEFT", 20, yOffset)
StyleMenuButton(settingsButton)
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
    iNIF:DebugMsg("Disenchant cast completed", 3)
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
    iNIF:DebugMsg("DE result: " .. count .. "x " .. (matLink or "?"), 3)
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

    iNIF:DebugMsg("Recorded disenchant: " .. #mats .. " material types", 3)
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
    -- Keep the movable tracker above the normal HUD without covering
    -- full-screen Blizzard panels such as the world map.
    frame:SetFrameStrata("MEDIUM")
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
        for _, data in pairs(players) do
            table.insert(sorted, { name = data.name or "Unknown", wins = data.wins, rolls = data.rolls })
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

-- Create minimap button data object (following iWR pattern)
-- NOTE: LDBIcon:Register is deferred to ADDON_LOADED so saved minimap position is used
if LDBroker and LDBIcon then
    iNIF.MinimapDataObject = LDBroker:NewDataObject("iNeedIfYouNeed", {
        type = "data source",
        text = "iNIF",
        icon = "Interface\\AddOns\\iNeedIfYouNeed\\images\\Logo_iNIF",
        iconCoords = { 0.14, 0.86, 0.10, 0.82 },
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
                            iNIF:DebugMsg("Showing hidden loot frame for rollID: " .. rollID, 3) -- INFO
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

    -- Registration deferred to ADDON_LOADED (see OnEvent handler)
end
