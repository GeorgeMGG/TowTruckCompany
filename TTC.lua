script_name("TTC Helper Mod")
script_author("TTC")
script_description("TTC")
script_version("3.5")
local LOCAL_VERSION = "3.5"
local VERSION_URL = "https://raw.githubusercontent.com/GeorgeMGG/TowTruckCompany/refs/heads/main/version.txt"
local SCRIPT_URL  = "https://raw.githubusercontent.com/GeorgeMGG/TowTruckCompany/refs/heads/main/TTC.lua"

require "lib.moonloader"
local imgui = require "imgui"
local sampev = require "lib.samp.events"
local inicfg = require "inicfg"
local vkeys = require "vkeys"

local UI_THEME = {
    accent = { 102, 0, 255, 255 },
    text = { 255, 255, 255, 255 },
    window_bg = { 26, 26, 26, 255 },
    child_bg = { 36, 36, 36, 255 },
    frame_bg = { 51, 51, 51, 255 },
    separator = { 110, 110, 128, 128 },
    header = { 102, 0, 255, 204 },
    button = { 51, 51, 51, 255 },
    button_hovered = { 64, 64, 64, 255 },
    button_active = { 102, 0, 255, 255 }
}

local function themeColor(key)
    local c = UI_THEME[key] or UI_THEME.text
    return imgui.ImVec4(c[1] / 255, c[2] / 255, c[3] / 255, c[4] / 255)
end

