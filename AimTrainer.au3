HotKeySet("{ESC}", "_Quit")

Opt("PixelCoordMode", 1)
Opt("MouseCoordMode", 1)

Local Const $TARGET_COLOR = 0x95C3E8 ; Color of the target (hopefully its a unique color on the screen)
Local $gameOn = True
Local $counter = 0

Func FindPixelColor($color, $variation = 0)
	Local $screenWidth = @DesktopWidth
	Local $screenHeight = @DesktopHeight

	Local $pos = PixelSearch(0,0, $screenWidth - 1, $screenHeight - 1, $color, $variation)

	If @error Then
		If $counter < 3 Then ;Counting the amount of time it couldn't find the target to check if the game has ended.
			$counter = $counter + 1
			ConsoleWrite("Pixel Color Not Found." & @CRLF)
			Return SetError(1,0,0)
		ElseIf $counter > 3 Then ;Counter exceeds 3 which should be an indication for the game ending.
			$gameOn = False
			ConsoleWrite("Game Ended." & @CRLF)
			Exit
		EndIf
	Else
		sleep(10)
		$counter = 0 ;Reset the counter
		ConsoleWrite("Pixel found at X: " & $pos[0] & " Y: " & $pos[1] & @CRLF)
		MouseClick("Left", $pos[0], $pos[1] + 45, 1, 0) ;Click at the target with the offset of Y just because it would be on top of the target so we lower it a bit.
		Return $pos
	EndIf
EndFunc

While True
	If $gameOn Then
		FindPixelColor($TARGET_COLOR)
	EndIf
WEnd

Func _Quit()
	Exit
EndFunc