#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

Menu, Tray, Icon, .\Oxygen.ico

#Include, AHKHID\AHKHID.ahk

#UseHook, On

;Set up the constants
AHKHID_UseConstants()

;Intercept WM_INPUT
OnMessage(0x00FF, "InputMsg")

InputMsg(wParam, lParam) {
    Local r, h, v, p, l, d, b, x, z, s
    Critical

    ; OutputDebug, % Format("w: 0x{:x}, l: 0x{:x}", wParam, lParam)
    ;Get device type
    r := AHKHID_GetInputInfo(lParam, II_DEVTYPE)
    If (r == -1) {
        OutputDebug %ErrorLevel%
    }
    If (r = RIM_TYPEHID) {
        h := AHKHID_GetInputInfo(lParam, II_DEVHANDLE)
        v := AHKHID_GetDevInfo(h, DI_HID_VENDORID, True)
        p := AHKHID_GetDevInfo(h, DI_HID_PRODUCTID, True)
        ; OutputDebug, % Format("h: 0x{:x}, v: {:d}, p: {:d}", h, v, p)
        If (v != 1452 Or p != 597) {
            OutputDebug, % "Ignoring vendor/device combination"
            Return
        }
        l := AHKHID_GetInputData(lParam, d)
        ; OutputDebug, % Format("d: {}, l: {}", Bin2Hex(&d, l), l)
        b := 0xE0
        x := Format("0x{:x}", Bin2Hex(&d, l) - 0x44C)
        SendLevel, 1
        Switch x {
            Case 0x0:
                While, True {
                    If (!(z := KeyStack.Pop()))
                        Break
                    s := Format("{sc{:03x} Up}", b+z)
                    ; OutputDebug, % s
                    SendEvent, % s
                }
            Default:
                KeyStack.Push(x)
                s := Format("{sc{:03x} down}", b+x)
                ; OutputDebug, % s
                SendEvent, % s
        }
    } Else {
        OutputDebug, % Format("r ({}) != RIM_TYPEHID", r)
    }
}

Global KeyStack := []

AHKHID_Register(12, 1, A_ScriptHwnd, RIDEV_INPUTSINK)

;By Laszlo, adapted by TheGood
;http://www.autohotkey.com/forum/viewtopic.php?p=377086#377086
Bin2Hex(addr,len) {
    Static fun, ptr 
    If (fun = "") {
        If A_IsUnicode
            If (A_PtrSize = 8)
                h=4533c94c8bd14585c07e63458bd86690440fb60248ffc2418bc9410fb6c0c0e8043c090fb6c00f97c14180e00f66f7d96683e1076603c8410fb6c06683c1304180f8096641890a418bc90f97c166f7d94983c2046683e1076603c86683c13049ffcb6641894afe75a76645890ac366448909c3
            Else h=558B6C241085ED7E5F568B74240C578B7C24148A078AC8C0E90447BA090000003AD11BD2F7DA66F7DA0FB6C96683E2076603D16683C230668916240FB2093AD01BC9F7D966F7D96683E1070FB6D06603CA6683C13066894E0283C6044D75B433C05F6689065E5DC38B54240833C966890A5DC3
        Else h=558B6C241085ED7E45568B74240C578B7C24148A078AC8C0E9044780F9090F97C2F6DA80E20702D1240F80C2303C090F97C1F6D980E10702C880C1308816884E0183C6024D75CC5FC606005E5DC38B542408C602005DC3
        VarSetCapacity(fun, StrLen(h) // 2)
        Loop % StrLen(h) // 2
            NumPut("0x" . SubStr(h, 2 * A_Index - 1, 2), fun, A_Index - 1, "Char")
        ptr := A_PtrSize ? "Ptr" : "UInt"
        DllCall("VirtualProtect", ptr, &fun, ptr, VarSetCapacity(fun), "UInt", 0x40, "UInt*", 0)
    }
    VarSetCapacity(hex, A_IsUnicode ? 4 * len + 2 : 2 * len + 1)
    DllCall(&fun, ptr, &hex, ptr, addr, "UInt", len, "CDecl")
    VarSetCapacity(hex, -1) ; update StrLen
    Return hex
}

#MaxThreadsPerHotkey, 3
sc0ea & F10::Send {Volume_Mute}
sc0ea & F11::Send {Volume_Down}
sc0ea & F12::Send {Volume_Up}
sc0ea & Left::Send, % (GetKeyState("Shift") ? "+{Home}" : "{Home}")
sc0ea & Right::Send, % (GetKeyState("Shift") ? "+{End}" : "{End}")
sc0ea & Up::Send, % (GetKeyState("Shift") ? "+{PgUp}" : "{PgUp}")
sc0ea & Down::Send, % (GetKeyState("Shift") ? "+{PgDn}" : "{PgDn}")
sc0ea & BackSpace::Send, {Delete}

sc0f2:: ; ea+e8
Drive, Eject
if (A_TimeSinceThisHotkey < 1000)  ; Adjust this time if needed.
    Drive, Eject, , 1
Return