-- =========================
-- TRANSLATIONS
-- =========================
local translations = {
    ro = {
        main = "MAIN",
        info = "INFO",
        rules = "REGULAMENT",
        settings = "SETARI",
        close = "INCHIDE",
        luxury_settings = "SETARI",
        global_mod = "Mod Global",
        auto_repair = "Auto Repair",
        auto_engine = "Auto Engine",
        fast_cmds = "Comenzi Rapide",
        fvr = "FVR",
        custom_cmds = "Comenzi Custom",
        tow_truck_settings = "SETARI TOW TRUCK",
        tow_ls = "Tow LS",
        tow_lv = "Tow LV",
        tow_sf = "Tow SF",
        at_tractez1 = "Atentie Tractez",
        at_tractez2 = "Va rog sa eliberati zona", 
        repair_refill = "Repair/Refill",
        sell_kit = "Sell Kit",
        repair_refill_me = "Repair/Refill ME",
        key = "TASTA",
        none = "NIMIC",
        desc_ls = "Acesta comanda alege orasul LS",
        desc_lv = "Acesta comanda alege orasul LV",
        desc_sf = "Acesta comanda alege orasul SF",
        desc_at = "Trimite /s Atentie tractez!",
        desc_rr = "Ofera repair/refill jucatorilor din jur.",
        desc_sk = "Ofera repair kit jucatorilor din jur.",
        desc_rrme = "Acest mod iti ofera repair/refill",
        key_dialog_title = "Setare Tasta",
        key_dialog_msg = "Alege pe ce tasta vrei sa fie comanda",
        press_key = "Apasa orice tasta acum...",
        cancel = "Anuleaza",
        msg_prefix = "{ffe699}TowTruckHelper{FFFFFF}:",
        msg_tow_ls = "{ffe699}TowTruckHelper: {FFFFFF}Remorcheaza masina pana in Orasul {48FF23}Los Santos{FFFFFF}!",
        msg_tow_lv = "{ffe699}TowTruckHelper: {FFFFFF}Remorcheaza masina pana in Orasul {48FF23}Las Venturas{FFFFFF}!",
        msg_tow_sf = "{ffe699}TowTruckHelper: {FFFFFF}Remorcheaza masina pana in Orasul {48FF23}San Fierro{FFFFFF}!",
        msg_not_in_veh = "Nu esti intr-un vehicul.",
        msg_no_player = "Niciun jucator in apropiere.",
        msg_hitman = "Membrii Hitman nu beneficieaza de acest serviciu automat.",
        msg_target_no_veh = "Jucatorul nu este intr-un vehicul.",
        msg_welcome2 = "Foloseste comanda /%s pentru a deschide meniul cu toate informatiile.",
        msg_cmd_disabled = "Comanda nu poate fi folosita, modul sau comenzile rapide dezactivate.",
        lang_settings = "SETARI LIMBA",
        color_settings = "CULOARE MENIU",
        textdraw_settings = "Alte setari",
        enable_textdraw = "Activeaza Textdraw",
        loading_screen = "Ecran de incarcare",
        menu_open_cmd = "Comanda deschidere meniu",
        menu_open_key = "Tasta deschidere meniu",
        fvr_settings_title = "Setari FVR",
        fvr_text_f_label = "Text /f",
        fvr_text_final_label = "Text final",
        fvr_text_sfvr_label = "Text /sfVR",
        fvr_seconds_label = "Secunde",
        save = "Salveaza",
        choose_lang = "Alege Limba",
        choose_color = "Alege Culoare",
        ui_colors = "Culori UI Detaliate",
        window_bg = "Fundal fereastra",
        child_bg = "Fundal sub-fereastra",
        frame_bg = "Fundal controale",
        separator_color = "Separator",
        header_color = "Header",
        button_color = "Buton",
        button_hovered_color = "Buton hover",
        button_active_color = "Buton activ",
        text_color = "Text",
        update_available = "Update disponibil",
        current_version = "Versiune curenta",
        online_version = "Versiune online",
        reason_ro = "Motiv (RO)",
        reason_en = "Motiv (EN)",
        download_now = "Descarca acum",
        later = "Mai tarziu",
        update_settings = "Update",
        auto_check_update = "Verificare automata la pornire",
        check_now = "Verifica acum",
        active = "ACTIV",
        inactive = "INACTIV",
        DebugMode = "Parola incorecta pentru Mod Debug.",
        mod_active = "Modul este {00FFAA}- ACTIVAT.",
        mod_inactive = "Modul este {FF5555}- DEZACTIVAT.",
        ar_active = "Auto Repair {00FFAA}- ACTIVAT.",
        ar_inactive = "Auto Repair {FF5555}- DEZACTIVAT.",
        ae_active = "Auto Engine {00FFAA}- ACTIVAT.",
        ae_inactive = "Auto Engine {FF5555}- DEZACTIVAT.",
        cmds_active = "Comenzi rapide {00FFAA}- ACTIVATE.",
        cmds_inactive = "Comenzi rapide {FF5555}- DEZACTIVATE.",
        ar_disabled_kit = "Auto Repair dezactivat {00A1FF}(Nu mai ai kit){FFFFFF}.",
        cmd_correct = "{00A1FF}Comanda corecta: {FFFFFF}",
        id_invalid = "ID invalid sau jucatorul nu este conectat.",
        chat_clear = "Chat-ul urmeaza sa fie sters!",
        see_rules = "Vezi tot regulamentul pe site...",
        open_browser = "Deschide Regulament Complet (Browser)",
        td_title = "COMMANDS STATUS:",
        splash_title = "Bine ai venit!",
        loading = "Se incarca Tow Truck Company by George_VP...",
        ttme = "Tow Truck la mine - raport.",
        ttrr = "Vehiculul de tip Tow Truck a fost respawnat cu succes.",
        ume = "Utility la mine - in scopuri personale",
        urr = "Vehiculul de tip Utility a fost respawnat cu succes.",
        srr1 = "Cine vrea Repair/Refill?",
        srr2 = "Pret Repair/Refill 50$, Refill Gascan 20$!",
        skit1 = "Cine doreste kit-uri de Repair/Refill?",
        skit2 = "Pret special: Repair 4.000$ | Refill 8.000$!",
        skit3 = "La NPC: Repair 10.000$-15.000$ | Refill 15.000$-25.000$",
        rule1  = "/ls – Tractezi un vehicul in orasul Los Santos.",
        rule2  = "/lv – Tractezi un vehicul in orasul Las Venturas.",
        rule3  = "/sf – Tractezi un vehicul in orasul San Fierro.",
        rule4  = "/rrtt <id> – Oferi simultan repair, refill si refill gascan pentru 1$.",
        rule5  = "/rrall <id> – Oferi simultan repair si refill pentru 50$ si refill gascan pentru 20$.",
        rule6  = "/kit1 <id> – Oferi un kit de reparatie pentru suma de 4.000$.",
        rule7  = "/kit2 <id> – Oferi un kit de combustibil pentru suma de 8.000$.",
        rule8  = "/ttme – Anunti pe /f Tow Truck la mine – raport.",
        rule9  = "/ttrr – Anunti pe /f Vehiculul de tip Tow Truck a fost respawnat cu succes.",
        rule10 = "/ume – Anunti pe /f Utility la mine – uz personal.",
        rule11 = "/urr – Anunti pe /f Utility respawnat cu succes.",
        rule12 = "/at – Strigi: *Atentie, tractez!*",
        rule13 = "/srr – Strigi: *Cine doreste Repair sau Refill? Pret: Repair/Refill 50$, Refill gascan 20$!*",
        rule14 = "/skit – Strigi: *Cine doreste kit Repair sau Refill?*",
        rule15 = "/ms <id> – Multumim, <nume>, pentru ca folosesti serviciile Tow Truck Company!",
        rule16 = "/mycc – Comanda de clear chat personal; iti curata chat-ul.",
        rule17 = "/sal – Comanda spune *Salut* pe toate cele 3 chat-uri (/f, /c, /ac).",
        rule18 = "/nb – Comanda spune *Noapte buna* pe toate cele 3 chat-uri (/f, /c, /ac).",
        rule19  = "/tp   – Verifici cate tow points mai ai disponibile",
        rule20  = "/att <id>  – Comanda rapida pentru /accept towtruck <id>",
        rules_title = "Comenzi prescurtate specifice Tow Truck Company",
        srules_title = "Prescurtari utile",
        srule1  = "/dt   – Comanda rapida pentru /duty + /pin",
        srule2  = "/sp   – Comanda rapida pentru /spawnchange",
        srule3  = "/gj   – Comanda rapida pentru /getjob",
        srule4  = "/cmb  – Comanda rapida pentru /clanmembers",
        srule5  = "/mb   – Comanda rapida pentru /members",
        srule6  = "/kc   – Comanda rapida pentru /killcp",
        srule7 = "/mmc  – Comanda rapida pentru /missed calls + /missed messages",
        srule8 = "/cf   – Comanda rapida pentru /cancel find",
        srule9 = "/gk <id>   – Comanda rapida pentru /givekey <id>",
        srule10 = "/atk <id>  – Comanda rapida pentru /accept ticket <id>",
        srule11 = "/st   – Comanda rapida pentru /stats",
        srule12 = "/ra   – Comanda rapida pentru /raport",
        srule13 = "/sa   – Comanda rapida pentru /stopanim",
        srule14 = "/ha   – Comanda rapida pentru /heal",
        srule15 = "/not  – Comanda rapida pentru /notifications",
        msg_first_run = "Salut %s[%d] Aceasta este noul mod, foloseste comanda /%s pentru a deschide meniul."
    },
    en = {
        main = "MAIN",
        info = "INFO",
        rules = "RULES",
        settings = "SETTINGS",
        close = "CLOSE",
        luxury_settings = "SETTINGS",
        global_mod = "Global Mod",
        auto_repair = "Auto Repair",
        auto_engine = "Auto Engine",
        fast_cmds = "Fast Commands",
        fvr = "FVR",
        custom_cmds = "Custom Commands",
        tow_truck_settings = "TOW TRUCK SETTINGS",
        tow_ls = "Tow LS",
        tow_lv = "Tow LV",
        tow_sf = "Tow SF",
        at_tractez1 = "Attention Towing",
        at_tractez2 = "Please clear the area.", 
        repair_refill = "Repair/Refill",
        sell_kit = "Sell Kit",
        repair_refill_me = "Repair/Refill ME",
        key = "KEY",
        none = "NONE",
        desc_ls = "This command selects LS city",
        desc_lv = "This command selects LV city",
        desc_sf = "This command selects SF city",
        desc_at = "Attention, I am towing!",
        desc_rr = "Offers repair/refill to nearby players.",
        desc_sk = "Offers repair kit to nearby players.",
        desc_rrme = "This mod offers you repair/refill",
        key_dialog_title = "Set Key",
        key_dialog_msg = "Choose a key for command",
        press_key = "Press any key now...",
        cancel = "Cancel",
        msg_prefix = "{ffe699}TowTruckHelper{FFFFFF}:",
        msg_tow_ls = "{ffe699}TowTruckHelper: {FFFFFF}Tow the car to the city {48FF23}Los Santos{FFFFFF}!",
        msg_tow_lv = "{ffe699}TowTruckHelper: {FFFFFF}Tow the car to the city {48FF23}Las Venturas{FFFFFF}!",
        msg_tow_sf = "{ffe699}TowTruckHelper: {FFFFFF}Tow the car to the city {48FF23}San Fierro{FFFFFF}!",
        msg_not_in_veh = "You are not in a vehicle.",
        msg_no_player = "No player nearby.",
        msg_hitman = "Hitman members do not benefit from this automatic service.",
        msg_target_no_veh = "Player is not in a vehicle.",
        msg_welcome2 = "Use command /%s to open the menu with all information.",
        msg_cmd_disabled = "Command cannot be used, mod or fast commands disabled.",
        lang_settings = "LANGUAGE SETTINGS",
        color_settings = "MENU COLOR",
        textdraw_settings = "Other settings",
        enable_textdraw = "Enable Textdraw",
        loading_screen = "Loading screen",
        menu_open_cmd = "Menu open command",
        menu_open_key = "Menu open key",
        fvr_settings_title = "FVR Settings",
        fvr_text_f_label = "Text /f",
        fvr_text_final_label = "Final text",
        fvr_text_sfvr_label = "Text /sfVR",
        fvr_seconds_label = "Seconds",
        save = "Save",
        choose_lang = "Choose Language",
        choose_color = "Choose Color",
        ui_colors = "Detailed UI Colors",
        window_bg = "Window background",
        child_bg = "Child background",
        frame_bg = "Controls background",
        separator_color = "Separator",
        header_color = "Header",
        button_color = "Button",
        button_hovered_color = "Button hovered",
        button_active_color = "Button active",
        text_color = "Text",
        update_available = "Update available",
        current_version = "Current version",
        online_version = "Online version",
        reason_ro = "Reason (RO)",
        reason_en = "Reason (EN)",
        download_now = "Update now",
        later = "Update later",
        update_settings = "Update",
        auto_check_update = "Auto-check on startup",
        check_now = "Check now",
        active = "ACTIVE",
        inactive = "INACTIVE",
        DebugMode = "Incorrect password for Debug Mode.",
        mod_active = "Mod is {00FFAA}- ENABLED.",
        mod_inactive = "Mod is {FF5555}- DISABLED.",
        ar_active = "Auto Repair {00FFAA}- ENABLED.",
        ar_inactive = "Auto Repair {FF5555}- DISABLED.",
        ae_active = "Auto Engine {00FFAA}- ENABLED.",
        ae_inactive = "Auto Engine {FF5555}- DISABLED.",
        cmds_active = "Fast Commands {00FFAA}- ENABLED.",
        cmds_inactive = "Fast Commands {FF5555}- DISABLED.",
        ar_disabled_kit = "Auto Repair disabled {00A1FF}(No kit left){FFFFFF}.",
        cmd_correct = "{00A1FF}Correct command: {FFFFFF}",
        id_invalid = "Invalid ID or player not connected.",
        chat_clear = "Chat is about to be cleared!",
        see_rules = "See full rules on website...",
        open_browser = "Open Full Rules (Browser)",
        td_title = "COMMANDS STATUS:",
        splash_title = "Welcome!",
        loading = "Loading Tow Truck Company by George_VP...",
        ttme = "Tow Truck at me - raport.",
        ttrr = "The Tow Truck vehicle has been successfully respawned.",
        ume = "Utility at me - personal use",
        urr = "The Utility vehicle has been successfully respawned.",
        srr1 = "Who wants Repair/Refill?",
        srr2 = "Price for Repair/Refill 50$, Refill Gascan 20$!",
        skit1 = "Anyone interested in Repair / Refill kits?",
        skit2 = "Special price: Repair $4,000 | Refill $8,000!",
        skit3 = "NPC prices: Repair $10,000-$15,000 | Refill $15,000-$25,000",
        rule1  = "/ls – Tow a vehicle in Los Santos.",
        rule2  = "/lv – Tow a vehicle in Las Venturas.",
        rule3  = "/sf – Tow a vehicle in San Fierro.",
        rule4  = "/rrtt <id> – Offers repair, refill and gas can refill simultaneously for $1.",
        rule5  = "/rrall <id> – Offers repair and refill for $50 and gas can refill for $20.",
        rule6  = "/kit1 <id> – Offers a repair kit for $4,000.",
        rule7  = "/kit2 <id> – Offers a fuel kit for $8,000.",
        rule8  = "/ttme – Announces on /f: Tow Truck at my location – report.",
        rule9  = "/ttrr – Announces on /f: Tow Truck vehicle has been successfully respawned.",
        rule10 = "/ume – Announces on /f: Utility at my location – personal use.",
        rule11 = "/urr – Announces on /f: Utility has been successfully respawned.",
        rule12 = "/at – Shouts: *Attention, towing in progress!*",
        rule13 = "/srr – Shouts: *Anyone wants Repair or Refill? Price: Repair/Refill $50, Gas can refill $20!*",
        rule14 = "/skit – Shouts: *Anyone wants Repair or Refill kit?*",
        rule15 = "/ms <id> – Thank you, <name>, for using Tow Truck Company services!",
        rule16 = "/mycc – Personal clear chat command; clears your chat window.",
        rule17 = "/sal – Sends *Hello* on all 3 chats (/f, /c, /ac).",
        rule18 = "/nb – Sends *Good night* on all 3 chats (/f, /c, /ac).",
        rule19 = "/tp   – Check how many tow points you have left",
        rule20 = "/att <id>  – Quick command for /accept towtruck <id>",
        rules_title = "Tow Truck Company Specific Shortcut Commands",
        srules_title = "Useful Shortcuts",
        srule1  = "/dt   – Quick command for /duty + /pin",
        srule2  = "/sp   – Quick command for /spawnchange",
        srule3  = "/gj   – Quick command for /getjob",
        srule4  = "/cmb  – Quick command for /clanmembers",
        srule5  = "/mb   – Quick command for /members",
        srule6 = "/kc    – Quick command for /killcp",
        srule7 = "/mmc  – Quick command for /missed calls + /missed messages",
        srule8 = "/cf   – Quick command for /cancel find",
        srule9 = "/gk <id>   – Quick command for /givekey <id>",
        srule10 = "/atk <id>   – Quick command for /accept ticket <id>",
        srule11 = "/st   – Quick command for /stats",
        srule12 = "/ra   – Quick command for /report",
        srule13 = "/sa   – Quick command for /stopanim",
        srule14 = "/ha   – Quick command for /heal",
        srule15 = "/not  – Quick command for /notifications",
        msg_first_run = "Hello %s[%d] This is the new mod, use command /%s to open the menu."

    }
}

