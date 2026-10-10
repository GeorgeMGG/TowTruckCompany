script_name("TowTruckHelper")
script_author("George_VP")
script_description("TowTruckCompany")
script_version("3.7")
local LOCAL_VERSION = "3.7"
local VERSION_URL = "https://raw.githubusercontent.com/GeorgeMGG/TowTruckCompany/refs/heads/main/version.txt"
local SCRIPT_URL  = "https://raw.githubusercontent.com/GeorgeMGG/TowTruckCompany/refs/heads/main/TowTruckHelper.lua"

require "lib.moonloader"
local moonloader = require 'moonloader'
local AUDIOSTREAM_STATE = moonloader.audiostream_state or { PLAY = 1, STOP = 0 }
local imgui = require "imgui"
local sampev = require "lib.samp.events"
local inicfg = require "inicfg"
local vkeys = require "vkeys"
local ffi = require "ffi"

ffi.cdef[[
    void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long dwExtraInfo);
]]

local VK_F8 = 0x77
local KEYEVENTF_KEYUP = 0x0002

local UI_THEME = {
    accent = { 215, 206, 150, 255 },
    text = { 176, 176, 176, 255 },
    window_bg = { 8, 9, 10, 245 },
    child_bg = { 11, 12, 13, 235 },
    frame_bg = { 18, 19, 20, 255 },
    separator = { 215, 206, 150, 80 },
    header = { 215, 206, 150, 255 },
    button = { 22, 23, 24, 255 },
    button_hovered = { 34, 34, 31, 255 },
    button_active = { 215, 206, 150, 255 }
}

local UI_THEME_PRESETS = {
    {
        id = 3,
        key = "theme_gold",
        preview = "moonloader/resource/TowTruckHelper/assets/Theme/MenuB-zone.png",
        colors = {
            accent = { 215, 206, 150, 255 },
            text = { 210, 220, 230, 255 },
            window_bg = { 0, 0, 0, 245 },
            child_bg = { 0, 0, 0, 238 },
            frame_bg = { 3, 3, 3, 255 },
            separator = { 215, 206, 150, 105 },
            header = { 215, 206, 150, 255 },
            button = { 4, 4, 4, 255 },
            button_hovered = { 22, 22, 22, 255 },
            button_active = { 215, 206, 150, 255 }
        },
        hud = {
            bg_rgba = { 0, 0, 0, 205 },
            border_rgba = { 215, 206, 150, 120 },
            text_rgba = { 215, 206, 150, 255 }
        }
    },
    {
        id = 4,
        key = "theme_aero",
        preview = "moonloader/resource/TowTruckHelper/assets/Theme/theme_aero.png",
        colors = {
            accent = { 24, 88, 150, 255 },
            text = { 245, 250, 255, 255 },
            window_bg = { 0, 95, 175, 238 },
            child_bg = { 255, 255, 255, 245 },
            frame_bg = { 224, 235, 245, 255 },
            separator = { 170, 185, 200, 180 },
            header = { 24, 88, 150, 255 },
            button = { 36, 134, 215, 245 },
            button_hovered = { 74, 164, 235, 255 },
            button_active = { 18, 91, 166, 255 }
        },
        hud = {
            bg_rgba = { 230, 246, 255, 190 },
            border_rgba = { 84, 145, 190, 150 },
            text_rgba = { 24, 72, 112, 255 }
        }
    }
}

local function themeColor(key)
    local c = UI_THEME[key] or UI_THEME.text
    return imgui.ImVec4(c[1] / 255, c[2] / 255, c[3] / 255, c[4] / 255)
end

-- =========================
-- HUD (client-side) CONFIG
-- =========================
-- Imagini skin:  moonloader/resource/TowTruckHelper/assets/skins/<skinId>.png
-- Imagini vehicul: moonloader/resource/TowTruckHelper/assets/vehicles/Vehicle_<modelId>.png (sau <modelId>.png)
-- Recomandat: PNG, 64x64 sau 128x128, fundal transparent.
local HUD_CFG = {
    enabled_default = true,
    anchor_top_right_default = false,
    pos_default = { x = 1570, y = 440 },
    width_default = 330,
    height_default = 220,
    padding_default = 12,
    bg_rgba = { 12, 12, 12, 190 },
    border_rgba = { 215, 206, 150, 70 },
    text_rgba = { 215, 206, 150, 255 },
    refresh_towpoints_seconds_default = 300,
    assets_base = "moonloader/resource/TowTruckHelper/assets",
    skins_dir = "skins",
    vehicles_dir = "vehicles",
    vehicle_file_prefix = "Vehicle_",
    skin_placeholder = "moonloader/resource/TowTruckHelper/assets/skins/0.png",
    vehicle_placeholder = "moonloader/resource/TowTruckHelper/assets/vehicles/0.png",
    skin_image_size = 64,
    vehicle_image_size = 64
}

-- Pattern-uri ușor de editat (Lua patterns, nu regex PCRE)
local function copyColorTable(src)
    return { src[1], src[2], src[3], src[4] }
end

local function getThemePreset(themeId)
    local id = tonumber(themeId) or 1
    for _, preset in ipairs(UI_THEME_PRESETS) do
        if preset.id == id then return preset end
    end
    return UI_THEME_PRESETS[1]
end

local function applyUiThemePreset(themeId)
    local preset = getThemePreset(themeId)
    for key, value in pairs(preset.colors) do
        UI_THEME[key] = copyColorTable(value)
    end
    if preset.hud then
        HUD_CFG.bg_rgba = copyColorTable(preset.hud.bg_rgba)
        HUD_CFG.border_rgba = copyColorTable(preset.hud.border_rgba)
        HUD_CFG.text_rgba = copyColorTable(preset.hud.text_rgba)
    end
end

local CHAT_PATTERNS = {
    towpoints = {
        "(%d+)%s*tow%s*points",
        "tow%s*points%s*:?%s*(%d+)",
        "ai%s+(%d+)%s+tow%s*points",
        "you%s+have%s+(%d+)%s+tow%s*points",
        "you%s+have%s+(%d+)%s+tows%s+available",
        "poti%s+efectua%s+(%d+)%s+tractari"
    },
    duty_on = {
        "ai%s+intrat%s+in%s+duty",
        "acum%s+esti%s+on%s*duty",
        "you%s+are%s+now%s+on%s*duty",
        "esti%s+la%s+datorie%s+ca%s+mecanic%s+tow%s+truck%s+company"
    },
    duty_off = {
        "ai%s+iesit%s+din%s+duty",
        "nu%s+mai%s+esti%s+on%s*duty",
        "you%s+are%s+now%s+off%s*duty",
        "you%s+are%s+now%s+off%s+duty%s+from%s+your%s+tow%s+truck%s+job",
        "nu%s+mai%s+esti%s+la%s+datorie%s+ca%s+mecanic%s+in%s+tow%s+truck%s+company"
    }
}

-- Nume custom (opțional) pentru skin/vehicul. Dacă nu există, se afișează Skin <id> / Vehicle <id>.
local SKIN_NAMES = {
}

local VEHICLE_NAMES = {
}

-- Nume implicite pentru modelele GTA SA (fallback automat, fara mapare manuala in fiecare proiect)
local VEHICLE_MODEL_DEFAULTS = {
    [400]="Landstalker",[401]="Bravura",[402]="Buffalo",[403]="Linerunner",[404]="Perennial",[405]="Sentinel",[406]="Dumper",[407]="Firetruck",
    [408]="Trashmaster",[409]="Stretch",[410]="Manana",[411]="Infernus",[412]="Voodoo",[413]="Pony",[414]="Mule",[415]="Cheetah",
    [416]="Ambulance",[417]="Leviathan",[418]="Moonbeam",[419]="Esperanto",[420]="Taxi",[421]="Washington",[422]="Bobcat",[423]="Mr Whoopee",
    [424]="BF Injection",[425]="Hunter",[426]="Premier",[427]="Enforcer",[428]="Securicar",[429]="Banshee",[430]="Predator",[431]="Bus",
    [432]="Rhino",[433]="Barracks",[434]="Hotknife",[435]="Trailer",[436]="Previon",[437]="Coach",[438]="Cabbie",[439]="Stallion",
    [440]="Rumpo",[441]="RC Bandit",[442]="Romero",[443]="Packer",[444]="Monster",[445]="Admiral",[446]="Squalo",[447]="Seasparrow",
    [448]="Pizzaboy",[449]="Tram",[450]="Trailer",[451]="Turismo",[452]="Speeder",[453]="Reefer",[454]="Tropic",[455]="Flatbed",
    [456]="Yankee",[457]="Caddy",[458]="Solair",[459]="Topfun",[460]="Skimmer",[461]="PCJ-600",[462]="Faggio",[463]="Freeway",
    [464]="RC Baron",[465]="RC Raider",[466]="Glendale",[467]="Oceanic",[468]="Sanchez",[469]="Sparrow",[470]="Patriot",[471]="Quad",
    [472]="Coastguard",[473]="Dinghy",[474]="Hermes",[475]="Sabre",[476]="Rustler",[477]="ZR-350",[478]="Walton",[479]="Regina",
    [480]="Comet",[481]="BMX",[482]="Burrito",[483]="Camper",[484]="Marquis",[485]="Baggage",[486]="Dozer",[487]="Maverick",
    [488]="News Chopper",[489]="Rancher",[490]="FBI Rancher",[491]="Virgo",[492]="Greenwood",[493]="Jetmax",[494]="Hotring Racer",
    [495]="Sandking",[496]="Blista Compact",[497]="Police Maverick",[498]="Boxville",[499]="Benson",[500]="Mesa",[501]="RC Goblin",
    [502]="Hotring Racer A",[503]="Hotring Racer B",[504]="Bloodring Banger",[505]="Rancher",[506]="Super GT",[507]="Elegant",
    [508]="Journey",[509]="Bike",[510]="Mountain Bike",[511]="Beagle",[512]="Cropduster",[513]="Stuntplane",[514]="Tanker",
    [515]="Roadtrain",[516]="Nebula",[517]="Majestic",[518]="Buccaneer",[519]="Shamal",[520]="Hydra",[521]="FCR-900",[522]="NRG-500",
    [523]="HPV1000",[524]="Cement Truck",[525]="Towtruck",[526]="Fortune",[527]="Cadrona",[528]="FBI Truck",[529]="Willard",
    [530]="Forklift",[531]="Tractor",[532]="Combine Harvester",[533]="Feltzer",[534]="Remington",[535]="Slamvan",[536]="Blade",
    [537]="Freight",[538]="Brown Streak",[539]="Vortex",[540]="Vincent",[541]="Bullet",[542]="Clover",[543]="Sadler",
    [544]="Firetruck LA",[545]="Hustler",[546]="Intruder",[547]="Primo",[548]="Cargobob",[549]="Tampa",[550]="Sunrise",
    [551]="Merit",[552]="Utility Van",[553]="Nevada",[554]="Yosemite",[555]="Windsor",[556]="Monster A",[557]="Monster B",
    [558]="Uranus",[559]="Jester",[560]="Sultan",[561]="Stratum",[562]="Elegy",[563]="Raindance",[564]="RC Tiger",
    [565]="Flash",[566]="Tahoma",[567]="Savanna",[568]="Bandito",[569]="Freight Flat Trailer",[570]="Streak Trailer",
    [571]="Kart",[572]="Mower",[573]="Dune",[574]="Sweeper",[575]="Broadway",[576]="Tornado",[577]="AT-400",[578]="DFT-30",
    [579]="Huntley",[580]="Stafford",[581]="BF-400",[582]="News Van",[583]="Tug",[584]="Petrol Trailer",[585]="Emperor",
    [586]="Wayfarer",[587]="Euros",[588]="Hotdog",[589]="Club",[590]="Freight Box Trailer",[591]="Article Trailer 3",
    [592]="Andromada",[593]="Dodo",[594]="RC Cam",[595]="Launch",[596]="Police Car LS",[597]="Police Car SF",[598]="Police Car LV",
    [599]="Police Ranger",[600]="Picador",[601]="S.W.A.T.",[602]="Alpha",[603]="Phoenix",[604]="Glendale Shit",[605]="Sadler Shit",
    [606]="Baggage Trailer A",[607]="Baggage Trailer B",[608]="Tug Stairs Trailer",[609]="Boxville Trailer",[610]="Farm Trailer",
    [611]="Utility Trailer"
}

-- =========================
-- TRANSLATIONS
-- =========================
local translations = {
    ro = {
        main = "Meniu Principal",
        info = "Comenzi disponibile",
        rules = "REGULAMENT",
        settings = "Setari",
        ui_theme = "Teme UI",
        ui_theme_title = "Teme meniu si HUD",
        theme_default = "Default",
        theme_split = "Craciun",
        theme_gold = "B-Zone",
        theme_aero = "Windows 7 Aero",
        close = "INCHIDE",
        ttcs_settings = "Setari",
        global_mod = "Mod Global",
        auto_repair = "Auto Repair",
        auto_refill = "Auto Refill",
        auto_engine = "Auto Engine",
        confirm = "Confirma",
        start_stop = "Start-Stop",
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
        mouse_detect = "Detectare ID cu Mouse",
        at_auto_dl = "Auto Dovezi Tractare",
        key = "TASTA",
        none = "NIMIC",
        desc_ls = "Acesta comanda alege orasul LS",
        desc_lv = "Acesta comanda alege orasul LV",
        desc_sf = "Acesta comanda alege orasul SF",
        desc_at = "Trimite /s Atentie tractez!\nPoti dezactiva auto screenshot-ul si auto /dl-ul mai sus in setari.",
        desc_rr = "Ofera repair/refill jucatorilor din jur.",
        desc_sk = "Ofera repair kit jucatorilor din jur.",
        desc_rrme = "Acest mod iti ofera repair/refill",
        desc_mouse_detect = "Tine tasta setata si click dreapta pe un player pentru a deschide radial menu cu Repair/Refill, SellKit, Refill si Repair.",
        desc_at_auto_dl = "Activeaza sau dezactiveaza auto /dl si screenshot-ul automat pentru Atentie Tractez.",
        key_dialog_title = "Setare Tasta",
        key_dialog_msg = "Alege pe ce tasta vrei sa fie comanda",
        press_key = "Apasa orice tasta acum...",
        cancel = "Anuleaza",
        msg_prefix = "{ffe699}TowTruckHelper{FFFFFF}: ",
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
        auto_raport_detect = "Detectare automata raport",
        desc_auto_raport_detect = "Activeaza/Dezactiveaza detectarea automata a raport-ului.",
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
        rule6  = "/gkit <id> – Oferi kit de repair/refill.",
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
        msg_first_runID = "Salut %s[%d]!", 
        msg_first_run1 = "TowTruckHelper a aparut prima data in varianta CLEO (13.11.2024).",
        msg_first_run2 = "Acum vine in versiunea MoonLoader (.lua), pastrand aceleasi functii cunoscute, dar intr-un meniu modern.",
        msg_first_runCMD = "Setarile sunt disponibile folosind comanda %s.",
        volume_label = "Control volum",
        setari_audio = "Setari Audio",
        Music_label = "Activeaza sau dezactiveaza muzica",
        textdraw_label = "Pozitie Textdraw",
        textdraw_label1 = "Foloseste sagetile pentru a muta textdraw-ul.",
        textdraw_label2 = "Tine SHIFT pentru miscare mai rapida.",
        shift1 = "Foloseste sagetile pentru miscare. SHIFT pentru viteza.",
        shift2 = "Click dreapta pe alt element pentru a comuta.",
        hud_title = "Tow Truck Helper RPG.B-ZONE.RO",
        hud_player_fallback = "Jucator",
        hud_skin = "Skin",
        hud_vehicle_id = "ID",
        hud_speed_unit = "KM/H",
        hud_hp = "HP",
        hud_fuel = "Combustibil",
        hud_status = "Status",
        hud_odometer = "Kilometraj",
        hud_locked = "Inchis",
        hud_unlocked = "Deschis",
        hud_duty_on = "[Duty - ON]",
        hud_duty_off = "[Duty - OFF]",
        hud_towpoints = "TowPoints",
        hud_report = "Raport",
        hud_report_progress = "Progres raport",
        hud_completed = "Completat",
        hud_incomplete = "Incomplet",
        hud_any_action = "Orice Actiune",
        hud_tows = "Tractari",
        auto_repair_confirm_msg = "Acest vehicul a ajuns sub 350 HP, doresti repair?",
        auto_refill_confirm_msg = "Combustibilul a ajuns la 10%, doresti refill?"
    },
    en = {
        main = "Main Menu",
        info = "Available Commands",
        rules = "RULES",
        settings = "Settings",
        ui_theme = "UI Theme",
        ui_theme_title = "Menu and HUD Themes",
        theme_default = "Default",
        theme_split = "Christmas",
        theme_gold = "B-Zone",
        theme_aero = "Windows 7 Aero",
        close = "CLOSE",
        ttcs_settings = "Settings",
        global_mod = "Global Mod",
        auto_repair = "Auto Repair",
        auto_refill = "Auto Refill",
        auto_engine = "Auto Engine",
        confirm = "Confirm",
        start_stop = "Start-Stop",
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
        mouse_detect = "Mouse Detection",
        at_auto_dl = "Auto Towing Proof",
        key = "KEY",
        none = "NONE",
        desc_ls = "This command selects LS city",
        desc_lv = "This command selects LV city",
        desc_sf = "This command selects SF city",
        desc_at = "Sends /s Attention towing!\nYou can disable the automatic screenshot and auto /dl above in settings.",
        desc_rr = "Offers repair/refill to nearby players.",
        desc_sk = "Offers repair kit to nearby players.",
        desc_rrme = "This mod offers you repair/refill",
        desc_mouse_detect = "Hold the selected key and right click a player to open the radial menu with Repair/Refill, SellKit, Refill and Repair.",
        desc_at_auto_dl = "Enable or disable the automatic /dl command and automatic screenshot for Attention Towing.",
        key_dialog_title = "Set Key",
        key_dialog_msg = "Choose a key for command",
        press_key = "Press any key now...",
        cancel = "Cancel",
        msg_prefix = "{ffe699}TowTruckHelper{FFFFFF}: ",
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
        auto_raport_detect = "Automatic report detection",
        desc_auto_raport_detect = "Enable/Disable automatic report detection.",
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
        skit1 = "Anyone interested in Repair/Refill kits?",
        skit2 = "Special price: Repair $4,000 | Refill $8,000!",
        skit3 = "NPC prices: Repair $10,000-$15,000 | Refill $15,000-$25,000",
        rule1  = "/ls – Tow a vehicle in Los Santos.",
        rule2  = "/lv – Tow a vehicle in Las Venturas.",
        rule3  = "/sf – Tow a vehicle in San Fierro.",
        rule4  = "/rrtt <id> – Offers repair, refill and gas can refill simultaneously for $1.",
        rule5  = "/rrall <id> – Offers repair and refill for $50 and gas can refill for $20.",
        rule6  = "/gkit <id> – Offers repair/refill kit.",
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
        msg_first_runID = "Hello %s[%d]!",
        msg_first_run1 = "TowTruckHelper was first released in a CLEO version (13.11.2024).",
        msg_first_run2 = "Now available as a MoonLoader (.lua) version, keeping the same familiar features but with a modern menu.",
        msg_first_runCMD = "Settings are available using the %s command.",
        volume_label = "Volume control",
        setari_audio = "Audio Settings",
        Music_label = "Enable or disable music",
        textdraw_label = "Textdraw Position",
        textdraw_label1 = "Use the arrow keys to move the textdraw.",
        textdraw_label2 = "Hold SHIFT for faster movement.",
        shift1 = "Use Arrows to move. Shift for speed.",
        shift2 = "Right click another element to switch.",
        hud_title = "Tow Truck Helper RPG.B-ZONE.RO",
        hud_player_fallback = "Player",
        hud_skin = "Skin",
        hud_vehicle_id = "ID",
        hud_speed_unit = "KM/H",
        hud_hp = "HP",
        hud_fuel = "Fuel",
        hud_status = "Status",
        hud_odometer = "Odometer",
        hud_locked = "Locked",
        hud_unlocked = "Unlocked",
        hud_duty_on = "[Duty - ON]",
        hud_duty_off = "[Duty - OFF]",
        hud_towpoints = "TowPoints",
        hud_report = "Report",
        hud_report_progress = "Report progress",
        hud_completed = "Completed",
        hud_incomplete = "Incomplete",
        hud_any_action = "Any Action",
        hud_tows = "Vehicles to tow",
        auto_repair_confirm_msg = "This vehicle is below 350 HP, do you want to repair it?",
        auto_refill_confirm_msg = "Fuel reached 10%, do you want to refill?"
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
        auto_raport_detect_enabled = true,
        hide_server_speedo = false,
        speedo_probe = false,
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
        ui_theme = 1,
        start = 0,
        loading_screen_enabled = false,
        menu_cmd = "ttc",
        startstop_enabled = false,
        hud_enabled = true,
        hud_anchor_top_right = false,
        hud_pos_x = 1570,
        hud_pos_y = 440,
        hud_initial_pos_migrated = false,
        hud_width = 330,
        hud_height = 220,
        hud_padding = 12,
        hud_skin_image_size = 64,
        hud_vehicle_image_size = 64,
        hud_vehicle_file_prefix = "Vehicle_",
        hud_skin_placeholder = "moonloader/resource/TowTruckHelper/assets/skins/0.png",
        hud_vehicle_placeholder = "moonloader/resource/TowTruckHelper/assets/vehicles/0.png",
        towpoints_refresh_seconds = 300,
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
        at_auto_dl_enabled = true,
        repair_refill_enabled = false,
        repair_refill_key = 0,
        sellkit_enabled = false,
        sellkit_key = 0,
        repair_refill_me_enabled = false,
        repair_refill_me_key = 0,
        mouse_detect_enabled = false,
        mouse_detect_key = 0,
        textdraw_pos_x = 0,
        textdraw_pos_y = 0,
        ttc_info_shown = 0
    },
    layout = {} -- Stores custom positions
}
local cfg = inicfg.load(cfg_default, "TowTruckHelper.ini")
if not cfg then
    cfg = cfg_default
    inicfg.save(cfg, "TowTruckHelper.ini")
end
if cfg.layout == nil then cfg.layout = {} end

