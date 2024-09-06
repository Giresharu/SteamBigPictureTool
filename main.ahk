#Requires AutoHotkey v2.0
#Include lib\WinEvent.ahk

bpmState := 0
toolToggle := false
fisrtToolToggle := true
darkTheme := true

;INIREAD
FileEncoding("UTF-8")
ReadINI()

A_TrayMenu.Delete()
A_TrayMenu.Add("编辑配置", (n, p, m) => Run(A_ScriptDir "\config.ini"))
A_TrayMenu.Add("神奇妙妙工具", ToggleTool)
A_TrayMenu.Add("使用暗色图标", ChangeTheme)
A_TrayMenu.Add("刷新配置", (n, p, m) => ReadINI())
A_TrayMenu.Add("退出", (n, p, m) => ExitApp)

;Register WinEvent
WinEvent.Show(OnBPMWinCreated, title)
WinEvent.NotExist(OnBPMWinClose, title)

;Recovery primary display on startup
OnBPMWinClose(0, 0, 0)
Persistent

ReadINI() {
    global title := IniRead("config.ini", "Settings", "BigPictureModeTitle", "Steam 大屏幕模式")
    global PrimaryDisplay := IniRead("config.ini", "Settings", "PrimaryDisplay", MonitorGetName(MonitorGetPrimary()))
    global GameTVDisplay := IniRead("config.ini", "Settings", "GameTVDisplay", "")
    global DefaultSoundDevice := IniRead("config.ini", "Settings", "DefaultSoundDevice", RegExReplace(SoundGetName(), "\s\(.*\)", ""))
    global GameTVSoundDevice := IniRead("config.ini", "Settings", "GameTVSoundDevice", "")
    global darkTheme := IniRead("config.ini", "Settings", "Theme", "Dark") == "Dark" ? true : false
}

ToggleTool(n, p, m) {
    global toolToggle := !toolToggle
    A_TrayMenu.ToggleCheck("神奇妙妙工具")

    if toolToggle {
        MsgBox("神奇妙妙工具已开启。`nF10：将 BigPictureModeTitle 设为当前激活的窗口标题。`nF11：将 PrimaryDisplay 配置为当前主屏。`nF12：将 GameTVDisplay 配置为当前主屏。（为此请在切换主屏到电视后再使用本功能）`n使用完毕后请从系统栏菜单关闭神奇妙妙工具功能。")
        global fisrtToolToggle
        if fisrtToolToggle {
            ;Register Hotkey
            Hotkey("~F10", SetActivedWinTitle)
            Hotkey("~F11", SetPrimaryDisplayName)
            Hotkey("~F12", SetGameTVDisplayName)
        }
        fisrtToolToggle := false
    } else {
        MsgBox("神奇妙妙工具已关闭。")
    }
}

ChangeTheme(n, p, m) {
    global darkTheme := !darkTheme
    A_TrayMenu.ToggleCheck("使用暗色图标")

    TraySetIcon(A_ScriptDir "\icons\" (darkTheme ? "dark" : "light") "\" (bpmState ? "on.ico" : "off.ico"))
}

SetActivedWinTitle(_) {
    global toolToggle
    if !toolToggle
        return

    title := WinGetTitle("A")
    ; A_Clipboard := title
    MsgBox("已将 `"" title "`".`n 写入 BigPictureModeTitle 配置。")
    IniWrite(title, "config.ini", "Settings", "BigPictureModeTitle")
    ReadINI()
}

SetPrimaryDisplayName(_) {
    global toolToggle
    if !toolToggle
        return
    primaryDisplay := MonitorGetName(MonitorGetPrimary())
    ; A_Clipboard := primaryDisplay
    MsgBox("已将 `"" primaryDisplay "`".`n 写入 PrimaryDisplay 配置。")
    IniWrite(primaryDisplay, "config.ini", "Settings", "PrimaryDisplay")
    ReadINI()
}

SetGameTVDisplayName(_) {
    global toolToggle
    if !toolToggle
        return
    primaryDisplay := MonitorGetName(MonitorGetPrimary())
    ; A_Clipboard := primaryDisplay
    MsgBox("已将 `"" primaryDisplay "`".`n 写入 GameTVDisplay 配置。")
    IniWrite(primaryDisplay, "config.ini", "Settings", "GameTVDisplay")
    ReadINI()
}


OnBPMWinCreated(hWnd, eventObj, dwmsEventTime) {
    global bpmState := 1
    if GameTVSoundDevice != "" {
        ; 等待目标显示器开机，再来切换硬件
        while (GameTVDisplay != "" && !CheckDisplayExit(GameTVDisplay)) {
            Sleep(500)
            ; 如果没有找到需要切换的显示器的期间，又关闭了大屏幕模式则直接返回
            if bpmState == 0
                return
        }
        Run("nircmd setdefaultsounddevice " GameTVSoundDevice)
    }
    TraySetIcon(A_ScriptDir "\icons\" (darkTheme ? "dark" : "light") "\" (bpmState ? "on.ico" : "off.ico"))
}

OnBPMWinClose(hWnd, eventObj, dwmsEventTime) {
    global bpmState := 0
    ; 等待目标显示器开机，再来切换硬件
    while (!CheckDisplayExit(PrimaryDisplay)) {
        Sleep(500)
        ; 如果没有找到需要恢复的显示器的期间，又启动了大屏幕模式则直接返回
        if bpmState == 1
            return
    }
    Run("nircmd setprimarydisplay " PrimaryDisplay)
    if DefaultSoundDevice != ""
        Run("nircmd setdefaultsounddevice " DefaultSoundDevice)
    TraySetIcon(A_ScriptDir "\icons\" (darkTheme ? "dark" : "light") "\" (bpmState ? "on.ico" : "off.ico"))
}

CheckDisplayExit(Name) {
    count := MonitorGetCount()
    i := 1
    while (i <= count) {
        if MonitorGetName(i) == Name
            return true
        i++
    }
    return false
}