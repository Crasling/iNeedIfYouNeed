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

-- Local aliases
local Colors = iNIF.Colors
local Title = iNIF.Title
local Version = iNIF.Version
local activeRolls = iNIF.activeRolls
local AceComm = iNIF.AceComm
local Print = function(...) return iNIF.Print(...) end
local Debug = function(...) return iNIF.Debug(...) end
local CountTable = function(...) return iNIF.CountTable(...) end
local HasActiveRolls = function(...) return iNIF.HasActiveRolls(...) end
local UpdateAllCheckboxes = iNIF.UpdateAllCheckboxes

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Slash Commands                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
SLASH_iNIF1 = "/inif"
SlashCmdList["iNIF"] = function(msg)
    msg = string.lower(string.trim(msg or ""))

    if msg == "config" or msg == "settings" or msg == "options" then
        -- Open custom settings frame
        if iNIF.InCombat then print(L["InCombat"]) return end
        if iNIF.SettingsFrame then
            iNIF.SettingsFrame:Show()
        end

    elseif msg == "toggle" then
        iNIFDB.enabled = not iNIFDB.enabled
        if iNIFDB.enabled and iNIFDB.enchanterMode then
            Print(L["StatusEnchanterMode"])
        else
            Print(iNIFDB.enabled and L["StatusEnabled"] or L["StatusDisabled"])
        end

    elseif msg == "notifications" or msg == "notify" then
        iNIFDB.showNotifications = not iNIFDB.showNotifications
        Print(L["SlashNotifications"] .. (iNIFDB.showNotifications and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "party" then
        iNIFDB.partyMessages = not iNIFDB.partyMessages
        Print(L["SlashPartyMessages"] .. (iNIFDB.partyMessages and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "remember" then
        iNIFDB.checkboxRememberState = not iNIFDB.checkboxRememberState
        Print(L["SlashRememberState"] .. (iNIFDB.checkboxRememberState and L["SlashEnabled"] or L["SlashDisabled"]))

    elseif msg == "enchanter" or msg == "de" then
        if HasActiveRolls() then
            Print(L["EnchanterModeActiveRoll"])
            return
        end
        iNIFDB.enchanterMode = not iNIFDB.enchanterMode
        Print(L["SlashEnchanterMode"] .. (iNIFDB.enchanterMode and L["SlashEnabled"] or L["SlashDisabled"]))
        UpdateAllCheckboxes("enchanterMode", iNIFDB.enchanterMode)

    elseif msg == "quickloot" or msg == "ql" then
        if iNIF.SettingsFrame then
            iNIF.SettingsFrame:Show()
            if iNIF.ShowTab then iNIF.ShowTab(2) end
        end

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
        print(L["TestActiveRollsCount"] .. Colors.Yellow .. tostring(CountTable(activeRolls)) .. Colors.Reset)
        print(L["TestRegisteredEvents"])
        print(L["TestEventAddonLoaded"] .. (iNIF.eventFrame:IsEventRegistered("ADDON_LOADED") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventPlayerLogin"] .. (iNIF.eventFrame:IsEventRegistered("PLAYER_LOGIN") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventStartLootRoll"] .. (iNIF.eventFrame:IsEventRegistered("START_LOOT_ROLL") and L["TestYes"] or L["TestNo"]))
        print(L["TestEventCancelLootRoll"] .. (iNIF.eventFrame:IsEventRegistered("CANCEL_LOOT_ROLL") and L["TestYes"] or L["TestNo"]))

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
        print("  " .. L["SlashHelpEnchanter"])
        print("  " .. L["SlashHelpQuickLoot"])
        print("  " .. L["SlashHelpDebug"])
        print("  " .. L["SlashHelpTest"])
        print("  " .. L["SlashHelpTestComm"])
    end
end
