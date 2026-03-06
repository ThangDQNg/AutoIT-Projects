;========Set-up========

#RequireAdmin
#include-once
#include "WinApi.au3"
#include <GDIPlus.au3>
#include "WinCaptureEx.au3"

_GDIPlus_Startup()

Local $Title = "Roblox"
Global $Handle = WinGetHandle($Title)
Opt("PixelCoordMode", 2)

ConsoleWrite("SCRIPT: ON" & @CRLF)

;========Hotkeys========

HotKeySet("{F1}", "_TeamBlue")
HotKeySet("{F2}", "_TeamRed")
HotKeySet("{F3}","_Start")
HotKeySet("{F4}","_Pause")
HotKeySet("{F6}", "_Pic")
HotKeySet("{F7}", "_Exit")

;========Variables========

Local $IsStarted = False
Local $IsBlue = False
Global $enemyColor = 0xFFFFFF ;Filler Color
Local $enemyOutline = 0xCB00D5
Global $lastShot = 0

Global $cx = @DesktopWidth / 2
Global $cy = @DesktopHeight / 2

Global $scanSize = 4

Global $left = $cx - $scanSize
Global $top = $cy - $scanSize
Global $right = $cx + $scanSize
Global $bottom = $cy + $scanSize

;========Functions========

Func _PixelSearch($left,$top,$right,$bottom,$color,$tolerance)
    Local $pos = PixelSearch($left,$top,$right,$bottom,$color,$tolerance,0,$Handle)

    If @error Then
        Return False
    EndIf
    Return $pos
EndFunc

Func _Click($X, $Y, $wPos) ; Click function
	MouseMove($wPos[0] + $X,$wPos[1] + $Y + 30)
EndFunc

Func _setupwindow($Handle)
	Local $width = 816
	Local $heigh = 638
	WinActivate($Handle)
	Winmove($Handle, "", 0, 0, @DesktopWidth, @DesktopHeight)
EndFunc

Func _TeamBlue()
    $enemyColor = 0xD72C36
    ConsoleWrite("You are Blue - enemy Red" & @CRLF)
EndFunc

Func _TeamRed()
    $enemyColor = 0x36374B
    ConsoleWrite("You are Red - enemy Blue" & @CRLF)
EndFunc

Func _Start()
	If $IsStarted == False Then
		$IsStarted = True
		ConsoleWrite("Started" & @CRLF)
	EndIf
EndFunc

Func _Pause()
	If $IsStarted == True Then
		$IsStarted = False
		ConsoleWrite("Stopped" & @CRLF)
	EndIf
EndFunc

Func _Exit()
	ConsoleWrite("Exiting" & @CRLF)
	_GDIPlus_Shutdown()
	Exit
EndFunc

Func _Pic()
	Local $BMP = _WindowCaptureEx("test.jpg", $Handle)
	ConsoleWrite("took a pic" & @CRLF)
EndFunc

;========Loop-Logic========

_setupwindow($Handle)

While True
    If $IsStarted Then
		Local $enemy = _PixelSearch($left,$top,$right,$bottom,$enemyColor,20)
        Local $outline = _PixelSearch($left,$top,$right,$bottom,$enemyOutline,10)

        If IsArray($enemy) Or IsArray($outline) Then
			If TimerDiff($lastShot) > 120 Then
				MouseClick("left")
				$lastShot = TimerInit()
				Sleep(120)
			EndIf
        EndIf
    EndIf
    Sleep(15)
WEnd