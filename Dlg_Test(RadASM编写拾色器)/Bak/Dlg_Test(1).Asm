.386
.model flat,stdcall
option casemap:none

include Dlg_Test.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov		CommandLine,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	;保存光标的坐标值
	LOCAL @stPoint:POINT
	
	LOCAL @hDcShowPic:HDC
	LOCAL @hDcScreen:HDC
	LOCAL @hDcShowColor:HDC

	LOCAL @dwDx:DWORD
	LOCAL @dwDy:DWORD
		
	LOCAL @colorRect:RECT
	LOCAL @hColorWin:HWND
	LOCAL @dwColor:DWORD
	
	LOCAL @hBrush:HBRUSH
	LOCAL @hBrushOld:HBRUSH
	
	LOCAL @colorRed:byte
	LOCAL @colorGreen:byte
	LOCAL @colorBlue:byte
	
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		;保存对话框的窗口句柄
		push	hWin
		pop		hWnd
		;设置主窗口的图标
		invoke LoadIcon,hInstance,IDI_WIN_MAIN
		invoke SendMessage,hWnd,WM_SETICON,ICON_BIG,eax
		;使得窗口总在最前显示
		invoke SetWindowPos,hWnd,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE or SWP_NOSIZE
		
		;设置定时器
		invoke SetTimer,hWnd,NULL,100,NULL
		
	.elseif eax	== WM_TIMER
		;响应定时器的消息
		;获取当前光标的坐标值
		invoke GetCursorPos,addr @stPoint
		;将x，y的坐标显示到对话框
		invoke SetDlgItemInt,hWnd,IDC_EDT_POS_X,@stPoint.x,FALSE
		invoke SetDlgItemInt,hWnd,IDC_EDT_POS_Y,@stPoint.y,FALSE
		
		;向XY坐标靠前一点
		mov eax,@stPoint.x
		sub eax,12
		mov @dwDx,eax
		mov eax,@stPoint.y
		sub eax,12
		mov @dwDy,eax
		
		;获取整个屏幕的DC
		invoke GetDC,NULL
		mov @hDcScreen,eax
		
		;获取显示屏幕制定区域的窗口DC
		invoke GetDlgItem,hWnd,IDC_IMG_SHOWPIC ;获取图片框控件的句柄
		invoke GetDC,eax
		mov @hDcShowPic,eax
		
		;将屏幕指定区域绘制到指定的窗口DC中
		invoke StretchBlt,@hDcShowPic,0,0,160,160,@hDcScreen,@dwDx,@dwDy,24,24,SRCCOPY
		
		;向图片屏幕指定区域绘制到指定的窗口DC中
		;创建一个黑色的实心画笔
		invoke CreatePen,PS_SOLID,1,0	;这里可以设置画笔的类型、宽度、颜色
		mov @hBrush,eax
		invoke MoveToEx,@hDcShowPic,0,80,NULL	;将始点移到点(0,80)
		invoke LineTo,@hDcShowPic,160,80		;画水平线，从点(0,80)画到(160,80)
		invoke MoveToEx,@hDcShowPic,80,0,NULL	;将始点移到点(80,0)
		invoke LineTo,@hDcShowPic,80,160		;;画垂直线，从点(80,0)画到(80,160)
		
		;显示当前鼠标指向的颜色值
		invoke GetDlgItem,hWnd,IDC_IMG_COLOR ;获取控件的句柄
		mov @hColorWin,eax
		invoke GetDC,eax	;由控件的句柄获取这个图片框控件的DC
		mov @hDcShowColor,eax
		
		;构造显示颜色值的图片框的坐标
		mov @colorRect.left,0
		mov @colorRect.top,0
		mov @colorRect.right,118
		mov @colorRect.bottom,22
		
		;获取屏幕上鼠标所指向的点的颜色值
		invoke GetPixel,@hDcScreen,@stPoint.x,@stPoint.y
		mov @dwColor,eax
		
		;为当前获取的颜色值创建一个实心画刷
		invoke CreateSolidBrush,@dwColor
		mov @hBrush,eax
		
		;在显示颜色的图片框中填充画刷指定的颜色值
		;即把在指定的区域用这个画刷(hBrush)在指定的DC(hDcShowColor)上填充颜色
		invoke FillRect,@hDcShowColor,addr @colorRect,@hBrush
		
		;拆解32位的颜色值到三个字节类型的变量中，然后显示
		mov eax,@dwColor
		mov @colorRed,al
		mov @colorGreen,ah
		ror eax,16	;将eax中的值循环右移16位
		mov @colorBlue,al
		invoke SetDlgItemInt,hWnd,IDC_EDIT_RED,@colorRed,FALSE
		invoke SetDlgItemInt,hWnd,IDC_EDIT_GREEN,@colorGreen,FALSE
		invoke SetDlgItemInt,hWnd,IDC_EDIT_BLUE,@colorBlue,FALSE
		
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		and		eax,0FFFFh
		.if eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_HELP_ABOUT
			invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
		.endif
;	.elseif eax==WM_SIZE
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

end start