-- =========================
-- CONFIGURATION
-- =========================
local cfg_default = {
    settings = {
        language = 0, -- 0: RO, 1: EN
        menu_color_r = 102,
        menu_color_g = 0,
        menu_color_b = 255,
        textdraw_enabled = false,
        window_bg_r = 26,
        window_bg_g = 26,
        window_bg_b = 26,
        window_bg_a = 255,
        child_bg_r = 36,
        child_bg_g = 36,
        child_bg_b = 36,
        child_bg_a = 255,
        frame_bg_r = 51,
        frame_bg_g = 51,
        frame_bg_a = 255,
        frame_bg_b = 51,
        separator_r = 110,
        separator_g = 110,
        separator_b = 128,
        separator_a = 128,
        header_r = 102,
        header_g = 0,
        header_b = 255,
        header_a = 204,
        button_r = 51,
        button_g = 51,
        button_b = 51,
        button_a = 255,
        button_hovered_r = 64,
        button_hovered_g = 64,
        button_hovered_b = 64,
        button_hovered_a = 255,
        button_active_r = 102,
        button_active_g = 0,
        button_active_b = 255,
        button_active_a = 255,
        text_r = 255,
        text_g = 255,
        text_b = 255,
        text_a = 255,
        update_auto_check = true,
        start = 0,
        loading_screen_enabled = false,
        menu_cmd = "lux",
        menu_key_enabled = false,
        menu_open_key = 0,
        music_enabled = true,
        music_volume = 50,
        fvr_enabled = false,
        custom_enabled = false,
        fvr_text_f = "Atentie, fvr in 10 secunde.",
        fvr_text_final = "Comanda fvr executata cu succes.",
        fvr_text_sfvr = "M-am razgandit, nu mai dau FVR.",
        fvr_seconds = 10,
        custom1_active = false, custom1_alias = "", custom1_text = "",
        custom2_active = false, custom2_alias = "", custom2_text = "",
        custom3_active = false, custom3_alias = "", custom3_text = "",
        custom4_active = false, custom4_alias = "", custom4_text = "",
        custom5_active = false, custom5_alias = "", custom5_text = "",
        custom6_active = false, custom6_alias = "", custom6_text = "",
        custom7_active = false, custom7_alias = "", custom7_text = "",
        custom8_active = false, custom8_alias = "", custom8_text = "",
        custom9_active = false, custom9_alias = "", custom9_text = "",
        custom10_active = false, custom10_alias = "", custom10_text = "",
        
        tow_ls_enabled = false,
        tow_ls_key = 0,
        tow_lv_enabled = false,
        tow_lv_key = 0,
        tow_sf_enabled = false,
        tow_sf_key = 0,
        at_enabled = false,
        at_key = 0,
        repair_refill_enabled = false,
        repair_refill_key = 0,
        sellkit_enabled = false,
        sellkit_key = 0,
        repair_refill_me_enabled = false,
        repair_refill_me_key = 0
    },
    layout = {} -- Stores custom positions
}
local cfg = inicfg.load(cfg_default, "TTC.ini")
if not cfg then
    cfg = cfg_default
    inicfg.save(cfg, "TTC.ini")
end
if cfg.layout == nil then cfg.layout = {} end

local isEditMode = false
local editPassword = "George_VP#UnknownLegend"
local selectedElement = nil 
local audioStream = nil

-- Helper function to save layout
local function saveLayout()
    inicfg.save(cfg, "TTC.ini")
end

-- Ensure new keys exist if updating from old config
if cfg.settings.language == nil then cfg.settings.language = 0 end
if cfg.settings.menu_color_r == nil then 
    cfg.settings.menu_color_r = 102 
    cfg.settings.menu_color_g = 0 
    cfg.settings.menu_color_b = 255 
end
if cfg.settings.textdraw_enabled == nil then cfg.settings.textdraw_enabled = false end
if cfg.settings.update_auto_check == nil then cfg.settings.update_auto_check = true end
if cfg.settings.start == nil then cfg.settings.start = 0 end
if cfg.settings.loading_screen_enabled == nil then cfg.settings.loading_screen_enabled = false end
if cfg.settings.menu_cmd == nil then cfg.settings.menu_cmd = "lux" end
if cfg.settings.menu_key_enabled == nil then cfg.settings.menu_key_enabled = false end
if cfg.settings.menu_open_key == nil then cfg.settings.menu_open_key = 0 end
if cfg.settings.fvr_enabled == nil then cfg.settings.fvr_enabled = false end
if cfg.settings.custom_enabled == nil then cfg.settings.custom_enabled = false end
if cfg.settings.fvr_text_f == nil then cfg.settings.fvr_text_f = "Atentie, fvr in 10 secunde." end
if cfg.settings.fvr_text_final == nil then cfg.settings.fvr_text_final = "Comanda fvr executata cu succes." end
if cfg.settings.fvr_text_sfvr == nil then cfg.settings.fvr_text_sfvr = "M-am razgandit, nu mai dau FVR." end
if cfg.settings.fvr_seconds == nil then cfg.settings.fvr_seconds = 10 end
if cfg.settings.music_enabled == nil then cfg.settings.music_enabled = true end
if cfg.settings.music_volume == nil then cfg.settings.music_volume = 50 end
for i = 1, 10 do
    if cfg.settings['custom'..i..'_active'] == nil then cfg.settings['custom'..i..'_active'] = false end
    if cfg.settings['custom'..i..'_alias'] == nil then cfg.settings['custom'..i..'_alias'] = '' end
    if cfg.settings['custom'..i..'_text'] == nil then cfg.settings['custom'..i..'_text'] = '' end
end

local function cfgColor(prefix)
    return themeColor(prefix)
end

-- =========================
-- STATE
-- =========================
local showMenu = imgui.ImBool(false)
local activeTab = 1 -- 1: Main, 2: Info, 3: Rules, 4: Settings
local modEnabled = imgui.ImBool(true)
local repairEnabled = imgui.ImBool(true)
local engineEnabled = imgui.ImBool(true)
local commandsEnabled = imgui.ImBool(true) 
local lastMod, lastRepair, lastEngine, lastCmds = false, false, false, true

-- Keybind Dialog State
local showKeyDialog = imgui.ImBool(false)
local waitingForKey = nil 

-- Logo
local logoTexture = nil
local splashTexture = nil

-- Textdraw Font
local tdFont = nil

local showUpdateDialog = imgui.ImBool(false)
local updateInfo = { version_online = nil, reason_ro = nil, reason_en = nil }
local toggleAnim = {}
local showSplash = imgui.ImBool(false)
local splashProgress = 0.0
local splashStartClock = nil
local openMenuAfterSplash = false
local showFvrDialog = imgui.ImBool(false)
local showCustomDialog = imgui.ImBool(false)
local fvrBuffers = {
    start = imgui.ImBuffer(256),
    final = imgui.ImBuffer(256),
    cancel = imgui.ImBuffer(256),
    seconds = imgui.ImInt(10)
}
local customBuffers = {}
for i = 1, 10 do
    customBuffers[i] = {
        active = imgui.ImBool(false),
        alias = imgui.ImBuffer(32),
        text = imgui.ImBuffer(256)
    }
end
local customHandlers = {}
local fvrRunning = false
local fvrCancel = false
local menuCmdBuffer = imgui.ImBuffer(32)
local menuRegistered = {}

-- =========================
-- HELPER FUNCTIONS
-- =========================
function T(key)
    local lang_code = (cfg.settings.language == 1) and "en" or "ro"
    return translations[lang_code][key] or key
end

function getAccentColor()
    return themeColor('accent')
end

local function parseVersionFile(path)
    local data = { }
    local f = io.open(path, "r")
    if not f then return data end
    for line in f:lines() do
        local k, v = line:match("^%s*([%w_]+)%s*[:=]%s*(.-)%s*$")
        if k and v then
            data[k] = v
        end
    end
    f:close()
    return data
end

function checkUpdateOnce()
    if VERSION_URL == "" then return end
    local tmp = "TTC_version.txt"
    local ok = downloadUrlToFile(VERSION_URL, tmp)
    if ok then
        local info = parseVersionFile(tmp)
        local onlineV = tostring(info.version or "")
        if onlineV ~= "" and onlineV ~= LOCAL_VERSION then
            updateInfo.version_online = onlineV
            updateInfo.reason_ro = info.reason_ro or ""
            updateInfo.reason_en = info.reason_en or ""
            showUpdateDialog.v = true
            
            -- Force enable ImGui and cursor for the dialog
            imgui.Process = true
            sampSetCursorMode(true)
        end
    end
end

-- =========================
-- EDIT MODE HELPER
-- =========================
function ImMovable(id, drawCallback)
    local p = imgui.GetCursorPos()
    local savedX = cfg.layout[id .. "_x"]
    local savedY = cfg.layout[id .. "_y"]
    
    if savedX and savedY then
        imgui.SetCursorPos(imgui.ImVec2(savedX, savedY))
    end
    
    -- Execute the actual drawing
    drawCallback()
    
    -- Handle Edit Mode Logic
    if isEditMode then
        local itemMin = imgui.GetItemRectMin()
        local itemMax = imgui.GetItemRectMax()
        local drawList = imgui.GetWindowDrawList()
        
        -- Draw yellow border for visibility
        drawList:AddRect(itemMin, itemMax, 0xFFFFFF00)
        
        -- Check selection (Right Click to select)
        if imgui.IsItemHovered() and imgui.IsMouseClicked(1) then
            selectedElement = id
            sampAddChatMessage(T("msg_prefix") .. "Element selectat: " .. id, -1)
        end
        
        -- Handle Movement if selected
        if selectedElement == id then
            -- Draw Red border to show it's ACTIVE
            drawList:AddRect(itemMin, itemMax, 0xFFFF0000, 0, 15, 2.0)
            
            local moveSpeed = 1
            if isKeyDown(vkeys.VK_SHIFT) then moveSpeed = 10 end
            
            local moved = false
            local currentX = savedX or p.x
            local currentY = savedY or p.y
            
            if wasKeyPressed(vkeys.VK_UP) then currentY = currentY - moveSpeed; moved = true end
            if wasKeyPressed(vkeys.VK_DOWN) then currentY = currentY + moveSpeed; moved = true end
            if wasKeyPressed(vkeys.VK_LEFT) then currentX = currentX - moveSpeed; moved = true end
            if wasKeyPressed(vkeys.VK_RIGHT) then currentX = currentX + moveSpeed; moved = true end
            
            if moved then
                cfg.layout[id .. "_x"] = currentX
                cfg.layout[id .. "_y"] = currentY
                -- No save here to avoid lag, save on exit edit mode
            end
            
            -- Tooltip with coords
            imgui.BeginTooltip()
            imgui.Text("ID: " .. id)
            imgui.Text("X: " .. currentX .. " Y: " .. currentY)
            imgui.Text("Use Arrows to move. Shift for speed.")
            imgui.Text("Right click another element to switch.")
            imgui.EndTooltip()
        end
    end
end