local isEditMode = false
local editPassword = "George_VP#UnknownLegend"
local selectedElement = nil 
local audioStream = nil
local MENU_MUSIC_CANDIDATES = {
    "moonloader/resource/TowTruckHelper/MenuMusic.mp3",
    "moonloader/resource/MenuMusic.mp3",
    "moonloader/resource/music.mp3"
}

-- Helper function to save layout
local function saveLayout()
    inicfg.save(cfg, "TowTruckHelper.ini")
end

local function loadMenuAudio()
    for _, path in ipairs(MENU_MUSIC_CANDIDATES) do
        if doesFileExist(path) then
            audioStream = loadAudioStream(path)
            if audioStream then
                if setAudioStreamLooped then
                    setAudioStreamLooped(audioStream, false)
                end
                return true
            end
        end
    end
    return false
end

-- Ensure new keys exist if updating from old config
if cfg.settings.language == nil then cfg.settings.language = 0 end
if cfg.settings.menu_color_r == nil then 
    cfg.settings.menu_color_r = 102 
    cfg.settings.menu_color_g = 0 
    cfg.settings.menu_color_b = 255 
end
if cfg.settings.textdraw_enabled == nil then cfg.settings.textdraw_enabled = false end
if cfg.settings.auto_raport_detect_enabled == nil then cfg.settings.auto_raport_detect_enabled = true end
if cfg.settings.hide_server_speedo == nil then cfg.settings.hide_server_speedo = false end
if cfg.settings.speedo_probe == nil then cfg.settings.speedo_probe = false end
if cfg.settings.update_auto_check == nil then cfg.settings.update_auto_check = true end
if cfg.settings.ui_theme == nil or cfg.settings.ui_theme == 1 or cfg.settings.ui_theme == 2 then
    cfg.settings.ui_theme = 3
    inicfg.save(cfg, "TowTruckHelper.ini")
end
applyUiThemePreset(cfg.settings.ui_theme)
if cfg.settings.start == nil then cfg.settings.start = 0 end
if cfg.settings.loading_screen_enabled == nil then cfg.settings.loading_screen_enabled = false end
if cfg.settings.menu_cmd == nil then cfg.settings.menu_cmd = "ttc" end
if cfg.settings.menu_key_enabled == nil then cfg.settings.menu_key_enabled = false end
if cfg.settings.menu_open_key == nil then cfg.settings.menu_open_key = 0 end
if cfg.settings.startstop_enabled == nil then cfg.settings.startstop_enabled = false end
if cfg.settings.hud_enabled == nil then cfg.settings.hud_enabled = HUD_CFG.enabled_default end
if cfg.settings.hud_anchor_top_right == nil then cfg.settings.hud_anchor_top_right = HUD_CFG.anchor_top_right_default end
if cfg.settings.hud_pos_x == nil then cfg.settings.hud_pos_x = HUD_CFG.pos_default.x end
if cfg.settings.hud_pos_y == nil then cfg.settings.hud_pos_y = HUD_CFG.pos_default.y end
if cfg.settings.hud_initial_pos_migrated == nil then cfg.settings.hud_initial_pos_migrated = false end
if not cfg.settings.hud_initial_pos_migrated or ((tonumber(cfg.settings.hud_pos_x) or 0) == 570 and (tonumber(cfg.settings.hud_pos_y) or 0) == 440) then
    cfg.settings.hud_anchor_top_right = false
    cfg.settings.hud_pos_x = HUD_CFG.pos_default.x
    cfg.settings.hud_pos_y = HUD_CFG.pos_default.y
    cfg.settings.hud_initial_pos_migrated = true
    inicfg.save(cfg, "TowTruckHelper.ini")
end
if cfg.settings.hud_width == nil then cfg.settings.hud_width = HUD_CFG.width_default end
if cfg.settings.hud_height == nil then cfg.settings.hud_height = HUD_CFG.height_default end
if cfg.settings.hud_padding == nil then cfg.settings.hud_padding = HUD_CFG.padding_default end
if cfg.settings.hud_skin_image_size == nil then cfg.settings.hud_skin_image_size = HUD_CFG.skin_image_size end
if cfg.settings.hud_vehicle_image_size == nil then cfg.settings.hud_vehicle_image_size = HUD_CFG.vehicle_image_size end
if cfg.settings.hud_vehicle_file_prefix == nil then cfg.settings.hud_vehicle_file_prefix = HUD_CFG.vehicle_file_prefix end
if cfg.settings.hud_skin_placeholder == nil then cfg.settings.hud_skin_placeholder = HUD_CFG.skin_placeholder end
if cfg.settings.hud_vehicle_placeholder == nil then cfg.settings.hud_vehicle_placeholder = HUD_CFG.vehicle_placeholder end
if cfg.settings.towpoints_refresh_seconds == nil then cfg.settings.towpoints_refresh_seconds = HUD_CFG.refresh_towpoints_seconds_default end
if cfg.settings.fvr_enabled == nil then cfg.settings.fvr_enabled = false end
if cfg.settings.custom_enabled == nil then cfg.settings.custom_enabled = false end
if cfg.settings.fvr_text_f == nil then cfg.settings.fvr_text_f = "Atentie, fvr in 10 secunde." end
if cfg.settings.fvr_text_final == nil then cfg.settings.fvr_text_final = "Comanda fvr executata cu succes." end
if cfg.settings.fvr_text_sfvr == nil then cfg.settings.fvr_text_sfvr = "M-am razgandit, nu mai dau FVR." end
if cfg.settings.fvr_seconds == nil then cfg.settings.fvr_seconds = 10 end
if cfg.settings.music_enabled == nil then cfg.settings.music_enabled = true end
if cfg.settings.music_volume == nil then cfg.settings.music_volume = 50 end
if cfg.settings.mouse_detect_enabled == nil then cfg.settings.mouse_detect_enabled = false end
if cfg.settings.mouse_detect_key == nil then cfg.settings.mouse_detect_key = 0 end
if cfg.settings.at_auto_dl_enabled == nil then cfg.settings.at_auto_dl_enabled = true end
if cfg.settings.textdraw_pos_x == nil then cfg.settings.textdraw_pos_x = 0 end
if cfg.settings.textdraw_pos_y == nil then cfg.settings.textdraw_pos_y = 0 end
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
showMenu = imgui.ImBool(false)
activeTab = 1 -- 1: Main, 2: Info, 3: Rules, 4: Settings
modEnabled = imgui.ImBool(true)
repairEnabled = imgui.ImBool(true)
refillEnabled = imgui.ImBool(false)
engineEnabled = imgui.ImBool(false)
startStopEnabled = imgui.ImBool(not not cfg.settings.startstop_enabled)
hudEnabled = imgui.ImBool(not not cfg.settings.hud_enabled)
commandsEnabled = imgui.ImBool(true) 
lastMod, lastRepair, lastEngine, lastCmds = false, false, false, true
startStopLastWsTime = os.clock()
startStopEngineAssumedOn = true
startStopLastToggleAt = 0.0
cursorWantedLast = false
cursorStateLast = false
altPlayerPickActive = false
altPickedPlayerId = -1
radialMenuActive = false
radialMenuTargetId = -1
radialMenuCenterX = 0
radialMenuCenterY = 0
radialMenuHoveredAction = nil
radialRightWasDown = false

isDuty = false
dutyRequestedAt = 0.0
startupHudBootstrapActive = false
dutyInitialRequestsScheduled = false
nextTowpointsRefreshAt = 0.0
towpoints = 0
towpointsRequestPending = false
towpointsRequestAt = 0.0
raportRequestPending = false
raportRequestAt = 0.0
nextRaportAt = 0.0

speedoTdIds = {}
footerTdIds = {}
speedoTdMeta = {}

hudState = {
    playerName = "",
    playerId = -1,
    skinId = -1,
    skinName = "Unknown",
    inVehicle = false,
    vehicleHandle = 0,
    vehicleModel = -1,
    vehicleName = "On Foot",
    vehicleHp = 0,
    vehicleSpeed = nil,
    vehicleFuel = nil,
    vehicleOdometer = nil,
    vehicleStatus = nil,
    vehicleLocked = nil,
    vehicleSpeedoAt = 0.0,
    raportWeekDone = nil,
    raportWeekAction = nil,
    raportWeekTows = nil,
    raportAt = 0.0
}

skinTextures = {}
vehicleTextures = {}
themePreviewTextures = {}
skinPlaceholderTex = nil
vehiclePlaceholderTex = nil
win7MenuBackgroundTex = nil
win7HudBackgroundTex = nil
bzoneHudBackgroundTex = nil
bzoneMenuBackgroundTex = nil

local speedoIcons = {
    hp = nil,
    fuel = nil,
    odo = nil,
    lock = nil
}

local function hudColor(c)
    return imgui.ImVec4(c[1] / 255, c[2] / 255, c[3] / 255, c[4] / 255)
end

local function hudColU32(c)
    return imgui.ColorConvertFloat4ToU32(hudColor(c))
end

local function drawStatIcon(draw_list, kind, x, y, s, col)
    local c = imgui.ColorConvertFloat4ToU32(col)
    local x2 = x + s
    local y2 = y + s
    if kind == "heart" then
        local r = s * 0.22
        draw_list:AddCircleFilled(imgui.ImVec2(x + s * 0.35, y + s * 0.35), r, c, 18)
        draw_list:AddCircleFilled(imgui.ImVec2(x + s * 0.65, y + s * 0.35), r, c, 18)
        draw_list:AddTriangleFilled(
            imgui.ImVec2(x + s * 0.18, y + s * 0.45),
            imgui.ImVec2(x + s * 0.82, y + s * 0.45),
            imgui.ImVec2(x + s * 0.50, y + s * 0.86),
            c
        )
    elseif kind == "drop" then
        draw_list:AddCircleFilled(imgui.ImVec2(x + s * 0.5, y + s * 0.45), s * 0.28, c, 18)
        draw_list:AddTriangleFilled(
            imgui.ImVec2(x + s * 0.5, y + s * 0.1),
            imgui.ImVec2(x + s * 0.72, y + s * 0.42),
            imgui.ImVec2(x + s * 0.28, y + s * 0.42),
            c
        )
        draw_list:AddTriangleFilled(
            imgui.ImVec2(x + s * 0.28, y + s * 0.42),
            imgui.ImVec2(x + s * 0.72, y + s * 0.42),
            imgui.ImVec2(x + s * 0.5, y + s * 0.92),
            c
        )
    elseif kind == "lock" then
        local bw = s * 0.66
        local bh = s * 0.52
        local bx = x + (s - bw) * 0.5
        local by = y + s * 0.44
        draw_list:AddRectFilled(imgui.ImVec2(bx, by), imgui.ImVec2(bx + bw, by + bh), c, 3)
        draw_list:AddRect(imgui.ImVec2(bx + bw * 0.18, y + s * 0.20), imgui.ImVec2(bx + bw * 0.82, by), c, 5, 0, 2)
    elseif kind == "gear" then
        local cx = x + s * 0.5
        local cy = y + s * 0.5
        local r1 = s * 0.18
        local r2 = s * 0.36
        for i = 0, 7 do
            local a = (i / 8) * (math.pi * 2)
            local tx = cx + math.cos(a) * r2
            local ty = cy + math.sin(a) * r2
            draw_list:AddRectFilled(imgui.ImVec2(tx - s * 0.06, ty - s * 0.06), imgui.ImVec2(tx + s * 0.06, ty + s * 0.06), c, 2)
        end
        draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), s * 0.30, c, 24)
        draw_list:AddCircleFilled(imgui.ImVec2(cx, cy), r1, 0xFF101010, 18)
    elseif kind == "car" then
        draw_list:AddRectFilled(imgui.ImVec2(x + s * 0.14, y + s * 0.45), imgui.ImVec2(x + s * 0.86, y + s * 0.72), c, 4)
        draw_list:AddRectFilled(imgui.ImVec2(x + s * 0.28, y + s * 0.32), imgui.ImVec2(x + s * 0.72, y + s * 0.52), c, 4)
        draw_list:AddCircleFilled(imgui.ImVec2(x + s * 0.30, y + s * 0.74), s * 0.10, 0xFF101010, 12)
        draw_list:AddCircleFilled(imgui.ImVec2(x + s * 0.70, y + s * 0.74), s * 0.10, 0xFF101010, 12)
    else
        draw_list:AddRect(imgui.ImVec2(x, y), imgui.ImVec2(x2, y2), c, 0, 0, 2)
    end
end

local sevenSegmentMap = {
    ["0"] = { "a", "b", "c", "d", "e", "f" },
    ["1"] = { "b", "c" },
    ["2"] = { "a", "b", "g", "e", "d" },
    ["3"] = { "a", "b", "g", "c", "d" },
    ["4"] = { "f", "g", "b", "c" },
    ["5"] = { "a", "f", "g", "c", "d" },
    ["6"] = { "a", "f", "g", "e", "c", "d" },
    ["7"] = { "a", "b", "c" },
    ["8"] = { "a", "b", "c", "d", "e", "f", "g" },
    ["9"] = { "a", "b", "c", "d", "f", "g" },
    ["-"] = { "g" }
}

local function sevenSegmentSize(text, h)
    local s = tostring(text or "0")
    local digitW = h * 0.58
    local gap = h * 0.14
    local w = 0
    for i = 1, #s do
        local ch = s:sub(i, i)
        if ch == "." then
            w = w + h * 0.16 + gap
        else
            w = w + digitW + gap
        end
    end
    if w > 0 then w = w - gap end
    return imgui.ImVec2(w, h)
end

local function drawSevenSegmentText(draw_list, text, x, y, h, col)
    local color = imgui.ColorConvertFloat4ToU32(col)
    local s = tostring(text or "0")
    local digitW = h * 0.58
    local thick = math.max(2.0, h * 0.10)
    local gap = h * 0.14
    local inset = thick * 0.85
    local midY = y + h * 0.50
    local bottomY = y + h

    local function hasSegment(list, seg)
        for _, value in ipairs(list) do
            if value == seg then return true end
        end
        return false
    end

    local function segment(x1, y1, x2, y2)
        draw_list:AddLine(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), color, thick)
    end

    local cursorX = x
    for i = 1, #s do
        local ch = s:sub(i, i)
        if ch == "." then
            draw_list:AddCircleFilled(imgui.ImVec2(cursorX + thick, bottomY - thick), thick * 0.45, color, 10)
            cursorX = cursorX + h * 0.16 + gap
        else
            local list = sevenSegmentMap[ch] or sevenSegmentMap["0"]
            if hasSegment(list, "a") then segment(cursorX + inset, y + thick * 0.5, cursorX + digitW - inset, y + thick * 0.5) end
            if hasSegment(list, "g") then segment(cursorX + inset, midY, cursorX + digitW - inset, midY) end
            if hasSegment(list, "d") then segment(cursorX + inset, bottomY - thick * 0.5, cursorX + digitW - inset, bottomY - thick * 0.5) end
            if hasSegment(list, "f") then segment(cursorX + thick * 0.5, y + inset, cursorX + thick * 0.5, midY - inset) end
            if hasSegment(list, "b") then segment(cursorX + digitW - thick * 0.5, y + inset, cursorX + digitW - thick * 0.5, midY - inset) end
            if hasSegment(list, "e") then segment(cursorX + thick * 0.5, midY + inset, cursorX + thick * 0.5, bottomY - inset) end
            if hasSegment(list, "c") then segment(cursorX + digitW - thick * 0.5, midY + inset, cursorX + digitW - thick * 0.5, bottomY - inset) end
            cursorX = cursorX + digitW + gap
        end
    end
end

local function ensureDir(path)
    if not doesDirectoryExist(path) then
        createDirectory(path)
    end
end

local function setupHudAssets()
    ensureDir(HUD_CFG.assets_base)
    ensureDir(HUD_CFG.assets_base .. "/" .. HUD_CFG.skins_dir)
    ensureDir(HUD_CFG.assets_base .. "/" .. HUD_CFG.vehicles_dir)
    ensureDir(HUD_CFG.assets_base .. "/Speedo")
    ensureDir(HUD_CFG.assets_base .. "/Theme")
end

local function loadSpeedoIcons()
    local base = HUD_CFG.assets_base .. "/Speedo"
    local pHp = base .. "/hp.png"
    local pFuel = base .. "/fuel.png"
    local pOdo = base .. "/odometer.png"
    local pLock = base .. "/lock.png"

    speedoIcons.hp = doesFileExist(pHp) and imgui.CreateTextureFromFile(pHp) or nil
    speedoIcons.fuel = doesFileExist(pFuel) and imgui.CreateTextureFromFile(pFuel) or nil
    speedoIcons.odo = doesFileExist(pOdo) and imgui.CreateTextureFromFile(pOdo) or nil
    speedoIcons.lock = doesFileExist(pLock) and imgui.CreateTextureFromFile(pLock) or nil
end

local function loadThemePreviewTextures()
    for _, preset in ipairs(UI_THEME_PRESETS) do
        if preset.preview and doesFileExist(preset.preview) then
            themePreviewTextures[preset.id] = imgui.CreateTextureFromFile(preset.preview)
        end
    end
end

local function loadWin7ThemeBackgrounds()
    local base = HUD_CFG.assets_base .. "/Theme"
    local menuPath = base .. "/menuwin7.png"
    local hudPath = base .. "/hudwin7.png"
    local bzoneMenuPath = base .. "/MenuB-zone.png"
    local bzoneHudPath = base .. "/Hudb-zone.png"
    win7MenuBackgroundTex = doesFileExist(menuPath) and imgui.CreateTextureFromFile(menuPath) or nil
    win7HudBackgroundTex = doesFileExist(hudPath) and imgui.CreateTextureFromFile(hudPath) or nil
    bzoneMenuBackgroundTex = doesFileExist(bzoneMenuPath) and imgui.CreateTextureFromFile(bzoneMenuPath) or nil
    bzoneHudBackgroundTex = doesFileExist(bzoneHudPath) and imgui.CreateTextureFromFile(bzoneHudPath) or nil
end

local function loadTextureCached(cache, id, filePath, placeholder)
    if cache[id] then return cache[id] end
    if doesFileExist(filePath) then
        cache[id] = imgui.CreateTextureFromFile(filePath)
        if cache[id] then return cache[id] end
    end
    return placeholder
end

local function getSkinName(skinId)
    return SKIN_NAMES[skinId] or ("Skin " .. tostring(skinId))
end

local function getVehicleName(modelId)
    return VEHICLE_NAMES[modelId] or VEHICLE_MODEL_DEFAULTS[modelId] or ("Vehicle " .. tostring(modelId))
end

local function getSkinTexture(skinId)
    local p = string.format("%s/%s/%d.png", HUD_CFG.assets_base, HUD_CFG.skins_dir, skinId)
    return loadTextureCached(skinTextures, skinId, p, skinPlaceholderTex)
end

local function getVehicleTexture(modelId)
    local prefix = cfg.settings.hud_vehicle_file_prefix or HUD_CFG.vehicle_file_prefix or ""
    local p1 = string.format("%s/%s/%s%d.png", HUD_CFG.assets_base, HUD_CFG.vehicles_dir, prefix, modelId)
    if doesFileExist(p1) then
        return loadTextureCached(vehicleTextures, modelId, p1, vehiclePlaceholderTex)
    end
    local p2 = string.format("%s/%s/%d.png", HUD_CFG.assets_base, HUD_CFG.vehicles_dir, modelId)
    return loadTextureCached(vehicleTextures, modelId, p2, vehiclePlaceholderTex)
end

local function parseTowpointsFromChat(text)
    local low = (text or ""):lower()
    for _, pat in ipairs(CHAT_PATTERNS.towpoints) do
        local n = low:match(pat)
        if n then return tonumber(n) end
    end
    return nil
end

local function requestTowpoints()
    towpointsRequestPending = true
    towpointsRequestAt = os.clock()
    sampSendChat("/towpoints")
end

local function stripSampColors2(s)
    s = tostring(s or "")
    s = s:gsub("{%x%x%x%x%x%x}", "")
    s = s:gsub("{%x+}", "")
    return s
end

local function parseRaportDialogText(text)
    local raw = stripSampColors2(text or "")
    raw = raw:gsub("\t", " ")
    local weekDone = nil
    local weekAction = nil
    local weekTows = nil
    local inWeek = false

    for line in raw:gmatch("[^\r\n]+") do
        local l = line:gsub("^%s+", ""):gsub("%s+$", "")
        if l ~= "" then
            local low = l:lower()
            if low:find("progres saptamana curenta", 1, true) or low:find("current week progress", 1, true) then
                inWeek = true
                local st = l:match("%(([^%)]+)%)")
                st = tostring(st or ""):lower()
                if st:find("incomplet", 1, true) or st:find("incomplete", 1, true) then
                    weekDone = false
                elseif st:find("complet", 1, true) or st:find("completed", 1, true) then
                    weekDone = true
                end
            elseif inWeek and low:find("bonus", 1, true) then
                break
            elseif inWeek and low:find("rank", 1, true) then
                break
            elseif inWeek then
                local a = l:match("[Oo]rice%s+actiune.-:%s*([%d%/%.,]+)")
                if not a then a = l:match("[Aa]ny%s+action%s+in%s+faction.-:%s*([%d%/%.,]+)") end
                if a then weekAction = a end
                local t = l:match("[Ss]ervicii%s+de%s+tractari.-:%s*([%d%/%.,]+)")
                if not t then t = l:match("[Vv]ehicles%s+to%s+tow.-:%s*([%d%/%.,]+)") end
                if t then weekTows = t end
            end
        end
    end

    return weekDone, weekAction, weekTows
end

local function requestRaport()
    raportRequestPending = true
    raportRequestAt = os.clock()
    sampSendChat("/raport")
end

local function scheduleDutyHudInitialRequests()
    if dutyInitialRequestsScheduled then return end
    dutyInitialRequestsScheduled = true
    lua_thread.create(function()
        wait(5000)
        if not isDuty then
            dutyInitialRequestsScheduled = false
            return
        end
        if sampIsChatInputActive() or sampIsDialogActive() or isSampfuncsConsoleActive() then
            wait(1000)
        end
        if not isDuty then
            dutyInitialRequestsScheduled = false
            return
        end
        requestTowpoints()
        if cfg.settings.auto_raport_detect_enabled then
            wait(500)
            requestRaport()
            nextRaportAt = os.clock() + 30
        else
            nextRaportAt = 0.0
        end
        nextTowpointsRefreshAt = os.clock() + 30
        dutyInitialRequestsScheduled = false
    end)
end

