-- ════════════════════════════════════════════════════════════
-- ██╗███╗   ██╗███████╗███████╗██████╗ ██╗███████╗██╗   ██╗
-- ██║████╗  ██║██╔════╝██╔════╝██╔══██╗██║██╔════╝╚██╗ ██╔╝
-- ██║██╔██╗ ██║█████╗  █████╗  ██║  ██║██║█████╗   ╚████╔╝
-- ██║██║╚██╗██║██╔══╝  ██╔══╝  ██║  ██║██║██╔══╝    ╚██╔╝
-- ██║██║ ╚████║███████╗███████╗██████╔╝██║██║        ██║
-- ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═════╝ ╚═╝╚═╝        ╚═╝
-- ════════════════════════════════════════════════════════════
-- iNeedIfYouNeed - Smart Loot Addon
-- Localization File: English (enUS) - Default

local addonName, addon = ...

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                     Colors                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local Colors = {
    -- Standard Colors
    iNIF = "|cffff9716",
    White = "|cFFFFFFFF",
    Black = "|cFF000000",
    Red = "|cFFFF0000",
    Green = "|cFF00FF00",
    Blue = "|cFF0000FF",
    Yellow = "|cFFFFFF00",
    Cyan = "|cFF00FFFF",
    Magenta = "|cFFFF00FF",
    Orange = "|cFFFFA500",
    Gray = "|cFF808080",

    -- Reset Color
    Reset = "|r"
}

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Localization Table Setup                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local L = {}
addon.L = L

-- Fallback: Return key if translation missing
setmetatable(L, {__index = function(t, k)
    return k
end})

