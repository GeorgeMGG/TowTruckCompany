script_name("TTC Helper Mod")
script_author("TTC")
script_description("TTC")
script_version("3.6")
local LOCAL_VERSION = "3.6"

require "lib.moonloader"
local imgui = require "imgui"
local sampev = require "lib.samp.events"
local inicfg = require "inicfg"
local vkeys = require "vkeys"

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
        tow_truck_settings = "SETARI TOW TRUCK",
        tow_ls = "Tow LS",
        tow_lv = "Tow LV",
        tow_sf = "Tow SF",
        at_tractez = "Atentie Tractez",
        repair_refill = "Repair/Refill",
        sell_kit = "Sell Kit",
        repair_refill_me = "Repair/Refill ME",
        key = "TASTA",
        none = "NIMIC",
        desc_ls = "Acesta comanda alege orasul LS",
        desc_lv = "Acesta comanda alege orasul LV",
        desc_sf = "Acesta comanda alege orasul SF",
        desc_at = "Striga: /s Atentie tractez!",
        desc_rr = "Ofera repair/refill jucatorilor din jur.",
        desc_sk = "Ofera repair kit jucatorilor din jur.",
        desc_rrme = "Acest mod iti ofera repair/refill",
        key_dialog_title = "Setare Tasta",
        key_dialog_msg = "Alege pe ce tasta vrei sa fie comanda",
        press_key = "Apasa orice tasta acum...",
        cancel = "Anuleaza",
        msg_prefix = "{6600FF}[Team of Luxury System]{FFFFFF}: ",
        msg_tow_ls = "Orasul de tow este LS",
        msg_tow_lv = "Orasul de tow este LV",
        msg_tow_sf = "Orasul de tow este SF",
        msg_not_in_veh = "Nu esti intr-un vehicul.",
        msg_no_player = "Niciun jucator in apropiere.",
        msg_hitman = "Membrii Hitman nu beneficieaza de acest serviciu automat.",
        msg_target_no_veh = "Jucatorul nu este intr-un vehicul.",
        msg_welcome1 = "Modpack creat special pentru membrii Team of Luxury.",
        msg_welcome2 = "Foloseste comanda /lux pentru a deschide meniul cu toate informatiile.",
        msg_cmd_disabled = "Comanda nu poate fi folosita, modul sau comenzile rapide dezactivate.",
        lang_settings = "SETARI LIMBA",
        color_settings = "CULOARE MENIU",
        textdraw_settings = "TEXTDRAW",
        enable_textdraw = "Activeaza Textdraw",
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
        manifest_url = "Manifest URL",
        auto_check_update = "Verifica automat",
        active = "ACTIV",
        inactive = "INACTIV",
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
        td_title = "COMMANDS STATUS:"
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
        tow_truck_settings = "TOW TRUCK SETTINGS",
        tow_ls = "Tow LS",
        tow_lv = "Tow LV",
        tow_sf = "Tow SF",
        at_tractez = "Attention Towing",
        repair_refill = "Repair/Refill",
        sell_kit = "Sell Kit",
        repair_refill_me = "Repair/Refill ME",
        key = "KEY",
        none = "NONE",
        desc_ls = "This command selects LS city",
        desc_lv = "This command selects LV city",
        desc_sf = "This command selects SF city",
        desc_at = "Shouts: /s Atentie tractez!",
        desc_rr = "Offers repair/refill to nearby players.",
        desc_sk = "Offers repair kit to nearby players.",
        desc_rrme = "This mod offers you repair/refill",
        key_dialog_title = "Set Key",
        key_dialog_msg = "Choose a key for command",
        press_key = "Press any key now...",
        cancel = "Cancel",
        msg_prefix = "{6600FF}[Team of Luxury System]{FFFFFF}: ",
        msg_tow_ls = "Tow city is LS",
        msg_tow_lv = "Tow city is LV",
        msg_tow_sf = "Tow city is SF",
        msg_not_in_veh = "You are not in a vehicle.",
        msg_no_player = "No player nearby.",
        msg_hitman = "Hitman members do not benefit from this automatic service.",
        msg_target_no_veh = "Player is not in a vehicle.",
        msg_welcome1 = "Modpack created especially for Team of Luxury members.",
        msg_welcome2 = "Use command /lux to open the menu with all information.",
        msg_cmd_disabled = "Command cannot be used, mod or fast commands disabled.",
        lang_settings = "LANGUAGE SETTINGS",
        color_settings = "MENU COLOR",
        textdraw_settings = "TEXTDRAW",
        enable_textdraw = "Enable Textdraw",
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
        download_now = "Download now",
        later = "Later",
        update_settings = "Update",
        manifest_url = "Manifest URL",
        auto_check_update = "Auto-check",
        active = "ACTIVE",
        inactive = "INACTIVE",
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
        td_title = "COMMANDS STATUS:"
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
        update_manifest_url = "",
        update_auto_check = true,
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
        frame_bg_b = 51,
        frame_bg_a = 255,
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
    }
}
local cfg = inicfg.load(cfg_default, "TTC.ini")
if not cfg then
    cfg = cfg_default
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
if cfg.settings.update_manifest_url == nil then cfg.settings.update_manifest_url = "" end
if cfg.settings.update_auto_check == nil then cfg.settings.update_auto_check = true end