-- =========================
-- STYLE
-- =========================
function apply_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 10.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 5.0
    style.FrameRounding = 5.0
    style.ItemSpacing = imgui.ImVec2(8, 6)
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 5.0
    style.GrabMinSize = 10.0
    style.GrabRounding = 5.0

    colors[clr.Text]                   = cfgColor('text')
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = cfgColor('window_bg')
    colors[clr.ChildWindowBg]          = cfgColor('child_bg')
    colors[clr.PopupBg]                = cfgColor('window_bg')
    colors[clr.Border]                 = cfgColor('separator')
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = cfgColor('frame_bg')
    colors[clr.FrameBgHovered]         = cfgColor('button_hovered')
    colors[clr.FrameBgActive]          = cfgColor('button_active')
    colors[clr.TitleBg]                = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = getAccentColor()
    colors[clr.ScrollbarGrabHovered]   = cfgColor('button_hovered')
    colors[clr.ScrollbarGrabActive]    = cfgColor('button_active')
    colors[clr.CheckMark]              = getAccentColor()
    colors[clr.SliderGrab]             = getAccentColor()
    colors[clr.SliderGrabActive]       = getAccentColor()
    colors[clr.Button]                 = cfgColor('button')
    colors[clr.ButtonHovered]          = cfgColor('button_hovered')
    colors[clr.ButtonActive]           = cfgColor('button_active')
    colors[clr.Header]                 = cfgColor('header')
    colors[clr.HeaderHovered]          = cfgColor('button_hovered')
    colors[clr.HeaderActive]           = cfgColor('button_active')
    colors[clr.Separator]              = cfgColor('separator')
    colors[clr.SeparatorHovered]       = cfgColor('button_hovered')
    colors[clr.SeparatorActive]        = cfgColor('button_active')
    colors[clr.ResizeGrip]             = getAccentColor()
    colors[clr.ResizeGripHovered]      = cfgColor('button_hovered')
    colors[clr.ResizeGripActive]       = cfgColor('button_active')
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.70, 0.00, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

apply_style()

-- =========================
-- CUSTOM WIDGETS
-- =========================
function imgui.ToggleButton(str_id, v)
    local p = imgui.GetCursorScreenPos()
    local draw_list = imgui.GetWindowDrawList()
    local height = 20
    local width = 45
    local radius = height * 0.50

    local toggled = false
    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        v.v = not v.v
        toggled = true
        toggleAnim[str_id] = 1.0
    end
    local hovered = imgui.IsItemHovered()
    
    local col_bg = v.v and getAccentColor() or imgui.ImVec4(0.33, 0.33, 0.33, 1.0)
    if hovered then
        col_bg = imgui.ImVec4(math.min(col_bg.x + 0.06, 1.0), math.min(col_bg.y + 0.06, 1.0), math.min(col_bg.z + 0.06, 1.0), col_bg.w)
    end
    
    draw_list:AddRectFilled(
        p, 
        imgui.ImVec2(p.x + width, p.y + height), 
        imgui.ColorConvertFloat4ToU32(col_bg), 
        height * 0.5
    )
    
    local circle_x = v.v and (p.x + width - radius) or (p.x + radius)
    local scale = 1.0
    local anim = toggleAnim[str_id] or 0.0
    if anim > 0.0 then
        scale = 1.0 + 0.2 * anim
        toggleAnim[str_id] = math.max(0.0, anim - 0.12)
    elseif hovered then
        scale = 1.08
    end
    draw_list:AddCircleFilled(
        imgui.ImVec2(circle_x, p.y + radius), 
        (radius - 1.5) * scale, 
        0xFFFFFFFF
    )
    return toggled
end

-- =========================
-- MAIN
-- =========================
function main()
    repeat wait(0) until isSampAvailable()

    if doesFileExist("moonloader/resource/lux_logo.png") then
        logoTexture = imgui.CreateTextureFromFile("moonloader/resource/lux_logo.png")
    end
    if doesFileExist("moonloader/resource/music.mp3") then
        audioStream = loadAudioStream("moonloader/resource/music.mp3")
    end
    if doesFileExist("moonloader/resource/logo_lux2.png") then
        splashTexture = imgui.CreateTextureFromFile("moonloader/resource/logo_lux2.png")
    end
    
    -- Create Font for Textdraw
    tdFont = renderCreateFont("Arial", 10, 5) -- 5 = FCR_BORDER

    registerMenuCommand(cfg.settings.menu_cmd or "lux")

    sampRegisterChatCommand("scripter", function(arg)
        if arg == editPassword then
            isEditMode = not isEditMode
            if isEditMode then
                setMenu(true)
            else
                saveLayout()
            end
        else
            sampAddChatMessage(T("msg_prefix") .. T("DebugMode"), -1)
        end
    end)
    
    sampRegisterChatCommand("debugaudio", debugAudioCmd)
    sampRegisterChatCommand("reloadaudio", function()
        if audioStream then
            setAudioStreamState(audioStream, 0)
            audioStream = nil
        end
        if doesFileExist("moonloader/resource/music.mp3") then
            audioStream = loadAudioStream("moonloader/resource/music.mp3")
            if audioStream then
                sampAddChatMessage(T("msg_prefix") .. "Audio reloaded successfully!", -1)
            else
                sampAddChatMessage(T("msg_prefix") .. "Failed to load audio stream.", -1)
            end
        else
            sampAddChatMessage(T("msg_prefix") .. "Audio file missing.", -1)
        end
    end)

    local commands = {
        st = "/stats",
        sp = "/spawnchange",
        tp = "/towpoints", 
        gj = "/getjob", 
        cmb = "/clanmembers", 
        mb = "/members", 
        kc = "/killcp", 
        cf = "/cancel find", 
        ra = "/raport", 
        sa = "/stopanim", 
        ha = "/heal", 
        notf = "/notifications"
    }

    for cmd, chatCmd in pairs(commands) do
        sampRegisterChatCommand(cmd, function()
            if not modEnabled.v or not commandsEnabled.v then
                sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
                return
            end
            sampSendChat(chatCmd)
        end)
    end

    lua_thread.create(menuKeyLoop)

    sampRegisterChatCommand("ls", cmdls)
    sampRegisterChatCommand("lv", cmdlv)
    sampRegisterChatCommand("sf", cmdsf)

    sampRegisterChatCommand("dt", cmddt)
    sampRegisterChatCommand("att", cmdatt)
    sampRegisterChatCommand("mmc", cmdmmc)
    sampRegisterChatCommand("gk", cmdgk)
    sampRegisterChatCommand("atk", cmdatk)
    sampRegisterChatCommand("afvr", cmdafvr)
    sampRegisterChatCommand("sfvr", cmdsfvr)
    registerCustomCommands()

    sampRegisterChatCommand("rrtt", cmdrrtt)
    sampRegisterChatCommand("rrall", cmdrrall)
    sampRegisterChatCommand("ttme", cmdttme)
    sampRegisterChatCommand("ttrr", cmdttrr)
    sampRegisterChatCommand("ume", cmdume)
    sampRegisterChatCommand("urr", cmdurr)
    sampRegisterChatCommand("at", cmdat)
    sampRegisterChatCommand("srr", cmdsrr)
    sampRegisterChatCommand("skit", cmdskit)
    sampRegisterChatCommand("ms", cmdms)
    sampRegisterChatCommand("salut", cmdSalut)
    sampRegisterChatCommand("welcome", cmdwelcome)
    sampRegisterChatCommand("sal", cmdsal)
    sampRegisterChatCommand("nb", cmdnb)
    sampRegisterChatCommand("cvrr", cmdCVR)
    sampRegisterChatCommand("mycc", cmdmycc)
    sampRegisterChatCommand("gkit", cmdgkit)
    lua_thread.create(autoRepairLoop)

    sampAddChatMessage(string.format(T("msg_prefix") .. T("msg_welcome2"), cfg.settings.menu_cmd), -1)
    if cfg.settings.update_auto_check then
        lua_thread.create(function()
            wait(1500)
            checkUpdateOnce()
        end)
    end
    
    if cfg.settings.start == 0 then
        lua_thread.create(function()
            wait(2000) -- Wait a bit to ensure player is spawned/connected
            local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local name = sampGetPlayerNickname(id)
            local cmd = cfg.settings.menu_cmd
            
            if result then
                sampAddChatMessage(string.format(T("msg_prefix") .. T("msg_first_run"), name, id, cmd), -1)
                
                cfg.settings.start = 1
                inicfg.save(cfg, "TTC.ini")
            end
        end)
    end
    
    while true do
        wait(0)
        
        -- Handle Keys
        if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            if cfg.settings.tow_ls_enabled and cfg.settings.tow_ls_key > 0 and wasKeyPressed(cfg.settings.tow_ls_key) then
                sampAddChatMessage(T("msg_tow_ls"), -1)
                sampSendChat("/tow ls")
            end
            if cfg.settings.tow_lv_enabled and cfg.settings.tow_lv_key > 0 and wasKeyPressed(cfg.settings.tow_lv_key) then
                sampAddChatMessage(T("msg_tow_lv"), -1)
                sampSendChat("/tow lv")
            end
            if cfg.settings.tow_sf_enabled and cfg.settings.tow_sf_key > 0 and wasKeyPressed(cfg.settings.tow_sf_key) then
                sampAddChatMessage(T("msg_tow_sf"), -1)
                sampSendChat("/tow sf")
            end
            if cfg.settings.at_enabled and cfg.settings.at_key > 0 and wasKeyPressed(cfg.settings.at_key) then
                sampSendChat("/s " .. T("at_tractez1"))
                sampSendChat("/s " .. T("at_tractez2"))
            end
            if cfg.settings.repair_refill_enabled and cfg.settings.repair_refill_key > 0 and wasKeyPressed(cfg.settings.repair_refill_key) then
                processService("repair_refill")
            end
            if cfg.settings.sellkit_enabled and cfg.settings.sellkit_key > 0 and wasKeyPressed(cfg.settings.sellkit_key) then
                processService("sellkit")
            end
            if cfg.settings.repair_refill_me_enabled and cfg.settings.repair_refill_me_key > 0 and wasKeyPressed(cfg.settings.repair_refill_me_key) then
                if isCharInAnyCar(PLAYER_PED) then
                    sampSendChat("/repair")
                    lua_thread.create(function()
                        wait(500)
                        sampSendChat("/refill")
                    end)
                else
                    sampAddChatMessage(T("msg_prefix") .. T("msg_not_in_veh"), -1)
                end
            end
        end
        
        -- Render Textdraw
        if cfg.settings.textdraw_enabled and tdFont then
            local lines = {}
            -- table.insert(lines, T("td_title")) -- Optional Header
            
            if cfg.settings.tow_ls_enabled then table.insert(lines, T("tow_ls")) end
            if cfg.settings.tow_lv_enabled then table.insert(lines, T("tow_lv")) end
            if cfg.settings.tow_sf_enabled then table.insert(lines, T("tow_sf")) end
            if cfg.settings.at_enabled then table.insert(lines, T("at_tractez1")) end
            if cfg.settings.repair_refill_enabled then table.insert(lines, T("repair_refill")) end
            if cfg.settings.sellkit_enabled then table.insert(lines, T("sell_kit")) end
            if cfg.settings.repair_refill_me_enabled then table.insert(lines, T("repair_refill_me")) end
            
            if #lines > 0 then
                local sw, sh = getScreenResolution()
                local x = sw - 10
                local y = sh - 31 - (#lines * 15)
                
                for i, line in ipairs(lines) do
                    local width = renderGetFontDrawTextLength(tdFont, line)
                    -- Right align: x - width
                    renderFontDrawText(tdFont, line, x - width, y + (i-1)*15, 0xFFFFFFFF)
                end
            end
        end
    end
end

-- =========================
-- LOGIC: Repair/Refill/SellKit
-- =========================
local sellkitState = {
    active = false,
    targetId = -1,
    lastType = '',
    triedFuel = false,
    triedRepair = false,
    kitfuel = 0,
    kitrepair = 0,
    startedAt = 0
}

function processService(type)
    local maxDist = 15.0
    local closestId = -1
    local closestDist = maxDist
    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)

    local myVeh = 0
    if isCharInAnyCar(PLAYER_PED) then
        myVeh = storeCarCharIsInNoSave(PLAYER_PED)
    end

    for i = 0, 1000 do
        if sampIsPlayerConnected(i) then
            local result, char = sampGetCharHandleBySampPlayerId(i)
            if result and doesCharExist(char) and char ~= PLAYER_PED then
                local skip = false
                if myVeh ~= 0 and isCharInAnyCar(char) then
                    local veh = storeCarCharIsInNoSave(char)
                    if veh == myVeh then
                        skip = true
                    end
                end

                if not skip then
                    local x, y, z = getCharCoordinates(char)
                    local dist = getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z)
                    if dist < closestDist then
                        closestDist = dist
                        closestId = i
                    end
                end
            end
        end
    end

    if closestId == -1 then
        sampAddChatMessage(T("msg_prefix") .. T("msg_no_player"), -1)
        return
    end

    local color = sampGetPlayerColor(closestId)
    local rgb = bit.band(color, 0xFFFFFF) 

    if rgb == 0xAA3333 then
        sampAddChatMessage(T("msg_prefix") .. T("msg_hitman"), -1)
        return
    end

    local price = 50
    local kitrepair = 4000
    local kitfuel = 8000
    if rgb == 0xF5DEB3 then price = 1 end

    if type == "repair_refill" then
        local result, char = sampGetCharHandleBySampPlayerId(closestId)
        if result then
            if not isCharInAnyCar(char) then
                sampAddChatMessage(T("msg_prefix") .. T("msg_target_no_veh"), -1)
                return
            end
        end
        sampSendChat("/repair " .. closestId .. " " .. price)
        lua_thread.create(function()
            wait(500)
            sampSendChat("/refill " .. closestId .. " " .. price)
        end)
    elseif type == "sellkit" then
        sellkitState.active = true
        sellkitState.targetId = closestId
        sellkitState.lastType = 'fuel'
        sellkitState.triedFuel = true
        sellkitState.triedRepair = false
        sellkitState.kitfuel = kitfuel
        sellkitState.kitrepair = kitrepair
        sellkitState.startedAt = os.clock()
        sampSendChat("/sellkit " .. closestId .. " fuel " .. kitfuel)

        lua_thread.create(function()
            wait(800)
            if sellkitState.active and not sellkitState.triedRepair then
                 sellkitState.triedRepair = true
                 sellkitState.lastType = 'repair'
                 sampSendChat("/sellkit " .. sellkitState.targetId .. " repair " .. sellkitState.kitrepair)
            end
        end)
    end
