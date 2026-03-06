#include-once
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <WinAPI.au3>


;#---------------------------------------------------
;Nếu $sFileSavePath = '' thì trả về Bitmap
;Nếu set giá trị cho $iLeft, $iTop , $iWidth , $iHeight thì sẽ chụp 1 phần cửa sổ ứng với các thông số này
;$ImagePixelFormat: Xem _GDIPlus_BitmapCloneArea
;$FixBorder: Nếu ảnh capture bị dư thừa 3 sọc đen ở 2 bên cạnh và dưới đáy nghĩa là nó bị dôi ra phần Border thừa, khi này phải bật True fix nó.
;$DelayBeforeCapturing: Thời gian hoãn trước khi thực hiện hành động chụp hWnd. Nếu ảnh chụp bị thiếu control của hWnd thì có lẽ do nó draw chưa kịp -> tăng delay lên thử.
;#---------------------------------------------------
Func _WindowCaptureEx($sFileSavePath = '', $hWnd = 0, $iLeft = 0, $iTop = 0, $iWidth = Default, $iHeight = Default, $DelayBeforeCapturing = 30, $FixBorder = True, $ImagePixelFormat = 0x00021808, $ImageQuality = 100)
	If $hWnd = 0 Then Return SetError(1, 0, 0)

	#Khởi tạo ban đầu
	_GDIPlus_Startup()
	Local Static $hWndManager = ObjCreate("{EE09B103-97E0-11CF-978F-00A02463E06F}")
	Local Static $_WM_PAINT = 0x000F, $PW_RENDERFULLCONTENT = 0x0002
	Local Static $HWND_HIDE = 0, $HWND_SHOWMINIMIZED = 2, $HWND_SHOWNOACTIVATE = 4
	Local $shWnd = String($hWnd), $IsMinimized = False, $IsMinimizeAnimation = False, $IsLayered = True, $DisplayAffinity = 0, $hWndExStyle = 0, $iError
	If $sFileSavePath == 'WindowSettings' Then
		Local $aWindowSettings[4] = [$hWndManager($shWnd & ':$IsMinimizeAnimation'), $hWndManager($shWnd & ':$DisplayAffinity'), $hWndManager($shWnd & ':$hWndExStyle')]
		Return $aWindowSettings
	ElseIf $sFileSavePath = 'DisableRestore' Then
		$hWndManager($shWnd & ':$DisableRestore') = True
		Return 0
	ElseIf $sFileSavePath = 'EnableRestore' Then
		$hWndManager($shWnd & ':$DisableRestore') = False
		Return 0
	EndIf
	
	#Check hWnd đầu vào là control hay window, nếu nó là window thì Parent hay Child gì cũng là nó ;))
	Local $Parent = _WinAPI_GetAncestor($hWnd, $GA_ROOT)
	Local $Child = $hWnd
	
	#Switch tới Parent trước để xử lý các phương pháp kế tiếp chuẩn bị cho việc chụp
	$hWnd = $Parent
	
	#Check cửa sổ có bị bảo vệ khỏi Capture hay không, nếu có thì tắt
	$DisplayAffinity = _WinAPI_GetWindowDisplayAffinity($hWnd)
	If $DisplayAffinity <> 0 Then
		_WinAPI_SetWindowDisplayAffinity($hWnd, 0)
		$hWndManager($shWnd & ':$DisplayAffinity') = $DisplayAffinity
	EndIf
	
	#Check cửa sổ có bị Thu nhỏ hay không, nếu có thì:
	Local $WinState = BitAND(WinGetState($hWnd), BitOR($WIN_STATE_MINIMIZED, $WIN_STATE_VISIBLE))
	If $WinState = (Not $WIN_STATE_VISIBLE) Or $WinState = (Not $WIN_STATE_VISIBLE + $WIN_STATE_MINIMIZED) Or $WinState = ($WIN_STATE_VISIBLE + $WIN_STATE_MINIMIZED) Then
		$IsMinimized = True
		#Check chế độ Hoạt ảnh khi Thu nhỏ cửa sổ có được mở hay không, nếu có thì tắt
		If _WinAPI_DisplayAnimate() = 1 Then
			$IsMinimizeAnimation = True
			$hWndManager($shWnd & ':$IsMinimizeAnimation') = $IsMinimizeAnimation
			_WinAPI_DisplayAnimate(False)
		EndIf
		#Check cửa sổ có ở chế độ Layer hay không, nếu không thì set layer cho nó
		$hWndExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)
		$hWndManager($shWnd & ':$hWndExStyle') = $hWndExStyle
		If BitAND($hWndExStyle, $WS_EX_LAYERED) <> $WS_EX_LAYERED Then
			$IsLayered = False
			_WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitOR($hWndExStyle, $WS_EX_LAYERED))
			If $hWndExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE) Then
				ConsoleWrite(@CRLF & '![Error] _WindowCaptureEx could not change ExStyle of this hWnd. Please add #RequiredAdmin on top of script and retry.' & @CRLF)
			EndIf
		EndIf
		#Set Transparent cho cửa sổ với mức tối thiểu là 1 để hàm Print vẫn có thể in được dù cửa sổ đang trong suốt
		_WinAPI_SetLayeredWindowAttributes($hWnd, 0, 1, $LWA_ALPHA)
		#Hiện cửa sổ ở chế độ Inactive
		_WinAPI_ShowWindow($hWnd, $HWND_SHOWNOACTIVATE)
		Sleep($DelayBeforeCapturing)
	EndIf
	
	#Switch tới Child để chụp
	$hWnd = $Child

	#Chụp lại cửa sổ
	Local $iW = _WinAPI_GetWindowWidth($hWnd)
	Local $iH = _WinAPI_GetWindowHeight($hWnd)
	Local $Border = Abs($iW - _WinAPI_GetClientWidth($hWnd)) / 2 - 1
	If $Border = -1 Then $Border = 0
	Local $hGWDC = _WinAPI_GetWindowDC($hWnd)
	Local $hCCDC = _WinAPI_CreateCompatibleDC($hGWDC)
	Local $hHBitmap = _WinAPI_CreateCompatibleBitmap($hGWDC, $iW, $iH)
	Local $hObject = _WinAPI_SelectObject($hCCDC, $hHBitmap)
	_WinAPI_PrintWindow($hWnd, $hCCDC, $PW_RENDERFULLCONTENT)

	#Switch tới Parent lại để trả về chế độ gốc
	$hWnd = $Parent

	#Trả về các chế độ gốc của cửa sổ và hệ thống
	If Not $hWndManager($shWnd & ':$DisableRestore') Then
		If $IsMinimized = True Then
			Switch $WinState
				Case Not $WIN_STATE_VISIBLE
					_WinAPI_ShowWindow($hWnd, $HWND_HIDE)
				Case $WIN_STATE_MINIMIZED
					_WinAPI_ShowWindow($hWnd, $HWND_HIDE)
					_WinAPI_ShowWindow($hWnd, $HWND_SHOWMINIMIZED)
				Case $WIN_STATE_MINIMIZED + $WIN_STATE_VISIBLE
					_WinAPI_ShowWindow($hWnd, $HWND_SHOWMINIMIZED)
			EndSwitch
			_WinAPI_SetLayeredWindowAttributes($hWnd, 0, 255, $LWA_ALPHA)
			If $IsLayered = False Then
				_WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $hWndExStyle)
			EndIf
			If $IsMinimizeAnimation = True Then
				_WinAPI_DisplayAnimate(True)
			EndIf
		EndIf
		If $DisplayAffinity <> 0 Then _WinAPI_SetWindowDisplayAffinity($hWnd, $DisplayAffinity)
	EndIf
	
	#Giải phóng bộ nhớ
	_WinAPI_DeleteDC($hCCDC)
	_WinAPI_ReleaseDC($hWnd, $hGWDC)

	#Tạo Bitmap từ HBitmap
	Local $hBmpOrigin = _GDIPlus_BitmapCreateFromHBITMAP($hHBitmap), $hBmp
	
	#Nếu ảnh capture bị dư thừa 3 sọc đen ở 2 bên cạnh và dưới đáy nghĩa là nó bị dôi ra phần Border thừa, khi này phải fix nó:
	If $FixBorder = True And $Border > 0 Then
		$iW -= $Border * 2
		$iH -= $Border
		$hBmp = _GDIPlus_BitmapCloneArea($hBmpOrigin, $Border, 0, $iW, $iH, $ImagePixelFormat)
		If Not @error Then
			_GDIPlus_BitmapDispose($hBmpOrigin)
			$hBmpOrigin = $hBmp
		EndIf
	EndIf
	
	#Check lại kích thước thực của cửa sổ và thông số left, top, width, height đã truyền vào:
	If $iWidth = Default Or $iWidth <= 0 Or $iWidth > $iW Then $iWidth = $iW
	If $iHeight = Default Or $iHeight <= 0 Or $iHeight > $iH Then $iHeight = $iH
	If $iLeft >= $iW Then $iLeft = 0
	If $iLeft + $iWidth > $iW Then $iWidth = $iW - $iLeft
	If $iTop >= $iH Then $iTop = 0
	If $iTop + $iHeight > $iH Then $iHeight = $iH - $iTop
	
	#Check xem chụp hết cửa sổ hay chỉ chụp 1 phần
	If $iLeft <> 0 Or $iTop <> 0 Or $iWidth <> $iW Or $iHeight <> $iH Then
		$hBmp = _GDIPlus_BitmapCloneArea($hBmpOrigin, $iLeft, $iTop, $iWidth, $iHeight, $ImagePixelFormat)
		If @error Then ConsoleWrite(@CRLF & '![Error] _WindowCaptureEx could not capture a part of hWnd. Please check $iLeft, $iTop, $iWidth, $iHeight.' & @CRLF)
		_GDIPlus_BitmapDispose($hBmpOrigin)
	Else
		$hBmp = $hBmpOrigin
	EndIf
	
	#Lưu kết quả
	Local $sFileExt = StringRegExp($sFileSavePath, '\.(\w+)$', 1)
	$sFileExt = (@error ? '' : $sFileExt[0])
	If $sFileSavePath = '' Or $sFileExt = '' Then
		Return $hBmp
	Else
		If Not IsNumber($ImageQuality) Then $ImageQuality = 100
		Local $sCLSID = _GDIPlus_EncodersGetCLSID($sFileExt)
		Local $tEncoderParams = _GDIPlus_ParamInit(1)
		Local $tEncoderQuality = DllStructCreate("int Quality")
		DllStructSetData($tEncoderQuality, 'Quality', $ImageQuality)
		_GDIPlus_ParamAdd($tEncoderParams, $GDIP_EPGQUALITY, 1, $GDIP_EPTLONG, DllStructGetPtr($tEncoderQuality, 'Quality'))
		_GDIPlus_ImageSaveToFileEx($hBmp, $sFileSavePath, $sCLSID, $tEncoderParams)
		$iError = @error
		_WinAPI_DeleteObject($hHBitmap)
		_GDIPlus_BitmapDispose($hBmp)
		If $iError Then Return SetError(2)
	EndIf