local function runStartupHudBootstrap()
    lua_thread.create(function()
        while true do
            wait(500)
            local ok, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            if ok and sampIsPlayerConnected(id) then
                break
            end
        end

        wait(1200)
        startupHudBootstrapActive = true
        sampSendChat("/duty")
        wait(5000)
        requestTowpoints()
        if cfg.settings.auto_raport_detect_enabled then
            wait(500)
            requestRaport()
        end
        wait(1600)
        sampSendChat("/duty")
        wait(4000)
        startupHudBootstrapActive = false
    end)
end

local function tryConsumeRaportDialog()
    if not raportRequestPending then return end
    if not sampIsDialogActive() then return end

    local cap = ""
    if sampGetDialogCaption then
        local ok, v = pcall(sampGetDialogCaption)
        if ok and v then cap = tostring(v) end
    end
    local body = ""
    if sampGetDialogText then
        local ok, v = pcall(sampGetDialogText)
        if ok and v then body = tostring(v) end
    end

    local lowCap = stripSampColors2(cap):lower()
    local lowBody = stripSampColors2(body):lower()
    if not (lowCap:find("faction report", 1, true) or lowBody:find("progres saptamana curenta", 1, true) or lowBody:find("current week progress", 1, true)) then
        return
    end

    local weekDone, weekAction, weekTows = parseRaportDialogText(body)
    hudState.raportWeekDone = weekDone
    hudState.raportWeekAction = weekAction
    hudState.raportWeekTows = weekTows
    hudState.raportAt = os.clock()

    raportRequestPending = false
    nextRaportAt = os.clock() + 30
    if sampCloseCurrentDialogWithButton then
        pcall(sampCloseCurrentDialogWithButton, 1)
    end
end

-- forward declaration (used inside updateImguiProcess)
local showHudEditDialog = imgui.ImBool(false)

local function updateImguiProcess()
    imgui.Process = (showMenu.v or showSplash.v or showUpdateDialog.v or showKeyDialog.v or showFvrDialog.v or showCustomDialog.v or showTdEditDialog.v or showHudEditDialog.v or showRepairConfirmDialog.v or showRefillConfirmDialog.v or hudEnabled.v or cfg.settings.hide_server_speedo)
end

local function getRealtimeVehicleSpeed(veh)
    if veh == 0 or type(getCarSpeed) ~= "function" then
        return nil
    end

    local ok, speed = pcall(getCarSpeed, veh)
    if not ok or speed == nil then
        return nil
    end

    return math.floor((tonumber(speed) or 0) * 3.6 + 0.5)
end

local function updateHudData()
    local ok, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok then
        hudState.playerId = id
        hudState.playerName = sampGetPlayerNickname(id) or ""
    end

    local skinId = getCharModel(PLAYER_PED)
    if skinId ~= hudState.skinId then
        hudState.skinId = skinId
        hudState.skinName = getSkinName(skinId)
    end

    hudState.inVehicle = isCharInAnyCar(PLAYER_PED)
    if hudState.inVehicle then
        local veh = storeCarCharIsInNoSave(PLAYER_PED)
        hudState.vehicleHandle = veh
        if veh ~= 0 then
            local model = getCarModel(veh)
            if model ~= hudState.vehicleModel then
                hudState.vehicleModel = model
                hudState.vehicleName = getVehicleName(model)
            end
            hudState.vehicleHp = math.floor(getCarHealth(veh))
        end
        if hudState.vehicleSpeedoAt > 0 and (os.clock() - hudState.vehicleSpeedoAt) > 3.5 then
            hudState.vehicleSpeed = nil
            hudState.vehicleFuel = nil
            hudState.vehicleOdometer = nil
            hudState.vehicleStatus = nil
            hudState.vehicleLocked = nil
            hudState.vehicleSpeedoAt = 0.0
        end
        local realtimeSpeed = getRealtimeVehicleSpeed(veh)
        if realtimeSpeed ~= nil then
            hudState.vehicleSpeed = realtimeSpeed
        end
    else
        hudState.vehicleHandle = 0
        hudState.vehicleModel = -1
        hudState.vehicleName = "On Foot"
        hudState.vehicleHp = 0
        hudState.vehicleSpeed = nil
        hudState.vehicleFuel = nil
        hudState.vehicleOdometer = nil
        hudState.vehicleStatus = nil
        hudState.vehicleLocked = nil
        hudState.vehicleSpeedoAt = 0.0
    end
end

-- Keybind Dialog State
showKeyDialog = imgui.ImBool(false)
local waitingForKey = nil 

showRepairConfirmDialog = imgui.ImBool(false)
showRefillConfirmDialog = imgui.ImBool(false)
local repairAsked = false
local refillAsked = false

-- Logo
local logoTexture = nil
local splashTexture = nil

-- Textdraw Font
local tdFont = nil

showUpdateDialog = imgui.ImBool(false)
local updateInfo = { version_online = nil, reason_ro = nil, reason_en = nil }
local toggleAnim = {}
showSplash = imgui.ImBool(false)
local splashProgress = 0.0
local splashStartClock = nil
local openMenuAfterSplash = false
showFvrDialog = imgui.ImBool(false)
showCustomDialog = imgui.ImBool(false)
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
local pendingUiThemeApply = nil
local menuCmdBuffer = imgui.ImBuffer(32)
hudSettingsInit = false
hudVehiclePrefixBuffer = imgui.ImBuffer(64)
hudSkinPlaceholderBuffer = imgui.ImBuffer(260)
hudVehiclePlaceholderBuffer = imgui.ImBuffer(260)
lastHudSaveAt = 0.0
lastHudPosX, lastHudPosY = 0.0, 0.0
menuRegistered = {}
firstRunDone = (cfg.settings.start ~= 0)

textdrawEditActive = false
tdEditX, tdEditY = 0, 0
tdOrigX, tdOrigY = 0, 0
showTdEditDialog = imgui.ImBool(false)

hudPosEditActive = false
hudEditX, hudEditY = 0, 0
hudOrigX, hudOrigY = 0, 0
showHudEditDialog = imgui.ImBool(false)

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
    -- Append timestamp to URL to bypass cache
    local urlWithTime = VERSION_URL .. "?t=" .. os.time()
    
    downloadUrlToFile(urlWithTime, tmp, function(id, status, p1, p2)
        -- status 6 = STATUS_ENDDOWNLOADDATA (Download complete)
        if status == 6 then
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
    end)
end

local function beginTextdrawEdit()
    local count = 0
    if cfg.settings.tow_ls_enabled then count = count + 1 end
    if cfg.settings.tow_lv_enabled then count = count + 1 end
    if cfg.settings.tow_sf_enabled then count = count + 1 end
    if cfg.settings.at_enabled then count = count + 1 end
    if cfg.settings.repair_refill_enabled then count = count + 1 end
    if cfg.settings.sellkit_enabled then count = count + 1 end
    if cfg.settings.repair_refill_me_enabled then count = count + 1 end

    local sw, sh = getScreenResolution()
    local defaultX = sw - 10
    local defaultY = sh - 31 - (count * 15)

    tdOrigX = cfg.settings.textdraw_pos_x or 0
    tdOrigY = cfg.settings.textdraw_pos_y or 0

    if (tdOrigX ~= 0) and (tdOrigY ~= 0) then
        tdEditX = tdOrigX
        tdEditY = tdOrigY
    else
        tdEditX = defaultX
        tdEditY = defaultY
    end

    textdrawEditActive = true
    showMenu.v = false
    showTdEditDialog.v = true
    imgui.Process = true
    sampSetCursorMode(true)
end

local function beginHudEdit()
    hudOrigX = cfg.settings.hud_pos_x or 0
    hudOrigY = cfg.settings.hud_pos_y or 0
    hudEditX = hudOrigX
    hudEditY = hudOrigY
    hudPosEditActive = true
    showHudEditDialog.v = true
    imgui.Process = true
    sampSetCursorMode(true)
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
            imgui.Text(T("shift1"))
            imgui.Text(T("shift2"))
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

    local isAeroTheme = tonumber(cfg.settings.ui_theme or 1) == 4
    if isAeroTheme then
        style.ScrollbarSize = 14.0
        style.ScrollbarRounding = 0.0
        style.GrabMinSize = 28.0
        style.GrabRounding = 0.0
    end

    colors[clr.Text]                   = cfgColor('text')
    colors[clr.TextDisabled]           = ImVec4(0.33, 0.33, 0.33, 1.00)
    colors[clr.WindowBg]               = cfgColor('window_bg')
    colors[clr.ChildWindowBg]          = cfgColor('child_bg')
    colors[clr.PopupBg]                = cfgColor('window_bg')
    colors[clr.Border]                 = cfgColor('separator')
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = cfgColor('frame_bg')
    colors[clr.FrameBgHovered]         = cfgColor('button_hovered')
    colors[clr.FrameBgActive]          = cfgColor('button_active')
    colors[clr.TitleBg]                = ImVec4(0.03, 0.03, 0.03, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.03, 0.03, 0.03, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg]              = ImVec4(0.05, 0.05, 0.05, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.70)
    colors[clr.ScrollbarGrab]          = getAccentColor()
    colors[clr.ScrollbarGrabHovered]   = cfgColor('button_hovered')
    colors[clr.ScrollbarGrabActive]    = cfgColor('button_active')
    if isAeroTheme then
        colors[clr.ScrollbarBg]          = ImVec4(0.96, 0.97, 0.97, 1.00)
        colors[clr.ScrollbarGrab]        = ImVec4(0.79, 0.81, 0.82, 1.00)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.68, 0.78, 0.86, 1.00)
        colors[clr.ScrollbarGrabActive]  = ImVec4(0.48, 0.64, 0.78, 1.00)
    end
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
    colors[clr.PlotLinesHovered]       = getAccentColor()
    colors[clr.TextSelectedBg]         = ImVec4(0.84, 0.81, 0.59, 0.28)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.00, 0.00, 0.00, 0.45)
end

apply_style()

-- =========================
-- CUSTOM WIDGETS
-- =========================
function imgui.ToggleButton(str_id, v)
    local p = imgui.GetCursorScreenPos()
    local draw_list = imgui.GetWindowDrawList()
    local themeId = tonumber(cfg.settings.ui_theme or 1)
    local height = themeId == 2 and 20 or 18
    local width = 54
    if themeId == 4 then
        p = imgui.ImVec2(p.x, p.y + 4)
    end

    local toggled = false
    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, math.max(height, 20))) then
        v.v = not v.v
        toggled = true
        toggleAnim[str_id] = 1.0
    end
    local hovered = imgui.IsItemHovered()

    local anim = toggleAnim[str_id] or 0.0
    if anim > 0.0 then
        toggleAnim[str_id] = math.max(0.0, anim - 0.12)
    end

    local function c(v4)
        return imgui.ColorConvertFloat4ToU32(v4)
    end

    if themeId == 4 then
        local trackY = p.y + (height * 0.5)
        local knobW = 9
        local knobH = 20
        local trackCol = c(imgui.ImVec4(0.74, 0.74, 0.74, 1.0))
        local activeCol = c(getAccentColor())
        local knobTop = imgui.ImVec2(p.x + (v.v and (width - knobW) or 0), p.y - 1)
        local knobBottom = imgui.ImVec2(knobTop.x + knobW, knobTop.y + knobH)
        local knobCol = hovered and c(imgui.ImVec4(0.95, 0.97, 0.98, 1.0)) or c(imgui.ImVec4(0.86, 0.88, 0.89, 1.0))
        local knobBorder = c(imgui.ImVec4(0.48, 0.50, 0.52, 1.0))
        draw_list:AddLine(imgui.ImVec2(p.x, trackY), imgui.ImVec2(p.x + width, trackY), trackCol, 1.0)
        if v.v then
            draw_list:AddLine(imgui.ImVec2(p.x, trackY), imgui.ImVec2(knobTop.x + (knobW * 0.5), trackY), activeCol, 2.0)
        end
        draw_list:AddRectFilled(knobTop, knobBottom, knobCol, 2)
        draw_list:AddRect(knobTop, knobBottom, knobBorder, 2, 0, 1.0)
    elseif themeId == 2 then
        local radius = 9
        local trackMin = imgui.ImVec2(p.x, p.y + 1)
        local trackMax = imgui.ImVec2(p.x + width, p.y + 19)
        local offCol = c(imgui.ImVec4(0.05, 0.18, 0.09, 1.0))
        local onCol = c(imgui.ImVec4(0.78, 0.08, 0.12, 1.0))
        local borderCol = c(imgui.ImVec4(0.84, 0.80, 0.55, 1.0))
        local knobX = p.x + (v.v and (width - 18) or 0) + 9
        draw_list:AddRectFilled(trackMin, trackMax, v.v and onCol or offCol, radius)
        draw_list:AddRect(trackMin, trackMax, borderCol, radius, 0, 1.0)
        draw_list:AddCircleFilled(imgui.ImVec2(knobX, p.y + 10), 7.0, c(imgui.ImVec4(0.96, 0.98, 0.94, 1.0)), 24)
        draw_list:AddCircle(imgui.ImVec2(knobX, p.y + 10), 7.0, hovered and c(imgui.ImVec4(1.0, 0.85, 0.30, 1.0)) or borderCol, 24, 1.2)
    elseif themeId == 3 then
        local trackMin = imgui.ImVec2(p.x, p.y + 2)
        local trackMax = imgui.ImVec2(p.x + width, p.y + 18)
        local fillMax = imgui.ImVec2(p.x + (v.v and width or 18), p.y + 18)
        local knobX = p.x + (v.v and (width - 14) or 0)
        draw_list:AddRectFilled(trackMin, trackMax, c(imgui.ImVec4(0.0, 0.0, 0.0, 1.0)), 2)
        draw_list:AddRectFilled(trackMin, fillMax, c(imgui.ImVec4(0.84, 0.81, 0.59, v.v and 0.85 or 0.25)), 2)
        draw_list:AddRect(trackMin, trackMax, c(imgui.ImVec4(0.84, 0.81, 0.59, 0.70)), 2, 0, 1.0)
        draw_list:AddRectFilled(imgui.ImVec2(knobX, p.y), imgui.ImVec2(knobX + 14, p.y + 20), hovered and c(imgui.ImVec4(0.92, 0.90, 0.74, 1.0)) or c(imgui.ImVec4(0.75, 0.72, 0.52, 1.0)), 2)
    else
        local trackMin = imgui.ImVec2(p.x, p.y + 3)
        local trackMax = imgui.ImVec2(p.x + width, p.y + 17)
        local knobX = p.x + (v.v and (width - 16) or 0)
        draw_list:AddRectFilled(trackMin, trackMax, c(imgui.ImVec4(0.08, 0.08, 0.08, 1.0)), 7)
        draw_list:AddRectFilled(trackMin, imgui.ImVec2(p.x + (v.v and width or 16), trackMax.y), c(getAccentColor()), 7)
        draw_list:AddRect(trackMin, trackMax, c(imgui.ImVec4(0.84, 0.81, 0.59, 0.45)), 7, 0, 1.0)
        draw_list:AddCircleFilled(imgui.ImVec2(knobX + 8, p.y + 10), 8.0, hovered and c(imgui.ImVec4(0.96, 0.94, 0.78, 1.0)) or c(imgui.ImVec4(0.84, 0.81, 0.59, 1.0)), 24)
    end
    return toggled
end

function imgui.ThemeSliderInt(str_id, value, minValue, maxValue, width)
    local themeId = tonumber(cfg.settings.ui_theme or 1)
    local draw_list = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local barWidth = width or 220
    local barHeight = themeId == 4 and 22 or 24
    local changed = false
    imgui.InvisibleButton(str_id, imgui.ImVec2(barWidth, barHeight))
    local io = imgui.GetIO()
    if imgui.IsItemActive() or (imgui.IsItemHovered() and imgui.IsMouseDown(0)) then
        local t = (io.MousePos.x - p.x) / barWidth
        if t < 0 then t = 0 end
        if t > 1 then t = 1 end
        local newValue = math.floor(minValue + ((maxValue - minValue) * t) + 0.5)
        if newValue ~= value.v then
            value.v = newValue
            changed = true
        end
    end

    local fraction = (value.v - minValue) / (maxValue - minValue)
    if fraction < 0 then fraction = 0 end
    if fraction > 1 then fraction = 1 end
    local hovered = imgui.IsItemHovered()
    local function c(v4) return imgui.ColorConvertFloat4ToU32(v4) end
    local accent = getAccentColor()

    if themeId == 4 then
        local trackY = p.y + (barHeight * 0.5)
        local knobW = 9
        local knobH = 20
        local knobX = p.x + (barWidth - knobW) * fraction
        draw_list:AddLine(imgui.ImVec2(p.x, trackY), imgui.ImVec2(p.x + barWidth, trackY), c(imgui.ImVec4(0.74, 0.74, 0.74, 1.0)), 1.0)
        draw_list:AddLine(imgui.ImVec2(p.x, trackY), imgui.ImVec2(knobX + (knobW * 0.5), trackY), c(accent), 2.0)
        draw_list:AddRectFilled(imgui.ImVec2(knobX, p.y + 1), imgui.ImVec2(knobX + knobW, p.y + 1 + knobH), hovered and c(imgui.ImVec4(0.95, 0.97, 0.98, 1.0)) or c(imgui.ImVec4(0.86, 0.88, 0.89, 1.0)), 2)
        draw_list:AddRect(imgui.ImVec2(knobX, p.y + 1), imgui.ImVec2(knobX + knobW, p.y + 1 + knobH), c(imgui.ImVec4(0.48, 0.50, 0.52, 1.0)), 2, 0, 1.0)
    elseif themeId == 2 then
        local y = p.y + 10
        local knobX = p.x + barWidth * fraction
        draw_list:AddLine(imgui.ImVec2(p.x, y), imgui.ImVec2(p.x + barWidth, y), c(imgui.ImVec4(0.04, 0.22, 0.11, 1.0)), 5.0)
        draw_list:AddLine(imgui.ImVec2(p.x, y), imgui.ImVec2(knobX, y), c(imgui.ImVec4(0.78, 0.08, 0.12, 1.0)), 5.0)
        draw_list:AddLine(imgui.ImVec2(p.x, y + 5), imgui.ImVec2(p.x + barWidth, y + 5), c(imgui.ImVec4(0.84, 0.80, 0.55, 0.55)), 1.0)
        draw_list:AddCircleFilled(imgui.ImVec2(knobX, y), 8.0, c(imgui.ImVec4(0.96, 0.98, 0.94, 1.0)), 24)
        draw_list:AddCircle(imgui.ImVec2(knobX, y), 8.0, hovered and c(imgui.ImVec4(1.0, 0.85, 0.30, 1.0)) or c(imgui.ImVec4(0.84, 0.80, 0.55, 1.0)), 24, 1.2)
    elseif themeId == 3 then
        local y = p.y + 11
        local knobX = p.x + barWidth * fraction
        draw_list:AddRectFilled(imgui.ImVec2(p.x, y - 3), imgui.ImVec2(p.x + barWidth, y + 3), c(imgui.ImVec4(0.0, 0.0, 0.0, 1.0)), 1)
        draw_list:AddRectFilled(imgui.ImVec2(p.x, y - 3), imgui.ImVec2(knobX, y + 3), c(imgui.ImVec4(0.84, 0.81, 0.59, 0.88)), 1)
        draw_list:AddRect(imgui.ImVec2(p.x, y - 3), imgui.ImVec2(p.x + barWidth, y + 3), c(imgui.ImVec4(0.84, 0.81, 0.59, 0.75)), 1, 0, 1.0)
        draw_list:AddRectFilled(imgui.ImVec2(knobX - 5, p.y + 1), imgui.ImVec2(knobX + 5, p.y + 21), hovered and c(imgui.ImVec4(0.92, 0.90, 0.74, 1.0)) or c(imgui.ImVec4(0.75, 0.72, 0.52, 1.0)), 1)
    else
        local y = p.y + 11
        local knobX = p.x + barWidth * fraction
        draw_list:AddRectFilled(imgui.ImVec2(p.x, y - 4), imgui.ImVec2(p.x + barWidth, y + 4), c(imgui.ImVec4(0.08, 0.08, 0.08, 1.0)), 4)
        draw_list:AddRectFilled(imgui.ImVec2(p.x, y - 4), imgui.ImVec2(knobX, y + 4), c(accent), 4)
        draw_list:AddCircleFilled(imgui.ImVec2(knobX, y), 8.0, hovered and c(imgui.ImVec4(0.96, 0.94, 0.78, 1.0)) or c(imgui.ImVec4(0.84, 0.81, 0.59, 1.0)), 24)
    end

    return changed
end

local function win7KeyButton(label, size)
    if tonumber(cfg.settings.ui_theme or 1) ~= 4 then
        return imgui.Button(label, size)
    end

    local clicked = imgui.InvisibleButton("##win7_key_" .. label, size)
    local min = imgui.GetItemRectMin()
    local max = imgui.GetItemRectMax()
    local hovered = imgui.IsItemHovered()
    local dl = imgui.GetWindowDrawList()
    local topCol = hovered and imgui.ImVec4(0.93, 0.96, 0.98, 1.0) or imgui.ImVec4(0.86, 0.90, 0.93, 1.0)
    local botCol = hovered and imgui.ImVec4(0.72, 0.84, 0.94, 1.0) or imgui.ImVec4(0.70, 0.76, 0.81, 1.0)
    local borderCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.42, 0.49, 0.55, 1.0))
    local midY = min.y + ((max.y - min.y) * 0.5)

    dl:AddRectFilled(min, imgui.ImVec2(max.x, midY), imgui.ColorConvertFloat4ToU32(topCol), 2, 1 + 2)
    dl:AddRectFilled(imgui.ImVec2(min.x, midY), max, imgui.ColorConvertFloat4ToU32(botCol), 2, 4 + 8)
    dl:AddRect(min, max, borderCol, 2, 0, 1.0)
    local textSize = imgui.CalcTextSize(label)
    dl:AddText(imgui.ImVec2(min.x + 8, min.y + ((max.y - min.y - textSize.y) * 0.5)), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.08, 0.13, 0.18, 1.0)), label)
    local ax = max.x - 14
    local ay = min.y + ((max.y - min.y) * 0.5) - 1
    local arrowCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.05, 0.16, 0.25, 1.0))
    dl:AddTriangleFilled(imgui.ImVec2(ax, ay), imgui.ImVec2(ax + 8, ay), imgui.ImVec2(ax + 4, ay + 5), arrowCol)
    return clicked
