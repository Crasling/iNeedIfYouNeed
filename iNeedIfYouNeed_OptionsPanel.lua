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
local Print = function(...) return iNIF.Print(...) end
local Debug = function(...) return iNIF.Debug(...) end
local HasActiveRolls = function(...) return iNIF.HasActiveRolls(...) end
local UpdateAllCheckboxes = iNIF.UpdateAllCheckboxes

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Helper Functions                                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯

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

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Options Panel                                       │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
function iNIF.CreateOptionsPanel()
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
    local quickLootContainer, quickLootContent = CreateTabContent()
    local enchanterContainer, enchanterContent = CreateTabContent()

    -- ALWAYS create addon tabs (detection deferred to OnShow hook)
    local aboutContainer, aboutContent = CreateTabContent()
    local iWRContainer, iWRContent = CreateTabContent()
    local iSPContainer, iSPContent = CreateTabContent()

    local tabContents = {generalContainer, quickLootContainer, enchanterContainer, aboutContainer, iWRContainer, iSPContainer}

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

    iNIF.ShowTab = ShowTab

    -- Build sidebar with section headers and tabs (iWR style)
    local sidebarItems = {
        {type = "header", label = L["SidebarHeaderiNIF"]},
        {type = "tab", label = L["Tab1General"], index = 1},
        {type = "tab", label = L["Tab2QuickLoot"], index = 2},
        {type = "tab", label = L["Tab3Enchanter"] or "Enchanter", index = 3},
        {type = "tab", label = L["Tab4About"] or L["Tab2About"], index = 4},
        {type = "header", label = L["SidebarHeaderOtherAddons"]},
        {type = "tab", label = L["Tab5iWR"] or L["Tab3iWR"], index = 5},
        {type = "tab", label = L["Tab6iSP"] or L["Tab4iSP"], index = 6},
    }

    local sidebarY = -6
    for _, item in ipairs(sidebarItems) do
        if item.type == "header" then
            -- Create section header text
            local headerText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            headerText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 12, sidebarY - 2)
            headerText:SetText(item.label)
            sidebarY = sidebarY - 20
        else
            -- Create tab button
            local btn = CreateFrame("Button", nil, sidebar)
            btn:SetSize(sidebarWidth - 12, 26)
            btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, sidebarY)

            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(btn)
            bg:SetColorTexture(0, 0, 0, 0)
            btn.bg = bg

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", btn, "LEFT", 14, 0)
            text:SetText(item.label)
            btn.text = text

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(btn)
            highlight:SetColorTexture(1, 1, 1, 0.08)

            btn:SetScript("OnClick", function()
                ShowTab(item.index)
            end)

            table.insert(sidebarButtons, btn)
            sidebarY = sidebarY - 28
        end
    end

    -- Show first tab by default
    ShowTab(1)

    -- Track checkboxes for refresh
    local checkboxRefs = {}

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                          General Tab Content                               │
    -- ╰────────────────────────────────────────────────────────────────────────────╯
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

    -- ── Ninja Detection ──
    y = y - 10
    _, y = CreateSectionHeader(generalContent, L["SettingsSectionNinjaDetection"] or "Ninja Detection", y)

    local cbNinja
    cbNinja, y = CreateSettingsCheckbox(generalContent, L["SettingsNinjaDetection"] or "Enable Ninja Detection",
        L["SettingsNinjaDetectionDesc"] or "", y, "ninjaDetection")
    checkboxRefs.ninjaDetection = cbNinja

    local cbNinjaAnnounce
    cbNinjaAnnounce, y = CreateSettingsCheckbox(generalContent, L["SettingsNinjaAnnounce"] or "Announce ninja to party/raid",
        L["SettingsNinjaAnnounceDesc"] or "", y, "ninjaAnnounce")
    checkboxRefs.ninjaAnnounce = cbNinjaAnnounce

    -- ── Roll Tracker ──
    y = y - 10
    _, y = CreateSectionHeader(generalContent, L["SettingsSectionRollTracker"] or "Roll Tracker", y)

    local cbRollTracker
    cbRollTracker, y = CreateSettingsCheckbox(generalContent, L["SettingsRollTracker"] or "Enable Roll Tracker",
        L["SettingsRollTrackerDesc"] or "", y, "rollTracker")
    checkboxRefs.rollTracker = cbRollTracker

    -- Show Luck Meter button
    local btnLuck = CreateFrame("Button", nil, generalContent, "UIPanelButtonTemplate")
    btnLuck:SetSize(150, 22)
    btnLuck:SetPoint("TOPLEFT", generalContent, "TOPLEFT", 25, y)
    btnLuck:SetText(L["RollTrackerShowButton"] or "Show Luck Meter")
    btnLuck:SetScript("OnClick", function()
        if iNIF.ToggleLuckMeter then iNIF.ToggleLuckMeter() end
    end)
    y = y - 30

    scrollChildren[1]:SetHeight(math.abs(y) + 20)

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                        QuickLoot Tab Content                               │
    -- ╰────────────────────────────────────────────────────────────────────────────╯
    y = -10

    _, y = CreateSectionHeader(quickLootContent, L["SettingsSectionQuickLoot"], y)

    local qlDesc
    qlDesc, y = CreateInfoText(quickLootContent, L["QuickLootDesc"], y, "GameFontHighlight")
    y = y - 6

    -- Input row: EditBox + Need/Greed/Pass buttons
    local qlInputRow = CreateFrame("Frame", nil, quickLootContent)
    qlInputRow:SetSize(500, 30)
    qlInputRow:SetPoint("TOPLEFT", quickLootContent, "TOPLEFT", 25, y)

    local qlEditBox = CreateFrame("EditBox", nil, qlInputRow, "InputBoxTemplate")
    qlEditBox:SetSize(260, 22)
    qlEditBox:SetPoint("LEFT", qlInputRow, "LEFT", 0, 0)
    qlEditBox:SetAutoFocus(false)
    qlEditBox:SetFontObject(GameFontHighlight)
    qlEditBox:SetMaxLetters(80)

    -- Placeholder text
    local qlPlaceholder = qlEditBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    qlPlaceholder:SetPoint("LEFT", qlEditBox, "LEFT", 6, 0)
    qlPlaceholder:SetText(L["QuickLootItemNamePlaceholder"])
    qlEditBox:SetScript("OnTextChanged", function(self)
        qlPlaceholder:SetShown(self:GetText() == "")
    end)
    qlEditBox:SetScript("OnEditFocusGained", function(self)
        qlPlaceholder:SetShown(self:GetText() == "")
    end)
    qlEditBox:SetScript("OnEditFocusLost", function(self)
        qlPlaceholder:SetShown(self:GetText() == "")
    end)

    -- Add rule function
    local function AddQuickLootRule(rollType)
        local itemName = qlEditBox:GetText()
        if not itemName or itemName == "" then
            Print(L["QuickLootEmptyName"])
            return
        end
        itemName = strtrim(itemName)
        if itemName == "" then
            Print(L["QuickLootEmptyName"])
            return
        end
        iNIFCharDB.quickLoot[itemName] = rollType
        local actionName = rollType == 1 and L["QuickLootActionNeed"] or rollType == 2 and L["QuickLootActionGreed"] or rollType == 3 and L["QuickLootActionToggle"] or L["QuickLootActionPass"]
        Print(string.format(L["QuickLootAdded"], itemName, actionName))
        qlEditBox:SetText("")
        qlEditBox:ClearFocus()
        if iNIF.RefreshQuickLootList then iNIF.RefreshQuickLootList() end
    end

    -- Need button
    local btnNeed = CreateFrame("Button", nil, qlInputRow, "UIPanelButtonTemplate")
    btnNeed:SetSize(60, 22)
    btnNeed:SetPoint("LEFT", qlEditBox, "RIGHT", 8, 0)
    btnNeed:SetText(L["QuickLootBtnNeed"])
    btnNeed:GetFontString():SetTextColor(1, 0.3, 0.3)
    btnNeed:SetScript("OnClick", function() AddQuickLootRule(1) end)

    -- Greed button
    local btnGreed = CreateFrame("Button", nil, qlInputRow, "UIPanelButtonTemplate")
    btnGreed:SetSize(60, 22)
    btnGreed:SetPoint("LEFT", btnNeed, "RIGHT", 4, 0)
    btnGreed:SetText(L["QuickLootBtnGreed"])
    btnGreed:GetFontString():SetTextColor(0.3, 1, 0.3)
    btnGreed:SetScript("OnClick", function() AddQuickLootRule(2) end)

    -- Pass button
    local btnPass = CreateFrame("Button", nil, qlInputRow, "UIPanelButtonTemplate")
    btnPass:SetSize(60, 22)
    btnPass:SetPoint("LEFT", btnGreed, "RIGHT", 4, 0)
    btnPass:SetText(L["QuickLootBtnPass"])
    btnPass:GetFontString():SetTextColor(1, 1, 0.3)
    btnPass:SetScript("OnClick", function() AddQuickLootRule(0) end)

    -- Toggle button (auto-check iNIF checkbox instead of instant roll)
    local btnToggle = CreateFrame("Button", nil, qlInputRow, "UIPanelButtonTemplate")
    btnToggle:SetSize(60, 22)
    btnToggle:SetPoint("LEFT", btnPass, "RIGHT", 4, 0)
    btnToggle:SetText(L["QuickLootBtnToggle"])
    btnToggle:GetFontString():SetTextColor(1, 0.59, 0.09)
    btnToggle:SetScript("OnClick", function() AddQuickLootRule(3) end)

    -- Enter key submits as Greed by default
    qlEditBox:SetScript("OnEnterPressed", function(self)
        AddQuickLootRule(2)
    end)
    qlEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    y = y - 36

    -- Rules list container with border
    local qlListBorder = CreateFrame("Frame", nil, quickLootContent, "BackdropTemplate")
    qlListBorder:SetPoint("TOPLEFT", quickLootContent, "TOPLEFT", 25, y)
    qlListBorder:SetPoint("TOPRIGHT", quickLootContent, "TOPRIGHT", -25, y)
    qlListBorder:SetHeight(250)
    qlListBorder:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    qlListBorder:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
    qlListBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)

    -- Scrollable list inside the border
    local qlScrollFrame = CreateFrame("ScrollFrame", nil, qlListBorder, "UIPanelScrollFrameTemplate")
    qlScrollFrame:SetPoint("TOPLEFT", qlListBorder, "TOPLEFT", 4, -4)
    qlScrollFrame:SetPoint("BOTTOMRIGHT", qlListBorder, "BOTTOMRIGHT", -24, 4)

    local qlScrollChild = CreateFrame("Frame", nil, qlScrollFrame)
    qlScrollChild:SetWidth(qlScrollFrame:GetWidth() or 440)
    qlScrollChild:SetHeight(1)
    qlScrollFrame:SetScrollChild(qlScrollChild)

    -- "No rules" placeholder text
    local qlNoRules = qlScrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    qlNoRules:SetPoint("TOP", qlScrollChild, "TOP", 0, -20)
    qlNoRules:SetText(L["QuickLootNoRules"])

    -- Refresh list function
    local function RefreshQuickLootList()
        -- Clear existing row frames
        local children = {qlScrollChild:GetChildren()}
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end

        -- Sort entries alphabetically
        if not iNIFCharDB.quickLoot then iNIFCharDB.quickLoot = {} end
        local sorted = {}
        for itemName, rollType in pairs(iNIFCharDB.quickLoot) do
            table.insert(sorted, {name = itemName, action = rollType})
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)

        if #sorted == 0 then
            qlNoRules:Show()
            qlScrollChild:SetHeight(60)
            return
        end
        qlNoRules:Hide()

        local rowHeight = 24
        local rowY = 0
        for i, entry in ipairs(sorted) do
            local row = CreateFrame("Frame", nil, qlScrollChild, "BackdropTemplate")
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", qlScrollChild, "TOPLEFT", 0, -rowY)
            row:SetPoint("TOPRIGHT", qlScrollChild, "TOPRIGHT", 0, -rowY)

            -- Alternating row backgrounds
            if i % 2 == 0 then
                row:SetBackdrop({bgFile = "Interface\\BUTTONS\\WHITE8X8"})
                row:SetBackdropColor(1, 1, 1, 0.03)
            end

            -- Item name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
            nameText:SetWidth(300)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(entry.name)

            -- Action button (clickable to cycle Need/Greed/Pass)
            local capturedName = entry.name
            local actionBtn = CreateFrame("Button", nil, row)
            actionBtn:SetSize(70, rowHeight)
            actionBtn:SetPoint("RIGHT", row, "RIGHT", -28, 0)
            local actionLabel = actionBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            actionLabel:SetPoint("CENTER", actionBtn, "CENTER", 0, 0)
            local actionText = entry.action == 1 and L["QuickLootActionNeed"] or entry.action == 2 and L["QuickLootActionGreed"] or entry.action == 3 and L["QuickLootActionToggle"] or L["QuickLootActionPass"]
            actionLabel:SetText("[" .. actionText .. "]")
            actionBtn:SetScript("OnClick", function()
                local current = iNIFCharDB.quickLoot[capturedName]
                -- Cycle: Need(1) -> Greed(2) -> Pass(0) -> Toggle(3) -> Need(1)
                local nextAction = current == 1 and 2 or current == 2 and 0 or current == 0 and 3 or 1
                iNIFCharDB.quickLoot[capturedName] = nextAction
                RefreshQuickLootList()
            end)
            actionBtn:SetScript("OnEnter", function(self)
                SetCursor("INTERACT_CURSOR")
            end)
            actionBtn:SetScript("OnLeave", function(self)
                SetCursor(nil)
            end)

            -- Remove button
            local removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            removeBtn:SetSize(20, 20)
            removeBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            removeBtn:SetText(L["QuickLootRemove"])
            removeBtn:GetFontString():SetTextColor(1, 0.3, 0.3)
            removeBtn:SetScript("OnClick", function()
                iNIFCharDB.quickLoot[capturedName] = nil
                Print(string.format(L["QuickLootRemoved"], capturedName))
                RefreshQuickLootList()
            end)

            rowY = rowY + rowHeight
        end

        qlScrollChild:SetHeight(math.max(rowY, 60))
    end

    iNIF.RefreshQuickLootList = RefreshQuickLootList
    RefreshQuickLootList()

    y = y - 260
    scrollChildren[2]:SetHeight(400)

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                        Enchanter Tab Content                               │
    -- ╰────────────────────────────────────────────────────────────────────────────╯
    y = -10

    -- ── Enchanter Mode Settings ──
    _, y = CreateSectionHeader(enchanterContent, L["SettingsSectionEnchanterMode"], y)

    local cbEnchanter
    cbEnchanter, y = CreateSettingsCheckbox(enchanterContent, L["SettingsEnchanterMode"],
        L["SettingsEnchanterModeDesc"], y, "enchanterMode")
    checkboxRefs.enchanterMode = cbEnchanter

    -- Override OnClick: block toggle during active rolls
    cbEnchanter:SetScript("OnClick", function(self)
        if HasActiveRolls() then
            self:SetChecked(iNIFDB.enchanterMode)
            Print(L["EnchanterModeActiveRoll"])
            return
        end
        local checked = self:GetChecked() and true or false
        iNIFDB.enchanterMode = checked
        Debug(L["SettingsEnchanterMode"] .. " " .. (checked and (Colors.Green .. "enabled" .. Colors.Reset) or (Colors.Red .. "disabled" .. Colors.Reset)))
        UpdateAllCheckboxes("enchanterMode", checked)
    end)

    -- Grey out checkbox when rolls are active (poll on show/update)
    local enchanterTicker = nil
    local function UpdateEnchanterCheckboxState()
        local hasRolls = HasActiveRolls()
        if hasRolls then
            cbEnchanter:SetAlpha(0.4)
            cbEnchanter:SetEnabled(false)
            cbEnchanter.Text:SetTextColor(0.5, 0.5, 0.5)
        else
            cbEnchanter:SetAlpha(1.0)
            cbEnchanter:SetEnabled(true)
            cbEnchanter.Text:SetTextColor(1, 1, 1)
        end
    end

    settingsFrame:HookScript("OnShow", function()
        UpdateEnchanterCheckboxState()
        if not enchanterTicker then
            enchanterTicker = C_Timer.NewTicker(0.5, UpdateEnchanterCheckboxState)
        end
    end)
    settingsFrame:HookScript("OnHide", function()
        if enchanterTicker then
            enchanterTicker:Cancel()
            enchanterTicker = nil
        end
    end)

    local cbAnnounceDE
    cbAnnounceDE, y = CreateSettingsCheckbox(enchanterContent, L["SettingsAnnounceDE"] or "Announce item received for DE",
        L["SettingsAnnounceDEDesc"] or "", y, "enchanterAnnounceDE")
    checkboxRefs.enchanterAnnounceDE = cbAnnounceDE

    local cbAnnounceResults
    cbAnnounceResults, y = CreateSettingsCheckbox(enchanterContent, L["SettingsAnnounceResults"] or "Announce disenchant results",
        L["SettingsAnnounceResultsDesc"] or "", y, "enchanterAnnounceResults")
    checkboxRefs.enchanterAnnounceResults = cbAnnounceResults

    -- ── Disenchant History ──
    y = y - 10
    _, y = CreateSectionHeader(enchanterContent, L["SettingsSectionEnchanterHistory"] or "Disenchant History", y)

    -- History list container
    local deHistoryBorder = CreateFrame("Frame", nil, enchanterContent, "BackdropTemplate")
    deHistoryBorder:SetPoint("TOPLEFT", enchanterContent, "TOPLEFT", 25, y)
    deHistoryBorder:SetPoint("TOPRIGHT", enchanterContent, "TOPRIGHT", -25, y)
    deHistoryBorder:SetHeight(150)
    deHistoryBorder:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    deHistoryBorder:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
    deHistoryBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)

    local deHistoryScroll = CreateFrame("ScrollFrame", nil, deHistoryBorder, "UIPanelScrollFrameTemplate")
    deHistoryScroll:SetPoint("TOPLEFT", deHistoryBorder, "TOPLEFT", 4, -4)
    deHistoryScroll:SetPoint("BOTTOMRIGHT", deHistoryBorder, "BOTTOMRIGHT", -24, 4)

    local deHistoryChild = CreateFrame("Frame", nil, deHistoryScroll)
    deHistoryChild:SetWidth(deHistoryScroll:GetWidth() or 440)
    deHistoryChild:SetHeight(1)
    deHistoryScroll:SetScrollChild(deHistoryChild)

    local deHistoryEmpty = deHistoryChild:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    deHistoryEmpty:SetPoint("TOP", deHistoryChild, "TOP", 0, -20)
    deHistoryEmpty:SetText(L["EnchanterHistoryEmpty"] or "No disenchants recorded this session.")

    -- Refresh disenchant history display
    local function RefreshEnchanterHistory()
        local children = {deHistoryChild:GetChildren()}
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end

        if not iNIF.enchanterHistory or #iNIF.enchanterHistory == 0 then
            deHistoryEmpty:Show()
            deHistoryChild:SetHeight(60)
            return
        end
        deHistoryEmpty:Hide()

        local rowHeight = 20
        local rowY = 0
        -- Show newest first
        for i = #iNIF.enchanterHistory, 1, -1 do
            local entry = iNIF.enchanterHistory[i]
            local row = CreateFrame("Frame", nil, deHistoryChild)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", deHistoryChild, "TOPLEFT", 0, -rowY)
            row:SetPoint("TOPRIGHT", deHistoryChild, "TOPRIGHT", 0, -rowY)

            local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", row, "LEFT", 8, 0)
            text:SetWidth(420)
            text:SetJustifyH("LEFT")

            local matStr = ""
            if entry.mats then
                for _, mat in ipairs(entry.mats) do
                    if matStr ~= "" then matStr = matStr .. ", " end
                    matStr = matStr .. mat.count .. "x " .. (mat.matLink or "?")
                end
            end
            text:SetText((entry.itemLink or "?") .. " → " .. (matStr ~= "" and matStr or "..."))

            rowY = rowY + rowHeight
        end
        deHistoryChild:SetHeight(math.max(rowY, 60))
    end

    iNIF.RefreshEnchanterHistory = RefreshEnchanterHistory

    y = y - 160

    -- Clear History button
    local btnClearHistory = CreateFrame("Button", nil, enchanterContent, "UIPanelButtonTemplate")
    btnClearHistory:SetSize(130, 22)
    btnClearHistory:SetPoint("TOPLEFT", enchanterContent, "TOPLEFT", 25, y)
    btnClearHistory:SetText(L["EnchanterClearHistoryButton"] or "Clear History")
    btnClearHistory:SetScript("OnClick", function()
        wipe(iNIF.enchanterHistory)
        wipe(iNIF.enchanterMatTotals)
        RefreshEnchanterHistory()
        Print(L["EnchanterHistoryCleared"] or "Disenchant history cleared.")
    end)

    -- Open Split Window button
    local btnSplit = CreateFrame("Button", nil, enchanterContent, "UIPanelButtonTemplate")
    btnSplit:SetSize(150, 22)
    btnSplit:SetPoint("LEFT", btnClearHistory, "RIGHT", 8, 0)
    btnSplit:SetText(L["EnchanterSplitButton"] or "Open Split Window")
    btnSplit:SetScript("OnClick", function()
        if iNIF.ToggleSplitWindow then iNIF.ToggleSplitWindow() end
    end)

    y = y - 30

    scrollChildren[3]:SetHeight(math.abs(y) + 20)

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                          About Tab Content                                 │
    -- ╰────────────────────────────────────────────────────────────────────────────╯
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

    scrollChildren[4]:SetHeight(math.abs(y) + 20)

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                           iWR Settings Tab                                 │
    -- ╰────────────────────────────────────────────────────────────────────────────╯

    -- Create INSTALLED variant frame (always created, hidden initially)
    local iWRInstalledFrame = CreateFrame("Frame", nil, iWRContent)
    iWRInstalledFrame:SetAllPoints(iWRContent)
    iWRInstalledFrame:Hide()

    y = -10
    _, y = CreateSectionHeader(iWRInstalledFrame, L["SettingsSectionIWR"], y)

    local iWRDesc
    iWRDesc, y = CreateInfoText(iWRInstalledFrame,
        L["IWRInstalledDesc1"] .. "\n\n" .. L["IWRInstalledDesc2"],
        y, "GameFontHighlight")

    y = y - 10

    -- Button to open iWR settings
    local iWRButton = CreateFrame("Button", nil, iWRInstalledFrame, "UIPanelButtonTemplate")
    iWRButton:SetSize(180, 28)
    iWRButton:SetPoint("TOPLEFT", iWRInstalledFrame, "TOPLEFT", 25, y)
    iWRButton:SetText(L["IWROpenSettingsButton"])
    iWRButton:SetScript("OnClick", function()
        -- iWR is an AceAddon global, its settings frame is on the addon object
        local iWRFrame = _G.iWR and _G.iWR.SettingsFrame
        if iWRFrame then
            local point, _, relPoint, xOfs, yOfs = settingsFrame:GetPoint()
            iWRFrame:ClearAllPoints()
            iWRFrame:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
            settingsFrame:Hide()
            iWRFrame:Show()
        else
            Print(Colors.Red .. L["ErroriWRNotFound"])
        end
    end)

    -- Create PROMO variant frame (always created, hidden initially)
    local iWRPromoFrame = CreateFrame("Frame", nil, iWRContent)
    iWRPromoFrame:SetAllPoints(iWRContent)
    iWRPromoFrame:Hide()

    y = -10
    _, y = CreateSectionHeader(iWRPromoFrame, Colors.iNIF .. "iWillRemember", y)

    local iWRPromo
    iWRPromo, y = CreateInfoText(iWRPromoFrame,
        L["IWRPromoDesc"],
        y, "GameFontHighlight")

    y = y - 4

    local iWRPromoLink
    iWRPromoLink, y = CreateInfoText(iWRPromoFrame,
        L["IWRPromoLink"],
        y, "GameFontDisableSmall")

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                           iSP Settings Tab                                 │
    -- ╰────────────────────────────────────────────────────────────────────────────╯

    -- Create INSTALLED variant frame (always created, hidden initially)
    local iSPInstalledFrame = CreateFrame("Frame", nil, iSPContent)
    iSPInstalledFrame:SetAllPoints(iSPContent)
    iSPInstalledFrame:Hide()

    y = -10
    _, y = CreateSectionHeader(iSPInstalledFrame, L["SettingsSectionISP"], y)

    local iSPDesc
    iSPDesc, y = CreateInfoText(iSPInstalledFrame,
        L["ISPInstalledDesc1"] .. "\n\n" .. L["ISPInstalledDesc2"],
        y, "GameFontHighlight")

    y = y - 10

    -- Button to open iSP settings
    local iSPButton = CreateFrame("Button", nil, iSPInstalledFrame, "UIPanelButtonTemplate")
    iSPButton:SetSize(180, 28)
    iSPButton:SetPoint("TOPLEFT", iSPInstalledFrame, "TOPLEFT", 25, y)
    iSPButton:SetText(L["ISPOpenSettingsButton"])
    iSPButton:SetScript("OnClick", function()
        -- iSP uses local namespace, access via named frame
        local iSPFrame = _G["iSPSettingsFrame"]
        if iSPFrame then
            local point, _, relPoint, xOfs, yOfs = settingsFrame:GetPoint()
            iSPFrame:ClearAllPoints()
            iSPFrame:SetPoint(point, UIParent, relPoint, xOfs, yOfs)
            settingsFrame:Hide()
            iSPFrame:Show()
        else
            Print(Colors.Red .. L["ErroriSPNotFound"])
        end
    end)

    -- Create PROMO variant frame (always created, hidden initially)
    local iSPPromoFrame = CreateFrame("Frame", nil, iSPContent)
    iSPPromoFrame:SetAllPoints(iSPContent)
    iSPPromoFrame:Hide()

    y = -10
    _, y = CreateSectionHeader(iSPPromoFrame, Colors.iNIF .. "iSoundPlayer", y)

    local iSPPromo
    iSPPromo, y = CreateInfoText(iSPPromoFrame,
        L["ISPPromoDesc"],
        y, "GameFontHighlight")

    y = y - 4

    local iSPPromoLink
    iSPPromoLink, y = CreateInfoText(iSPPromoFrame,
        L["ISPPromoLink"],
        y, "GameFontDisableSmall")

    -- ╭────────────────────────────────────────────────────────────────────────────╮
    -- │                     Blizzard Interface Options Stub                        │
    -- ╰────────────────────────────────────────────────────────────────────────────╯
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

    -- Refresh checkboxes and toggle addon frames when shown
    settingsFrame:HookScript("OnShow", function()
        -- Close other addon settings panels
        local iSPFrame = _G["iSPSettingsFrame"]
        if iSPFrame and iSPFrame:IsShown() then iSPFrame:Hide() end

        local iWRFrame = _G.iWR and _G.iWR.SettingsFrame
        if iWRFrame and iWRFrame:IsShown() then iWRFrame:Hide() end

        -- Refresh checkboxes
        for key, cb in pairs(checkboxRefs) do
            if iNIFDB[key] ~= nil then
                cb:SetChecked(iNIFDB[key])
            end
        end

        -- Deferred addon detection (guaranteed loaded by now)
        local iWRLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("iWillRemember")
        iWRInstalledFrame:SetShown(iWRLoaded)
        iWRPromoFrame:SetShown(not iWRLoaded)

        -- Update iWR sidebar button text
        if sidebarButtons[5] then
            sidebarButtons[5].text:SetText(iWRLoaded and (L["Tab5iWR"] or L["Tab3iWR"]) or L["Tab3iWRPromo"])
        end

        local iSPLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("iSoundPlayer")
        iSPInstalledFrame:SetShown(iSPLoaded)
        iSPPromoFrame:SetShown(not iSPLoaded)

        -- Update iSP sidebar button text
        if sidebarButtons[6] then
            sidebarButtons[6].text:SetText(iSPLoaded and (L["Tab6iSP"] or L["Tab4iSP"]) or L["Tab4iSPPromo"])
        end

        -- Refresh disenchant history when settings open
        if iNIF.RefreshEnchanterHistory then iNIF.RefreshEnchanterHistory() end

        -- Refresh QuickLoot list when settings open
        if iNIF.RefreshQuickLootList then iNIF.RefreshQuickLootList() end
    end)

    return stubPanel
end