-- Helper function for consistent message formatting
local function Msg(message)
    return Colors.iNIF .. "[iNIF]: " .. Colors.Reset .. message
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                 Debug Messages                                 │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["PrintPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugInfo"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "INFO: " .. Colors.Reset .. Colors.iNIF
L["DebugWarning"] = Colors.iNIF .. "[iNIF]: " .. Colors.Yellow .. "WARNING: " .. Colors.Reset .. Colors.iNIF
L["DebugError"] = Colors.iNIF .. "[iNIF]: " .. Colors.Red .. "ERROR: " .. Colors.Reset .. Colors.iNIF

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Timer Window (Monitor)                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MonitorWindowTitle"] = "Active Rolls"
L["MonitorWindowHidden"] = "Monitor window hidden. Re-enable debug mode to show it again."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                               Checkbox Tooltip                                 │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["CheckboxTooltipTitle"] = "Need if someone needs"
L["CheckboxTooltipDesc"] = "When greeding: Automatically roll Need if someone else rolls Need, otherwise Greed at the end of the timer."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Chat Messages (Actions)                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ChatRolledGreed"] = Colors.Green .. "Rolled GREED" .. Colors.Reset
L["ChatNobodyNeeded"] = " on %s (nobody needed)"
L["ChatRollingNeed"] = Colors.Red .. "Rolled NEED" .. Colors.Reset
L["ChatBecauseNeeded"] = " on %s because " .. Colors.Yellow .. "%s" .. Colors.Reset .. " needed it"
L["ChatPartyAutoNeed"] = "[iNIF]: Automatically needed on %s because %s needed."
L["ChatMonitoring"] = Colors.iNIF .. "Monitoring %s... Will Need if someone Needs, otherwise Greed at end of timer."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Minimap Button Tooltip                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TooltipLeftClick"] = Colors.Yellow .. "Left Click: " .. Colors.Orange
L["TooltipToggleAddon"] = "Enable/Disable addon"
L["TooltipShiftLeftClick"] = Colors.Yellow .. "Shift+Left Click: " .. Colors.Orange
L["TooltipShowFrames"] = "Show hidden loot frames"
L["TooltipRightClick"] = Colors.Yellow .. "Right Click: " .. Colors.Orange
L["TooltipOpenSettings"] = "Open settings"
L["TooltipStatus"] = Colors.Yellow .. "Status: " .. Colors.Reset
L["StatusEnabled"] = Colors.Green .. "Smart looting activated" .. Colors.Reset
L["StatusDisabled"] = Colors.Red .. "Smart looting deactivated" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Minimap Button Click Actions                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ShowingFramesSingular"] = Msg("Showing " .. Colors.Yellow .. "%d" .. Colors.Reset .. " hidden loot frame")
L["ShowingFramesPlural"] = Msg("Showing " .. Colors.Yellow .. "%d" .. Colors.Reset .. " hidden loot frames")
L["NoHiddenFrames"] = Msg(Colors.Yellow .. "No hidden loot frames to show" .. Colors.Reset)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Settings Panel - Headers                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionAddon"] = Colors.iNIF .. "Addon Settings"
L["SettingsSectionAbout"] = Colors.iNIF .. "About"
L["SettingsSectionDiscord"] = Colors.iNIF .. "Discord"
L["SettingsSectionDeveloper"] = Colors.iNIF .. "Developer"
L["SettingsSectionIWR"] = Colors.iNIF .. "iWillRemember Settings"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Settings Panel - General Tab                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsEnableAddon"] = "Enable Addon"
L["SettingsEnableAddonDesc"] = Colors.Gray .. "When disabled, the addon will not add checkboxes to loot windows." .. Colors.Reset
L["SettingsShowNotifications"] = "Show Chat Notifications"
L["SettingsShowNotificationsDesc"] = Colors.Gray .. "Display messages in chat when rolling on items." .. Colors.Reset
L["SettingsPartyAnnounce"] = "Announce Needs to Party/Raid"
L["SettingsPartyAnnounceDesc"] = Colors.Gray .. "Announce to party or raid chat when you need an item because someone else needed it." .. Colors.Reset
L["SettingsHideLootFrame"] = "Hide Loot Frame After Greed+Checkbox"
L["SettingsHideLootFrameDesc"] = Colors.Gray .. "Hide Blizzard's loot frame (Need/Greed/Pass window) after clicking Greed with checkbox enabled." .. Colors.Reset
L["SettingsHideMonitor"] = "Hide Monitor Window After Greed+Checkbox"
L["SettingsHideMonitorDesc"] = Colors.Gray .. "Hide the Active Rolls monitor window after clicking Greed with checkbox enabled." .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Settings Panel - About Tab                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["AboutCreatedBy"] = "Created by: "
L["AboutGameVersion"] = "Classic TBC"
L["AboutDescription1"] = Colors.iNIF .. "iNeedIfYouNeed " .. Colors.Reset .. "is an addon designed to help you with smart looting."
L["AboutDescription2"] = Colors.iNIF .. "iNIF " .. Colors.Reset .. "is in early development. Join the Discord for help with issues, questions, or suggestions."
L["AboutDiscordDesc"] = Colors.Gray .. "Copy this link to join our Discord for support and updates" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                       Settings Panel - Developer Tab                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsDebugMode"] = "Enable Debug Mode"
L["SettingsDebugModeDesc"] = Colors.Gray .. "Enables verbose debug messages in chat. Not recommended for normal use." .. Colors.Reset
L["DebugModeActivated"] = Colors.Red .. "Debug Mode is activated. " .. Colors.Reset
L["DebugModeWarning"] = "This is not recommended for common use and will cause message spam."
L["DebugModeActivatedFull"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "INFO: " .. Colors.Reset .. Colors.iNIF .. "Debug Mode is activated. " .. Colors.Red .. "This is not recommended for common use and will cause message spam." .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Settings Panel - iWR Tab                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["IWRInstalledDesc1"] = Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " is installed! You can access iWR settings from here."
L["IWRInstalledDesc2"] = Colors.Gray .. "Note: These settings are managed by iWR and will affect the iWR addon." .. Colors.Reset
L["IWROpenSettingsButton"] = "Open iWR Settings"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Stub Panel (Blizzard Interface Options)                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StubPanelDesc"] = "Left-click the minimap button or type " .. Colors.Yellow .. "/inif settings" .. Colors.Reset .. " to open the full settings panel."
L["StubOpenSettingsButton"] = "Open Settings"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                               Startup Message                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StartupMessage"] = "%s Classic TBC" .. Colors.Reset .. " %s Loaded."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                Sidebar Tabs                                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TabGeneral"] = "General"
L["TabAbout"] = "About"
L["TabIWRSettings"] = "iWR Settings"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Menu Panel (Minimap Right-Click)                          │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MenuTitle"] = Colors.iNIF .. "iNIF Menu" .. Colors.Reset
L["MenuEnableAddon"] = "Enable Addon"
L["MenuShowNotifications"] = "Show Notifications"
L["MenuPartyAnnouncements"] = "Party Announcements"
L["MenuHideLootFrame"] = "Hide Loot Frame After Greed+Checkbox"
L["MenuHideMonitor"] = "Hide Monitor Window After Greed+Checkbox"
L["MenuDebugMode"] = "Debug Mode"
L["MenuFullSettings"] = "Full Settings"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Slash Command Responses                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashNotifications"] = "Notifications "
L["SlashPartyMessages"] = "Party messages "
L["SlashRememberState"] = "Remember checkbox state "
L["SlashEnabled"] = Colors.Green .. "enabled" .. Colors.Reset
L["SlashDisabled"] = Colors.Red .. "disabled" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Slash Command Help                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashVersionInfo"] = "%s v%s"
L["SlashCommandsHeader"] = Colors.iNIF .. "Commands:" .. Colors.Reset
L["SlashHelpConfig"] = Colors.Yellow .. "/inif config" .. Colors.Reset .. " - Open settings panel"
L["SlashHelpToggle"] = Colors.Yellow .. "/inif toggle" .. Colors.Reset .. " - Enable/disable addon"
L["SlashHelpNotifications"] = Colors.Yellow .. "/inif notifications" .. Colors.Reset .. " - Toggle chat notifications"
L["SlashHelpParty"] = Colors.Yellow .. "/inif party" .. Colors.Reset .. " - Toggle party/raid announcements"
L["SlashHelpRemember"] = Colors.Yellow .. "/inif remember" .. Colors.Reset .. " - Toggle checkbox state memory"
L["SlashHelpDebug"] = Colors.Yellow .. "/inif debug" .. Colors.Reset .. " - Toggle debug mode"
L["SlashHelpTest"] = Colors.Yellow .. "/inif test" .. Colors.Reset .. " - Show addon status and active rolls"
L["SlashHelpTestComm"] = Colors.Yellow .. "/inif testcomm" .. Colors.Reset .. " - Test AceComm message reception (requires active monitored roll)"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Test Command Output                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TestActiveRollsCount"] = "Active rolls count: "
L["TestRegisteredEvents"] = "Registered events:"
L["TestNoActiveRolls"] = "No active rolls"
L["TestCommHeader"] = Colors.iNIF .. "[iNIF AceComm Test]" .. Colors.Reset
L["TestCommNotLoaded"] = Colors.Red .. "ERROR: AceComm-3.0 not loaded!" .. Colors.Reset
L["TestCommNoRoll"] = Colors.Yellow .. "No active monitored roll found." .. Colors.Reset
L["TestCommInstructions"] = "To test: Trigger a loot roll and click Greed+checkbox first"
L["TestDebugTempEnabled"] = Colors.Yellow .. "Debug mode temporarily enabled for test" .. Colors.Reset
L["TestCommSimulating"] = "Simulating received message from "
L["TestCommMessage"] = "Message: "
L["TestCommSuccess1"] = Colors.Green .. "✓ Message parsed successfully" .. Colors.Reset
L["TestCommSuccess2"] = Colors.Green .. "✓ Fake player tracked in iNIFGreeds" .. Colors.Reset
L["TestCommTotalUsers"] = "Total iNIF users: "
L["TestCommIncludingYou"] = " (including you)"
L["TestCommGracePeriod"] = "Grace period will expire in ~2 seconds, then auto-roll Greed"
L["TestCommFailed"] = Colors.Red .. "✗ Message parsing FAILED" .. Colors.Reset
L["TestDebugRestored"] = Colors.Yellow .. "Debug mode restored to off" .. Colors.Reset

-- Test command - Additional strings
L["TestHeader"] = Colors.iNIF .. "[iNIF TEST]" .. Colors.Reset
L["TestEventAddonLoaded"] = "  - ADDON_LOADED: "
L["TestEventPlayerLogin"] = "  - PLAYER_LOGIN: "
L["TestEventStartLootRoll"] = "  - START_LOOT_ROLL: "
L["TestEventCancelLootRoll"] = "  - CANCEL_LOOT_ROLL: "
L["TestYes"] = Colors.Green .. "YES" .. Colors.Reset
L["TestNo"] = Colors.Red .. "NO" .. Colors.Reset
L["TestRollInfo"] = "  Roll #%d: ID=%d, item=%s, checkbox=%s"