end

local function pressF8()
    ffi.C.keybd_event(VK_F8, 0, 0, 0)
    wait(100)
    ffi.C.keybd_event(VK_F8, 0, KEYEVENTF_KEYUP, 0)
end

local function processDlCommand()
    if sampProcessChatInput then
        sampProcessChatInput("/dl")
    else
        sampSendChat("/dl")
    end
end

local function runAtentieTractezSequence()
    lua_thread.create(function()
        sampSendChat("/s " .. T("at_tractez1"))
        sampSendChat("/s " .. T("at_tractez2"))
        if not cfg.settings.at_auto_dl_enabled then
            return
        end
        wait(500)
        processDlCommand()
        wait(500)
        pressF8()
        wait(500)
        processDlCommand()
    end)
end

local processServiceForPlayer

local function getMouseScreenPos()
    if getCursorPos then
        local ok, x, y = pcall(getCursorPos)
        if ok and x and y then return tonumber(x), tonumber(y) end
    end
    if imgui.GetMousePos then
        local ok, p = pcall(imgui.GetMousePos)
        if ok and p then return tonumber(p.x), tonumber(p.y) end
    end
    return nil, nil
end

local function worldToScreenSafe(x, y, z)
    if not convert3DCoordsToScreen then return nil, nil end
    local ok, sx, sy = pcall(convert3DCoordsToScreen, x, y, z)
    if ok and sx and sy then
        return tonumber(sx), tonumber(sy)
    end
    return nil, nil
end

local function sampPlayerColorToU32(playerId, fallback)
    if not sampIsPlayerConnected(playerId) then return fallback end
    local ok, color = pcall(sampGetPlayerColor, playerId)
    if not ok or not color then return fallback end

    local rgb = bit.band(color, 0xFFFFFF)
    local r = bit.rshift(bit.band(rgb, 0xFF0000), 16)
    local g = bit.rshift(bit.band(rgb, 0x00FF00), 8)
    local b = bit.band(rgb, 0x0000FF)
    return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r / 255, g / 255, b / 255, 1.0))
end

local function isHitmanPlayer(playerId)
    if not playerId or playerId < 0 or not sampIsPlayerConnected(playerId) then
        return false
    end
    local ok, color = pcall(sampGetPlayerColor, playerId)
    if not ok or not color then
        return false
    end
    return bit.band(color, 0xFFFFFF) == 0xAA3333
end

local function pickPlayerUnderCursor()
    local mx, my = getMouseScreenPos()
    if not mx or not my then return -1 end

    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    local bestId = -1
    local bestScore = 45.0

    for id = 0, 1000 do
        if sampIsPlayerConnected(id) and not isHitmanPlayer(id) then
            local result, char = sampGetCharHandleBySampPlayerId(id)
            if result and doesCharExist(char) and char ~= PLAYER_PED then
                local x, y, z = getCharCoordinates(char)
                local dist = getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z)
                if dist <= 80.0 then
                    local sx, sy = worldToScreenSafe(x, y, z + 0.8)
                    if sx and sy then
                        local dx = sx - mx
                        local dy = sy - my
                        local score = math.sqrt(dx * dx + dy * dy)
                        if score < bestScore then
                            bestScore = score
                            bestId = id
                        end
                    end
                end
            end
        end
    end

    return bestId
end

local function handleAltPlayerPicker()
    if showMenu.v or showSplash.v or showUpdateDialog.v or showKeyDialog.v or showFvrDialog.v or showCustomDialog.v or showTdEditDialog.v or showRepairConfirmDialog.v or showRefillConfirmDialog.v or showHudEditDialog.v then
        altPlayerPickActive = false
        radialMenuActive = false
        radialRightWasDown = false
        return false
    end
    if sampIsChatInputActive() or sampIsDialogActive() or isSampfuncsConsoleActive() then
        altPlayerPickActive = false
        radialMenuActive = false
        radialRightWasDown = false
        return false
    end

    if not cfg.settings.mouse_detect_enabled or (tonumber(cfg.settings.mouse_detect_key) or 0) <= 0 then
        altPlayerPickActive = false
        radialMenuActive = false
        radialRightWasDown = false
        return false
    end

    local detectKeyDown = isKeyDown(cfg.settings.mouse_detect_key)
    local rightDown = isKeyDown(vkeys.VK_RBUTTON or 0x02)
    altPlayerPickActive = detectKeyDown
    if detectKeyDown and rightDown and not radialRightWasDown then
        local id = pickPlayerUnderCursor()
        if id >= 0 then
            altPickedPlayerId = id
            radialMenuTargetId = id
            radialMenuActive = true
            radialMenuHoveredAction = nil
            local mx, my = getMouseScreenPos()
            radialMenuCenterX = mx or 0
            radialMenuCenterY = my or 0
        end
    end
    if radialRightWasDown and not rightDown then
        if radialMenuActive and radialMenuTargetId >= 0 and radialMenuHoveredAction then
            processServiceForPlayer(radialMenuTargetId, radialMenuHoveredAction)
        end
        radialMenuActive = false
        radialMenuTargetId = -1
        radialMenuHoveredAction = nil
    end
    radialRightWasDown = rightDown
    if not detectKeyDown then
        radialMenuActive = false
        radialMenuTargetId = -1
        radialMenuHoveredAction = nil
        radialRightWasDown = false
    end
    return detectKeyDown or radialMenuActive
end

local function drawRadialActionMenu()
    if not radialMenuActive or radialMenuTargetId < 0 then return end
    if showMenu.v or showSplash.v or showUpdateDialog.v or showKeyDialog.v or showFvrDialog.v or showCustomDialog.v or showTdEditDialog.v or showRepairConfirmDialog.v or showRefillConfirmDialog.v or showHudEditDialog.v then
        radialMenuActive = false
        radialMenuTargetId = -1
        radialMenuHoveredAction = nil
        radialRightWasDown = false
        return
    end
    local mx, my = getMouseScreenPos()
    if not mx or not my then return end

    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
    imgui.SetNextWindowSize(imgui.ImVec2(sw, sh), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.Begin("##TTH_RADIAL_MENU", nil,
        (imgui.WindowFlags.NoTitleBar or 0)
        + (imgui.WindowFlags.NoResize or 0)
        + (imgui.WindowFlags.NoMove or 0)
        + (imgui.WindowFlags.NoScrollbar or 0)
        + (imgui.WindowFlags.NoSavedSettings or 0)
        + (imgui.WindowFlags.NoInputs or 0)
    )

    local cx = radialMenuCenterX
    local cy = radialMenuCenterY
    local options = {
        { label = "Repair/Refill", action = "repair_refill", angle = -90 },
        { label = "SellKit", action = "sellkit", angle = 0 },
        { label = "Refill", action = "refill", angle = 90 },
        { label = "Repair", action = "repair", angle = 180 }
    }

    local dx = mx - cx
    local dy = my - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    local hovered = nil
    if dist >= 40 and dist <= 174 then
        local deg = math.deg(math.atan2(dy, dx))
        if deg < 0 then deg = deg + 360 end
        if deg >= 315 or deg < 45 then
            hovered = "sellkit"
        elseif deg >= 45 and deg < 135 then
            hovered = "refill"
        elseif deg >= 135 and deg < 225 then
            hovered = "repair"
        else
            hovered = "repair_refill"
        end
    end
    radialMenuHoveredAction = hovered

    local dl = imgui.GetWindowDrawList()
    local gold = imgui.ColorConvertFloat4ToU32(getAccentColor())
    local softGold = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.60))
    local faintGold = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.28))
    local outerBg = 0xD0060708
    local innerBg = 0xEE111213
    local itemBg = 0xEE161718
    local itemHover = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.93))
    local textCol = 0xFFB0B0B0
    local selectedTextCol = 0xFF08090A
    local mutedCol = sampPlayerColorToU32(radialMenuTargetId, gold)

    dl:AddCircleFilled(imgui.ImVec2(cx, cy), 182, outerBg, 96)
    dl:AddCircle(imgui.ImVec2(cx, cy), 182, faintGold, 96, 5)
    dl:AddCircle(imgui.ImVec2(cx, cy), 177, softGold, 96, 1.5)
    dl:AddCircleFilled(imgui.ImVec2(cx, cy), 72, innerBg, 64)
    dl:AddCircle(imgui.ImVec2(cx, cy), 72, softGold, 64, 1.2)
    dl:AddCircle(imgui.ImVec2(cx, cy), 108, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.15)), 84, 1)

    local targetName = sampGetPlayerNickname(radialMenuTargetId) or "Player"
    local centerLabel = string.format("%s[%d]", targetName, radialMenuTargetId)
    if #centerLabel > 30 then
        centerLabel = centerLabel:sub(1, 27) .. "..."
    end
    local centerSz = imgui.CalcTextSize(centerLabel)
    dl:AddText(imgui.ImVec2(cx - centerSz.x * 0.5, cy - 7), mutedCol, centerLabel)

    for _, opt in ipairs(options) do
        local rad = math.rad(opt.angle)
        local ox = cx + math.cos(rad) * 132
        local oy = cy + math.sin(rad) * 132
        local selected = hovered == opt.action
        local w = opt.action == "repair_refill" and 150 or 108
        local h = 38
        local min = imgui.ImVec2(ox - w * 0.5, oy - h * 0.5)
        local max = imgui.ImVec2(ox + w * 0.5, oy + h * 0.5)
        dl:AddRectFilled(min, max, selected and itemHover or itemBg, 7)
        dl:AddRect(min, max, selected and gold or faintGold, 7, 0, selected and 1.6 or 1.0)
        local sz = imgui.CalcTextSize(opt.label)
        dl:AddText(imgui.ImVec2(ox - sz.x * 0.5, oy - sz.y * 0.5), selected and selectedTextCol or textCol, opt.label)
    end

    imgui.End()
    imgui.PopStyleVar()
    imgui.PopStyleColor()
end