end

-- =========================
-- MENU
-- =========================
function setMenu(state)
    showMenu.v = state
    imgui.Process = state
    sampSetCursorMode(state)

    if audioStream then
        local vol = tonumber(cfg.settings.music_volume) or 50
        local enabled = cfg.settings.music_enabled
        -- sampAddChatMessage(string.format("DEBUG: setMenu state=%s enabled=%s vol=%s", tostring(state), tostring(enabled), tostring(vol)), -1)
        
        if state and enabled then
            setAudioStreamState(audioStream, 1) -- Play
            local finalVol = vol / 100.0
            if finalVol < 0.0 then finalVol = 0.0 end
            if finalVol > 1.0 then finalVol = 1.0 end
            setAudioStreamVolume(audioStream, finalVol)
            -- sampAddChatMessage("DEBUG: Playing music at volume " .. tostring(finalVol), -1)
        else
            setAudioStreamState(audioStream, 0) -- Stop
        end
    else
        -- sampAddChatMessage("DEBUG: audioStream is nil in setMenu", -1)
    end
end

function debugAudioCmd()
    if audioStream then
        local state = getAudioStreamState(audioStream)
        sampAddChatMessage("DEBUG CMD: Stream State: " .. tostring(state), -1)
        setAudioStreamState(audioStream, 1)
        setAudioStreamVolume(audioStream, 1.0)
        sampAddChatMessage("DEBUG CMD: Forced Play & Vol 1.0 (Max)", -1)
    else
        sampAddChatMessage("DEBUG CMD: No audio stream loaded", -1)
    end
end

function toggleMenu()
    if not showMenu.v and (cfg.settings.start == 0 or cfg.settings.loading_screen_enabled) then
        openMenuAfterSplash = true
        showSplash.v = true
        splashStartClock = os.clock()
        imgui.Process = true
        return
    end
    setMenu(not showMenu.v)
end

function registerMenuCommand(alias)
    local cmd = tostring(alias or "lux"):gsub('^%s*/',''):match('^%S+') or 'lux'
    if not menuRegistered[cmd] then
        sampRegisterChatCommand(cmd, toggleMenu)
        menuRegistered[cmd] = true
    end
end

function menuKeyLoop()
    while true do
        wait(50)
        if cfg.settings.menu_key_enabled and (cfg.settings.menu_open_key or 0) > 0 then
            if wasKeyPressed(cfg.settings.menu_open_key) then
                toggleMenu()
            end
        end
    end
end
function registerCustomCommands()
    for i = 1, 10 do
        local active = cfg.settings['custom'..i..'_active']
        local alias = tostring(cfg.settings['custom'..i..'_alias'] or '')
        local text = tostring(cfg.settings['custom'..i..'_text'] or '')
        if active and alias ~= '' and text ~= '' then
            local cmd = alias:gsub('^%s*/', ''):match('^%S+') or ''
            if not customHandlers[cmd] then
                sampRegisterChatCommand(cmd, function(param)
                    if not modEnabled.v or not commandsEnabled.v or not cfg.settings.custom_enabled then
                        sampAddChatMessage(T('msg_prefix') .. T('msg_cmd_disabled'), -1)
                        return
                    end
                    local used = ''
                    for j = 1, 10 do
                        local a = tostring(cfg.settings['custom'..j..'_alias'] or '')
                        local c = a:gsub('^%s*/',''):match('^%S+') or ''
                        if c == cmd and cfg.settings['custom'..j..'_active'] then
                            used = tostring(cfg.settings['custom'..j..'_text'] or '')
                            break
                        end
                    end
                    if used ~= '' then sampSendChat(used) end
                end)
                customHandlers[cmd] = true
            end
        end
    end
end

-- =========================
-- IMGUI DRAW
-- =========================
local menuPos = imgui.ImVec2(300, 200)
local menuWidth = 800
local menuHeight = 500

