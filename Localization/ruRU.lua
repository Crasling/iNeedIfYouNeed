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
    return Colors.iNIF .. "[iNIF]: " .. message
end
--Translator ZamestoTV
-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                 Debug Messages                                 │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["PrintPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugInfo"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "ИНФО: " .. Colors.Reset .. Colors.iNIF
L["DebugWarning"] = Colors.iNIF .. "[iNIF]: " .. Colors.Yellow .. "ВНИМАНИЕ: " .. Colors.Reset .. Colors.iNIF
L["DebugError"] = Colors.iNIF .. "[iNIF]: " .. Colors.Red .. "ОШИБКА: " .. Colors.Reset .. Colors.iNIF

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Timer Window (Monitor)                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MonitorWindowTitle"] = "Активные роллы"
L["MonitorWindowHidden"] = "Окно мониторинга скрыто. Включите режим отладки, чтобы снова его показать."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                               Checkbox Tooltip                                 │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["CheckboxTooltipTitle"] = "Нужен, если кто-то нуждается"
L["CheckboxTooltipDesc"] = "При выборе жадности: автоматически роллить Нужен, если кто-то другой нажал Нужен, иначе в конце таймера — Жадность."
L["CheckboxTooltipTitleEnchanter"] = "Нужен для распыления"
L["CheckboxTooltipDescEnchanter"] = "Режим распылителя: автоматически роллить Нужен, если никто другой не нуждается в предмете. Объявляется группе/рейду."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Chat Messages (Actions)                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ChatRolledGreed"] = Colors.Green .. "Выпало ЖАДНОСТЬ" .. Colors.Reset
L["ChatNobodyNeeded"] = " на %s (никому не нужен)"
L["ChatRollingNeed"] = Colors.Red .. "Выпало НУЖЕН" .. Colors.Reset
L["ChatBecauseNeeded"] = " на %s, потому что " .. Colors.Yellow .. "%s" .. Colors.Reset .. " нуждался"
L["ChatPartyAutoNeed"] = "[iNIF]: Автоматически нуждался на %s, потому что %s нуждался."
L["ChatMonitoring"] = Colors.iNIF .. "Слежу за %s... Нажму Нужен, если кто-то нажмёт Нужен, иначе Жадность в конце таймера."
L["ChatMonitoringEnchanter"] = Colors.iNIF .. "Слежу за %s... Нажму Нужен для распыления, если никто другой не нуждается."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Minimap Button Tooltip                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TooltipLeftClick"] = Colors.Yellow .. "ЛКМ: " .. Colors.Orange
L["TooltipToggleAddon"] = "Вкл/Выкл аддон"
L["TooltipShiftLeftClick"] = Colors.Yellow .. "Shift+ЛКМ: " .. Colors.Orange
L["TooltipShowFrames"] = "Показать скрытые окна лута"
L["TooltipRightClick"] = Colors.Yellow .. "ПКМ: " .. Colors.Orange
L["TooltipOpenSettings"] = "Открыть настройки"
L["TooltipStatus"] = Colors.Yellow .. "Статус: " .. Colors.Reset
L["StatusEnabled"] = Colors.Green .. "Умный лут включён" .. Colors.Reset
L["StatusDisabled"] = Colors.Red .. "Умный лут выключен" .. Colors.Reset
L["StatusEnchanterMode"] = "|cFFAA55FF" .. "Умное распыление включено" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Minimap Button Click Actions                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ShowingFramesSingular"] = Msg("Показываю " .. Colors.Yellow .. "%d" .. Colors.Reset .. " скрытое окно лута")
L["ShowingFramesPlural"] = Msg("Показываю " .. Colors.Yellow .. "%d" .. Colors.Reset .. " скрытых окон лута")
L["NoHiddenFrames"] = Msg(Colors.Yellow .. "Нет скрытых окон лута для показа" .. Colors.Reset)

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                              Combat Messages                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["InCombat"] = Msg("Нельзя использовать в бою.")
L["EnchanterModeActiveRoll"] = Msg("Нельзя переключать режим распылителя во время активного ролла.")

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Settings Panel - Headers                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionAddon"] = Colors.iNIF .. "Настройки аддона"
L["SettingsSectionAbout"] = Colors.iNIF .. "О аддоне"
L["SettingsSectionDiscord"] = Colors.iNIF .. "Discord"
L["SettingsSectionDeveloper"] = Colors.iNIF .. "Разработчик"
L["SettingsSectionIWR"] = Colors.iNIF .. "Настройки iWillRemember"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Settings Panel - General Tab                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsEnableAddon"] = "Включить аддон"
L["SettingsEnableAddonDesc"] = Colors.Gray .. "Если выключено, аддон не будет добавлять галочки в окна лута." .. Colors.Reset
L["SettingsShowNotifications"] = "Показывать сообщения в чате"
L["SettingsShowNotificationsDesc"] = Colors.Gray .. "Показывать в чате информацию о роллах." .. Colors.Reset
L["SettingsPartyAnnounce"] = "Объявлять нужду в группу/рейд"
L["SettingsPartyAnnounceDesc"] = Colors.Gray .. "Сообщать в чат группы или рейда, когда вы нуждаетесь в предмете из-за того, что кто-то другой нуждался." .. Colors.Reset
L["SettingsHideLootFrame"] = "Скрывать окно лута после Жадность+галочка"
L["SettingsHideLootFrameDesc"] = Colors.Gray .. "Скрывать стандартное окно Blizzard (Нужен/Жадность/Пасс) после нажатия Жадность с включённой галочкой." .. Colors.Reset
L["SettingsHideMonitor"] = "Скрывать окно мониторинга после Жадность+галочка"
L["SettingsHideMonitorDesc"] = Colors.Gray .. "Скрывать окно «Активные роллы» после нажатия Жадность с включённой галочкой." .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                       Settings Panel - Enchanter Mode                         │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionEnchanterMode"] = Colors.iNIF .. "Режим распылителя"
L["SettingsEnchanterMode"] = "Включить режим распылителя"
L["SettingsEnchanterModeDesc"] = Colors.Gray .. "Когда включено и стоит галочка: нажимать Нужен на предметы, которые никому больше не нужны (для распыления). Инвертирует обычное поведение iNIF. Всегда объявляется в группу/рейд для прозрачности." .. Colors.Reset
L["EnchanterModeLabel"] = "Режим распылителя"
L["EnchanterModeNeeded"] = Colors.Green .. "Режим распылителя: " .. Colors.Reset .. "Нужен "
L["EnchanterModePartyMsg"] = "[iNIF]: Нужен %s для распыления (режим распылителя)"
L["SlashEnchanterMode"] = "Режим распылителя: "

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Settings Panel - About Tab                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["AboutCreatedBy"] = "Автор: "
L["AboutGameVersion"] = "Classic TBC"
L["AboutDescription1"] = Colors.iNIF .. "iNeedIfYouNeed " .. Colors.Reset .. "— аддон для умного распределения лута."
L["AboutDescription2"] = Colors.iNIF .. "iNIF " .. Colors.Reset .. "находится в ранней разработке. Присоединяйтесь к Discord для вопросов, помощи и предложений."
L["AboutDiscordDesc"] = Colors.Gray .. "Скопируйте ссылку, чтобы присоединиться к нашему Discord для поддержки и обновлений" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                       Settings Panel - Developer Tab                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsDebugMode"] = "Включить режим отладки"
L["SettingsDebugModeDesc"] = Colors.Gray .. "Включает подробные отладочные сообщения в чат. Не рекомендуется для обычной игры." .. Colors.Reset
L["DebugModeActivated"] = Colors.Red .. "Режим отладки включён. " .. Colors.Reset
L["DebugModeWarning"] = "Это не рекомендуется для обычного использования — будет очень много сообщений."
L["DebugModeActivatedFull"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "ИНФО: " .. Colors.Reset .. Colors.iNIF .. "Режим отладки включён. " .. Colors.Red .. "Это не рекомендуется для обычной игры и вызовет спам сообщений." .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Settings Panel - iWR Tab                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["IWRInstalledDesc1"] = Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " установлен! Настройки iWR доступны здесь."
L["IWRInstalledDesc2"] = Colors.Gray .. "Внимание: эти настройки управляются аддоном iWR и влияют на него." .. Colors.Reset
L["IWROpenSettingsButton"] = "Открыть настройки iWR"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Stub Panel (Blizzard Interface Options)                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StubPanelDesc"] = "ПКМ по кнопке на миникарте или введите " .. Colors.Yellow .. "/inif settings" .. Colors.Reset .. ", чтобы открыть панель настроек."
L["StubOpenSettingsButton"] = Colors.iNIF .. " Настройки"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                               Startup Message                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StartupMessage"] = "%s Classic TBC" .. Colors.Reset .. " %s загружен."

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                Sidebar Tabs                                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SidebarHeaderiNIF"] = Colors.iNIF .. "iNeedIfYouNeed|r"
L["SidebarHeaderOtherAddons"] = Colors.iNIF .. "Другие аддоны|r"
L["Tab1General"] = "Основное"
L["Tab2About"] = "О аддоне"
L["Tab3iWR"] = "Настройки iWR"
L["Tab3iWRPromo"] = "iWillRemember"
L["Tab4iSP"] = "Настройки iSP"
L["Tab4iSPPromo"] = "iSoundPlayer"

-- QuickLoot Tab
L["Tab2QuickLoot"] = "Быстрый лут"
L["SettingsSectionQuickLoot"] = Colors.iNIF .. "Правила быстрого лута"
L["QuickLootDesc"] = Colors.Gray .. "Введите точное название предмета (например, Арканный фолиант) и выберите Нужен / Жадность / Пасс — аддон будет автоматически роллить при выпадении этого предмета." .. Colors.Reset
L["QuickLootItemNamePlaceholder"] = "Введите название предмета..."
L["QuickLootBtnNeed"] = "Нужен"
L["QuickLootBtnGreed"] = "Жадность"
L["QuickLootBtnPass"] = "Пасс"
L["QuickLootNoRules"] = Colors.Gray .. "Правила быстрого лута не настроены." .. Colors.Reset
L["QuickLootRemove"] = "X"
L["QuickLootAdded"] = "Быстрый лут: добавлен %s (%s)"
L["QuickLootRemoved"] = "Быстрый лут: удалён %s"
L["QuickLootEmptyName"] = "Быстрый лут: введите название предмета"
L["QuickLootAutoRoll"] = "Быстрый лут: автоматически роллю %s на %s"
L["QuickLootActionNeed"] = Colors.Red .. "Нужен" .. Colors.Reset
L["QuickLootActionGreed"] = Colors.Green .. "Жадность" .. Colors.Reset
L["QuickLootActionPass"] = Colors.Yellow .. "Пасс" .. Colors.Reset

-- Error messages
L["ErroriWRNotFound"] = "Аддон iWR не найден или настройки не инициализированы!"
L["ErroriSPNotFound"] = "Аддон iSP не найден или настройки не инициализированы!"

-- iWR Promo (when NOT installed)
L["IWRPromoDesc"] = Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " — аддон для персональных заметок об игроках. Записывайте друзей, врагов, памятные встречи. Добавляйте заметки, тип отношений, делитесь с друзьями.\n\n" .. Colors.Reset .. "Улучшенный фрейм цели, предупреждения в группе, интеграция в чат и многое другое!"
L["IWRPromoLink"] = "Доступен в CurseForge App и на curseforge.com/wow/addons/iwillremember"

-- iSP Promo (when NOT installed)
L["ISPPromoDesc"] = Colors.iNIF .. "iSoundPlayer" .. Colors.Reset .. " — аддон для проигрывания своих звуков. Запускайте MP3/OGG по игровым событиям — вход в игру, левел-ап, достижения, убийства и т.д.!\n\n" .. Colors.Reset .. "Более 40 триггеров, учёт мульти-киллов в PvP, зацикливание, расширенные настройки."
L["ISPPromoLink"] = "Доступен в CurseForge App и на curseforge.com/wow/addons/isoundplayer"

-- iSP Settings (when installed)
L["SettingsSectionISP"] = Colors.iNIF .. "Настройки iSoundPlayer"
L["ISPInstalledDesc1"] = Colors.iNIF .. "iSoundPlayer" .. Colors.Reset .. " установлен! Настройки iSP доступны здесь."
L["ISPInstalledDesc2"] = Colors.Gray .. "Внимание: эти настройки управляются аддоном iSP и влияют на него." .. Colors.Reset
L["ISPOpenSettingsButton"] = "Открыть настройки iSP"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Menu Panel (Minimap Right-Click)                          │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MenuTitle"] = Colors.iNIF .. "Меню iNIF" .. Colors.Reset
L["MenuEnableAddon"] = "Включить аддон"
L["MenuShowNotifications"] = "Показывать уведомления"
L["MenuPartyAnnouncements"] = "Объявления в группу"
L["MenuHideLootFrame"] = "Скрывать окно лута после Жадность+галочка"
L["MenuHideMonitor"] = "Скрывать мониторинг после Жадность+галочка"
L["MenuDebugMode"] = "Режим отладки"
L["MenuFullSettings"] = "Полные настройки"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Slash Command Responses                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashNotifications"] = "Уведомления "
L["SlashPartyMessages"] = "Сообщения в группу "
L["SlashRememberState"] = "Запоминать состояние галочки "
L["SlashEnabled"] = Colors.Green .. "включено" .. Colors.Reset
L["SlashDisabled"] = Colors.Red .. "выключено" .. Colors.Reset

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Slash Command Help                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashVersionInfo"] = "%s v%s"
L["SlashCommandsHeader"] = Colors.iNIF .. "Команды:" .. Colors.Reset
L["SlashHelpConfig"] = Colors.Yellow .. "/inif config" .. Colors.Reset .. " — открыть панель настроек"
L["SlashHelpToggle"] = Colors.Yellow .. "/inif toggle" .. Colors.Reset .. " — вкл/выкл аддон"
L["SlashHelpNotifications"] = Colors.Yellow .. "/inif notifications" .. Colors.Reset .. " — вкл/выкл уведомления в чат"
L["SlashHelpParty"] = Colors.Yellow .. "/inif party" .. Colors.Reset .. " — вкл/выкл объявления в группу/рейд"
L["SlashHelpRemember"] = Colors.Yellow .. "/inif remember" .. Colors.Reset .. " — вкл/выкл запоминание состояния галочки"
L["SlashHelpEnchanter"] = Colors.Yellow .. "/inif enchanter" .. Colors.Reset .. " — вкл/выкл режим распылителя"
L["SlashHelpQuickLoot"] = Colors.Yellow .. "/inif quickloot" .. Colors.Reset .. " — открыть вкладку Быстрый лут"
L["SlashHelpDebug"] = Colors.Yellow .. "/inif debug" .. Colors.Reset .. " — вкл/выкл режим отладки"
L["SlashHelpTest"] = Colors.Yellow .. "/inif test" .. Colors.Reset .. " — показать статус аддона и активные роллы"
L["SlashHelpTestComm"] = Colors.Yellow .. "/inif testcomm" .. Colors.Reset .. " — протестировать получение сообщений AceComm (нужен активный ролл)"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Test Command Output                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TestActiveRollsCount"] = "Количество активных роллов: "
L["TestRegisteredEvents"] = "Зарегистрированные события:"
L["TestNoActiveRolls"] = "Нет активных роллов"
L["TestCommHeader"] = Colors.iNIF .. "[iNIF AceComm Тест]" .. Colors.Reset
L["TestCommNotLoaded"] = Colors.Red .. "ОШИБКА: AceComm-3.0 не загружен!" .. Colors.Reset
L["TestCommNoRoll"] = Colors.Yellow .. "Не найден активный отслеживаемый ролл." .. Colors.Reset
L["TestCommInstructions"] = "Для теста: начните ролл лута и сначала нажмите Жадность+галочку"
L["TestDebugTempEnabled"] = Colors.Yellow .. "Режим отладки временно включён для теста" .. Colors.Reset
L["TestCommSimulating"] = "Симулирую полученное сообщение от "
L["TestCommMessage"] = "Сообщение: "
L["TestCommSuccess1"] = Colors.Green .. "✓ Сообщение успешно разобрано" .. Colors.Reset
L["TestCommSuccess2"] = Colors.Green .. "✓ Фейковый игрок добавлен в iNIFGreeds" .. Colors.Reset
L["TestCommTotalUsers"] = "Всего пользователей iNIF: "
L["TestCommIncludingYou"] = " (включая вас)"
L["TestCommGracePeriod"] = "Льготный период истечёт через ~2 секунды, затем авто-ролл Жадность"
L["TestCommFailed"] = Colors.Red .. "✗ Ошибка разбора сообщения" .. Colors.Reset
L["TestDebugRestored"] = Colors.Yellow .. "Режим отладки возвращён в выключенное состояние" .. Colors.Reset

-- Test command - Additional strings
L["TestHeader"] = Colors.iNIF .. "[iNIF ТЕСТ]" .. Colors.Reset
L["TestEventAddonLoaded"] = "  - ADDON_LOADED: "
L["TestEventPlayerLogin"] = "  - PLAYER_LOGIN: "
L["TestEventStartLootRoll"] = "  - START_LOOT_ROLL: "
L["TestEventCancelLootRoll"] = "  - CANCEL_LOOT_ROLL: "
L["TestYes"] = Colors.Green .. "ДА" .. Colors.Reset
L["TestNo"] = Colors.Red .. "НЕТ" .. Colors.Reset
L["TestRollInfo"] = "  Ролл #%d: ID=%d, предмет=%s, галочка=%s"