-- =========================
-- MAIN
-- =========================
function main()
    repeat wait(0) until isSampAvailable()

    if doesFileExist("moonloader/resource/TowTruckHelper/MenuLogo.png") then
        logoTexture = imgui.CreateTextureFromFile("moonloader/resource/TowTruckHelper/MenuLogo.png")
    end
    loadMenuAudio()
    if doesFileExist("moonloader/resource/TowTruckHelper/LoadingScreen.png") then
        splashTexture = imgui.CreateTextureFromFile("moonloader/resource/TowTruckHelper/LoadingScreen.png")
    end
    
    -- Create Font for Textdraw
    tdFont = renderCreateFont("Arial", 10, 5) -- 5 = FCR_BORDER

    setupHudAssets()
    if doesFileExist(cfg.settings.hud_skin_placeholder) then
        skinPlaceholderTex = imgui.CreateTextureFromFile(cfg.settings.hud_skin_placeholder)
    end
    if doesFileExist(cfg.settings.hud_vehicle_placeholder) then
        vehiclePlaceholderTex = imgui.CreateTextureFromFile(cfg.settings.hud_vehicle_placeholder)
    end
    loadSpeedoIcons()
    loadThemePreviewTextures()
    loadWin7ThemeBackgrounds()
    hudEnabled.v = not not cfg.settings.hud_enabled
    updateImguiProcess()

    lua_thread.create(function()
        while true do
            wait(200)
            updateHudData()
        end
    end)

    runStartupHudBootstrap()

    registerMenuCommand(cfg.settings.menu_cmd or "ttc")

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
            setAudioStreamState(audioStream, AUDIOSTREAM_STATE.STOP)
            audioStream = nil
        end
        if loadMenuAudio() then
            sampAddChatMessage(T("msg_prefix") .. "Audio reloaded successfully!", -1)
            if audioStream and cfg.settings.music_enabled and showMenu.v then
                local vol = tonumber(cfg.settings.music_volume) or 50
                local finalVol = vol / 100.0
                if finalVol < 0.0 then finalVol = 0.0 end
                if finalVol > 1.0 then finalVol = 1.0 end
                setAudioStreamState(audioStream, AUDIOSTREAM_STATE.PLAY)
                setAudioStreamVolume(audioStream, finalVol)
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
    sampRegisterChatCommand("mycc", cmdmycc)
    sampRegisterChatCommand("gkit", cmdgkit)

    sampRegisterChatCommand("hidespeedo", function()
        cfg.settings.hide_server_speedo = not cfg.settings.hide_server_speedo
        speedoTdIds = {}
        footerTdIds = {}
        inicfg.save(cfg, "TowTruckHelper.ini")
        updateImguiProcess()
        sampAddChatMessage(T("msg_prefix") .. (cfg.settings.hide_server_speedo and "Server speedo ascuns." or "Server speedo vizibil."), -1)
    end)

    sampRegisterChatCommand("speedoprobe", function()
        cfg.settings.speedo_probe = not cfg.settings.speedo_probe
        inicfg.save(cfg, "TowTruckHelper.ini")
        sampAddChatMessage(T("msg_prefix") .. (cfg.settings.speedo_probe and "Speedo probe ON (log textdraw)." or "Speedo probe OFF."), -1)
    end)

    lua_thread.create(autoRepairLoop)

    sampAddChatMessage(string.format(T("msg_prefix") .. T("msg_welcome2"), cfg.settings.menu_cmd), -1)
    if cfg.settings.update_auto_check then
        lua_thread.create(function()
            while true do
                wait(500)
                local ok, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                if ok and sampIsPlayerConnected(id) then
                    break
                end
            end
            wait(1000)
            checkUpdateOnce()
        end)
    end
    
    
    while true do
        wait(0)

        local uiAlreadyOpen = showMenu.v or showSplash.v or showUpdateDialog.v or showKeyDialog.v or showFvrDialog.v or showCustomDialog.v or showTdEditDialog.v or showRepairConfirmDialog.v or showRefillConfirmDialog.v or showHudEditDialog.v
        local altPickerWanted = (not uiAlreadyOpen) and handleAltPlayerPicker() or false
        local cursorWanted = uiAlreadyOpen or altPickerWanted
        if altPickerWanted then
            imgui.Process = true
        elseif not cursorWanted then
            updateImguiProcess()
        end
        imgui.ShowCursor = cursorWanted
        imgui.DisableInput = not cursorWanted
        imgui.LockPlayer = cursorWanted
        if cursorWanted ~= cursorStateLast then
            cursorStateLast = cursorWanted
            sampSetCursorMode(cursorWanted)
        end

        tryConsumeRaportDialog()

        if showMenu.v and wasKeyPressed(vkeys.VK_ESCAPE) then
            setMenu(false)
        end
        
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
                runAtentieTractezSequence()
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

            if modEnabled.v and startStopEnabled.v and isCharInAnyCar(PLAYER_PED) then
                local veh = storeCarCharIsInNoSave(PLAYER_PED)
                if veh ~= 0 then
                    local now = os.clock()
                    local ws = isKeyDown(vkeys.VK_W) or isKeyDown(vkeys.VK_S)
                    if not startStopEngineAssumedOn and (now - startStopLastToggleAt) < 1.3 then
                        ws = false
                    end
                    if ws then
                        startStopLastWsTime = now
                        if not startStopEngineAssumedOn and (now - startStopLastToggleAt) >= 0.8 then
                            sampSendChat("/engine")
                            sampSendChat("/lights")
                            startStopEngineAssumedOn = true
                            startStopLastToggleAt = now
                        end
                    else
                        if startStopEngineAssumedOn and (now - startStopLastWsTime) >= 10 and (now - startStopLastToggleAt) >= 0.8 then
                            sampSendChat("/engine")
                            sampSendChat("/lights")
                            startStopEngineAssumedOn = false
                            startStopLastToggleAt = now
                        end
                    end
                end
            end
        end

        local now = os.clock()
        if towpointsRequestPending and (now - towpointsRequestAt) > 6.0 then
            towpointsRequestPending = false
        end
        if raportRequestPending and (now - raportRequestAt) > 6.0 then
            raportRequestPending = false
        end
        if isDuty then
            local towpointsRefresh = 30
            local raportRefresh = 30
            if nextTowpointsRefreshAt == 0.0 then
                nextTowpointsRefreshAt = now + towpointsRefresh
            end
            if not towpointsRequestPending and now >= nextTowpointsRefreshAt then
                if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                    requestTowpoints()
                    nextTowpointsRefreshAt = now + towpointsRefresh
                end
            end

            if cfg.settings.auto_raport_detect_enabled then
                if nextRaportAt == 0.0 then
                    nextRaportAt = now + raportRefresh
                end
                if not raportRequestPending and now >= nextRaportAt then
                    if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
                        requestRaport()
                        nextRaportAt = now + raportRefresh
                    end
                end
            else
                raportRequestPending = false
                nextRaportAt = 0.0
            end
        else
            nextTowpointsRefreshAt = 0.0
            nextRaportAt = 0.0
        end
        
        -- Render Textdraw
        if textdrawEditActive then
            local speed = 1
            if isKeyDown(vkeys.VK_SHIFT) then speed = 10 end
            if wasKeyPressed(vkeys.VK_UP) then tdEditY = tdEditY - speed end
            if wasKeyPressed(vkeys.VK_DOWN) then tdEditY = tdEditY + speed end
            if wasKeyPressed(vkeys.VK_LEFT) then tdEditX = tdEditX - speed end
            if wasKeyPressed(vkeys.VK_RIGHT) then tdEditX = tdEditX + speed end
        end

        if hudPosEditActive then
            local speed = 1
            if isKeyDown(vkeys.VK_SHIFT) then speed = 10 end
            if wasKeyPressed(vkeys.VK_UP) then hudEditY = hudEditY - speed end
            if wasKeyPressed(vkeys.VK_DOWN) then hudEditY = hudEditY + speed end
            if wasKeyPressed(vkeys.VK_LEFT) then hudEditX = hudEditX - speed end
            if wasKeyPressed(vkeys.VK_RIGHT) then hudEditX = hudEditX + speed end
        end

        if cfg.settings.textdraw_enabled and tdFont then
            local lines = {}

            local function getKeyName(k)
                if not k or k == 0 then return "" end
                return vkeys.id_to_name(k) or tostring(k)
            end

            if cfg.settings.tow_ls_enabled then
                table.insert(lines, { txt = T("tow_ls"), key = getKeyName(cfg.settings.tow_ls_key) })
            end
            if cfg.settings.tow_lv_enabled then
                table.insert(lines, { txt = T("tow_lv"), key = getKeyName(cfg.settings.tow_lv_key) })
            end
            if cfg.settings.tow_sf_enabled then
                table.insert(lines, { txt = T("tow_sf"), key = getKeyName(cfg.settings.tow_sf_key) })
            end
            if cfg.settings.at_enabled then
                table.insert(lines, { txt = T("at_tractez1"), key = getKeyName(cfg.settings.at_key) })
            end
            if cfg.settings.repair_refill_enabled then
                table.insert(lines, { txt = T("repair_refill"), key = getKeyName(cfg.settings.repair_refill_key) })
            end
            if cfg.settings.sellkit_enabled then
                table.insert(lines, { txt = T("sell_kit"), key = getKeyName(cfg.settings.sellkit_key) })
            end
            if cfg.settings.repair_refill_me_enabled then
                table.insert(lines, { txt = T("repair_refill_me"), key = getKeyName(cfg.settings.repair_refill_me_key) })
            end
            if cfg.settings.mouse_detect_enabled then
                table.insert(lines, { txt = T("mouse_detect"), key = getKeyName(cfg.settings.mouse_detect_key) })
            end

            if #lines > 0 then
                local sw, sh = getScreenResolution()
                local x, y

                if textdrawEditActive then
                    x = tdEditX
                    y = tdEditY
                else
                    local cx = cfg.settings.textdraw_pos_x or 0
                    local cy = cfg.settings.textdraw_pos_y or 0
                    if cx ~= 0 and cy ~= 0 then
                        x = cx
                        y = cy
                    else
                        x = sw - 10
                        y = sh - 31 - (#lines * 15)
                    end
                end

                for i, data in ipairs(lines) do
                    local keyStr = ""
                    if data.key ~= "" then
                        keyStr = " [" .. data.key .. "]"
                    end

                    local wText = renderGetFontDrawTextLength(tdFont, data.txt)
                    local wKey = renderGetFontDrawTextLength(tdFont, keyStr)
                    local totalWidth = wText + wKey

                    local startX = x - totalWidth

                    renderFontDrawText(tdFont, data.txt, startX, y + (i-1)*15, 0xFFFFFFFF)

                    if keyStr ~= "" then
                        renderFontDrawText(tdFont, keyStr, startX + wText, y + (i-1)*15, 0xFFffe699)
                    end
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

function processServiceForPlayer(targetId, serviceType)
    if not targetId or targetId < 0 or not sampIsPlayerConnected(targetId) then
        sampAddChatMessage(T("msg_prefix") .. T("id_invalid"), -1)
        return
    end

    if isHitmanPlayer(targetId) then
        sampAddChatMessage(T("msg_prefix") .. T("msg_hitman"), -1)
        return
    end

    local color = sampGetPlayerColor(targetId)
    local rgb = bit.band(color, 0xFFFFFF)

    local price = 50
    local kitrepair = 4000
    local kitfuel = 8000
    if rgb == 0xF5DEB3 then price = 1 end

    if serviceType == "repair_refill" then
        local result, char = sampGetCharHandleBySampPlayerId(targetId)
        if result and not isCharInAnyCar(char) then
            sampAddChatMessage(T("msg_prefix") .. T("msg_target_no_veh"), -1)
            return
        end
        sampSendChat("/repair " .. targetId .. " " .. price)
        lua_thread.create(function()
            wait(500)
            sampSendChat("/refill " .. targetId .. " " .. price)
        end)
    elseif serviceType == "sellkit" then
        sellkitState.active = true
        sellkitState.targetId = targetId
        sellkitState.lastType = 'fuel'
        sellkitState.triedFuel = true
        sellkitState.triedRepair = false
        sellkitState.kitfuel = kitfuel
        sellkitState.kitrepair = kitrepair
        sellkitState.startedAt = os.clock()
        sampSendChat("/sellkit " .. targetId .. " fuel " .. kitfuel)

        lua_thread.create(function()
            wait(800)
            if sellkitState.active and not sellkitState.triedRepair then
                 sellkitState.triedRepair = true
                 sellkitState.lastType = 'repair'
                 sampSendChat("/sellkit " .. sellkitState.targetId .. " repair " .. sellkitState.kitrepair)
            end
        end)
    elseif serviceType == "repair" then
        local result, char = sampGetCharHandleBySampPlayerId(targetId)
        if result and not isCharInAnyCar(char) then
            sampAddChatMessage(T("msg_prefix") .. T("msg_target_no_veh"), -1)
            return
        end
        sampSendChat("/repair " .. targetId .. " " .. price)
    elseif serviceType == "refill" then
        local result, char = sampGetCharHandleBySampPlayerId(targetId)
        if result and not isCharInAnyCar(char) then
            sampAddChatMessage(T("msg_prefix") .. T("msg_target_no_veh"), -1)
            return
        end
        sampSendChat("/refill " .. targetId .. " " .. price)
    end
end

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

    processServiceForPlayer(closestId, type)
end

-- =========================
-- MENU
-- =========================
function setMenu(state)
    showMenu.v = state
    if state then
        altPlayerPickActive = false
        altPickedPlayerId = -1
        radialMenuActive = false
        radialMenuTargetId = -1
        radialMenuHoveredAction = nil
        radialRightWasDown = false
    end
    updateImguiProcess()
    sampSetCursorMode(state)

    if audioStream then
        local vol = tonumber(cfg.settings.music_volume) or 50
        local enabled = cfg.settings.music_enabled
        if state and enabled then
            local finalVol = vol / 100.0
            if finalVol < 0.0 then finalVol = 0.0 end
            if finalVol > 1.0 then finalVol = 1.0 end
            setAudioStreamState(audioStream, AUDIOSTREAM_STATE.PLAY)
            setAudioStreamVolume(audioStream, finalVol)
        else
            setAudioStreamState(audioStream, AUDIOSTREAM_STATE.STOP)
        end
    end
end

function debugAudioCmd()
    if audioStream then
        local state = getAudioStreamState(audioStream)
        sampAddChatMessage("DEBUG CMD: Stream State: " .. tostring(state), -1)
        setAudioStreamState(audioStream, AUDIOSTREAM_STATE.PLAY)
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
    local cmd = tostring(alias or "ttc"):gsub('^%s*/',''):match('^%S+') or 'ttc'
    if not menuRegistered[cmd] then
        sampRegisterChatCommand(cmd, function()
            if cfg.settings.start == 0 then
                local ok, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                if ok then
                    local name = sampGetPlayerNickname(id)
                    local menuCmd = cfg.settings.menu_cmd
                    sampAddChatMessage(string.format(T("msg_prefix") .. T("msg_first_runID"), name, id), -1)
                    sampAddChatMessage(T("msg_prefix") .. T("msg_first_run1"), -1)
                    sampAddChatMessage(T("msg_prefix") .. T("msg_first_run2"), -1)
                    sampAddChatMessage(string.format(T("msg_prefix") .. T("msg_first_runCMD"), menuCmd), -1)
                end
            end
            toggleMenu()
        end)
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
local menuWidth = 800
local menuHeight = 500

function imgui.OnDrawFrame()
    drawRadialActionMenu()

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
            inicfg.save(cfg, "TowTruckHelper.ini")
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
                updateImguiProcess()
                sampSetCursorMode(false)
            end
        end
        imgui.Spacing()
        if imgui.Button(T("later"), imgui.ImVec2(-1, 30)) then
            showUpdateDialog.v = false
            if not showMenu.v then
                updateImguiProcess()
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
                        inicfg.save(cfg, "TowTruckHelper.ini")
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
        local bzoneDialogTheme = tonumber(cfg.settings.ui_theme or 1) == 3
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(520, 260), imgui.Cond.Always)
        if bzoneDialogTheme then
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.02, 0.02, 0.02, 0.94))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.85))
            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.65))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.08, 0.08, 0.08, 0.96))
            imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0.12, 0.12, 0.12, 0.98))
            imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0.16, 0.16, 0.16, 1.0))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 0.96))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.16, 0.16, 0.16, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.0))
        end
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
            imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
            imgui.InputText("##fvrstart", fvrBuffers.start)
            imgui.PopStyleColor(2)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_text_final_label"))
            imgui.PushItemWidth(-1)
            imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
            imgui.InputText("##fvrfinal", fvrBuffers.final)
            imgui.PopStyleColor(2)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_text_sfvr_label"))
            imgui.PushItemWidth(-1)
            imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
            imgui.InputText("##fvrcancel", fvrBuffers.cancel)
            imgui.PopStyleColor(2)
            imgui.PopItemWidth()

            imgui.Text(T("fvr_seconds_label"))
            imgui.PushItemWidth(100)
            imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
            imgui.InputInt("##fvrsec", fvrBuffers.seconds)
            imgui.PopStyleColor(2)
            imgui.PopItemWidth()

            imgui.Spacing()
            if imgui.Button(T("save"), imgui.ImVec2(120, 30)) then
                cfg.settings.fvr_text_f = fvrBuffers.start.v
                cfg.settings.fvr_text_final = fvrBuffers.final.v
                cfg.settings.fvr_text_sfvr = fvrBuffers.cancel.v
                cfg.settings.fvr_seconds = fvrBuffers.seconds.v
                inicfg.save(cfg, "TowTruckHelper.ini")
                showFvrDialog.v = false
            end
            imgui.SameLine()
            if imgui.Button(T("close"), imgui.ImVec2(120, 30)) then
                showFvrDialog.v = false
            end

        imgui.End()
        if bzoneDialogTheme then
            imgui.PopStyleColor(10)
        end
        return
    end

    if showCustomDialog.v then
        local w, h = getScreenResolution()
        local bzoneDialogTheme = tonumber(cfg.settings.ui_theme or 1) == 3
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 330), imgui.Cond.Always)
        if bzoneDialogTheme then
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.02, 0.02, 0.02, 0.94))
            imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.85))
            imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 0.65))
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.08, 0.08, 0.08, 0.96))
            imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0.12, 0.12, 0.12, 0.98))
            imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0.16, 0.16, 0.16, 1.0))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.10, 0.10, 0.10, 0.96))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.16, 0.16, 0.16, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.22, 0.22, 0.22, 1.0))
            imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(215 / 255, 206 / 255, 150 / 255, 1.0))
        end
        imgui.Begin(T("custom_cmds"), showCustomDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

            for i = 1, 10 do
                imgui.PushID(i)
                if imgui.Checkbox("##active"..i, customBuffers[i].active) then end
                imgui.SameLine()
                imgui.PushItemWidth(120)
                imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
                imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
                imgui.InputText("Alias##"..i, customBuffers[i].alias)
                imgui.PopStyleColor(2)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.TextColored(bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or getAccentColor(), "Alias")
                imgui.SameLine()
                imgui.PushItemWidth(-1)
                imgui.PushStyleColor(imgui.Col.Text, bzoneDialogTheme and imgui.ImVec4(1.0, 1.0, 1.0, 1.0) or imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
                imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
                imgui.InputText("Text##"..i, customBuffers[i].text)
                imgui.PopStyleColor(2)
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
                inicfg.save(cfg, "TowTruckHelper.ini")
                registerCustomCommands()
                showCustomDialog.v = false
            end
            imgui.SameLine()
            if imgui.Button(T("close"), imgui.ImVec2(120, 30)) then
                showCustomDialog.v = false
            end

        imgui.End()
        if bzoneDialogTheme then
            imgui.PopStyleColor(11)
        end
        return
    end

    if showTdEditDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(420, 180), imgui.Cond.Always)
        imgui.Begin(T("textdraw_label"), showTdEditDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

        imgui.Text(T("textdraw_label1"))
        imgui.Text(T("textdraw_label2"))
        imgui.Spacing()

        if imgui.Button("Save", imgui.ImVec2(120, 30)) then
            cfg.settings.textdraw_pos_x = tdEditX
            cfg.settings.textdraw_pos_y = tdEditY
            inicfg.save(cfg, "TowTruckHelper.ini")
            textdrawEditActive = false
            showTdEditDialog.v = false
            if not showMenu.v then
                updateImguiProcess()
                sampSetCursorMode(false)
            end
        end
        imgui.SameLine()
        if imgui.Button("Cancel", imgui.ImVec2(120, 30)) then
            textdrawEditActive = false
            showTdEditDialog.v = false
            if not showMenu.v then
                updateImguiProcess()
                sampSetCursorMode(false)
            end
        end

        imgui.End()
        return
    end

    if showHudEditDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(440, 190), imgui.Cond.Always)
        imgui.Begin("HUD Position", showHudEditDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)

        imgui.Text("Modificare pozitie HUD")
        imgui.Separator()
        imgui.TextWrapped("Foloseste sagetile pentru a muta HUD-ul. Tine SHIFT pentru miscare mai rapida.")
        imgui.Spacing()
        imgui.Text(string.format("X: %d   Y: %d", hudEditX, hudEditY))

        imgui.Spacing()
        if imgui.Button("Save", imgui.ImVec2(120, 30)) then
            cfg.settings.hud_pos_x = hudEditX
            cfg.settings.hud_pos_y = hudEditY
            inicfg.save(cfg, "TowTruckHelper.ini")
            hudPosEditActive = false
            showHudEditDialog.v = false
            if not showMenu.v then
                updateImguiProcess()
                sampSetCursorMode(false)
            end
        end
        imgui.SameLine()
        if imgui.Button("Cancel", imgui.ImVec2(120, 30)) then
            hudEditX = hudOrigX
            hudEditY = hudOrigY
            hudPosEditActive = false
            showHudEditDialog.v = false
            if not showMenu.v then
                updateImguiProcess()
                sampSetCursorMode(false)
            end
        end

        imgui.End()
        return
    end

    if showRepairConfirmDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 92), imgui.Cond.Always)
        imgui.Begin("Auto Repair Confirmation", showRepairConfirmDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
            local msg = T("auto_repair_confirm_msg")
            local msgSz = imgui.CalcTextSize(msg)
            local winW = imgui.GetWindowWidth()
            imgui.SetCursorPos(imgui.ImVec2(math.max(8, (winW - msgSz.x) * 0.5), 12))
            imgui.Text(msg)

            local btnW = 180
            local btnH = 36
            local btnSpacing = imgui.GetStyle().ItemSpacing.x
            local btnStartX = (winW - ((btnW * 2) + btnSpacing)) * 0.5
            imgui.SetCursorPos(imgui.ImVec2(btnStartX, 43))
            if imgui.Button(T("confirm") .. "##repair", imgui.ImVec2(btnW, btnH)) then
                sampSendChat("/repair")
                showRepairConfirmDialog.v = false
                if not showMenu.v then
                    updateImguiProcess()
                    sampSetCursorMode(false)
                end
            end
            imgui.SameLine(0, btnSpacing)
            if imgui.Button(T("cancel") .. "##repair", imgui.ImVec2(btnW, btnH)) then
                showRepairConfirmDialog.v = false
                if not showMenu.v then
                    updateImguiProcess()
                    sampSetCursorMode(false)
                end
            end
        imgui.End()
        return
    end

    if showRefillConfirmDialog.v then
        local w, h = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(w / 2, h / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 92), imgui.Cond.Always)
        imgui.Begin("Auto Refill Confirmation", showRefillConfirmDialog, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
            local msg = T("auto_refill_confirm_msg")
            local msgSz = imgui.CalcTextSize(msg)
            local winW = imgui.GetWindowWidth()
            imgui.SetCursorPos(imgui.ImVec2(math.max(8, (winW - msgSz.x) * 0.5), 12))
            imgui.Text(msg)

            local btnW = 180
            local btnH = 36
            local btnSpacing = imgui.GetStyle().ItemSpacing.x
            local btnStartX = (winW - ((btnW * 2) + btnSpacing)) * 0.5
            imgui.SetCursorPos(imgui.ImVec2(btnStartX, 43))
            if imgui.Button(T("confirm") .. "##refill", imgui.ImVec2(btnW, btnH)) then
                sampSendChat("/refill")
                showRefillConfirmDialog.v = false
                if not showMenu.v then
                    updateImguiProcess()
                    sampSetCursorMode(false)
                end
            end
            imgui.SameLine(0, btnSpacing)
            if imgui.Button(T("cancel") .. "##refill", imgui.ImVec2(btnW, btnH)) then
                showRefillConfirmDialog.v = false
                if not showMenu.v then
                    updateImguiProcess()
                    sampSetCursorMode(false)
                end
            end
        imgui.End()
        return
    end

    if hudEnabled.v then
        local sw, sh = getScreenResolution()
        local w = cfg.settings.hud_width or HUD_CFG.width_default
        local hCfg = cfg.settings.hud_height or HUD_CFG.height_default
        local pad = cfg.settings.hud_padding or HUD_CFG.padding_default
        local skinSize = cfg.settings.hud_skin_image_size or HUD_CFG.skin_image_size
        local vehicleSize = cfg.settings.hud_vehicle_image_size or HUD_CFG.vehicle_image_size
        local aeroHud = tonumber(cfg.settings.ui_theme or 1) == 4
        local bzoneHud = tonumber(cfg.settings.ui_theme or 1) == 3

        local lineH = 20
        local titleH = aeroHud and 28 or 22
        local titleBarH = aeroHud and 8 or 4
        local panelH = aeroHud and 108 or 102
        local inVeh = hudState.inVehicle and hudState.vehicleModel > 0
        local raportExtra = isDuty and (lineH * 3 + (inVeh and 24 or 12)) or 0
        local minFootH = (pad * 2)
            + titleH + titleBarH + 10
            + lineH + 4 + skinSize + 12
            + raportExtra
            + lineH + 8
        local minVehH = (pad * 2)
            + titleH + titleBarH + 10
            + lineH + 4 + skinSize + 12
            + lineH + 4 + vehicleSize + 12
            + panelH + 12
            + raportExtra
            + lineH + 8
        local bzoneMinH = 232
        if bzoneHud then
            if inVeh then
                bzoneMinH = isDuty and 304 or 214
            else
                bzoneMinH = isDuty and 232 or 132
            end
        end
        local aeroMinH = 118
        if aeroHud then
            if inVeh then
                aeroMinH = isDuty and 226 or 196
            else
                aeroMinH = isDuty and 126 or 84
            end
        end
        local h = aeroHud and math.max(math.min(hCfg, aeroMinH), aeroMinH)
            or (bzoneHud and math.max(hCfg, bzoneMinH) or (inVeh and math.max(hCfg, minVehH) or minFootH))

        local x = hudPosEditActive and hudEditX or (cfg.settings.hud_pos_x or 0)
        local y = hudPosEditActive and hudEditY or (cfg.settings.hud_pos_y or 0)
        local anchored = not not cfg.settings.hud_anchor_top_right
        if anchored and not isEditMode then
            x = sw - w - 20 + (hudPosEditActive and hudEditX or (cfg.settings.hud_pos_x or 0))
            y = 20 + (hudPosEditActive and hudEditY or (cfg.settings.hud_pos_y or 0))
        end

        local flags = (imgui.WindowFlags.NoTitleBar or 0)
            + (imgui.WindowFlags.NoResize or 0)
            + (imgui.WindowFlags.NoCollapse or 0)
            + (imgui.WindowFlags.NoSavedSettings or 0)
            + (imgui.WindowFlags.NoScrollbar or 0)
            + (imgui.WindowFlags.NoScrollWithMouse or 0)

        if not isEditMode then
            flags = flags + (imgui.WindowFlags.NoMove or 0) + (imgui.WindowFlags.NoInputs or 0)
        end

        imgui.SetNextWindowPos(imgui.ImVec2(x, y), isEditMode and imgui.Cond.Once or imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(w, h), imgui.Cond.Always)

        imgui.PushStyleColor(imgui.Col.WindowBg, hudColor(HUD_CFG.bg_rgba))
        imgui.PushStyleColor(imgui.Col.Border, hudColor(HUD_CFG.border_rgba))
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(pad, pad))

        imgui.Begin("##TTH_HUD", nil, flags)
            if isEditMode then
                local wp = imgui.GetWindowPos()
                local changed = (math.abs(wp.x - lastHudPosX) > 0.5) or (math.abs(wp.y - lastHudPosY) > 0.5)
                if changed and (os.clock() - lastHudSaveAt) > 0.3 then
                    lastHudPosX, lastHudPosY = wp.x, wp.y
                    cfg.settings.hud_anchor_top_right = false
                    cfg.settings.hud_pos_x = wp.x
                    cfg.settings.hud_pos_y = wp.y
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    lastHudSaveAt = os.clock()
                end
            end

            local dl = imgui.GetWindowDrawList()
            local wp = imgui.GetWindowPos()
            local ws = imgui.GetWindowSize()

            if aeroHud then
                if win7HudBackgroundTex then
                    dl:AddImage(win7HudBackgroundTex, wp, imgui.ImVec2(wp.x + ws.x, wp.y + ws.y))
                else
                    local border = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.18, 0.54, 0.86, 1.0))
                    local titleBar = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.04, 0.38, 0.74, 0.98))
                    local titleBarHi = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.42, 0.78, 1.0, 0.48))
                    local skyTop = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.66, 0.89, 1.0, 0.86))
                    local skyBottom = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.88, 0.98, 1.0, 0.90))
                    local glassPanel = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.92, 0.98, 1.0, 0.62))
                    local lineCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.50, 0.68, 0.82, 0.56))
                    dl:AddRectFilled(wp, imgui.ImVec2(wp.x + ws.x, wp.y + ws.y), border, 7)
                    dl:AddRectFilled(imgui.ImVec2(wp.x + 5, wp.y + 5), imgui.ImVec2(wp.x + ws.x - 5, wp.y + titleH), titleBar, 5, 1 + 2)
                    dl:AddRectFilled(imgui.ImVec2(wp.x + 5, wp.y + 5), imgui.ImVec2(wp.x + ws.x - 5, wp.y + 15), titleBarHi, 5, 1 + 2)
                    dl:AddRectFilled(imgui.ImVec2(wp.x + 5, wp.y + titleH), imgui.ImVec2(wp.x + ws.x - 5, wp.y + ws.y - 6), skyTop, 0)
                    dl:AddRectFilled(imgui.ImVec2(wp.x + 5, wp.y + titleH + 100), imgui.ImVec2(wp.x + ws.x - 5, wp.y + ws.y - 6), skyBottom, 0)
                    dl:AddRectFilled(imgui.ImVec2(wp.x + 18, wp.y + titleH + 198), imgui.ImVec2(wp.x + ws.x - 18, wp.y + ws.y - 40), glassPanel, 5)
                    dl:AddRect(imgui.ImVec2(wp.x + 18, wp.y + titleH + 198), imgui.ImVec2(wp.x + ws.x - 18, wp.y + ws.y - 40), lineCol, 5, 0, 1.0)
                    dl:AddRect(imgui.ImVec2(wp.x + 5, wp.y + 5), imgui.ImVec2(wp.x + ws.x - 5, wp.y + ws.y - 6), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.54, 0.90, 1.0, 0.70)), 5, 0, 1.0)
                    dl:AddLine(imgui.ImVec2(wp.x + 18, wp.y + ws.y - 37), imgui.ImVec2(wp.x + ws.x - 18, wp.y + ws.y - 37), lineCol, 1.0)
                end

                local textDark = imgui.ImVec4(0.0, 0.0, 0.0, 1.0)
                local textSoft = imgui.ImVec4(0.0, 0.0, 0.0, 1.0)
                local gadgetWhite = imgui.ImVec4(0.0, 0.0, 0.0, 1.0)
                local title = T("hud_title")
                local titleSz = imgui.CalcTextSize(title)
                imgui.SetCursorPos(imgui.ImVec2((ws.x - titleSz.x) * 0.5, 8))
                imgui.TextColored(textDark, title)
                local dutyText = isDuty and T("hud_duty_on") or T("hud_duty_off")
                local towText = string.format("%s: %d", T("hud_towpoints"), towpoints)
                local towSz = imgui.CalcTextSize(towText)
                local footerY = inVeh and (ws.y - 16) or (ws.y - 22)

                if inVeh then
                    local speed = hudState.vehicleSpeed
                    local spdText = speed and tostring(speed) or "0"
                    local speedCol = imgui.ImVec4(0.0, 0.0, 0.0, 1.0)
                    if speed and speed >= 150 then
                        speedCol = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
                    elseif speed and speed >= 100 then
                        speedCol = imgui.ImVec4(1.0, 0.55, 0.0, 1.0)
                    end

                    local unitText = T("hud_speed_unit")
                    local speedAreaTop = titleH + 18
                    local speedAreaBottom = math.max(speedAreaTop + 70, ws.y - 96)
                    local speedAreaH = speedAreaBottom - speedAreaTop
                    local bigSpeedSz = sevenSegmentSize(spdText, 58)
                    imgui.SetWindowFontScale(1.45)
                    local unitSz = imgui.CalcTextSize(unitText)
                    local totalSpeedW = bigSpeedSz.x + 10 + unitSz.x
                    local speedX = (ws.x - totalSpeedW) * 0.5
                    local speedY = speedAreaTop + ((speedAreaH - bigSpeedSz.y) * 0.5)
                    drawSevenSegmentText(dl, spdText, wp.x + speedX, wp.y + speedY, 58, speedCol)
                    imgui.SetWindowFontScale(1.45)
                    imgui.SetCursorPos(imgui.ImVec2(speedX + bigSpeedSz.x + 10, speedY + bigSpeedSz.y - unitSz.y - 6))
                    imgui.TextColored(textSoft, unitText)
                    imgui.SetWindowFontScale(1.0)
                end

                if inVeh then
                    local hp = hudState.vehicleHp
                    local fuel = hudState.vehicleFuel
                    local odo = hudState.vehicleOdometer
                    local locked = hudState.vehicleLocked
                    local hpText = hp and tostring(hp) or "-"
                    local fuelText = "-"
                    if fuel ~= nil then
                        fuelText = fuel <= 100.0 and string.format("%.0f%%", fuel) or string.format("%.1fL", fuel)
                    end
                    local odoText = odo and string.format("%.1f", odo) or "-"
                    local lockText = "-"
                    if locked == true then
                        lockText = T("hud_locked")
                    elseif locked == false then
                        lockText = T("hud_unlocked")
                    elseif hudState.vehicleStatus ~= nil then
                        lockText = tostring(hudState.vehicleStatus)
                    end

                    local gridTop = 122
                    local gridLeft = 8
                    local gridRight = ws.x - 8
                    local gridW = gridRight - gridLeft
                    local colW = gridW / 4
                    local gridH = isDuty and 52 or 72
                    local boxCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.05, 0.35, 0.58, 0.28))
                    local lineCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.74, 0.92, 1.0, 0.42))
                    dl:AddRectFilled(imgui.ImVec2(wp.x + gridLeft, wp.y + gridTop), imgui.ImVec2(wp.x + gridRight, wp.y + gridTop + gridH), boxCol, 2)
                    for i = 1, 3 do
                        local lx = wp.x + gridLeft + (colW * i)
                        dl:AddLine(imgui.ImVec2(lx, wp.y + gridTop + 5), imgui.ImVec2(lx, wp.y + gridTop + 47), lineCol, 1.0)
                    end
                    if not isDuty then
                        dl:AddLine(imgui.ImVec2(wp.x + gridLeft + 4, wp.y + gridTop + 52), imgui.ImVec2(wp.x + gridRight - 4, wp.y + gridTop + 52), lineCol, 1.0)
                        footerY = gridTop + 54
                    end

                    local stats = {
                        { T("hud_hp"), hpText },
                        { T("hud_fuel"), fuelText },
                        { T("hud_status"), lockText },
                        { T("hud_odometer"), odoText }
                    }
                    for i, item in ipairs(stats) do
                        local sx = gridLeft + ((i - 1) * colW) + 6
                        imgui.SetCursorPos(imgui.ImVec2(sx, gridTop + 6))
                        imgui.TextColored(gadgetWhite, item[1])
                        imgui.SetCursorPos(imgui.ImVec2(sx, gridTop + 25))
                        imgui.TextColored(gadgetWhite, item[2])
                    end
                end

                if isDuty and hudState.raportAt > 0 then
                    local lines = {}
                    local statusValue = "-"
                    if hudState.raportWeekDone == true then
                        statusValue = T("hud_completed")
                    elseif hudState.raportWeekDone == false then
                        statusValue = T("hud_incomplete")
                    end
                    table.insert(lines, T("hud_report_progress") .. ": " .. statusValue)
                    table.insert(lines, T("hud_any_action") .. ": " .. tostring(hudState.raportWeekAction or "-"))
                    table.insert(lines, T("hud_tows") .. ": " .. tostring(hudState.raportWeekTows or "-"))

                    local baseY = inVeh and 178 or 48
                    for i, line in ipairs(lines) do
                        local reportSz = imgui.CalcTextSize(line)
                        imgui.SetCursorPos(imgui.ImVec2((ws.x - reportSz.x) * 0.5, baseY + ((i - 1) * 14)))
                        imgui.TextColored(gadgetWhite, line)
                    end
                end

                imgui.SetCursorPos(imgui.ImVec2(10, footerY))
                imgui.TextColored(gadgetWhite, dutyText)
                imgui.SetCursorPos(imgui.ImVec2(ws.x - towSz.x - 10, footerY))
                imgui.TextColored(gadgetWhite, towText)

                imgui.End()
                imgui.PopStyleVar()
                imgui.PopStyleColor(2)
            else
                if bzoneHud and bzoneHudBackgroundTex then
                    dl:AddRectFilled(wp, imgui.ImVec2(wp.x + ws.x, wp.y + ws.y), 0xEE000000, 10)
                    dl:AddRectFilled(wp, imgui.ImVec2(wp.x + ws.x, wp.y + 82), 0xFF000000, 10, 1 + 2)
                    dl:AddImage(bzoneHudBackgroundTex, imgui.ImVec2(wp.x, wp.y), imgui.ImVec2(wp.x + ws.x, wp.y + 82))
                    dl:AddRectFilled(wp, imgui.ImVec2(wp.x + ws.x, wp.y + 82), 0x88000000, 10, 1 + 2)
                    dl:AddRectFilled(imgui.ImVec2(wp.x, wp.y + 82), imgui.ImVec2(wp.x + ws.x, wp.y + ws.y), 0xD0000000, 0)
                else
                    dl:AddRectFilled(wp, imgui.ImVec2(wp.x + ws.x, wp.y + titleH), 0xFF000000, 10, 1 + 2)
                    dl:AddRectFilled(imgui.ImVec2(wp.x, wp.y + titleH), imgui.ImVec2(wp.x + ws.x, wp.y + titleH + titleBarH), 0xFF101010, 0)
                end
            end

            if bzoneHud then
                local title = T("hud_title")
                local titleSz = imgui.CalcTextSize(title)
                imgui.SetCursorPos(imgui.ImVec2((ws.x - titleSz.x) * 0.5, 6))
                imgui.TextColored(getAccentColor(), title)

                local centerX = ws.x * 0.5
                local accent = getAccentColor()
                local white = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
                if inVeh then
                    local speed = hudState.vehicleSpeed
                    local spdText = speed and tostring(speed) or "0"
                    local speedCol = white
                    if speed and speed >= 150 then
                        speedCol = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
                    elseif speed and speed >= 100 then
                        speedCol = imgui.ImVec4(1.0, 0.55, 0.0, 1.0)
                    end

                    local speedTop = 88
                    local speedLabel = T("hud_speed_unit") .. " "
                    imgui.SetWindowFontScale(1.85)
                    local labelSz = imgui.CalcTextSize(speedLabel)
                    local valueSz = sevenSegmentSize(spdText, 34)
                    local speedX = centerX - ((labelSz.x + valueSz.x) * 0.5)
                    imgui.SetCursorPos(imgui.ImVec2(speedX, speedTop))
                    imgui.TextColored(accent, speedLabel)
                    drawSevenSegmentText(dl, spdText, wp.x + speedX + labelSz.x, wp.y + speedTop - 4, 34, speedCol)
                    imgui.SetWindowFontScale(1.0)
                end

                if inVeh then
                    local panelW = math.min(292, ws.x - (pad * 2))
                    local panelH2 = 62
                    local panelX = centerX - (panelW * 0.5)
                    local panelY = 120
                    local pp = imgui.ImVec2(wp.x + panelX, wp.y + panelY)
                    dl:AddRectFilled(pp, imgui.ImVec2(pp.x + panelW, pp.y + panelH2), 0xB008101C, 8)
                    dl:AddRect(pp, imgui.ImVec2(pp.x + panelW, pp.y + panelH2), hudColU32(HUD_CFG.border_rgba), 8, 0, 1.2)

                    local hp = hudState.vehicleHp
                    local fuel = hudState.vehicleFuel
                    local odo = hudState.vehicleOdometer
                    local locked = hudState.vehicleLocked
                    local hpText = hp and tostring(hp) or "-"
                    local fuelText = "-"
                    if fuel ~= nil then
                        fuelText = fuel <= 100.0 and string.format("%.0f%%", fuel) or string.format("%.1fL", fuel)
                    end
                    local odoText = odo and string.format("%.1f", odo) or "-"
                    local lockText = "-"
                    if locked == true then
                        lockText = T("hud_locked")
                    elseif locked == false then
                        lockText = T("hud_unlocked")
                    elseif hudState.vehicleStatus ~= nil then
                        lockText = tostring(hudState.vehicleStatus)
                    end

                    local stats = {
                        { speedoIcons.hp, "heart", hpText },
                        { speedoIcons.fuel, "drop", fuelText },
                        { speedoIcons.lock, "lock", lockText },
                        { speedoIcons.odo, "gear", odoText }
                    }
                    local iconS = 18
                    local colW = (panelW - 24) * 0.5
                    for i, item in ipairs(stats) do
                        local row = i <= 2 and 0 or 1
                        local col = (i - 1) % 2
                        local sx = panelX + 12 + (col * colW)
                        local sy = panelY + 8 + (row * 29)
                        imgui.SetCursorPos(imgui.ImVec2(sx, sy))
                        if item[1] then
                            imgui.Image(item[1], imgui.ImVec2(iconS, iconS))
                        else
                            local sp = imgui.GetCursorScreenPos()
                            drawStatIcon(dl, item[2], sp.x, sp.y, iconS, accent)
                            imgui.Dummy(imgui.ImVec2(iconS, iconS))
                        end
                        imgui.SetCursorPos(imgui.ImVec2(sx + iconS + 8, sy + 4))
                        imgui.TextColored(accent, item[3])
                    end
                end

                local dutyText = isDuty and T("hud_duty_on") or T("hud_duty_off")
                local towText = string.format("%s: %d", T("hud_towpoints"), towpoints)
                local towSz = imgui.CalcTextSize(towText)
                local bottomY = ws.y - pad - lineH

                if isDuty and hudState.raportAt > 0 then
                    local statusLabel = T("hud_report_progress") .. ": "
                    local statusValue = "-"
                    local statusColor = accent
                    if hudState.raportWeekDone == true then
                        statusValue = T("hud_completed")
                        statusColor = imgui.ImVec4(0.0, 1.0, 0.0, 1.0)
                    elseif hudState.raportWeekDone == false then
                        statusValue = T("hud_incomplete")
                        statusColor = imgui.ImVec4(1.0, 0.2, 0.2, 1.0)
                    end
                    local line1 = statusLabel .. statusValue
                    local line2 = T("hud_any_action") .. ": " .. tostring(hudState.raportWeekAction or "-")
                    local line3 = T("hud_tows") .. ": " .. tostring(hudState.raportWeekTows or "-")
                    local lines = { line1, line2, line3 }

                    local startY = bottomY - (lineH * 3) + 4
                    for i, line in ipairs(lines) do
                        local reportSz = imgui.CalcTextSize(line)
                        imgui.SetCursorPos(imgui.ImVec2((ws.x - reportSz.x) * 0.5, startY + ((i - 1) * lineH)))
                        if i == 1 and (hudState.raportWeekDone == true or hudState.raportWeekDone == false) then
                            local labelSz = imgui.CalcTextSize(statusLabel)
                            local valueSz = imgui.CalcTextSize(statusValue)
                            local startX = (ws.x - (labelSz.x + valueSz.x)) * 0.5
                            imgui.SetCursorPos(imgui.ImVec2(startX, startY))
                            imgui.TextColored(accent, statusLabel)
                            imgui.SameLine(0, 0)
                            imgui.TextColored(statusColor, statusValue)
                        else
                            imgui.TextColored(accent, line)
                        end
                    end
                end

                imgui.SetCursorPos(imgui.ImVec2(pad, bottomY))
                imgui.TextColored(accent, dutyText)
                imgui.SetCursorPos(imgui.ImVec2(ws.x - pad - towSz.x, bottomY))
                imgui.TextColored(accent, towText)

                imgui.End()
                imgui.PopStyleVar()
                imgui.PopStyleColor(2)
            end

            if not aeroHud and not bzoneHud then
            local title = T("hud_title")
            local titleSz = imgui.CalcTextSize(title)
            imgui.SetCursorPos(imgui.ImVec2((ws.x - titleSz.x) * 0.5, aeroHud and 8 or 2))
            imgui.TextColored(aeroHud and imgui.ImVec4(0.05, 0.18, 0.28, 1.0) or getAccentColor(), title)

            local contentY = titleH + titleBarH + 10
            local centerX = ws.x * 0.5
            local accent = getAccentColor()
            local white = aeroHud and imgui.ImVec4(0.10, 0.16, 0.22, 1.0) or imgui.ImVec4(1, 1, 1, 1)

            local playerLine = string.format("%s (%d)", hudState.playerName ~= "" and hudState.playerName or T("hud_player_fallback"), hudState.playerId)
            local plSz = imgui.CalcTextSize(playerLine)
            imgui.SetCursorPos(imgui.ImVec2(centerX - (plSz.x * 0.5), contentY))
            imgui.TextColored(accent, playerLine)

            contentY = contentY + lineH + 4
            local skinX = centerX - (skinSize * 0.5)
            imgui.SetCursorPos(imgui.ImVec2(skinX, contentY))
            local skinTex = getSkinTexture(hudState.skinId)
            if skinTex then
                imgui.Image(skinTex, imgui.ImVec2(skinSize, skinSize))
            else
                imgui.TextColored(accent, T("hud_skin"))
            end

            contentY = contentY + skinSize + 12
            if inVeh then
                local vehName = hudState.vehicleName
                local vehModel = hudState.vehicleModel
                local vehicleLine = string.format("%s (%s %d)", vehName, T("hud_vehicle_id"), vehModel)
                local vnSz = imgui.CalcTextSize(vehicleLine)
                imgui.SetCursorPos(imgui.ImVec2(centerX - (vnSz.x * 0.5), contentY))
                imgui.TextColored(accent, vehicleLine)

                contentY = contentY + lineH + 4
                local vehX = centerX - (vehicleSize * 0.5)
                imgui.SetCursorPos(imgui.ImVec2(vehX, contentY))
                local vehTex = getVehicleTexture(hudState.vehicleModel) or vehiclePlaceholderTex
                if vehTex then
                    imgui.Image(vehTex, imgui.ImVec2(vehicleSize, vehicleSize))
                end

                contentY = contentY + vehicleSize + 12
            end

            if inVeh then
                local panelW = math.min(290, ws.x - (pad * 2))
                if panelW < 240 then panelW = ws.x - (pad * 2) end
                local panelX = centerX - (panelW * 0.5)
                local panelY = contentY
                local p = imgui.ImVec2(wp.x + panelX, wp.y + panelY)
                if aeroHud then
                    dl:AddRectFilled(p, imgui.ImVec2(p.x + panelW, p.y + panelH), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.96, 0.99, 1.0, 0.92)), 6)
                    dl:AddRectFilled(p, imgui.ImVec2(p.x + panelW, p.y + 34), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.78, 0.91, 1.0, 0.62)), 6, 1 + 2)
                    dl:AddRect(p, imgui.ImVec2(p.x + panelW, p.y + panelH), hudColU32(HUD_CFG.border_rgba), 6, 0, 1.2)
                    dl:AddLine(imgui.ImVec2(p.x + panelW * 0.5, p.y + 44), imgui.ImVec2(p.x + panelW * 0.5, p.y + panelH - 10), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.62, 0.76, 0.86, 0.60)), 1.0)
                else
                    dl:AddRectFilled(p, imgui.ImVec2(p.x + panelW, p.y + panelH), 0xB0101010, 10)
                    dl:AddRect(p, imgui.ImVec2(p.x + panelW, p.y + panelH), hudColU32(HUD_CFG.border_rgba), 10, 0, 1.5)
                end

                local speed = hudState.vehicleSpeed
                local spdText = speed and tostring(speed) or "-"
                local speedCol = aeroHud and imgui.ImVec4(0.05, 0.18, 0.32, 1.0) or imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
                if speed and speed >= 150 then
                    speedCol = imgui.ImVec4(1.0, 0.0, 0.0, 1.0)
                elseif speed and speed >= 100 then
                    speedCol = imgui.ImVec4(1.0, 0.55, 0.0, 1.0)
                end
                local speedLabel = T("hud_speed_unit") .. " "
                imgui.SetWindowFontScale(1.75)
                local labelSz = imgui.CalcTextSize(speedLabel)
                local valueSz = sevenSegmentSize(spdText, 34)
                local speedX = panelX + ((panelW - (labelSz.x + valueSz.x)) * 0.5)
                imgui.SetCursorPos(imgui.ImVec2(speedX, panelY + 8))
                imgui.TextColored(aeroHud and imgui.ImVec4(0.05, 0.18, 0.28, 1.0) or accent, speedLabel)
                drawSevenSegmentText(dl, spdText, wp.x + speedX + labelSz.x, wp.y + panelY + 4, 34, speedCol)
                imgui.SetWindowFontScale(1.0)

                local iconS = 22
                local row1Y = panelY + 46
                local row2Y = panelY + 74
                local colPad = 12
                local colW = (panelW - (colPad * 2)) * 0.5

                local hp = hudState.vehicleHp
                local fuel = hudState.vehicleFuel
                local odo = hudState.vehicleOdometer
                local locked = hudState.vehicleLocked

                local hpText = hp and tostring(hp) or "-"
                local fuelText = "-"
                if fuel ~= nil then
                    if fuel <= 100.0 then
                        fuelText = string.format("%.0f%%", fuel)
                    else
                        fuelText = string.format("%.1fL", fuel)
                    end
                end
                local odoText = odo and (string.format("%.1f", odo)) or "-"

                local lockText = "-"
                local lockCol = accent
                if locked == true then
                    lockText = T("hud_locked")
                    lockCol = accent
                elseif locked == false then
                    lockText = T("hud_unlocked")
                    lockCol = white
                elseif hudState.vehicleStatus ~= nil then
                    lockText = tostring(hudState.vehicleStatus)
                    lockCol = accent
                end

                local function iconOrFallback(tex, kind, x, y, col)
                    imgui.SetCursorPos(imgui.ImVec2(x, y))
                    if tex then
                        imgui.Image(tex, imgui.ImVec2(iconS, iconS))
                    else
                        local sp = imgui.GetCursorScreenPos()
                        drawStatIcon(dl, kind, sp.x, sp.y, iconS, col)
                        imgui.Dummy(imgui.ImVec2(iconS, iconS))
                    end
                end

                local c1x = panelX + colPad
                local c2x = panelX + colPad + colW
                local iconTextOffsetY = 5

                iconOrFallback(speedoIcons.hp, "heart", c1x, row1Y, accent)
                imgui.SetCursorPos(imgui.ImVec2(c1x + iconS + 8, row1Y + iconTextOffsetY))
                imgui.TextColored(accent, hpText)

                iconOrFallback(speedoIcons.fuel, "drop", c2x, row1Y, accent)
                imgui.SetCursorPos(imgui.ImVec2(c2x + iconS + 8, row1Y + iconTextOffsetY))
                imgui.TextColored(accent, fuelText)

                iconOrFallback(speedoIcons.lock, "lock", c1x, row2Y, lockCol)
                imgui.SetCursorPos(imgui.ImVec2(c1x + iconS + 8, row2Y + iconTextOffsetY))
                imgui.TextColored(lockCol, lockText)

                iconOrFallback(speedoIcons.odo, "gear", c2x, row2Y, accent)
                imgui.SetCursorPos(imgui.ImVec2(c2x + iconS + 8, row2Y + iconTextOffsetY))
                imgui.TextColored(accent, odoText)
            end

            local dutyText = isDuty and T("hud_duty_on") or T("hud_duty_off")
            local towText = string.format("%s: %d", T("hud_towpoints"), towpoints)
            local dutySz = imgui.CalcTextSize(dutyText)
            local towSz = imgui.CalcTextSize(towText)
            local bottomY = ws.y - pad - lineH

            if isDuty and hudState.raportAt > 0 then
                local ry = bottomY - (lineH * 3) + 4
                local label = T("hud_report_progress") .. ": "
                local value = "-"
                local valueCol = accent
                if hudState.raportWeekDone == true then
                    value = T("hud_completed")
                    valueCol = imgui.ImVec4(0.0, 1.0, 0.0, 1.0)
                elseif hudState.raportWeekDone == false then
                    value = T("hud_incomplete")
                    valueCol = imgui.ImVec4(1.0, 0.2, 0.2, 1.0)
                end
                local labelSz = imgui.CalcTextSize(label)
                local valueSz = imgui.CalcTextSize(value)
                local startX = centerX - ((labelSz.x + valueSz.x) * 0.5)
                imgui.SetCursorPos(imgui.ImVec2(startX, ry))
                imgui.TextColored(accent, label)
                imgui.SameLine(0, 0)
                imgui.TextColored(valueCol, value)

                local a = T("hud_any_action") .. ": " .. tostring(hudState.raportWeekAction or "-")
                local b = T("hud_tows") .. ": " .. tostring(hudState.raportWeekTows or "-")
                local sa = imgui.CalcTextSize(a)
                local sb = imgui.CalcTextSize(b)
                imgui.SetCursorPos(imgui.ImVec2(centerX - (sa.x * 0.5), ry + lineH))
                imgui.TextColored(accent, a)
                imgui.SetCursorPos(imgui.ImVec2(centerX - (sb.x * 0.5), ry + (lineH * 2)))
                imgui.TextColored(accent, b)
            end

            imgui.SetCursorPos(imgui.ImVec2(pad, bottomY))
            imgui.TextColored(accent, dutyText)
            imgui.SetCursorPos(imgui.ImVec2(ws.x - pad - towSz.x, bottomY))
            imgui.TextColored(accent, towText)
        imgui.End()

        imgui.PopStyleVar()
        imgui.PopStyleColor(2)
            end
    end

    if not showMenu.v then return end

    local sw, sh = getScreenResolution()
    local themeId = tonumber(cfg.settings.ui_theme or 1)
    local aeroTheme = themeId == 4
    local bzoneTheme = themeId == 3
    local currentMenuWidth = aeroTheme and 700 or menuWidth
    local currentMenuHeight = aeroTheme and 525 or menuHeight
    local centerX = (sw - currentMenuWidth) / 2
    local centerY = (sh - currentMenuHeight) / 2
    local menuSizeCond = imgui.Cond.Always or 0
    imgui.SetNextWindowPos(imgui.ImVec2(centerX, centerY), menuSizeCond)
    imgui.SetNextWindowSize(imgui.ImVec2(currentMenuWidth, currentMenuHeight), menuSizeCond)
    
    imgui.Begin("Tow Truck Company", showMenu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)
    
    local p = imgui.GetWindowPos()
    local windowWidth = imgui.GetWindowWidth()
    local windowHeight = imgui.GetWindowHeight()
    local draw_list = imgui.GetWindowDrawList()
    local activeNavCol = imgui.ColorConvertFloat4ToU32(getAccentColor())
    local activeNavBg = aeroTheme and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.55, 0.82, 1.0, 0.28)) or 0x332F2B19

    if aeroTheme then
        if win7MenuBackgroundTex then
            draw_list:AddImage(win7MenuBackgroundTex, p, imgui.ImVec2(p.x + windowWidth, p.y + windowHeight))
        else
            local border = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.23, 0.62, 0.92, 1.0))
            local titleBar = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.05, 0.38, 0.72, 0.98))
            local titleBarHi = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.43, 0.76, 1.0, 0.52))
            local sidebarTop = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.02, 0.32, 0.68, 0.98))
            local sidebarBottom = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.02, 0.62, 0.86, 0.96))
            local content = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 0.96))
            local softLine = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.72, 0.76, 0.80, 0.78))
            draw_list:AddRectFilled(p, imgui.ImVec2(p.x + windowWidth, p.y + windowHeight), border, 6)
            draw_list:AddRectFilled(imgui.ImVec2(p.x + 7, p.y + 7), imgui.ImVec2(p.x + windowWidth - 7, p.y + 34), titleBar, 4, 1 + 2)
            draw_list:AddRectFilled(imgui.ImVec2(p.x + 7, p.y + 7), imgui.ImVec2(p.x + windowWidth - 7, p.y + 18), titleBarHi, 4, 1 + 2)
            draw_list:AddRectFilled(imgui.ImVec2(p.x + 7, p.y + 34), imgui.ImVec2(p.x + 165, p.y + windowHeight - 8), sidebarTop, 0)
            draw_list:AddRectFilled(imgui.ImVec2(p.x + 7, p.y + 240), imgui.ImVec2(p.x + 165, p.y + windowHeight - 8), sidebarBottom, 0)
            draw_list:AddRectFilled(imgui.ImVec2(p.x + 165, p.y + 34), imgui.ImVec2(p.x + windowWidth - 7, p.y + windowHeight - 8), content, 0)
            draw_list:AddLine(imgui.ImVec2(p.x + 165, p.y + 34), imgui.ImVec2(p.x + 165, p.y + windowHeight - 8), softLine, 1.0)
            draw_list:AddLine(imgui.ImVec2(p.x + 180, p.y + 82), imgui.ImVec2(p.x + windowWidth - 20, p.y + 82), softLine, 1.0)
            draw_list:AddLine(imgui.ImVec2(p.x + 180, p.y + 192), imgui.ImVec2(p.x + windowWidth - 20, p.y + 192), softLine, 1.0)
            draw_list:AddLine(imgui.ImVec2(p.x + 180, p.y + 252), imgui.ImVec2(p.x + windowWidth - 20, p.y + 252), softLine, 1.0)
            draw_list:AddLine(imgui.ImVec2(p.x + 180, p.y + 432), imgui.ImVec2(p.x + windowWidth - 20, p.y + 432), softLine, 1.0)
            draw_list:AddRect(imgui.ImVec2(p.x + 7, p.y + 7), imgui.ImVec2(p.x + windowWidth - 7, p.y + windowHeight - 8), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.48, 0.90, 1.0, 0.70)), 4, 0, 1.0)
            local title = "TowTruckHelper"
            draw_list:AddText(imgui.ImVec2(p.x + 42, p.y + 13), 0xFFFFFFFF, title)
            draw_list:AddText(imgui.ImVec2(p.x + 19, p.y + 13), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.75, 0.93, 1.0, 1.0)), "T")
        end
    elseif bzoneTheme and bzoneMenuBackgroundTex then
        draw_list:AddRectFilled(p, imgui.ImVec2(p.x + windowWidth, p.y + windowHeight), 0xFF000000, 10)
        local bzoneImageLeft = p.x + 198
        local bzoneImageTop = p.y + 28
        local bzoneImageRight = p.x + windowWidth - 22
        local bzoneImageBottom = p.y + windowHeight - 24
        draw_list:AddImage(bzoneMenuBackgroundTex, imgui.ImVec2(bzoneImageLeft, bzoneImageTop), imgui.ImVec2(bzoneImageRight, bzoneImageBottom))
        draw_list:AddRectFilled(imgui.ImVec2(bzoneImageLeft, bzoneImageTop), imgui.ImVec2(bzoneImageRight, bzoneImageBottom), 0x77000000, 6)
        draw_list:AddRect(p, imgui.ImVec2(p.x + windowWidth, p.y + windowHeight), hudColU32(HUD_CFG.border_rgba), 10, 0, 1.2)
    end

    -- aici modifici pozitia la butoane
    local leftPaneWidth = aeroTheme and 165 or 180
    local navButtonWidth = aeroTheme and 135 or 160
    local navButtonHeight = aeroTheme and 40 or 40
    local navBottomMargin = 50
    local spacingY = imgui.GetStyle().ItemSpacing.y

    -- aici modifici pozitia la logo
    local logoTop = aeroTheme and 52 or 30
    local logoWidth = aeroTheme and 110 or 140
    local logoHeight = aeroTheme and 58 or 90

    if not aeroTheme then
        draw_list:AddRectFilled(p, imgui.ImVec2(p.x + leftPaneWidth, p.y + windowHeight), bzoneTheme and 0xB0000000 or 0xFF141414)
    end

    ImMovable("logo_group", function()
        imgui.BeginGroup()
            local xLogo = aeroTheme and 28 or ((leftPaneWidth - logoWidth) / 2)
            imgui.SetCursorPos(imgui.ImVec2(xLogo, logoTop))
            if logoTexture then
                imgui.Image(logoTexture, imgui.ImVec2(logoWidth, logoHeight))
            else
                imgui.TextColored(getAccentColor(), "TowTruck")
            end
            if aeroTheme then
                local logoLabel = "Tow Truck Company"
                local logoLabelSz = imgui.CalcTextSize(logoLabel)
                imgui.SetCursorPos(imgui.ImVec2(xLogo + ((logoWidth - logoLabelSz.x) * 0.5), logoTop + logoHeight + 8))
                imgui.TextColored(imgui.ImVec4(1.0, 1.0, 1.0, 1.0), logoLabel)
            end
        imgui.EndGroup()
    end)

    -- Aici setezi pozitia pe inaltime (Y) pentru fiecare buton in parte
    local btnMainY = aeroTheme and 160 or 160
    local btnInfoY = aeroTheme and 204 or 210
    local btnSettingsY = aeroTheme and 248 or 260
    local btnThemeY = aeroTheme and 292 or 310
    
    local xLeft = aeroTheme and 22 or ((leftPaneWidth - navButtonWidth) / 2)
    local navGap = 8

    -- Buton MAIN
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnMainY))
    ImMovable("nav_main", function()
        local bp = imgui.GetCursorScreenPos()
        if activeTab == 1 then
            draw_list:AddRectFilled(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavBg, 5)
        end
        if imgui.Button(T("main"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 1 end
        if activeTab == 1 then
            draw_list:AddRect(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavCol, 5, 0, 1.2)
        end
    end)

    -- Buton INFO
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnInfoY))
    ImMovable("nav_info", function()
        local bp = imgui.GetCursorScreenPos()
        if activeTab == 2 then
            draw_list:AddRectFilled(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavBg, 5)
        end
        if imgui.Button(T("info"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 2 end
        if activeTab == 2 then
            draw_list:AddRect(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavCol, 5, 0, 1.2)
        end
    end)

    -- Buton SETTINGS
    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnSettingsY))
    ImMovable("nav_settings", function()
        local bp = imgui.GetCursorScreenPos()
        if activeTab == 4 then
            draw_list:AddRectFilled(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavBg, 5)
        end
        if imgui.Button(T("settings"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 4 end
        if activeTab == 4 then
            draw_list:AddRect(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavCol, 5, 0, 1.2)
        end
    end)

    imgui.SetCursorPos(imgui.ImVec2(xLeft, btnThemeY))
    ImMovable("nav_theme", function()
        local bp = imgui.GetCursorScreenPos()
        if activeTab == 5 then
            draw_list:AddRectFilled(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavBg, 5)
        end
        if imgui.Button(T("ui_theme"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 5 end
        if activeTab == 5 then
            draw_list:AddRect(bp, imgui.ImVec2(bp.x + navButtonWidth, bp.y + navButtonHeight), activeNavCol, 5, 0, 1.2)
        end
    end)

    if aeroTheme then
        imgui.SetCursorPos(imgui.ImVec2(xLeft, windowHeight - 48))
        ImMovable("aero_sidebar_close", function()
            if imgui.Button(T("close"), imgui.ImVec2(navButtonWidth, 28)) then
                setMenu(false)
            end
        end)
    end

    imgui.SetCursorPos(imgui.ImVec2(aeroTheme and (windowWidth - 46) or xLeft, aeroTheme and 14 or (windowHeight - navBottomMargin)))
    ImMovable("btn_close", function()
        if aeroTheme then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.76, 0.18, 0.16, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.92, 0.28, 0.24, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.62, 0.10, 0.09, 1.0))
        end
        if imgui.Button(aeroTheme and "X" or T("close"), imgui.ImVec2(aeroTheme and 32 or navButtonWidth, aeroTheme and 24 or 30)) then
            setMenu(false)
        end
        if aeroTheme then
            imgui.PopStyleColor(3)
        end
    end)

    if aeroTheme then
        imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(1.0, 1.0, 1.0, 0.0))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.10, 0.16, 0.22, 1.0))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.80, 0.86, 0.91, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.88, 0.94, 0.99, 1.0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.64, 0.78, 0.90, 1.0))
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.88, 0.93, 0.97, 1.0))
    elseif bzoneTheme then
        imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.0, 0.0, 0.0, 0.46))
    end
    imgui.SetCursorPos(imgui.ImVec2(aeroTheme and 185 or 200, aeroTheme and 58 or 20))
    local contentFlags = aeroTheme and (imgui.WindowFlags.NoScrollbar or 0) or 0
    imgui.BeginChild("Content", imgui.ImVec2(aeroTheme and (windowWidth - 193) or (windowWidth - 220), aeroTheme and (windowHeight - 82) or (windowHeight - 40)), false, contentFlags)
        
        if activeTab == 1 then
            -- MAIN TAB
            local aeroControlX = aeroTheme and 270 or 300
            local aeroKeyButtonW = aeroTheme and 132 or 120
            imgui.TextColored(getAccentColor(), T("ttcs_settings"))
            imgui.Separator()
            imgui.Spacing()

            if aeroTheme then
                local rowStartY = imgui.GetCursorPosY() + 6
                local rowGap = 31
                local leftLabelX = 0
                local leftToggleX = 198
                local rightLabelX = 256
                local rightToggleX = 430

                local function DrawAeroTopToggle(label, toggleId, enabled, xLabel, xToggle, y, onChange)
                    imgui.SetCursorPos(imgui.ImVec2(xLabel, y + 4))
                    ImMovable("lbl_" .. toggleId, function()
                        imgui.Text(label)
                    end)
                    imgui.SetCursorPos(imgui.ImVec2(xToggle, y))
                    ImMovable("tgl_" .. toggleId, function()
                        if imgui.ToggleButton("##" .. toggleId, enabled) and onChange then
                            onChange()
                        end
                    end)
                end

                DrawAeroTopToggle(T("start_stop"), "start_stop", startStopEnabled, leftLabelX, leftToggleX, rowStartY, function()
                    cfg.settings.startstop_enabled = startStopEnabled.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    startStopLastWsTime = os.clock()
                    startStopLastToggleAt = 0.0
                    startStopEngineAssumedOn = true
                end)
                DrawAeroTopToggle(T("auto_repair"), "repair", repairEnabled, leftLabelX, leftToggleX, rowStartY + rowGap)
                DrawAeroTopToggle(T("auto_refill"), "refill", refillEnabled, leftLabelX, leftToggleX, rowStartY + (rowGap * 2))
                DrawAeroTopToggle(T("auto_engine"), "engine", engineEnabled, rightLabelX, rightToggleX, rowStartY)
                DrawAeroTopToggle(T("fast_cmds"), "cmds", commandsEnabled, rightLabelX, rightToggleX, rowStartY + rowGap)
                local atAutoDlAeroEnabled = imgui.ImBool(not not cfg.settings.at_auto_dl_enabled)
                DrawAeroTopToggle(T("at_auto_dl"), "at_auto_dl", atAutoDlAeroEnabled, rightLabelX, rightToggleX, rowStartY + (rowGap * 2), function()
                    cfg.settings.at_auto_dl_enabled = atAutoDlAeroEnabled.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end)
                imgui.SetCursorPos(imgui.ImVec2(rightToggleX + 38, rowStartY + (rowGap * 2) + 4))
                if imgui.TextDisabled then
                    imgui.TextDisabled("(?)")
                else
                    imgui.Text("(?)")
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(T("desc_at_auto_dl"))
                end

                imgui.SetCursorPosY(rowStartY + (rowGap * 3) + 8)
                imgui.Separator()
                imgui.Spacing()
            else
            imgui.Columns(2, "settings_cols", false)
            
            ImMovable("lbl_start_stop", function()
                imgui.Text(T("start_stop"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_start_stop", function()
                if imgui.ToggleButton("##start_stop", startStopEnabled) then
                    cfg.settings.startstop_enabled = startStopEnabled.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    startStopLastWsTime = os.clock()
                    startStopLastToggleAt = 0.0
                    startStopEngineAssumedOn = true
                end
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

            imgui.Spacing()

            ImMovable("lbl_auto_refill", function()
                imgui.Text(T("auto_refill"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            ImMovable("tgl_auto_refill", function()
                imgui.ToggleButton("##refill", refillEnabled)
            end)

            imgui.NextColumn()
            
            ImMovable("lbl_engine", function()
                imgui.Text(T("auto_engine"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - (aeroTheme and 82 or 55))
            ImMovable("tgl_engine", function()
                imgui.ToggleButton("##engine", engineEnabled)
            end)
            
            imgui.Spacing()
            
            ImMovable("lbl_cmds", function()
                imgui.Text(T("fast_cmds"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - (aeroTheme and 82 or 55))
            ImMovable("tgl_cmds", function()
                imgui.ToggleButton("##cmds", commandsEnabled)
            end)

            imgui.Spacing()

            ImMovable("lbl_at_auto_dl_top", function()
                imgui.Text(T("at_auto_dl"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            local atAutoDlTopEnabled = imgui.ImBool(not not cfg.settings.at_auto_dl_enabled)
            ImMovable("tgl_at_auto_dl_top", function()
                if imgui.ToggleButton("##at_auto_dl_top", atAutoDlTopEnabled) then
                    cfg.settings.at_auto_dl_enabled = atAutoDlTopEnabled.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)
            imgui.SameLine()
            ImMovable("help_at_auto_dl_top", function()
                if bzoneTheme then
                    imgui.TextColored(getAccentColor(), "(?)")
                else
                    imgui.TextDisabled("(?)")
                end
            end)
            if imgui.IsItemHovered() then
                imgui.SetTooltip(T("desc_at_auto_dl"))
            end
            
            imgui.Columns(1)
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            end

            -- FVR & Custom toggles
            -- Variabile pentru pozitionare butoane FVR si Custom
            local fvrSettingsBtnX = aeroControlX
            local customSettingsBtnX = aeroControlX
            
            ImMovable("lbl_fvr", function()
                imgui.Text(T("fvr"))
            end)
            imgui.SameLine()
            imgui.SetCursorPosX(aeroControlX)
            local fvrEn = imgui.ImBool(cfg.settings.fvr_enabled)
            ImMovable("tgl_fvr", function()
                if imgui.ToggleButton("##fvr_toggle", fvrEn) then
                    cfg.settings.fvr_enabled = fvrEn.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
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
            imgui.SetCursorPosX(aeroControlX)
            local custEn = imgui.ImBool(cfg.settings.custom_enabled)
            ImMovable("tgl_custom", function()
                if imgui.ToggleButton("##custom_toggle", custEn) then
                    cfg.settings.custom_enabled = custEn.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
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
                imgui.SetCursorPosX(aeroControlX)
                ImMovable("tgl_" .. key_prefix, function()
                    if imgui.ToggleButton("##toggle", enabled) then
                        cfg.settings[key_prefix .. '_enabled'] = enabled.v
                        inicfg.save(cfg, "TowTruckHelper.ini")
                    end
                end)
                
                imgui.SameLine()
                
                -- Pozitie Buton Key (modifica offset-ul sau pune SetCursorPosX)
                -- imgui.SetCursorPosX(350) 
                local k = cfg.settings[key_prefix .. '_key']
                local key_name = (k > 0) and (vkeys.id_to_name(k) or tostring(k)) or "NONE"
                
                ImMovable("key_" .. key_prefix, function()
                    local keyBtnW = aeroKeyButtonW
                    if win7KeyButton(T("key") .. ": " .. key_name, imgui.ImVec2(keyBtnW, 25)) then
                        waitingForKey = key_prefix
                        showKeyDialog.v = true
                    end
                end)
                
                imgui.SameLine()
                ImMovable("help_" .. key_prefix, function()
                    if aeroTheme then
                        imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
                    end
                    if bzoneTheme then
                        imgui.TextColored(getAccentColor(), "(?)")
                    else
                        imgui.TextDisabled("(?)")
                    end
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
            DrawTowOption(T("mouse_detect"), "mouse_detect", T("desc_mouse_detect"))

        elseif activeTab == 5 then
            imgui.TextColored(getAccentColor(), T("ui_theme_title"))
            imgui.Separator()
            imgui.Spacing()

            local previewW = 190
            local previewH = 110
            local gapX = 30
            local gapY = 32
            local totalW = (previewW * 2) + gapX
            local startX = math.max(10, (imgui.GetWindowWidth() - totalW) * 0.5)
            local startY = imgui.GetCursorPosY() + 12
            local dlTheme = imgui.GetWindowDrawList()
            local selectedCol = imgui.ColorConvertFloat4ToU32(getAccentColor())
            local normalBorder = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.32, 0.32, 0.32, 1.0))
            local fillCol = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.06, 0.06, 0.06, 0.95))

            for index, preset in ipairs(UI_THEME_PRESETS) do
                local col = (index - 1) % 2
                local row = math.floor((index - 1) / 2)
                local x = startX + col * (previewW + gapX)
                local y = startY + row * (previewH + gapY)
                imgui.SetCursorPos(imgui.ImVec2(x, y))
                imgui.PushID("theme_" .. tostring(preset.id))
                local clicked = imgui.InvisibleButton("##theme_card", imgui.ImVec2(previewW, previewH))
                local min = imgui.GetItemRectMin()
                local max = imgui.GetItemRectMax()
                local tex = themePreviewTextures[preset.id]
                if tex then
                    if preset.id == 3 then
                        dlTheme:AddRectFilled(min, max, 0xFF000000, 6)
                    end
                    dlTheme:AddImage(tex, min, max)
                else
                    dlTheme:AddRectFilled(min, max, fillCol, 6)
                    local label = T(preset.key)
                    local sz = imgui.CalcTextSize(label)
                    dlTheme:AddText(imgui.ImVec2(min.x + (previewW - sz.x) * 0.5, min.y + (previewH - sz.y) * 0.5), 0xFFB0B0B0, label)
                end
                local selected = tonumber(cfg.settings.ui_theme or 1) == preset.id
                dlTheme:AddRect(min, max, selected and selectedCol or normalBorder, 6, 0, selected and 2.5 or 1.0)
                if clicked then
                    cfg.settings.ui_theme = preset.id
                    pendingUiThemeApply = preset.id
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
                imgui.PopID()
            end

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
                    T("rule6"), T("rule8"), T("rule9"), T("rule10"),
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
            if bzoneTheme then
                imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
                imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(0.96, 0.96, 0.96, 1.0))
                imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(0.90, 0.90, 0.90, 1.0))
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.96, 0.96, 0.96, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.88, 0.88, 0.88, 1.0))
                imgui.PushStyleColor(imgui.Col.CheckMark, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
            end

            local function settingsThemeButton(label, size)
                if bzoneTheme then
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
                end
                local clicked = imgui.Button(label, size)
                if bzoneTheme then
                    imgui.PopStyleColor(1)
                end
                return clicked
            end

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
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)
            imgui.SameLine()
            ImMovable("radio_en", function()
                if imgui.RadioButton("English", cfg.settings.language == 1) then
                    cfg.settings.language = 1
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)

            imgui.Spacing()

            if isEditMode then
                if not hudSettingsInit then
                    hudSettingsInit = true
                    hudVehiclePrefixBuffer.v = tostring(cfg.settings.hud_vehicle_file_prefix or HUD_CFG.vehicle_file_prefix or "")
                    hudSkinPlaceholderBuffer.v = tostring(cfg.settings.hud_skin_placeholder or HUD_CFG.skin_placeholder or "")
                    hudVehiclePlaceholderBuffer.v = tostring(cfg.settings.hud_vehicle_placeholder or HUD_CFG.vehicle_placeholder or "")
                end

                imgui.TextColored(getAccentColor(), "HUD")
                imgui.Separator()

                local hudOn = imgui.ImBool(cfg.settings.hud_enabled)
                if imgui.Checkbox("HUD Enabled", hudOn) then
                    cfg.settings.hud_enabled = hudOn.v
                    hudEnabled.v = hudOn.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    updateImguiProcess()
                end

                local anchor = imgui.ImBool(cfg.settings.hud_anchor_top_right)
                if imgui.Checkbox("Anchor Top-Right", anchor) then
                    cfg.settings.hud_anchor_top_right = anchor.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local hw = imgui.ImInt(cfg.settings.hud_width)
                if imgui.InputInt("HUD Width", hw) then
                    cfg.settings.hud_width = math.max(200, hw.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local hh = imgui.ImInt(cfg.settings.hud_height)
                if imgui.InputInt("HUD Height", hh) then
                    cfg.settings.hud_height = math.max(140, hh.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local hp = imgui.ImInt(cfg.settings.hud_padding)
                if imgui.InputInt("HUD Padding", hp) then
                    cfg.settings.hud_padding = math.max(6, hp.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local si = imgui.ImInt(cfg.settings.hud_skin_image_size)
                if imgui.InputInt("Skin Image Size", si) then
                    cfg.settings.hud_skin_image_size = math.max(24, si.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local vi = imgui.ImInt(cfg.settings.hud_vehicle_image_size)
                if imgui.InputInt("Vehicle Image Size", vi) then
                    cfg.settings.hud_vehicle_image_size = math.max(24, vi.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                local tp = imgui.ImInt(cfg.settings.towpoints_refresh_seconds)
                if imgui.InputInt("Towpoints Refresh (sec)", tp) then
                    cfg.settings.towpoints_refresh_seconds = math.max(30, tp.v)
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end

                if imgui.InputText("Vehicle Prefix", hudVehiclePrefixBuffer) then
                    cfg.settings.hud_vehicle_file_prefix = hudVehiclePrefixBuffer.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    vehicleTextures = {}
                end

                if imgui.InputText("Skin Placeholder Path", hudSkinPlaceholderBuffer) then
                    cfg.settings.hud_skin_placeholder = hudSkinPlaceholderBuffer.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    skinPlaceholderTex = doesFileExist(cfg.settings.hud_skin_placeholder) and imgui.CreateTextureFromFile(cfg.settings.hud_skin_placeholder) or nil
                end

                if imgui.InputText("Vehicle Placeholder Path", hudVehiclePlaceholderBuffer) then
                    cfg.settings.hud_vehicle_placeholder = hudVehiclePlaceholderBuffer.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    vehiclePlaceholderTex = doesFileExist(cfg.settings.hud_vehicle_placeholder) and imgui.CreateTextureFromFile(cfg.settings.hud_vehicle_placeholder) or nil
                end

                imgui.Spacing()
                imgui.TextDisabled("HUD Edit: click dreapta pe un element din HUD pentru selectare, apoi sageti pentru mutare. /scripter pentru exit + save.")
                imgui.Spacing()
            end

            ImMovable("lbl_audio_settings", function()
                imgui.TextColored(getAccentColor(), (T("setari_audio")))
            end)
            imgui.Separator()
            
            ImMovable("chk_audio", function()
                if imgui.Checkbox(T("Music_label"), imgui.ImBool(cfg.settings.music_enabled)) then
                    cfg.settings.music_enabled = not cfg.settings.music_enabled
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    if audioStream then
                         if cfg.settings.music_enabled and showMenu.v then
                            setAudioStreamState(audioStream, AUDIOSTREAM_STATE.PLAY)
                             setAudioStreamVolume(audioStream, cfg.settings.music_volume / 100.0)
                         else
                            setAudioStreamState(audioStream, AUDIOSTREAM_STATE.STOP)
                         end
                    end
                end
            end)
            
            ImMovable("slider_audio", function()
                local vol = imgui.ImInt(cfg.settings.music_volume)
                imgui.Text(T("volume_label"))
                local p = imgui.GetCursorScreenPos()
                local barWidth = 220
                local changed = imgui.ThemeSliderInt("##volume_bar", vol, 0, 100, barWidth)
                local label = tostring(vol.v) .. "%"
                local textSize = imgui.CalcTextSize(label)
                local labelPos = imgui.ImVec2(p.x + barWidth + 8, p.y + (24 - textSize.y) * 0.5)
                local labelCol = tonumber(cfg.settings.ui_theme or 1) == 4 and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.10, 0.16, 0.22, 1.0)) or 0xFFFFFFFF
                imgui.GetWindowDrawList():AddText(labelPos, labelCol, label)
                if changed then
                    cfg.settings.music_volume = vol.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
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
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)

            local autoRaportDetectEnabled = imgui.ImBool(not not cfg.settings.auto_raport_detect_enabled)
            ImMovable("chk_auto_raport_detect", function()
                if imgui.Checkbox(T("auto_raport_detect") .. "##auto_raport_detect", autoRaportDetectEnabled) then
                    cfg.settings.auto_raport_detect_enabled = autoRaportDetectEnabled.v
                    if not cfg.settings.auto_raport_detect_enabled then
                        raportRequestPending = false
                        nextRaportAt = 0.0
                    end
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)

            ImMovable("chk_hide_speedo", function()
                if imgui.Checkbox("Ascunde speedometru server", imgui.ImBool(cfg.settings.hide_server_speedo)) then
                    cfg.settings.hide_server_speedo = not cfg.settings.hide_server_speedo
                    speedoTdIds = {}
                    footerTdIds = {}
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    updateImguiProcess()
                end
            end)

            ImMovable("chk_hud", function()
                if imgui.Checkbox("Activeaza HUD", imgui.ImBool(cfg.settings.hud_enabled)) then
                    cfg.settings.hud_enabled = not cfg.settings.hud_enabled
                    hudEnabled.v = cfg.settings.hud_enabled
                    inicfg.save(cfg, "TowTruckHelper.ini")
                    updateImguiProcess()
                end
            end)

            ImMovable("lbl_hud_pos", function()
                imgui.Text("Pozitie HUD")
            end)
            imgui.SameLine()
            ImMovable("btn_hud_pos_edit", function()
                if settingsThemeButton("Edit position", imgui.ImVec2(120, 25)) then
                    beginHudEdit()
                end
            end)
            imgui.SameLine()
            ImMovable("btn_hud_pos_reset", function()
                if settingsThemeButton("Reset", imgui.ImVec2(80, 25)) then
                    cfg.settings.hud_anchor_top_right = false
                    cfg.settings.hud_pos_x = HUD_CFG.pos_default.x
                    cfg.settings.hud_pos_y = HUD_CFG.pos_default.y
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)

            ImMovable("lbl_td_pos", function()
                imgui.Text(T("textdraw_label"))
            end)
            imgui.SameLine()
            ImMovable("btn_td_pos_edit", function()
                if settingsThemeButton("Edit position", imgui.ImVec2(120, 25)) then
                    beginTextdrawEdit()
                end
            end)
            imgui.SameLine()
            ImMovable("btn_td_pos_reset", function()
                if settingsThemeButton("Reset", imgui.ImVec2(80, 25)) then
                    cfg.settings.textdraw_pos_x = 0
                    cfg.settings.textdraw_pos_y = 0
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)
            
            ImMovable("chk_loading", function()
                if imgui.Checkbox(T("loading_screen"), imgui.ImBool(cfg.settings.loading_screen_enabled)) then
                    cfg.settings.loading_screen_enabled = not cfg.settings.loading_screen_enabled
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)
            
            ImMovable("chk_autoupdate", function()
                if imgui.Checkbox(T("auto_check_update"), imgui.ImBool(cfg.settings.update_auto_check)) then
                    cfg.settings.update_auto_check = not cfg.settings.update_auto_check
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)
            
            imgui.Spacing()
            ImMovable("btn_check_update", function()
                if settingsThemeButton(T("check_now"), imgui.ImVec2(150, 30)) then
                    checkUpdateOnce()
                end
            end)

            imgui.Spacing()
            ImMovable("lbl_menu_cmd", function()
                imgui.Text(T("menu_open_cmd"))
            end)
            local cmdBuf = imgui.ImBuffer(cfg.settings.menu_cmd, 32)
            ImMovable("input_menu_cmd", function()
                if bzoneTheme then
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.0, 0.0, 0.0, 1.0))
                    imgui.PushStyleColor(imgui.Col.TextSelectedBg, imgui.ImVec4(0.30, 0.55, 0.85, 0.45))
                end
                if imgui.InputText("##menucmd", cmdBuf) then
                    cfg.settings.menu_cmd = cmdBuf.v
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
                if bzoneTheme then
                    imgui.PopStyleColor(2)
                end
            end)
            
            ImMovable("lbl_menu_key", function()
                 imgui.Text(T("menu_open_key"))
            end)
            local keyName = (cfg.settings.menu_open_key > 0) and (vkeys.id_to_name(cfg.settings.menu_open_key) or tostring(cfg.settings.menu_open_key)) or "NONE"
            ImMovable("btn_menu_key", function()
                if settingsThemeButton(keyName .. "##menukey", imgui.ImVec2(100, 25)) then
                    waitingForKey = "menu_open"
                    showKeyDialog.v = true
                end
            end)
            imgui.SameLine()
            ImMovable("chk_menu_key", function()
                if imgui.Checkbox("Active##menukey", imgui.ImBool(cfg.settings.menu_key_enabled)) then
                    cfg.settings.menu_key_enabled = not cfg.settings.menu_key_enabled
                    inicfg.save(cfg, "TowTruckHelper.ini")
                end
            end)

            if bzoneTheme then
                imgui.PopStyleColor(7)
            end
        end
        
    imgui.EndChild()
    if aeroTheme then
        imgui.PopStyleColor(6)
    elseif bzoneTheme then
        imgui.PopStyleColor(1)
    end
    if pendingUiThemeApply ~= nil then
        applyUiThemePreset(pendingUiThemeApply)
        apply_style()
        pendingUiThemeApply = nil
    end
    imgui.End()
end

-- =========================
-- AUTO REPAIR LOOP
-- =========================
function autoRepairLoop()
    local REPAIR_HP = 350
    local REFILL_FUEL = 10
    while true do
        wait(800)
        if modEnabled.v and repairEnabled.v then
            if isCharInAnyCar(PLAYER_PED) then
                local veh = storeCarCharIsInNoSave(PLAYER_PED)
                if veh ~= 0 then
                    local health = getCarHealth(veh)
                    if health <= REPAIR_HP then
                        if not repairAsked and not showRepairConfirmDialog.v and not showRefillConfirmDialog.v then
                            showRepairConfirmDialog.v = true
                            repairAsked = true
                            imgui.Process = true
                            sampSetCursorMode(true)
                        end
                    else
                        repairAsked = false
                    end
                end
            end
        else
            repairAsked = false
            showRepairConfirmDialog.v = false
        end

        if modEnabled.v and refillEnabled.v then
            if isCharInAnyCar(PLAYER_PED) then
                local fuel = tonumber(hudState.vehicleFuel)
                if fuel and fuel <= REFILL_FUEL then
                    if not refillAsked and not showRefillConfirmDialog.v and not showRepairConfirmDialog.v then
                        showRefillConfirmDialog.v = true
                        refillAsked = true
                        imgui.Process = true
                        sampSetCursorMode(true)
                    end
                elseif fuel and fuel > REFILL_FUEL then
                    refillAsked = false
                end
            else
                refillAsked = false
            end
        else
            refillAsked = false
            showRefillConfirmDialog.v = false
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
        if text:find("Nu esti intr%-o factiune care sa%-ti ofere un job secundar") or text:find("Nu esti mecanic") then
            repairEnabled.v = false
            showRepairConfirmDialog.v = false
            repairAsked = false
            sampAddChatMessage(T("msg_prefix") .. "{FF5555}Auto Repair dezactivat (Nu esti mecanic sau nu ai job secundar).", -1)
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
            if startStopEnabled.v then
                startStopEngineAssumedOn = false
                startStopLastToggleAt = os.clock()
                startStopLastWsTime = os.clock()
            else
                sampSendChat("/engine")
                sampSendChat("/lights")
            end
        end
    end

    local low = text:lower()
    for _, pat in ipairs(CHAT_PATTERNS.duty_on) do
        if low:match(pat) then
            isDuty = true
            nextTowpointsRefreshAt = 0.0
            nextRaportAt = 0.0
            if not startupHudBootstrapActive then
                scheduleDutyHudInitialRequests()
            end
            break
        end
    end
    for _, pat in ipairs(CHAT_PATTERNS.duty_off) do
        if low:match(pat) then
            isDuty = false
            dutyInitialRequestsScheduled = false
            nextTowpointsRefreshAt = 0.0
            nextRaportAt = 0.0
            if not startupHudBootstrapActive then
                towpoints = 0
            else
                startupHudBootstrapActive = false
            end
            break
        end
    end

    local n = parseTowpointsFromChat(text)
    if n then
        towpoints = n
        if towpointsRequestPending then
            towpointsRequestPending = false
            return false
        end
    end
end

function sampev.onPlayerSpawn()
end

local function stripSampColors2(s)
    s = tostring(s or "")
    s = s:gsub("{%x%x%x%x%x%x}", "")
    s = s:gsub("{%x+}", "")
    return s
end

local function parseRaportDialogText(text)
    local raw = stripSampColors2(text or "")
    raw = raw:gsub("\t", " ")
    local weekDone = nil
    local weekAction = nil
    local weekTows = nil
    local inWeek = false

    for line in raw:gmatch("[^\r\n]+") do
        local l = line:gsub("^%s+", ""):gsub("%s+$", "")
        if l ~= "" then
            local low = l:lower()
            if low:find("progres saptamana curenta", 1, true) or low:find("current week progress", 1, true) then
                inWeek = true
                local st = l:match("%(([^%)]+)%)")
                st = tostring(st or ""):lower()
                if st:find("incomplet", 1, true) or st:find("incomplete", 1, true) then
                    weekDone = false
                elseif st:find("complet", 1, true) or st:find("completed", 1, true) then
                    weekDone = true
                end
            elseif inWeek and low:find("bonus", 1, true) then
                break
            elseif inWeek and low:find("rank", 1, true) then
                break
            elseif inWeek then
                local a = l:match("[Oo]rice%s+actiune.-:%s*([%d%/%.,]+)")
                if not a then a = l:match("[Aa]ny%s+action%s+in%s+faction.-:%s*([%d%/%.,]+)") end
                if a then weekAction = a end
                local t = l:match("[Ss]ervicii%s+de%s+tractari.-:%s*([%d%/%.,]+)")
                if not t then t = l:match("[Vv]ehicles%s+to%s+tow.-:%s*([%d%/%.,]+)") end
                if t then weekTows = t end
            end
        end
    end

    return weekDone, weekAction, weekTows
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    local t = stripSampColors2(title or ""):lower()
    local body = stripSampColors2(text or ""):lower()
    if not raportRequestPending then
        return
    end
    if not (t:find("faction report", 1, true) or body:find("progres saptamana curenta", 1, true) or body:find("current week progress", 1, true)) then
        return
    end

    local weekDone, weekAction, weekTows = parseRaportDialogText(text)
    hudState.raportWeekDone = weekDone
    hudState.raportWeekAction = weekAction
    hudState.raportWeekTows = weekTows
    hudState.raportAt = os.clock()

    raportRequestPending = false
    nextRaportAt = os.clock() + 30
    return false
end

function sampev.onSendChat(text)
    if not text then return end
    local low = tostring(text):lower()
    if low:match("^%s*/duty") then
        dutyRequestedAt = os.clock()
    end
end

local function isSpeedoText(text)
    local t = (text or ""):lower()
    return t:find("km/h", 1, true)
        or t:find("kmh", 1, true)
        or t:find("mph", 1, true)
        or t:find("combustibil", 1, true)
        or t:find("fuel", 1, true)
        or t:find("viteza", 1, true)
        or t:find("kilometraj", 1, true)
        or t:find("status", 1, true)
end

local function isSpeedoPos(pos)
    if not pos then return false end
    local x = tonumber(pos.x) or 0
    local y = tonumber(pos.y) or 0
    return x >= 360 and y >= 260
end

local function isSpeedoBox(td)
    if not td then return false end
    local lw = tonumber(td.lineWidth) or 0
    local lh = tonumber(td.lineHeight) or 0
    local p = td.position or { x = 0, y = 0 }
    local y = tonumber(p.y) or 0
    return y >= 220 and (lw >= 150 or lh >= 40)
end

local function stripSampColors(s)
    s = tostring(s or "")
    s = s:gsub("{%x%x%x%x%x%x}", "")
    s = s:gsub("{%x+}", "")
    return s
end

local function tdPos640(pos)
    if not pos then return 0, 0 end
    local x = tonumber(pos.x) or 0
    local y = tonumber(pos.y) or 0
    if x <= 1.5 and y <= 1.5 then
        x = x * 640.0
        y = y * 448.0
    end
    return x, y
end

local function isFooterPosPlayer(pos)
    local x, y = tdPos640(pos)
    return x <= 320 and y >= 360
end

local function isFooterPosServer(pos)
    local x, y = tdPos640(pos)
    return x >= 320 and y >= 360
end

local function isFooterPlayerText(text)
    local t = stripSampColors(text)
    if #t < 6 then return false end
    if not t:match("%(%s*%d+%s*%)%s*$") then return false end
    if not t:match("%a") then return false end
    return true
end

local function isFooterServerText(text)
    local t = stripSampColors(text)
    if #t < 4 then return false end
    if t:match("[%w%-_]+%.[%w%-_]+%.[%w%-_]+") then return true end
    if t:find(".", 1, true) and t:match("%a") and #t <= 32 then return true end
    if t:match("^[%u%d%-%_%. ]+$") and #t <= 32 then return true end
    return false
end

local function speedoMetaPos(pos)
    local x = pos and tonumber(pos.x) or 0
    local y = pos and tonumber(pos.y) or 0
    if x <= 1.5 and y <= 1.5 then
        x = x * 640.0
        y = y * 448.0
    end
    return x, y
end

local function speedoGuessKindFromText(text)
    local t = stripSampColors(text):lower()
    if t:find("km/h", 1, true) or t:find("kmh", 1, true) or t:find("mph", 1, true) then
        return "speed"
    end
    if t:find("%", 1, true) or t:match("%d+%s*[lL]%s*$") then
        return "fuel"
    end
    if t:find("km", 1, true) and not (t:find("km/h", 1, true) or t:find("kmh", 1, true)) then
        return "odo"
    end
    return nil
end

local function speedoGuessKindFromPos(x, y)
    if y < 305 then return "fuel" end
    return "odo"
end

local function updateSpeedoInfoFromText(text)
    if not hudState.inVehicle then return end
    local raw = stripSampColors(text)
    local low = raw:lower()

    local speed = low:match("viteza%s*:%s*(%d+)")
    if not speed and not low:find("kilometraj", 1, true) then
        speed = low:match("(%d+)%s*km/h") or low:match("(%d+)%s*kmh")
    end
    if speed then
        hudState.vehicleSpeed = tonumber(speed)
    end

    local fuel = low:match("combustibil%s*:%s*([%d%,%.]+)%s*%%")
    if not fuel then
        fuel = low:match("([%d%,%.]+)%s*%%")
    end
    if not fuel then
        fuel = low:match("([%d%,%.]+)%s*[lL]%s*$")
    end
    if fuel then
        fuel = fuel:gsub(",", ".")
        hudState.vehicleFuel = tonumber(fuel)
    end

    local km = low:match("kilometraj%s*:%s*([%d%,%.]+)")
    if not km then
        if low:find("km", 1, true) and not (low:find("km/h", 1, true) or low:find("kmh", 1, true)) then
            km = low:match("([%d%,%.]+)%s*km")
        end
    end
    if km then
        km = km:gsub(",", ".")
        hudState.vehicleOdometer = tonumber(km)
    end

    local st = raw:match("[Ss]tatus%s*:%s*([^\r\n]+)")
    if st then
        st = st:gsub("^%s+", ""):gsub("%s+$", "")
        hudState.vehicleStatus = st
        local stLow = st:lower()
        if stLow:find("incuiat", 1, true) or stLow:find("inchis", 1, true) or stLow:find("locked", 1, true) then
            hudState.vehicleLocked = true
        elseif stLow:find("descuiat", 1, true) or stLow:find("deschis", 1, true) or stLow:find("unlocked", 1, true) then
            hudState.vehicleLocked = false
        end
    end

    if fuel or km or st then
        hudState.vehicleSpeedoAt = os.clock()
    end
end

local function updateSpeedoSpeedFromNumeric(text, pos, letterHeight)
    if not hudState.inVehicle then return end
    local v = tostring(text or ""):match("^%s*(%d+)%s*$")
    if not v then return end
    local x = pos and tonumber(pos.x) or 0
    local y = pos and tonumber(pos.y) or 0
    local lh = tonumber(letterHeight) or 0
    if x >= 350 and y >= 220 and lh >= 10 then
        hudState.vehicleSpeed = tonumber(v)
        hudState.vehicleSpeedoAt = os.clock()
    end
end

function sampev.onShowTextDraw(id, data)
    local footerPlayer = isFooterPlayerText(data and data.text)
    local footerServer = isFooterServerText(data and data.text)

    if cfg.settings.speedo_probe and (isSpeedoText(data and data.text) or isSpeedoPos(data and data.position) or isSpeedoBox(data) or footerPlayer or footerServer) then
        local p = data and data.position or {x = 0, y = 0}
        sampAddChatMessage(string.format("{AAAAAA}[TTH] TD show id=%d pos=%.1f/%.1f text=%s", id, tonumber(p.x) or 0, tonumber(p.y) or 0, tostring(data and data.text or "")), -1)
    end

    if data and data.text then
        updateSpeedoInfoFromText(data.text)
        updateSpeedoSpeedFromNumeric(data.text, data.position, data.letterHeight)
    end

    if data and data.position then
        local x, y = speedoMetaPos(data.position)
        local k = speedoGuessKindFromText(data.text)
        if k and k ~= "speed" then
            speedoTdMeta[id] = { kind = k, x = x, y = y }
        end
    end

    local hideSpeedo = cfg.settings.hide_server_speedo and (isSpeedoText(data and data.text) or speedoTdMeta[id] ~= nil)
    local hideFooter = cfg.settings.hide_server_speedo and (footerPlayer or footerServer)

    if hideFooter then
        footerTdIds[id] = true
        if data then
            data.text = ""
            data.lineWidth = 0.0
            data.lineHeight = 0.0
            data.letterWidth = 0.0
            data.letterHeight = 0.0
            data.boxColor = 0
            data.backgroundColor = 0
            data.letterColor = 0
            data.color = 0
            data.shadow = 0
            data.outline = 0
            data.selectable = 0
        end
        return { id, data }
    end

    if hideSpeedo then
        speedoTdIds[id] = true
        if data then
            data.text = ""
            data.lineWidth = 0.0
            data.lineHeight = 0.0
            data.letterWidth = 0.0
            data.letterHeight = 0.0
            data.boxColor = 0
            data.backgroundColor = 0
            data.letterColor = 0
            data.color = 0
            data.shadow = 0
            data.outline = 0
            data.selectable = 0
        end
        return { id, data }
    end
end

function sampev.onTextDrawSetString(id, text)
    if cfg.settings.speedo_probe and (speedoTdIds[id] or footerTdIds[id] or isSpeedoText(text)) then
        sampAddChatMessage(string.format("{AAAAAA}[TTH] TD str id=%d text=%s", id, tostring(text or "")), -1)
    end

    updateSpeedoInfoFromText(text)

    if cfg.settings.hide_server_speedo and (footerTdIds[id] or isFooterPlayerText(text) or isFooterServerText(text)) then
        footerTdIds[id] = true
        return { id, "" }
    end

    local meta = speedoTdMeta[id]
    if meta and (meta.kind == "fuel" or meta.kind == "odo") then
        local n = tostring(stripSampColors(text)):gsub(",", "."):match("([%d%.]+)")
        local v = n and tonumber(n) or nil
        if v then
            if meta.kind == "fuel" then
                hudState.vehicleFuel = v
            else
                hudState.vehicleOdometer = v
            end
            hudState.vehicleSpeedoAt = os.clock()
        end
    end

    if cfg.settings.hide_server_speedo and (speedoTdIds[id] or isSpeedoText(text)) then
        speedoTdIds[id] = true
        return { id, "" }
    end
end

function sampev.onTextDrawHide(id)
    speedoTdIds[id] = nil
    footerTdIds[id] = nil
    speedoTdMeta[id] = nil
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
        sampSendChat("/f " .. T("ttme")) 
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
        sampSendChat("/f " .. T("ttrr")) 
    end)
end

function cmdume(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/f " .. T("ume")) 
    end)
end

function cmdurr(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    lua_thread.create(function()
        wait(100)
        sampSendChat("/f " .. T("urr")) 
    end)
end

function cmdat(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    runAtentieTractezSequence()
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