function imgui.OnDrawFrame()
    if showSplash.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(650, 350), imgui.Cond.Always)
        imgui.Begin(T("splash_title"), showSplash, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)


            local windowWidth = imgui.GetWindowWidth()
            local windowHeight = imgui.GetWindowHeight()
            local draw_list = imgui.GetWindowDrawList()
            local p = imgui.GetCursorScreenPos()
            local style = imgui.GetStyle()
            local contentW = windowWidth - style.WindowPadding.x * 2
            local contentH = windowHeight - style.WindowPadding.y * 2

            if splashTexture then
                draw_list:AddImage(splashTexture, imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + contentW, p.y + contentH))
            else
                draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + contentW, p.y + contentH), 0xFF101010)
            end

            local barH = 20
            local barW = math.floor(contentW * 0.8)
            local barX = p.x + math.floor((contentW - barW) * 0.5)
            local barY = p.y + contentH - barH - 20
            local bgCol = 0xFF333333
            local fgCol = imgui.ColorConvertFloat4ToU32(getAccentColor())

            draw_list:AddRectFilled(imgui.ImVec2(barX, barY), imgui.ImVec2(barX + barW, barY + barH), bgCol, 8)

            -- Actualizează progresul pe baza timpului
            local elapsed = os.clock() - (splashStartClock or os.clock())
            splashProgress = math.min(1.0, elapsed / 2.0)
            local fillW = math.floor(barW * splashProgress)
            draw_list:AddRectFilled(imgui.ImVec2(barX, barY), imgui.ImVec2(barX + fillW, barY + barH), fgCol, 8)

            local loading_text = T("loading")
            local text_size = imgui.CalcTextSize(loading_text)
            local tx = p.x + (windowWidth - text_size.x) * 0.5
            local ty = barY + barH + 5
            draw_list:AddText(imgui.ImVec2(tx, ty), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1,1,1,1)), loading_text)

        imgui.End()

        if splashProgress >= 1.0 then
            cfg.settings.start = 1
            inicfg.save(cfg, "TTC.ini")
            showSplash.v = false
            if openMenuAfterSplash then
                openMenuAfterSplash = false
                setMenu(true)
            end
        end
        return
    end
    if showUpdateDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(520, 280), imgui.Cond.Always)
        imgui.Begin(T("update_available"), showUpdateDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.Text(string.format("%s: %s", T("current_version"), LOCAL_VERSION))
        imgui.Text(string.format("%s: %s", T("online_version"), tostring(updateInfo.version_online or "?")))
        imgui.Separator()
        imgui.Text(string.format("%s:", T("reason_ro")))
        imgui.TextWrapped(updateInfo.reason_ro or "-")
        imgui.Spacing()
        imgui.Text(string.format("%s:", T("reason_en")))
        imgui.TextWrapped(updateInfo.reason_en or "-")
        imgui.Spacing()
        if imgui.Button(T("download_now"), imgui.ImVec2(-1, 35)) then
            if SCRIPT_URL ~= "" then
                local ok = downloadUrlToFile(SCRIPT_URL, thisScript().path)
                if ok then
                    sampAddChatMessage(T("msg_prefix") .. "Update descarcat. Scriptul se reincarca...", -1)
                    lua_thread.create(function()
                        wait(1000)
                        thisScript():reload()
                    end)
                else
                    sampAddChatMessage(T("msg_prefix") .. "Eroare la descarcare.", -1)
                end
            end
            showUpdateDialog.v = false
            if not showMenu.v then
                imgui.Process = false
                sampSetCursorMode(false)
            end
        end
        imgui.Spacing()
        if imgui.Button(T("later"), imgui.ImVec2(-1, 30)) then
            showUpdateDialog.v = false
            if not showMenu.v then
                imgui.Process = false
                sampSetCursorMode(false)
            end
        end
        imgui.End()
        return
    end
    if showKeyDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 200), imgui.Cond.Always)
        
        imgui.Begin(T("key_dialog_title"), showKeyDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        
        imgui.TextWrapped(T("key_dialog_msg") .. ": " .. (waitingForKey or "???"):upper():gsub("_", " "))
        imgui.Spacing()
        imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), T("press_key"))
        
        if waitingForKey then
            for k = 1, 255 do
                if wasKeyPressed(k) then
                    if k ~= 1 and k ~= 2 then 
                        cfg.settings[waitingForKey .. '_key'] = k
                        inicfg.save(cfg, "TTC.ini")
                        showKeyDialog.v = false
                        waitingForKey = nil
                        break
                    end
                end
            end
        end
        
        if imgui.Button(T("cancel"), imgui.ImVec2(-1, 30)) then
            showKeyDialog.v = false
            waitingForKey = nil
        end
        
        imgui.End()
        return 
    end

    if showFvrDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(520, 260), imgui.Cond.Always)
        imgui.Begin(T("fvr_settings_title"), showFvrDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

            -- Buffere inițiale
            if fvrBuffers.start.v == "" and fvrBuffers.final.v == "" and fvrBuffers.cancel.v == "" then
                fvrBuffers.start.v = tostring(cfg.settings.fvr_text_f or "")
                fvrBuffers.final.v = tostring(cfg.settings.fvr_text_final or "")
                fvrBuffers.cancel.v = tostring(cfg.settings.fvr_text_sfvr or "")
                fvrBuffers.seconds.v = tonumber(cfg.settings.fvr_seconds or 10)
            end

            imgui.Text(T("fvr_text_f_label"))
            imgui.PushItemWidth(-1)
            imgui.InputText("##fvrstart", fvrBuffers.start)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_text_final_label"))
            imgui.PushItemWidth(-1)
            imgui.InputText("##fvrfinal", fvrBuffers.final)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_text_sfvr_label"))
            imgui.PushItemWidth(-1)
            imgui.InputText("##fvrcancel", fvrBuffers.cancel)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_seconds_label"))
            imgui.PushItemWidth(100)
            imgui.InputInt("##fvrsec", fvrBuffers.seconds)
            imgui.PopItemWidth()

            imgui.Spacing()
            if imgui.Button(T("save"), imgui.ImVec2(120, 30)) then
                cfg.settings.fvr_text_f = fvrBuffers.start.v
                cfg.settings.fvr_text_final = fvrBuffers.final.v
                cfg.settings.fvr_text_sfvr = fvrBuffers.cancel.v
                cfg.settings.fvr_seconds = fvrBuffers.seconds.v
                inicfg.save(cfg, "TTC.ini")
                showFvrDialog.v = false
            end
            imgui.SameLine()
            if imgui.Button(T("close"), imgui.ImVec2(120, 30)) then
                showFvrDialog.v = false
            end

        imgui.End()
        return
    end

    if showCustomDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 330), imgui.Cond.Always)
        imgui.Begin(T("custom_cmds"), showCustomDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

            for i = 1, 10 do
                imgui.PushID(i)
                if imgui.Checkbox("##active"..i, customBuffers[i].active) then end
                imgui.SameLine()
                imgui.PushItemWidth(120)
                imgui.InputText("Alias##"..i, customBuffers[i].alias)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(-1)
                imgui.InputText("Text##"..i, customBuffers[i].text)
                imgui.PopItemWidth()
                imgui.PopID()
            end

            imgui.Spacing()
            if imgui.Button(T("save"), imgui.ImVec2(120, 30)) then
                for i = 1, 10 do
                    cfg.settings['custom'..i..'_active'] = customBuffers[i].active.v
                    cfg.settings['custom'..i..'_alias'] = customBuffers[i].alias.v
                    cfg.settings['custom'..i..'_text'] = customBuffers[i].text.v
                end
                inicfg.save(cfg, "TTC.ini")
                registerCustomCommands()
                showCustomDialog.v = false
            end
            imgui.SameLine()
            if imgui.Button(T("close"), imgui.ImVec2(120, 30)) then
                showCustomDialog.v = false
            end

        imgui.End()
        return
    end

    if not showMenu.v then return end

    imgui.SetNextWindowPos(menuPos, imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(menuWidth, menuHeight), imgui.Cond.FirstUseEver)
    
    imgui.Begin("Team of Luxury", showMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
    
    local p = imgui.GetCursorScreenPos()
    local windowWidth = imgui.GetWindowWidth()
    local windowHeight = imgui.GetWindowHeight()
    local draw_list = imgui.GetWindowDrawList()

    -- aici modifici pozitia la butoane
    local leftPaneWidth = 180
    local navButtonWidth = 160
    local navButtonHeight = 40
    local navBottomMargin = 50
    local spacingY = imgui.GetStyle().ItemSpacing.y

    -- aici modifici pozitia la logo
    local logoTop = 30
    local logoWidth = 140
    local logoHeight = 90

    draw_list:AddRectFilled(p, imgui.ImVec2(p.x + leftPaneWidth, p.y + windowHeight), 0xFF141414) 

    ImMovable("logo_group", function()
        imgui.BeginGroup()
            local xLogo = (leftPaneWidth - logoWidth) / 2
            imgui.SetCursorPos(imgui.ImVec2(xLogo, logoTop))
            if logoTexture then
                imgui.Image(logoTexture, imgui.ImVec2(logoWidth, logoHeight))
            else
                imgui.TextColored(getAccentColor(), "LUXURY")
                imgui.Text("MODPACK")
            end
        imgui.EndGroup()
    end)

    -- Aici setezi pozitia pe inaltime (Y) pentru fiecare buton in parte
    local btnMainY = 160
    local btnInfoY = 210
    local btnSettingsY = 260
    
    local xLeft = (leftPaneWidth - navButtonWidth) / 2

    -- Buton MAIN
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnMainY))
    ImMovable("nav_main", function()
        if imgui.Button(T("main"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 1 end
    end)

    -- Buton INFO
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnInfoY))
    ImMovable("nav_info", function()
        if imgui.Button(T("info"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 2 end
    end)

    -- Buton SETTINGS
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnSettingsY))
    ImMovable("nav_settings", function()
        if imgui.Button(T("settings"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 4 end
    end)

    imgui.SetCursorPos(imgui.ImVec2(xLeft, windowHeight - navBottomMargin))
    ImMovable("btn_close", function()
        if imgui.Button(T("close"), imgui.ImVec2(navButtonWidth, 30)) then
            setMenu(false)
        end
    end)

    imgui.SetCursorPos(imgui.ImVec2(200, 20))
    imgui.BeginChild("Content", imgui.ImVec2(windowWidth - 220, windowHeight - 40), true)
        
        if activeTab == 1 then
            -- MAIN TAB
            imgui.TextColored(getAccentColor(), T("luxury_settings"))
            imgui.Separator()
            imgui.Spacing()

            imgui.Columns(2, "settings_cols", false)
            
            ImMovable("lbl_global_mod", function()
                imgui.Text(T("global_mod"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_global_mod", function()
                imgui.ToggleButton("##mod", modEnabled)
            end)
            
            imgui.Spacing()
            
            ImMovable("lbl_auto_repair", function()
                imgui.Text(T("auto_repair"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_auto_repair", function()
                imgui.ToggleButton("##repair", repairEnabled)
            end)

            imgui.NextColumn()
            
            ImMovable("lbl_engine", function()
                imgui.Text(T("auto_engine"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_engine", function()
                imgui.ToggleButton("##engine", engineEnabled)
            end)
            
            imgui.Spacing()
            
            ImMovable("lbl_cmds", function()
                imgui.Text(T("fast_cmds"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_cmds", function()
                imgui.ToggleButton("##cmds", commandsEnabled)
            end)
            
            imgui.Columns(1)
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- FVR & Custom toggles
            -- Variabile pentru pozitionare butoane FVR si Custom
            local fvrSettingsBtnX = 300
            local customSettingsBtnX = 300
            
            ImMovable("lbl_fvr", function()
                imgui.Text(T("fvr"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(300)
            local fvrEn = imgui.ImBool(cfg.settings.fvr_enabled)
            ImMovable("tgl_fvr", function()
                if imgui.ToggleButton("##fvr_toggle", fvrEn) then
                    cfg.settings.fvr_enabled = fvrEn.v
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            imgui.SameLine()
            
            -- Setare pozitie buton Settings FVR
            -- imgui.SetCursorPosX(fvrSettingsBtnX) -- Decomenteaza daca vrei pozitie absoluta X
            ImMovable("btn_fvr_set", function()
                if imgui.Button("Settings", imgui.ImVec2(120, 25)) then
                    fvrBuffers.start.v = tostring(cfg.settings.fvr_text_f or "")
                    fvrBuffers.final.v = tostring(cfg.settings.fvr_text_final or "")
                    fvrBuffers.cancel.v = tostring(cfg.settings.fvr_text_sfvr or "")
                    fvrBuffers.seconds.v = tonumber(cfg.settings.fvr_seconds or 10)
                    showFvrDialog.v = true
                end
            end)

            imgui.Spacing()
            ImMovable("lbl_custom", function()
                imgui.Text(T("custom_cmds"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(300)
            local custEn = imgui.ImBool(cfg.settings.custom_enabled)
            ImMovable("tgl_custom", function()
                if imgui.ToggleButton("##custom_toggle", custEn) then
                    cfg.settings.custom_enabled = custEn.v
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            imgui.SameLine()
            
            -- Setare pozitie buton Settings Custom
            -- imgui.SetCursorPosX(customSettingsBtnX) -- Decomenteaza daca vrei pozitie absoluta X
            ImMovable("btn_custom_set", function()
                if imgui.Button("Settings##custom", imgui.ImVec2(120, 25)) then
                    for i = 1, 10 do
                        customBuffers[i].active.v = not not cfg.settings['custom'..i..'_active']
                        customBuffers[i].alias.v = tostring(cfg.settings['custom'..i..'_alias'] or '')
                        customBuffers[i].text.v = tostring(cfg.settings['custom'..i..'_text'] or '')
                    end
                    showCustomDialog.v = true
                end
            end)

            ImMovable("header_tow", function()
                imgui.TextColored(getAccentColor(), T("tow_truck_settings"))
            end)
            imgui.Separator()
            imgui.Spacing()

            local function DrawTowOption(label, key_prefix, info_text)
                imgui.PushID(key_prefix)
                local enabled = imgui.ImBool(cfg.settings[key_prefix .. '_enabled'])
                
                ImMovable("lbl_" .. key_prefix, function()
                    imgui.Text(label)
                end)
                
                imgui.SameLine()
                
                -- Pozitie Toggle Button
                imgui.SetCursorPosX(300) 
                ImMovable("tgl_" .. key_prefix, function()
                    if imgui.ToggleButton("##toggle", enabled) then
                        cfg.settings[key_prefix .. '_enabled'] = enabled.v
                        inicfg.save(cfg, "TTC.ini")
                    end
                end)
                
                imgui.SameLine()
                
                -- Pozitie Buton Key (modifica offset-ul sau pune SetCursorPosX)
                -- imgui.SetCursorPosX(350) 
                local k = cfg.settings[key_prefix .. '_key']
                local key_name = (k > 0) and (vkeys.id_to_name(k) or tostring(k)) or "NONE"
                
                ImMovable("key_" .. key_prefix, function()
                    if imgui.Button(T("key") .. ": " .. key_name, imgui.ImVec2(120, 25)) then
                        waitingForKey = key_prefix
                        showKeyDialog.v = true
                    end
                end)
                
                imgui.SameLine()
                ImMovable("help_" .. key_prefix, function()
                    imgui.TextDisabled("(?)")
                end)
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(info_text)
                end
                imgui.PopID()
                imgui.Spacing()
            end

            DrawTowOption(T("tow_ls"), "tow_ls", T("desc_ls"))
            DrawTowOption(T("tow_lv"), "tow_lv", T("desc_lv"))
            DrawTowOption(T("tow_sf"), "tow_sf", T("desc_sf"))
            DrawTowOption(T("at_tractez1"), "at", T("desc_at"))
            DrawTowOption(T("repair_refill"), "repair_refill", T("desc_rr"))
            DrawTowOption(T("sell_kit"), "sellkit", T("desc_sk"))
            DrawTowOption(T("repair_refill_me"), "repair_refill_me", T("desc_rrme"))

        elseif activeTab == 2 then
            -- INFO TAB
                local function TextColoredCentered(id, col, text)
                    ImMovable(id, function()
                        local windowWidth = imgui.GetWindowSize().x
                        local textSize = imgui.CalcTextSize(text)
                        imgui.SetCursorPosX((windowWidth - textSize.x) / 2)
                        imgui.TextColored(col, text)
                    end)
                end

                TextColoredCentered("info_rules_title", getAccentColor(), T("rules_title"))
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()

                local lines = {
                    T("rule1"), T("rule2"), T("rule3"), T("rule4"), T("rule5"),
                    T("rule6"), T("rule7"), T("rule8"), T("rule9"), T("rule10"),
                    T("rule11"), T("rule12"), T("rule13"), T("rule14"), T("rule15"),
                    T("rule16"), T("rule17"), T("rule18"), T("rule19"), T("rule20"),
                }

                local fixedColor = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)

                for i, line in ipairs(lines) do
                    ImMovable("info_rule_" .. i, function()
                        imgui.TextColored(fixedColor, line)
                    end)
                end

                -- Spațiu + separator între seturi
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()

                -- Al doilea set de reguli
                TextColoredCentered("info_srules_title", getAccentColor(), T("srules_title"))
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()

                local s_lines = {
                    T("srule1"), T("srule2"), T("srule3"), T("srule4"), T("srule5"),
                    T("srule6"), T("srule7"), T("srule8"), T("srule9"), T("srule10"),
                    T("srule11"), T("srule12"), T("srule13"), T("srule14"), T("srule15"),
                }

                for i, line in ipairs(s_lines) do
                    ImMovable("info_srule_" .. i, function()
                        imgui.TextColored(fixedColor, line)
                    end)
                end

                -- Spațiu final
                imgui.Spacing()
                imgui.Separator()
            
            -- Variabile pozitie butoane INFO
            local infoBtnX = 20 
            
            ImMovable("btn_forum", function()
                if imgui.Button("Forum", imgui.ImVec2(-1, 30)) then
                     os.execute("start https://forum.b-zone.ro/profile/122529-georgevp/")
                end
            end)
            ImMovable("btn_discord", function()
                if imgui.Button("Discord George_VP", imgui.ImVec2(-1, 30)) then
                     os.execute("start https://discord.com/users/304567478846095361")
                end
            end)

        elseif activeTab == 3 then
            -- RULES TAB
            ImMovable("lbl_rules_header", function()
                imgui.TextColored(getAccentColor(), T("rules"))
            end)
            imgui.Separator()
            imgui.Spacing()
            ImMovable("txt_rules_desc", function()
                imgui.TextWrapped(T("see_rules"))
            end)
            ImMovable("btn_rules_browser", function()
                if imgui.Button(T("open_browser"), imgui.ImVec2(-1, 30)) then
                    os.execute("start https://www.rpg.b-zone.ro/factions/rules/tow-truck-company")
                end
            end)

        elseif activeTab == 4 then
            -- SETTINGS TAB
            ImMovable("lbl_lang_settings", function()
                imgui.TextColored(getAccentColor(), T("lang_settings"))
            end)
            imgui.Separator()
            ImMovable("lbl_choose_lang", function()
                imgui.Text(T("choose_lang"))
            end)
            ImMovable("radio_ro", function()
                if imgui.RadioButton("Romana", cfg.settings.language == 0) then
                    cfg.settings.language = 0
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            imgui.SameLine()
            ImMovable("radio_en", function()
                if imgui.RadioButton("English", cfg.settings.language == 1) then
                    cfg.settings.language = 1
                    inicfg.save(cfg, "TTC.ini")
                end
            end)

            imgui.Spacing()

            ImMovable("lbl_audio_settings", function()
                imgui.TextColored(getAccentColor(), "AUDIO SETTINGS")
            end)
            imgui.Separator()
            
            ImMovable("chk_audio", function()
                if imgui.Checkbox("Music Enabled", imgui.ImBool(cfg.settings.music_enabled)) then
                    cfg.settings.music_enabled = not cfg.settings.music_enabled
                    inicfg.save(cfg, "TTC.ini")
                    if audioStream then
                         if cfg.settings.music_enabled and showMenu.v then
                             setAudioStreamState(audioStream, 1)
                             setAudioStreamVolume(audioStream, cfg.settings.music_volume / 100.0)
                         else
                             setAudioStreamState(audioStream, 0)
                         end
                    end
                end
            end)
            
            ImMovable("slider_audio", function()
                local vol = imgui.ImInt(cfg.settings.music_volume)
                if imgui.SliderInt("Volume", vol, 0, 100) then
                    cfg.settings.music_volume = vol.v
                    inicfg.save(cfg, "TTC.ini")
                    if audioStream and cfg.settings.music_enabled and showMenu.v then
                        setAudioStreamVolume(audioStream, cfg.settings.music_volume / 100.0)
                    end
                end
            end)

            imgui.Spacing()

            ImMovable("lbl_td_settings", function()
                imgui.TextColored(getAccentColor(), T("textdraw_settings"))
            end)
            imgui.Separator()
            
            ImMovable("chk_textdraw", function()
                if imgui.Checkbox(T("enable_textdraw"), imgui.ImBool(cfg.settings.textdraw_enabled)) then
                    cfg.settings.textdraw_enabled = not cfg.settings.textdraw_enabled
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            
            ImMovable("chk_loading", function()
                if imgui.Checkbox(T("loading_screen"), imgui.ImBool(cfg.settings.loading_screen_enabled)) then
                    cfg.settings.loading_screen_enabled = not cfg.settings.loading_screen_enabled
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            
            ImMovable("chk_autoupdate", function()
                if imgui.Checkbox(T("auto_check_update"), imgui.ImBool(cfg.settings.update_auto_check)) then
                    cfg.settings.update_auto_check = not cfg.settings.update_auto_check
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            
            imgui.Spacing()
            ImMovable("btn_check_update", function()
                if imgui.Button(T("check_now"), imgui.ImVec2(150, 30)) then
                    checkUpdateOnce()
                end
            end)

            imgui.Spacing()
            ImMovable("lbl_menu_cmd", function()
                imgui.Text(T("menu_open_cmd"))
            end)
            local cmdBuf = imgui.ImBuffer(cfg.settings.menu_cmd, 32)
            ImMovable("input_menu_cmd", function()
                if imgui.InputText("##menucmd", cmdBuf) then
                    cfg.settings.menu_cmd = cmdBuf.v
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
            
            ImMovable("lbl_menu_key", function()
                 imgui.Text(T("menu_open_key"))
            end)
            local keyName = (cfg.settings.menu_open_key > 0) and (vkeys.id_to_name(cfg.settings.menu_open_key) or tostring(cfg.settings.menu_open_key)) or "NONE"
            ImMovable("btn_menu_key", function()
                if imgui.Button(keyName .. "##menukey", imgui.ImVec2(100, 25)) then
                    waitingForKey = "menu_open"
                    showKeyDialog.v = true
                end
            end)
            imgui.SameLine()
            ImMovable("chk_menu_key", function()
                if imgui.Checkbox("Active##menukey", imgui.ImBool(cfg.settings.menu_key_enabled)) then
                    cfg.settings.menu_key_enabled = not cfg.settings.menu_key_enabled
                    inicfg.save(cfg, "TTC.ini")
                end
            end)
        end
        
    imgui.EndChild()
    imgui.End()
end

-- =========================
-- AUTO REPAIR LOOP
-- =========================
function autoRepairLoop()
    local REPAIR_HP = 350
    local repairing = false
    while true do
        wait(800)
        if modEnabled.v and repairEnabled.v then
            if isCharInAnyCar(PLAYER_PED) and not repairing then
                local veh = storeCarCharIsInNoSave(PLAYER_PED)
                if veh ~= 0 and getCarHealth(veh) <= REPAIR_HP then
                    repairing = true
                    sampSendChat("/repair")
                end
            end
        else
            repairing = false
        end
    end
end

-- =========================
-- SERVER MESSAGES
-- =========================
function sampev.onServerMessage(_, text)
    if not text or not modEnabled.v then return end

    if sellkitState.active then
        if (os.clock() - (sellkitState.startedAt or 0)) > 5 then
            sellkitState.active = false
        else
            local fuelErr = "Eroare: Acest jucator are suficienta durabilitate ramasa pe kitul sau de combustibil."
            local repairErr = "Eroare: Acest jucator are suficienta durabilitate ramasa pe kitul sau de reparatie."

            if text:find(fuelErr, 1, true) and sellkitState.lastType == 'fuel' then
                local name = sampGetPlayerNickname(sellkitState.targetId) or "Player"
                sampAddChatMessage(T("msg_prefix") .. string.format("Jucatorul %s[%d] are suficienta durabilitate la kit-ul de combustibil.", name, sellkitState.targetId), -1)
                
                if not sellkitState.triedRepair then
                    sellkitState.triedRepair = true
                    sellkitState.lastType = 'repair'
                    lua_thread.create(function()
                        wait(200)
                        sampSendChat("/sellkit " .. sellkitState.targetId .. " repair " .. sellkitState.kitrepair)
                    end)
                else
                    sellkitState.active = false
                end
                return false
            end

            if text:find(repairErr, 1, true) and sellkitState.lastType == 'repair' then
                local name = sampGetPlayerNickname(sellkitState.targetId) or "Player"
                sampAddChatMessage(T("msg_prefix") .. string.format("Jucatorul %s[%d] are suficienta durabilitate la kit-ul de reparatie.", name, sellkitState.targetId), -1)

                if not sellkitState.triedFuel then
                    sellkitState.triedFuel = true
                    sellkitState.lastType = 'fuel'
                    lua_thread.create(function()
                        wait(200)
                        sampSendChat("/sellkit " .. sellkitState.targetId .. " fuel " .. sellkitState.kitfuel)
                    end)
                else
                    sellkitState.active = false
                end
                return false
            end
        end
    end

    if repairEnabled.v then
        if text:find("Nu esti mecanic") then
            lua_thread.create(function()
                wait(300)
                sampSendChat("/switchjob")
                wait(1200)
                sampSendChat("/repair")
            end)
        end
        if text:find("Opreste motorul") then
            lua_thread.create(function()
                wait(300)
                sampSendChat("/engine")
                wait(700)
                sampSendChat("/repair")
            end)
        end
        if text:find(T("msg_prefix") .. "Nu ai destula durabilitate!") then
            repairEnabled.v = false
            sampAddChatMessage(T("msg_prefix") .. T("ar_disabled_kit"), -1)
        end
    end

    if engineEnabled.v then
        if text:find("Scrie /engine") then
            sampSendChat("/engine")
        end
    end
end

-- =========================
-- COMMANDS
-- =========================
function cmdms(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. "/ms ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    local name = sampGetPlayerNickname(id)
    local msg
    if cfg.settings.language == 1 then
        msg = string.format("Thank you, %s[%d], for using Tow Truck Company services!", name, id)
    else
        msg = string.format("Multumim, %s[%d], pentru ca folosesti serviciile Tow Truck Company!", name, id)
    end
    sampSendChat("" .. msg)
end

function cmdSalut(param)
    if not modEnabled.v or not commandsEnabled.v then return end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. "/salut ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("Salut %s[%d]!", sampGetPlayerNickname(id), id))
end

function cmdwelcome(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. "/welcome ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("Bun venit in familia Team of Luxury, %s[%d]!", sampGetPlayerNickname(id), id))
end

function cmdsal(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampSendChat("/c Salut!")
    sampSendChat("/ac Salutare!")
    sampSendChat("/f Salut!")
end

function cmdnb(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampSendChat("/c Noapte buna!")
    sampSendChat("/ac Noapte buna!!")
    sampSendChat("/f Noapte buna!")
end

function cmdCVR(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampSendChat("/c ATENTIE, Vehiculele revin in 5 secunde.")
    lua_thread.create(function()
        wait(5000)
        sampSendChat("/cvr")
        sampSendChat("/c Done.")
    end)
end

-- =========================
-- UTILS
-- =========================


function cmdmycc(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampAddChatMessage(T("msg_prefix") .. T("chat_clear"), -1)
    lua_thread.create(function()
        wait(1000)
        for i = 1, 15 do sampAddChatMessage(" ", -1) end
    end)
end

function cmdls(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampAddChatMessage(T("msg_prefix") .. T("msg_tow_ls"), -1)
    lua_thread.create(function()
        wait(100)
        sampSendChat("/tow ls") 
    end)
end

function cmdlv(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampAddChatMessage(T("msg_prefix") .. T("msg_tow_lv"), -1)
    lua_thread.create(function()
        wait(100)
        sampSendChat("/tow lv") 
    end)
end

function cmdsf(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampAddChatMessage(T("msg_prefix") .. T("msg_tow_sf"), -1)
    lua_thread.create(function()
        wait(100)
        sampSendChat("/tow sf") 
    end)
end

function cmddt(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/duty") 
        sampSendChat("/pin") 
    end)
end

function cmdmmc(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/missed calls") 
        sampSendChat("/missed messages") 
    end)
end

function cmdatt(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. " /att ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("/accept towtruck %d", id))
end

function cmdgk(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. " /gk ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("/givekey %d", id))
end

function cmdatk(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. " /atk ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("/accept ticket %d", id))
end

function cmdrrtt(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. " /rrtt ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("/repair %d 1", id))
    sampSendChat(string.format("/refill %d 1", id))
end

function cmdrrall(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. " /rrall ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end
    sampSendChat(string.format("/repair %d 50", id))
    sampSendChat(string.format("/refill %d 50", id))
end

function cmdttme(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat(T("ttme"))
    end)
end

function cmdafvr(param)
    if not modEnabled.v or not commandsEnabled.v or not cfg.settings.fvr_enabled then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if fvrRunning then
        return
    end
    local startText = tostring(cfg.settings.fvr_text_f or "")
    local finalText = tostring(cfg.settings.fvr_text_final or "")
    local sec = tonumber(cfg.settings.fvr_seconds or 10)
    lua_thread.create(function()
        fvrRunning = true
        fvrCancel = false
        if startText ~= "" then sampSendChat("/f " .. startText) end
        local ms = math.max(0, sec) * 1000
        local waited = 0
        while waited < ms do
            if fvrCancel then break end
            wait(100)
            waited = waited + 100
        end
        if not fvrCancel then
            if finalText ~= "" then sampSendChat("/f " .. finalText) end
            sampSendChat("/fvr")
        end
        fvrRunning = false
        fvrCancel = false
    end)
end

function cmdsfvr(param)
    if not modEnabled.v or not commandsEnabled.v or not cfg.settings.fvr_enabled then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    local cancelText = tostring(cfg.settings.fvr_text_sfvr or "")
    fvrCancel = true
    if cancelText ~= "" then sampSendChat("/f " .. cancelText) end
    sampSendChat("/sfvr")
end

function cmdttrr(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat(T("ttrr")) 
    end)
end

function cmdume(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat(T("ume")) 
    end)
end

function cmdurr(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat(T("urr")) 
    end)
end

function cmdat(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/s " .. T("at_tractez1"))
        sampSendChat("/s " .. T("at_tractez2"))
    end)
end

function cmdsrr(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/s " .. T("srr1")) 
        sampSendChat("/s " .. T("srr2")) 
    end)
end

function cmdskit(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/s " .. T("skit1")) 
        sampSendChat("/s " .. T("skit2")) 
        sampSendChat("/s " .. T("skit3")) 
    end)
end

function cmdgkit(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    if not param or param == "" then
        sampAddChatMessage(T("msg_prefix") .. T("cmd_correct") .. "/gkit ID", -1)
        return
    end
    local id = tonumber(param)
    if not id or not sampIsPlayerConnected(id) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end

    local kitfuel = 8000
    local kitrepair = 4000

    sellkitState.active = true
    sellkitState.targetId = id
    sellkitState.lastType = 'fuel'
    sellkitState.triedFuel = true
    sellkitState.triedRepair = false
    sellkitState.kitfuel = kitfuel
    sellkitState.kitrepair = kitrepair
    sellkitState.startedAt = os.clock()
    
    sampSendChat("/sellkit " .. id .. " fuel " .. kitfuel)

    lua_thread.create(function()
        wait(800)
        if sellkitState.active and not sellkitState.triedRepair then
                sellkitState.triedRepair = true
                sellkitState.lastType = 'repair'
                sampSendChat("/sellkit " .. sellkitState.targetId .. " repair " .. sellkitState.kitrepair)
        end
    end)
end