local function cfgColor(prefix)
    local r = (cfg.settings[prefix .. '_r'] or 255) / 255
    local g = (cfg.settings[prefix .. '_g'] or 255) / 255
    local b = (cfg.settings[prefix .. '_b'] or 255) / 255
    local a = (cfg.settings[prefix .. '_a'] or 255) / 255
    return imgui.ImVec4(r, g, b, a)
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

-- Textdraw Font
local tdFont = nil

-- Update Dialog State
local showUpdateDialog = imgui.ImBool(false)
local updateInfo = { version_online = nil, reason_ro = nil, reason_en = nil, download_url = nil }

-- =========================
-- HELPER FUNCTIONS
-- =========================
function T(key)
    local lang_code = (cfg.settings.language == 1) and "en" or "ro"
    return translations[lang_code][key] or key
end

function getAccentColor()
    return imgui.ImVec4(
        cfg.settings.menu_color_r / 255, 
        cfg.settings.menu_color_g / 255, 
        cfg.settings.menu_color_b / 255, 
        1.0
    )
end

function checkUpdateOnce()
    if not cfg.settings.update_manifest_url or cfg.settings.update_manifest_url == "" then return end
    local tmp = "TTC_update.ini"
    local ok = downloadUrlToFile(cfg.settings.update_manifest_url, tmp)
    if ok then
        local manifest = inicfg.load({ update = {} }, tmp)
        if manifest and manifest.update and manifest.update.version then
            local onlineV = tostring(manifest.update.version)
            if onlineV ~= LOCAL_VERSION then
                updateInfo.version_online = onlineV
                updateInfo.reason_ro = manifest.update.reason_ro or ""
                updateInfo.reason_en = manifest.update.reason_en or ""
                updateInfo.download_url = manifest.update.download_url or ""
                showUpdateDialog.v = true
            end
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

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        v.v = not v.v
        return true
    end
    
    local col_bg = v.v and getAccentColor() or imgui.ImVec4(0.33, 0.33, 0.33, 1.0)
    
    draw_list:AddRectFilled(
        p, 
        imgui.ImVec2(p.x + width, p.y + height), 
        imgui.ColorConvertFloat4ToU32(col_bg), 
        height * 0.5
    )
    
    local circle_x = v.v and (p.x + width - radius) or (p.x + radius)
    draw_list:AddCircleFilled(
        imgui.ImVec2(circle_x, p.y + radius), 
        radius - 1.5, 
        0xFFFFFFFF
    )
    return false
end

-- =========================
-- MAIN
-- =========================
function main()
    repeat wait(0) until isSampAvailable()

    if doesFileExist("moonloader/resource/lux_logo.png") then
        logoTexture = imgui.CreateTextureFromFile("moonloader/resource/lux_logo.png")
    end
    
    -- Create Font for Textdraw
    tdFont = renderCreateFont("Arial", 10, 5) -- 5 = FCR_BORDER

    sampRegisterChatCommand("lux", toggleMenu)

    local commands = {
        st = "/stats",
        cmb = "/clanmembers",
        mb = "/members"
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

    sampRegisterChatCommand("salut", cmdSalut)
    sampRegisterChatCommand("welcome", cmdwelcome)
    sampRegisterChatCommand("sal", cmdsal)
    sampRegisterChatCommand("cvrr", cmdCVR)
    sampRegisterChatCommand("mycc", cmdmycc)
    lua_thread.create(autoRepairLoop)

    sampAddChatMessage(T("msg_prefix") .. T("msg_welcome1"), -1)
    sampAddChatMessage(T("msg_prefix") .. T("msg_welcome2"), -1)
    if cfg.settings.update_auto_check and cfg.settings.update_manifest_url ~= "" then
        lua_thread.create(function()
            wait(1500)
            checkUpdateOnce()
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
                sampSendChat("/s Atentie tractez!")
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
            if cfg.settings.at_enabled then table.insert(lines, T("at_tractez")) end
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
function processService(type)
    local maxDist = 15.0
    local closestId = -1
    local closestDist = maxDist
    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)

    for i = 0, 1000 do
        if sampIsPlayerConnected(i) then
            local result, char = sampGetCharHandleBySampPlayerId(i)
            if result and doesCharExist(char) and char ~= PLAYER_PED then
                local x, y, z = getCharCoordinates(char)
                local dist = getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z)
                if dist < closestDist then
                    closestDist = dist
                    closestId = i
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
        sampSendChat("/sellkit " .. closestId .. " " .. price)
    end
