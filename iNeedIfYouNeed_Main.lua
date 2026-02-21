-- ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗  ██╗ ███████╗ ██╗   ██╗  ██████╗  ██╗   ██╗ ███╗   ██╗ ███████╗ ███████╗ ██████╗
-- ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗ ██║ ██╔════╝ ╚██╗ ██╔╝ ██╔═══██╗ ██║   ██║ ████╗  ██║ ██╔════╝ ██╔════╝ ██╔══██╗
-- ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║ ██║ █████╗    ╚████╔╝  ██║   ██║ ██║   ██║ ██╔██╗ ██║ █████╗   █████╗   ██║  ██║
-- ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║ ██║ ██╔══╝     ╚██╔╝   ██║   ██║ ██║   ██║ ██║╚██╗██║ ██╔══╝   ██╔══╝   ██║  ██║
-- ██║ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝ ██║ ██║         ██║    ╚██████╔╝ ╚██████╔╝ ██║ ╚████║ ███████╗ ███████╗ ██████╔╝
-- ╚═╝ ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝  ╚═╝ ╚═╝         ╚═╝     ╚═════╝   ╚═════╝  ╚═╝  ╚═══╝ ╚══════╝ ╚══════╝ ╚═════╝
-- ══════════════════════════════════════════════════════════════════════════════════════════════════════════════════

local addonName, iNIF = ...
local L = iNIF.L or {}  -- Load localization table with fallback

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                  Libraries                                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
iNIF.LDBroker = LibStub("LibDataBroker-1.1", true)
iNIF.LDBIcon = LibStub("LibDBIcon-1.0", true)
iNIF.AceComm = LibStub("AceComm-3.0", true)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                  Metadata                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
iNIF.Title = select(2, C_AddOns.GetAddOnInfo(addonName)):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%s*v?[%d%.]+$", "")
iNIF.Version = C_AddOns.GetAddOnMetadata(addonName, "Version")
iNIF.Author = C_AddOns.GetAddOnMetadata(addonName, "Author")

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Saved Variables                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
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
        enchanterMode = false, -- Enchanter Mode: Need items nobody else needs (for disenchant)
        minimapButton = {
            hide = false,
            minimapPos = -30
        },
        monitorWindow = {
            point = "CENTER",
            relativeTo = "CENTER",
            xOffset = 0,
            yOffset = 200
        },
    }
end

-- Per-character saved variables
if not iNIFCharDB then iNIFCharDB = {} end
if not iNIFCharDB.quickLoot then iNIFCharDB.quickLoot = {} end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                   Colors                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
iNIF.Colors = {
    iNIF = "|cffff9716",      -- Orange (same as iWR base color)
    White = "|cFFFFFFFF",
    Green = "|cFF00FF00",
    Red = "|cFFFF0000",
    Orange = "|cFFFFA500",
    Yellow = "|cFFFFFF00",
    Teal = "|cFF00FFFF",
    Reset = "|r"
}

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Core Variables                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
iNIF.activeRolls = {} -- Track active loot rolls
iNIF.eventFrame = CreateFrame("Frame")
iNIF.timerWindow = nil -- Timer display window
iNIF.InCombat = false -- Combat state flag

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Combat State Handling                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        iNIF.InCombat = true

        -- Auto-hide settings frames on combat enter
        if iNIF.SettingsFrame and iNIF.SettingsFrame:IsShown() then
            iNIF.SettingsFrame:Hide()
        end

        local menuPanel = _G["iNIFMenuPanel"]
        if menuPanel and menuPanel:IsShown() then
            menuPanel:Hide()
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        iNIF.InCombat = false
    end
end)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Checkbox Registry                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
iNIF.CheckboxRegistry = {
    enabled = {},
    showNotifications = {},
    partyMessages = {},
    hideLootFrame = {},
    hideMonitorWindow = {},
    enchanterMode = {},
    debug = {}
}

-- Function to update all checkboxes for a setting
function iNIF.UpdateAllCheckboxes(settingKey, value)
    for _, cb in ipairs(iNIF.CheckboxRegistry[settingKey] or {}) do
        if cb and cb:IsShown() then
            cb:SetChecked(value)
        end
    end
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                             Style Helper                                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.CreateiNIFStyleFrame(parent, width, height, anchor)
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
