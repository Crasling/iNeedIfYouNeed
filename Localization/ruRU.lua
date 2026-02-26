-- ════════════════════════════════════════════════════════════
-- ██╗███╗   ██╗███████╗███████╗██████╗ ██╗███████╗██╗   ██╗
-- ██║████╗  ██║██╔════╝██╔════╝██╔══██╗██║██╔════╝╚██╗ ██╔╝
-- ██║██╔██╗ ██║█████╗  █████╗  ██║  ██║██║█████╗   ╚████╔╝
-- ██║██║╚██╗██║██╔══╝  ██╔══╝  ██║  ██║██║██╔══╝    ╚██╔╝
-- ██║██║ ╚████║███████╗███████╗██████╔╝██║██║        ██║
-- ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═════╝ ╚═╝╚═╝        ╚═╝
-- ════════════════════════════════════════════════════════════
-- iNeedIfYouNeed - Smart Loot Addon
-- Localization File: Russian (ruRU) - ИИ перевод

local addonName, addon = ...

-- Only load Russian localization on Russian clients
if GetLocale() ~= "ruRU" then return end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                                     Цвета                                     │
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

local L = addon.L

-- Helper function for consistent message formatting
local function Msg(message)
    return Colors.iNIF .. "[iNIF]: " .. message
end

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Отладочные сообщения                               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["PrintPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugPrefix"] = Colors.iNIF .. "[iNIF]: "
L["DebugInfo"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "ИНФО: " .. Colors.Reset .. Colors.iNIF -- ИИ перевод
L["DebugWarning"] = Colors.iNIF .. "[iNIF]: " .. Colors.Yellow .. "ВНИМАНИЕ: " .. Colors.Reset .. Colors.iNIF -- ИИ перевод
L["DebugError"] = Colors.iNIF .. "[iNIF]: " .. Colors.Red .. "ОШИБКА: " .. Colors.Reset .. Colors.iNIF -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                            Окно таймера (Монитор)                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MonitorWindowTitle"] = "Активные броски" -- ИИ перевод
L["MonitorWindowHidden"] = "Окно монитора скрыто. Включите режим отладки, чтобы снова его показать." -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Подсказка к чекбоксу                                │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["CheckboxTooltipTitle"] = "Нужно, если кому-то нужно" -- ИИ перевод
L["CheckboxTooltipDesc"] = "При жадности: автоматически бросить Нужно, если кто-то другой бросит Нужно, иначе Жадность по окончании таймера." -- ИИ перевод
L["CheckboxTooltipTitleEnchanter"] = "Нужно для разборки" -- ИИ перевод
L["CheckboxTooltipDescEnchanter"] = "Режим зачарователя: автоматически бросить Нужно, если никто другой не нуждается в этом предмете. Объявляет в группу/рейд." -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Сообщения чата (Действия)                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ChatRolledGreed"] = Colors.Green .. "Бросок ЖАДНОСТЬ" .. Colors.Reset -- ИИ перевод
L["ChatNobodyNeeded"] = " на %s (никому не нужно)" -- ИИ перевод
L["ChatRollingNeed"] = Colors.Red .. "Бросок НУЖНО" .. Colors.Reset -- ИИ перевод
L["ChatBecauseNeeded"] = " на %s потому что " .. Colors.Yellow .. "%s" .. Colors.Reset .. " нуждался в этом" -- ИИ перевод
L["ChatPartyAutoNeed"] = "[iNIF]: Автоматически бросил Нужно на %s, потому что %s нуждался." -- ИИ перевод
L["ChatMonitoring"] = Colors.iNIF .. "Отслеживание %s... Бросит Нужно, если кто-то бросит Нужно, иначе Жадность по окончании таймера." -- ИИ перевод
L["ChatMonitoringEnchanter"] = Colors.iNIF .. "Отслеживание %s... Бросит Нужно для разборки, если никто другой не бросит Нужно." -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Подсказка кнопки на миникарте                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TooltipLeftClick"] = Colors.Yellow .. "ЛКМ: " .. Colors.Orange -- ИИ перевод
L["TooltipToggleAddon"] = "Вкл./Выкл. аддон" -- ИИ перевод
L["TooltipShiftLeftClick"] = Colors.Yellow .. "Shift+ЛКМ: " .. Colors.Orange -- ИИ перевод
L["TooltipShowFrames"] = "Показать скрытые окна лута" -- ИИ перевод
L["TooltipRightClick"] = Colors.Yellow .. "ПКМ: " .. Colors.Orange -- ИИ перевод
L["TooltipOpenSettings"] = "Открыть настройки" -- ИИ перевод
L["TooltipStatus"] = Colors.Yellow .. "Статус: " .. Colors.Reset -- ИИ перевод
L["StatusEnabled"] = Colors.Green .. "Умная добыча активирована" .. Colors.Reset -- ИИ перевод
L["StatusDisabled"] = Colors.Red .. "Умная добыча деактивирована" .. Colors.Reset -- ИИ перевод
L["StatusEnchanterMode"] = "|cFFAA55FF" .. "Умная разборка активирована" .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Действия кнопки на миникарте                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["ShowingFramesSingular"] = Msg("Показано " .. Colors.Yellow .. "%d" .. Colors.Reset .. " скрытое окно лута") -- ИИ перевод
L["ShowingFramesPlural"] = Msg("Показано " .. Colors.Yellow .. "%d" .. Colors.Reset .. " скрытых окон лута") -- ИИ перевод
L["NoHiddenFrames"] = Msg(Colors.Yellow .. "Нет скрытых окон лута для показа" .. Colors.Reset) -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                           Сообщения о бое                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["InCombat"] = Msg("Нельзя использовать в бою.") -- ИИ перевод
L["EnchanterModeActiveRoll"] = Msg("Нельзя переключить Режим зачарователя во время активного броска.") -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Панель настроек - Заголовки                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionAddon"] = Colors.iNIF .. "Настройки аддона" -- ИИ перевод
L["SettingsSectionAbout"] = Colors.iNIF .. "О нас" -- ИИ перевод
L["SettingsSectionDiscord"] = Colors.iNIF .. "Discord"
L["SettingsSectionDeveloper"] = Colors.iNIF .. "Разработчик" -- ИИ перевод
L["SettingsSectionIWR"] = Colors.iNIF .. "Настройки iWillRemember" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                     Панель настроек - Вкладка Общие                            │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsEnableAddon"] = "Включить аддон" -- ИИ перевод
L["SettingsEnableAddonDesc"] = Colors.Gray .. "Когда выключен, аддон не будет добавлять чекбоксы к окнам лута." .. Colors.Reset -- ИИ перевод
L["SettingsShowNotifications"] = "Показывать уведомления в чате" -- ИИ перевод
L["SettingsShowNotificationsDesc"] = Colors.Gray .. "Показывать сообщения в чате при броске на предметы." .. Colors.Reset -- ИИ перевод
L["SettingsPartyAnnounce"] = "Объявлять Нужно в группу/рейд" -- ИИ перевод
L["SettingsPartyAnnounceDesc"] = Colors.Gray .. "Объявлять в чат группы или рейда, когда вы бросаете Нужно, потому что кто-то другой нуждался." .. Colors.Reset -- ИИ перевод
L["SettingsHideLootFrame"] = "Скрыть окно лута после Жадность+Чекбокс" -- ИИ перевод
L["SettingsHideLootFrameDesc"] = Colors.Gray .. "Скрыть стандартное окно Blizzard (Нужно/Жадность/Пропуск) после нажатия Жадность с включённым чекбоксом." .. Colors.Reset -- ИИ перевод
L["SettingsHideMonitor"] = "Скрыть окно монитора после Жадность+Чекбокс" -- ИИ перевод
L["SettingsHideMonitorDesc"] = Colors.Gray .. "Скрыть окно монитора активных бросков после нажатия Жадность с включённым чекбоксом." .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Панель настроек - Режим зачарователя                        │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionEnchanterMode"] = Colors.iNIF .. "Режим зачарователя" -- ИИ перевод
L["SettingsEnchanterMode"] = "Включить Режим зачарователя" -- ИИ перевод
L["SettingsEnchanterModeDesc"] = Colors.Gray .. "Когда включён с чекбоксом: бросать Нужно на предметы, которые никому не нужны (для разборки). Инвертирует обычное поведение iNIF. Объявляет в группу/рейд для полной прозрачности." .. Colors.Reset -- ИИ перевод
L["EnchanterModeLabel"] = "Режим зачарователя" -- ИИ перевод
L["EnchanterModeNeeded"] = Colors.Green .. "Режим зачарователя: " .. Colors.Reset .. "Нуждаюсь в " -- ИИ перевод
L["EnchanterModePartyMsg"] = "[iNIF]: Нуждаюсь в %s для разборки (Режим зачарователя)" -- ИИ перевод
L["SlashEnchanterMode"] = "Режим зачарователя: " -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Панель настроек - Вкладка О нас                           │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["AboutCreatedBy"] = "Создано: " -- ИИ перевод
L["AboutGameVersion"] = "Classic TBC"
L["AboutDescription1"] = Colors.iNIF .. "iNeedIfYouNeed " .. Colors.Reset .. "— это аддон, разработанный для умной добычи." -- ИИ перевод
L["AboutDescription2"] = Colors.iNIF .. "iNIF " .. Colors.Reset .. "находится на ранней стадии разработки. Присоединяйтесь к Discord для получения помощи, вопросов или предложений." -- ИИ перевод
L["AboutDiscordDesc"] = Colors.Gray .. "Скопируйте эту ссылку, чтобы присоединиться к нашему Discord для поддержки и обновлений" .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Панель настроек - Вкладка Разработчик                       │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsDebugMode"] = "Включить режим отладки" -- ИИ перевод
L["SettingsDebugModeDesc"] = Colors.Gray .. "Включает подробные отладочные сообщения в чате. Не рекомендуется для обычного использования." .. Colors.Reset -- ИИ перевод
L["DebugModeActivated"] = Colors.Red .. "Режим отладки активирован. " .. Colors.Reset -- ИИ перевод
L["DebugModeWarning"] = "Не рекомендуется для обычного использования — будет спам сообщениями." -- ИИ перевод
L["DebugModeActivatedFull"] = Colors.iNIF .. "[iNIF]: " .. Colors.White .. "ИНФО: " .. Colors.Reset .. Colors.iNIF .. "Режим отладки активирован. " .. Colors.Red .. "Не рекомендуется для обычного использования — будет спам сообщениями." .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Панель настроек - Вкладка iWR                             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["IWRInstalledDesc1"] = Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " установлен! Вы можете открыть настройки iWR отсюда." -- ИИ перевод
L["IWRInstalledDesc2"] = Colors.Gray .. "Примечание: Эти настройки управляются iWR и повлияют на аддон iWR." .. Colors.Reset -- ИИ перевод
L["IWROpenSettingsButton"] = "Открыть настройки iWR" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                  Заглушка (Настройки интерфейса Blizzard)                      │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StubPanelDesc"] = "Нажмите правой кнопкой на миникарте или введите " .. Colors.Yellow .. "/inif settings" .. Colors.Reset .. ", чтобы открыть панель настроек." -- ИИ перевод
L["StubOpenSettingsButton"] = Colors.iNIF .. " Настройки" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Стартовое сообщение                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["StartupMessage"] = "%s Classic TBC" .. Colors.Reset .. " %s Загружен." -- ИИ перевод
L["WelcomeStart"] = Msg("Спасибо ") -- ИИ перевод
L["WelcomeEnd"] = Colors.iNIF .. " за участие в разработке iNeedIfYouNeed, если у вас возникнут проблемы, обращайтесь на CurseForge в разделе комментариев или в Discord." -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                          Вкладки боковой панели                                │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SidebarHeaderiNIF"] = Colors.iNIF .. "iNeedIfYouNeed|r"
L["SidebarHeaderOtherAddons"] = Colors.iNIF .. "Другие аддоны|r" -- ИИ перевод
L["Tab1General"] = "Общие" -- ИИ перевод
L["Tab2About"] = "О нас" -- ИИ перевод
L["Tab3iWR"] = "Настройки iWR" -- ИИ перевод
L["Tab3iWRPromo"] = "iWillRemember"
L["Tab4iSP"] = "Настройки iSP" -- ИИ перевод
L["Tab4iSPPromo"] = "iSoundPlayer"

-- QuickLoot Tab -- ИИ перевод
L["Tab2QuickLoot"] = "Быстрая добыча" -- ИИ перевод
L["SettingsSectionQuickLoot"] = Colors.iNIF .. "Правила быстрой добычи" -- ИИ перевод
L["QuickLootDesc"] = Colors.Gray .. "Введите название предмета (например, Arcane Tome) и нажмите Нужно, Жадность, Пропуск или Переключить для автоматического броска при выпадении этого предмета. Переключить автоматически включит чекбокс iNIF вместо мгновенного броска. Названия должны совпадать точно." .. Colors.Reset -- ИИ перевод
L["QuickLootItemNamePlaceholder"] = "Введите название предмета..." -- ИИ перевод
L["QuickLootBtnNeed"] = "Нужно" -- ИИ перевод
L["QuickLootBtnGreed"] = "Жадность" -- ИИ перевод
L["QuickLootBtnPass"] = "Пропуск" -- ИИ перевод
L["QuickLootBtnToggle"] = "Переключить" -- ИИ перевод
L["QuickLootNoRules"] = Colors.Gray .. "Правила быстрой добычи не настроены." .. Colors.Reset -- ИИ перевод
L["QuickLootRemove"] = "X"
L["QuickLootAdded"] = "Быстрая добыча: Добавлено %s (%s)" -- ИИ перевод
L["QuickLootRemoved"] = "Быстрая добыча: Удалено %s" -- ИИ перевод
L["QuickLootEmptyName"] = "Быстрая добыча: Пожалуйста, введите название предмета" -- ИИ перевод
L["QuickLootAutoRoll"] = "Быстрая добыча: Автобросок %s на %s" -- ИИ перевод
L["QuickLootActionNeed"] = Colors.Red .. "Нужно" .. Colors.Reset -- ИИ перевод
L["QuickLootActionGreed"] = Colors.Green .. "Жадность" .. Colors.Reset -- ИИ перевод
L["QuickLootActionPass"] = Colors.Yellow .. "Пропуск" .. Colors.Reset -- ИИ перевод
L["QuickLootActionToggle"] = Colors.iNIF .. "Переключить" .. Colors.Reset -- ИИ перевод
L["QuickLootAutoToggle"] = "Быстрая добыча: Автопереключение чекбокса на %s" -- ИИ перевод

-- Error messages -- ИИ перевод
L["ErroriWRNotFound"] = "Аддон iWR не найден или настройки не инициализированы!" -- ИИ перевод
L["ErroriSPNotFound"] = "Аддон iSP не найден или настройки не инициализированы!" -- ИИ перевод

-- iWR Promo (when NOT installed) -- ИИ перевод
L["IWRPromoDesc"] = Colors.iNIF .. "iWillRemember" .. Colors.Reset .. " — это аддон для персональных заметок об игроках. Отслеживайте друзей, врагов и запоминающиеся встречи. Добавляйте заметки, назначайте типы отношений и делитесь с друзьями.\n\n" .. Colors.Reset .. "Улучшенная рамка цели, предупреждения о группе, интеграция с чатом и многое другое!" -- ИИ перевод
L["IWRPromoLink"] = "Доступно в приложении CurseForge и на curseforge.com/wow/addons/iwillremember" -- ИИ перевод

-- iSP Promo (when NOT installed) -- ИИ перевод
L["ISPPromoDesc"] = Colors.iNIF .. "iSoundPlayer" .. Colors.Reset .. " — это аддон для пользовательских звуков. Воспроизводите MP3/OGG файлы по игровым событиям — вход, повышение уровня, достижения, убийства и многое другое!\n\n" .. Colors.Reset .. "40+ триггеров событий, отслеживание PvP мульти-убийств, зацикливание и расширенные настройки звука." -- ИИ перевод
L["ISPPromoLink"] = "Доступно в приложении CurseForge и на curseforge.com/wow/addons/isoundplayer" -- ИИ перевод

-- iSP Settings (when installed) -- ИИ перевод
L["SettingsSectionISP"] = Colors.iNIF .. "Настройки iSoundPlayer" -- ИИ перевод
L["ISPInstalledDesc1"] = Colors.iNIF .. "iSoundPlayer" .. Colors.Reset .. " установлен! Вы можете открыть настройки iSP отсюда." -- ИИ перевод
L["ISPInstalledDesc2"] = Colors.Gray .. "Примечание: Эти настройки управляются iSP и повлияют на аддон iSP." .. Colors.Reset -- ИИ перевод
L["ISPOpenSettingsButton"] = "Открыть настройки iSP" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Панель меню (ПКМ на миникарте)                              │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["MenuTitle"] = Colors.iNIF .. "Меню iNIF" .. Colors.Reset -- ИИ перевод
L["MenuEnableAddon"] = "Включить аддон" -- ИИ перевод
L["MenuShowNotifications"] = "Показывать уведомления" -- ИИ перевод
L["MenuPartyAnnouncements"] = "Объявления в группу" -- ИИ перевод
L["MenuHideLootFrame"] = "Скрыть окно лута после Жадность+Чекбокс" -- ИИ перевод
L["MenuHideMonitor"] = "Скрыть монитор после Жадность+Чекбокс" -- ИИ перевод
L["MenuDebugMode"] = "Режим отладки" -- ИИ перевод
L["MenuFullSettings"] = "Все настройки" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Ответы слэш-команд                                     │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashNotifications"] = "Уведомления " -- ИИ перевод
L["SlashPartyMessages"] = "Сообщения в группу " -- ИИ перевод
L["SlashRememberState"] = "Запоминание состояния чекбокса " -- ИИ перевод
L["SlashEnabled"] = Colors.Green .. "включено" .. Colors.Reset -- ИИ перевод
L["SlashDisabled"] = Colors.Red .. "выключено" .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                         Справка слэш-команд                                   │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SlashVersionInfo"] = "%s v%s"
L["SlashCommandsHeader"] = Colors.iNIF .. "Команды:" .. Colors.Reset -- ИИ перевод
L["SlashHelpConfig"] = Colors.Yellow .. "/inif config" .. Colors.Reset .. " - Открыть панель настроек" -- ИИ перевод
L["SlashHelpToggle"] = Colors.Yellow .. "/inif toggle" .. Colors.Reset .. " - Вкл./Выкл. аддон" -- ИИ перевод
L["SlashHelpNotifications"] = Colors.Yellow .. "/inif notifications" .. Colors.Reset .. " - Переключить уведомления в чате" -- ИИ перевод
L["SlashHelpParty"] = Colors.Yellow .. "/inif party" .. Colors.Reset .. " - Переключить объявления в группу/рейд" -- ИИ перевод
L["SlashHelpRemember"] = Colors.Yellow .. "/inif remember" .. Colors.Reset .. " - Переключить запоминание состояния чекбокса" -- ИИ перевод
L["SlashHelpEnchanter"] = Colors.Yellow .. "/inif enchanter" .. Colors.Reset .. " - Переключить Режим зачарователя (Нужно для разборки)" -- ИИ перевод
L["SlashHelpSplit"] = Colors.Yellow .. "/inif split" .. Colors.Reset .. " - Открыть калькулятор раздела материалов" -- ИИ перевод
L["SlashHelpLuck"] = Colors.Yellow .. "/inif luck" .. Colors.Reset .. " - Показать трекер удачи бросков" -- ИИ перевод
L["SlashHelpNinja"] = Colors.Yellow .. "/inif ninja" .. Colors.Reset .. " - Показать инциденты ниндзя за сессию" -- ИИ перевод
L["SlashHelpQuickLoot"] = Colors.Yellow .. "/inif quickloot" .. Colors.Reset .. " - Открыть вкладку быстрой добычи" -- ИИ перевод
L["SlashHelpDebug"] = Colors.Yellow .. "/inif debug" .. Colors.Reset .. " - Переключить режим отладки" -- ИИ перевод
L["SlashHelpTest"] = Colors.Yellow .. "/inif test" .. Colors.Reset .. " - Показать статус аддона и активные броски" -- ИИ перевод
L["SlashHelpTestComm"] = Colors.Yellow .. "/inif testcomm" .. Colors.Reset .. " - Тест приёма сообщений AceComm (требуется активный отслеживаемый бросок)" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                        Вывод тестовой команды                                  │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["TestActiveRollsCount"] = "Количество активных бросков: " -- ИИ перевод
L["TestRegisteredEvents"] = "Зарегистрированные события:" -- ИИ перевод
L["TestNoActiveRolls"] = "Нет активных бросков" -- ИИ перевод
L["TestCommHeader"] = Colors.iNIF .. "[iNIF Тест AceComm]" .. Colors.Reset -- ИИ перевод
L["TestCommNotLoaded"] = Colors.Red .. "ОШИБКА: AceComm-3.0 не загружен!" .. Colors.Reset -- ИИ перевод
L["TestCommNoRoll"] = Colors.Yellow .. "Не найден активный отслеживаемый бросок." .. Colors.Reset -- ИИ перевод
L["TestCommInstructions"] = "Для теста: сначала запустите бросок лута и нажмите Жадность+чекбокс" -- ИИ перевод
L["TestDebugTempEnabled"] = Colors.Yellow .. "Режим отладки временно включён для теста" .. Colors.Reset -- ИИ перевод
L["TestCommSimulating"] = "Имитация полученного сообщения от " -- ИИ перевод
L["TestCommMessage"] = "Сообщение: " -- ИИ перевод
L["TestCommSuccess1"] = Colors.Green .. "✓ Сообщение успешно разобрано" .. Colors.Reset -- ИИ перевод
L["TestCommSuccess2"] = Colors.Green .. "✓ Фиктивный игрок отслежен в iNIFGreeds" .. Colors.Reset -- ИИ перевод
L["TestCommTotalUsers"] = "Всего пользователей iNIF: " -- ИИ перевод
L["TestCommIncludingYou"] = " (включая вас)" -- ИИ перевод
L["TestCommGracePeriod"] = "Льготный период истечёт через ~2 секунды, затем автобросок Жадность" -- ИИ перевод
L["TestCommFailed"] = Colors.Red .. "✗ Разбор сообщения НЕ УДАЛСЯ" .. Colors.Reset -- ИИ перевод
L["TestDebugRestored"] = Colors.Yellow .. "Режим отладки восстановлен в выключенный" .. Colors.Reset -- ИИ перевод

-- Test command - Additional strings -- ИИ перевод
L["TestHeader"] = Colors.iNIF .. "[iNIF ТЕСТ]" .. Colors.Reset -- ИИ перевод
L["TestEventAddonLoaded"] = "  - ADDON_LOADED: " -- ИИ перевод
L["TestEventPlayerLogin"] = "  - PLAYER_LOGIN: " -- ИИ перевод
L["TestEventStartLootRoll"] = "  - START_LOOT_ROLL: " -- ИИ перевод
L["TestEventCancelLootRoll"] = "  - CANCEL_LOOT_ROLL: " -- ИИ перевод
L["TestYes"] = Colors.Green .. "ДА" .. Colors.Reset -- ИИ перевод
L["TestNo"] = Colors.Red .. "НЕТ" .. Colors.Reset -- ИИ перевод
L["TestRollInfo"] = "  Бросок #%d: ID=%d, предмет=%s, чекбокс=%s" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                    Вкладки боковой панели (v0.4.0 переиндексация)             │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["Tab3Enchanter"] = "Зачарователь" -- ИИ перевод
L["Tab4About"] = "О нас" -- ИИ перевод
L["Tab5iWR"] = "Настройки iWR" -- ИИ перевод
L["Tab5iWRPromo"] = "iWillRemember"
L["Tab6iSP"] = "Настройки iSP" -- ИИ перевод
L["Tab6iSPPromo"] = "iSoundPlayer"

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                Панель настроек - Вкладка Зачарователь (v0.4.0)               │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
-- Настройки зачарователя -- ИИ перевод
L["SettingsAnnounceDE"] = "Объявлять о получении предмета для разборки" -- ИИ перевод
L["SettingsAnnounceDEDesc"] = Colors.Gray .. "Отправлять сообщение в группу/рейд при броске Нужно для разборки." .. Colors.Reset -- ИИ перевод
L["SettingsAnnounceResults"] = "Объявлять результаты разборки" -- ИИ перевод
L["SettingsAnnounceResultsDesc"] = Colors.Gray .. "Отправлять результаты разборки (материалы) в чат группы/рейда." .. Colors.Reset -- ИИ перевод

-- История разборки -- ИИ перевод
L["SettingsSectionEnchanterHistory"] = Colors.iNIF .. "История разборки" -- ИИ перевод
L["EnchanterHistoryEmpty"] = Colors.Gray .. "В этой сессии разборок не было." .. Colors.Reset -- ИИ перевод
L["EnchanterClearHistoryButton"] = "Очистить историю" -- ИИ перевод
L["EnchanterHistoryCleared"] = "История разборки очищена." -- ИИ перевод
L["EnchanterSplitButton"] = "Открыть окно раздела" -- ИИ перевод

-- Обнаружение разборки + Раздел (Frames) -- ИИ перевод
L["EnchanterResultPartyMsg"] = "[iNIF]: Разобрано -> %s" -- ИИ перевод
L["EnchanterHistoryItemDE"] = "Разобрано в: " -- ИИ перевод
L["EnchanterSplitTitle"] = "Раздел материалов" -- ИИ перевод
L["EnchanterSplitNoMats"] = "В этой сессии материалов не записано." -- ИИ перевод
L["EnchanterSplitTotal"] = "Всего материалов:" -- ИИ перевод
L["EnchanterSplitPerPlayer"] = "На игрока (%d участников):" -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Панель настроек - Обнаружение ниндзя                    │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionNinjaDetection"] = Colors.iNIF .. "Обнаружение ниндзя" -- ИИ перевод
L["SettingsNinjaDetection"] = "Включить обнаружение ниндзя" -- ИИ перевод
L["SettingsNinjaDetectionDesc"] = Colors.Gray .. "Предупреждать, когда кто-то бросает Нужно на броню, которую не может надеть." .. Colors.Reset -- ИИ перевод
L["SettingsNinjaAnnounce"] = "Объявлять ниндзя в группу/рейд" -- ИИ перевод
L["SettingsNinjaAnnounceDesc"] = Colors.Gray .. "Отправлять предупреждение в чат группы/рейда при обнаружении ниндзя." .. Colors.Reset -- ИИ перевод
L["NinjaDetected"] = Colors.Red .. "НИНДЗЯ: " .. Colors.Reset .. "%s (%s) бросил Нужно на %s — не может надеть %s броню!" -- ИИ перевод
L["NinjaPartyMsg"] = "[iNIF]: Внимание: %s бросил Нужно на %s — этот класс не может надеть %s броню" -- ИИ перевод
L["NinjaNoIncidents"] = "В этой сессии инцидентов ниндзя не зафиксировано." -- ИИ перевод
L["NinjaIncidentsHeader"] = Colors.Red .. "Инциденты ниндзя:" .. Colors.Reset -- ИИ перевод

-- ╭────────────────────────────────────────────────────────────────────────────────╮
-- │                      Панель настроек - Трекер бросков                        │
-- ╰────────────────────────────────────────────────────────────────────────────────╯
L["SettingsSectionRollTracker"] = Colors.iNIF .. "Трекер бросков" -- ИИ перевод
L["SettingsRollTracker"] = "Включить трекер бросков" -- ИИ перевод
L["SettingsRollTrackerDesc"] = Colors.Gray .. "Отслеживать победы в бросках по игрокам за сессию." .. Colors.Reset -- ИИ перевод
L["RollTrackerShowButton"] = "Показать измеритель удачи" -- ИИ перевод
L["RollTrackerTitle"] = "Трекер удачи бросков" -- ИИ перевод
L["RollTrackerEmpty"] = "В этой сессии бросков ещё не отслежено." -- ИИ перевод
L["RollTrackerWins"] = "Побед" -- ИИ перевод
L["RollTrackerRolls"] = "Бросков" -- ИИ перевод