end

-- =========================
-- MENU
-- =========================
function setMenu(state)
    showMenu.v = state
    imgui.Process = state
    sampSetCursorMode(state)
end

function toggleMenu()
    setMenu(not showMenu.v)
end

-- =========================
-- IMGUI DRAW
-- =========================
local menuPos = imgui.ImVec2(300, 200)
local menuWidth = 800
local menuHeight = 500

function imgui.OnDrawFrame()
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
            if updateInfo.download_url and updateInfo.download_url ~= "" then
                downloadUrlToFile(updateInfo.download_url, "moonloader\\LUX_Modified.lua")
                sampAddChatMessage(T("msg_prefix") .. "Update descarcat. Reincarca scriptul sau reporneste jocul.", -1)
            else
                sampAddChatMessage(T("msg_prefix") .. "URL download indisponibil.", -1)
            end
            showUpdateDialog.v = false
        end
        imgui.Spacing()
        if imgui.Button(T("later"), imgui.ImVec2(-1, 30)) then
            showUpdateDialog.v = false
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

    local groupHeight = (4 * navButtonHeight) + (3 * spacingY)
    local xLeft = (leftPaneWidth - navButtonWidth) / 2
    local startY = logoTop + logoHeight + math.max(0, (windowHeight - logoTop - logoHeight - groupHeight) / 2)
    imgui.SetCursorPos(imgui.ImVec2(xLeft, startY))
    imgui.BeginGroup()
        if imgui.Button(T("main"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 1 end
        imgui.Spacing()
        if imgui.Button(T("info"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 2 end
        imgui.Spacing()
        if imgui.Button(T("settings"), imgui.ImVec2(navButtonWidth, navButtonHeight)) then activeTab = 4 end
    imgui.EndGroup()

    imgui.SetCursorPos(imgui.ImVec2(xLeft, windowHeight - navBottomMargin))
    if imgui.Button(T("close"), imgui.ImVec2(navButtonWidth, 30)) then
        setMenu(false)
    end

    imgui.SetCursorPos(imgui.ImVec2(200, 20))
    imgui.BeginChild("Content", imgui.ImVec2(windowWidth - 220, windowHeight - 40), true)
        
        if activeTab == 1 then
            -- MAIN TAB
            imgui.TextColored(getAccentColor(), T("luxury_settings"))
            imgui.Separator()
            imgui.Spacing()

            imgui.Columns(2, "settings_cols", false)
            
            imgui.Text(T("global_mod"))
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            imgui.ToggleButton("##mod", modEnabled)
            
            imgui.Spacing()
            
            imgui.Text(T("auto_repair"))
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            imgui.ToggleButton("##repair", repairEnabled)

            imgui.NextColumn()
            
            imgui.Text(T("auto_engine"))
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            imgui.ToggleButton("##engine", engineEnabled)
            
            imgui.Spacing()
            
            imgui.Text(T("fast_cmds"))
            imgui.SameLine()
            imgui.SetCursorPosX(imgui.GetColumnOffset() + imgui.GetColumnWidth() - 55)
            imgui.ToggleButton("##cmds", commandsEnabled)
            
            imgui.Columns(1)
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            imgui.TextColored(getAccentColor(), T("tow_truck_settings"))
            imgui.Separator()
            imgui.Spacing()

            local function DrawTowOption(label, key_prefix, info_text)
                imgui.PushID(key_prefix)
                local enabled = imgui.ImBool(cfg.settings[key_prefix .. '_enabled'])
                imgui.Text(label)
                imgui.SameLine()
                imgui.SetCursorPosX(300) 
                if imgui.ToggleButton("##toggle", enabled) then
                    cfg.settings[key_prefix .. '_enabled'] = enabled.v
                    inicfg.save(cfg, "TTC.ini")
                end
                imgui.SameLine()
                local k = cfg.settings[key_prefix .. '_key']
                local key_name = (k > 0) and (vkeys.id_to_name(k) or tostring(k)) or "NONE"
                if imgui.Button(T("key") .. ": " .. key_name, imgui.ImVec2(120, 25)) then
                    waitingForKey = key_prefix
                    showKeyDialog.v = true
                end
                imgui.SameLine()
                imgui.TextDisabled("(?)")
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(info_text)
                end
                imgui.PopID()
                imgui.Spacing()
            end

            DrawTowOption(T("tow_ls"), "tow_ls", T("desc_ls"))
            DrawTowOption(T("tow_lv"), "tow_lv", T("desc_lv"))
            DrawTowOption(T("tow_sf"), "tow_sf", T("desc_sf"))
            DrawTowOption(T("at_tractez"), "at", T("desc_at"))
            DrawTowOption(T("repair_refill"), "repair_refill", T("desc_rr"))
            DrawTowOption(T("sell_kit"), "sellkit", T("desc_sk"))
            DrawTowOption(T("repair_refill_me"), "repair_refill_me", T("desc_rrme"))

        elseif activeTab == 2 then
            -- INFO TAB
            imgui.TextColored(getAccentColor(), T("info"))
            imgui.Separator()
            imgui.Spacing()
            
            local lines = {
                "[CopyText] Use ALT + Left/Right arrow!",
                "[AutoLogin] Modpack Team of Luxury -> Cleo -> [Autologin.ini]",
                "[Clan Reconnect] It let's clan players simply reconnect without re-launching samp",
                "[Season-Changer] - Allows to change between two seasons: Winter and Summer.", 
                "And in-game press on F2 to activate the script and change between textures.",
                "",
                "/mb - /members",
                "/cmb - /clanmembers",
                "/st - /stats"
            }
            
            for _, line in ipairs(lines) do
                imgui.TextWrapped(line)
            end
            
            imgui.Spacing()
            imgui.Separator()
            
            if imgui.Button("Forum", imgui.ImVec2(-1, 30)) then
                 os.execute("start https://forum.b-zone.ro/profile/122529-georgevp/")
            end
            if imgui.Button("Discord George_VP", imgui.ImVec2(-1, 30)) then
                 os.execute("start https://discord.com/users/304567478846095361")
            end

        elseif activeTab == 3 then
            -- RULES TAB
            imgui.TextColored(getAccentColor(), T("rules"))
            imgui.Separator()
            imgui.BeginChild("RulesScroll", imgui.ImVec2(0, -40), true)
                imgui.TextWrapped("Aici pot fi afisate regulile. (Continut simplificat pentru demo).")
                imgui.TextWrapped("...")
                imgui.TextColored(getAccentColor(), T("see_rules"))
            imgui.EndChild()
            
            if imgui.Button(T("open_browser"), imgui.ImVec2(-1, 30)) then
                os.execute("start https://sites.google.com/view/team-of-luxury/clan-rules")
            end

        elseif activeTab == 4 then
            -- SETTINGS TAB (NEW)
            imgui.TextColored(getAccentColor(), T("lang_settings"))
            imgui.Separator()
            imgui.Spacing()
            
            imgui.Text(T("choose_lang"))
            
            local lang = imgui.ImInt(cfg.settings.language)
            if imgui.RadioButton("Romana", lang.v == 0) then
                cfg.settings.language = 0
                inicfg.save(cfg, "TTC.ini")
            end
            imgui.SameLine()
            if imgui.RadioButton("English", lang.v == 1) then
                cfg.settings.language = 1
                inicfg.save(cfg, "TTC.ini")
            end
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            imgui.TextColored(getAccentColor(), T("textdraw_settings"))
            imgui.Separator()
            imgui.Spacing()
            
            local td = imgui.ImBool(cfg.settings.textdraw_enabled)
            imgui.Text(T("enable_textdraw"))
            imgui.SameLine()
            if imgui.ToggleButton("##td", td) then
                cfg.settings.textdraw_enabled = td.v
                inicfg.save(cfg, "TTC.ini")
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            imgui.TextColored(getAccentColor(), T("update_settings"))
            imgui.Separator()
            imgui.Spacing()
            imgui.Text(string.format("%s: %s", T("manifest_url"), cfg.settings.update_manifest_url ~= "" and cfg.settings.update_manifest_url or "-"))
            local autoUpd = imgui.ImBool(cfg.settings.update_auto_check)
            if imgui.Checkbox(T("auto_check_update"), autoUpd) then
                cfg.settings.update_auto_check = autoUpd.v
                inicfg.save(cfg, "TTC.ini")
            end
            imgui.SameLine()
            if imgui.Button("Verifica acum") then
                checkUpdateOnce()
            end

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            imgui.TextColored(getAccentColor(), T("ui_colors"))
            imgui.Separator()
            imgui.Spacing()

            local function drawColorEdit(label, prefix)
                local col = imgui.ImFloat4(
                    (cfg.settings[prefix .. '_r'] or 255) / 255,
                    (cfg.settings[prefix .. '_g'] or 255) / 255,
                    (cfg.settings[prefix .. '_b'] or 255) / 255,
                    (cfg.settings[prefix .. '_a'] or 255) / 255
                )
                if imgui.ColorEdit4(label, col) then
                    cfg.settings[prefix .. '_r'] = math.floor(col.v[1] * 255)
                    cfg.settings[prefix .. '_g'] = math.floor(col.v[2] * 255)
                    cfg.settings[prefix .. '_b'] = math.floor(col.v[3] * 255)
                    cfg.settings[prefix .. '_a'] = math.floor(col.v[4] * 255)
                    inicfg.save(cfg, "TTC.ini")
                    apply_style()
                end
            end

            local accent = imgui.ImFloat3(
                cfg.settings.menu_color_r / 255,
                cfg.settings.menu_color_g / 255,
                cfg.settings.menu_color_b / 255
            )
            if imgui.ColorEdit3(T("color_settings"), accent) then
                cfg.settings.menu_color_r = math.floor(accent.v[1] * 255)
                cfg.settings.menu_color_g = math.floor(accent.v[2] * 255)
                cfg.settings.menu_color_b = math.floor(accent.v[3] * 255)
                inicfg.save(cfg, "TTC.ini")
                apply_style()
            end

            drawColorEdit(T("window_bg"), "window_bg")
            drawColorEdit(T("child_bg"), "child_bg")
            drawColorEdit(T("frame_bg"), "frame_bg")
            drawColorEdit(T("separator_color"), "separator")
            drawColorEdit(T("header_color"), "header")
            drawColorEdit(T("button_color"), "button")
            drawColorEdit(T("button_hovered_color"), "button_hovered")
            drawColorEdit(T("button_active_color"), "button_active")
            drawColorEdit(T("text_color"), "text")

        end
        
    imgui.EndChild()
    imgui.End()
    
    -- Notifications
    if modEnabled.v ~= lastMod then
        sampAddChatMessage(T("msg_prefix") .. (modEnabled.v and T("mod_active") or T("mod_inactive")), -1)
        lastMod = modEnabled.v
    end
    if repairEnabled.v ~= lastRepair then
        sampAddChatMessage(T("msg_prefix") .. (repairEnabled.v and T("ar_active") or T("ar_inactive")), -1)
        lastRepair = repairEnabled.v
    end
    if engineEnabled.v ~= lastEngine then
        sampAddChatMessage(T("msg_prefix") .. (engineEnabled.v and T("ae_active") or T("ae_inactive")), -1)
        lastEngine = engineEnabled.v
    end
    if commandsEnabled.v ~= lastCmds then
        sampAddChatMessage(T("msg_prefix") .. (commandsEnabled.v and T("cmds_active") or T("cmds_inactive")), -1)
        lastCmds = commandsEnabled.v
    end
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
    if not modEnabled.v or not commandsEnabled.v then return end
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
end

function cmdCVR(param)
    if not modEnabled.v or not commandsEnabled.v then
        sampAddChatMessage(T("msg_prefix") .. T("msg_cmd_disabled"), -1)
        return
    end
    sampSendChat("/c ATENTIE, Vehiculele revin in 7 secunde.")
    lua_thread.create(function()
        wait(7000)
        sampSendChat("/cvr")
        sampSendChat("/c Done.")
    end)
end

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