EndFunc

Func _WindowRestore($hWnd, $Enable)
	If $hWnd = 0 Then Return SetError(1)
	If $Enable Then
		_WindowCaptureEx('EnableRestore', $hWnd)
		Local $aWindowSettings = _WindowCaptureEx('WindowSettings', $hWnd)
		Local $Parent = _WinAPI_GetAncestor($hWnd, $GA_ROOT)
		If Not @error And $Parent <> 0 Then $hWnd = $Parent
		If $aWindowSettings[0] <> 0 Then _WinAPI_DisplayAnimate(True)
		If $aWindowSettings[1] <> 0 Then _WinAPI_SetWindowDisplayAffinity($hWnd, $aWindowSettings[1])
		If $aWindowSettings[2] <> 0 Then _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $aWindowSettings[2])
		_WinAPI_SetLayeredWindowAttributes($hWnd, 0, 255, $LWA_ALPHA)
	Else
		_WindowCaptureEx('DisableRestore', $hWnd)
	EndIf
EndFunc









Func _WinAPI_DisplayAnimate($Enable = True)
	Local Static $__SPI_GETANIMATION = 0x0048, $__SPI_SETANIMATION = 0x0049
	Local $tAnimation = DllStructCreate("uint cbSize;int iMinAnimate")
	$tAnimation.cbSize = DllStructGetSize($tAnimation)
	If @NumParams = 1 Then
		$tAnimation.iMinAnimate = $Enable
		Local $aReturn = DllCall('user32.dll', 'int', 'SystemParametersInfo', 'uint', $__SPI_SETANIMATION, 'int', DllStructGetSize($tAnimation), 'ptr', DllStructGetPtr($tAnimation), 'uint', 0)
		If IsArray($aReturn) Then Return 1
	Else
		Local $aReturn = DllCall('user32.dll', 'int', 'SystemParametersInfo', 'uint', $__SPI_GETANIMATION, 'int', DllStructGetSize($tAnimation), 'ptr', DllStructGetPtr($tAnimation), 'uint', 0)
		If IsArray($aReturn) Then Return $tAnimation.iMinAnimate
	EndIf
	Return 0
EndFunc
