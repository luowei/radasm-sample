;--------------------------------------------------------------------------------
;程序作者：维唯为为
;开发日期：
;文件描述：我的应用程序模板
;注意事项：此份代码使用586指令集
;更新历史：
;--------------------------------------------------------------------------------

.586
.model flat,stdcall
option casemap:none

   include windows.inc
   include user32.inc
   include kernel32.inc
   include comdlg32.inc
   include gdi32.inc
   
   includelib user32.lib
   includelib kernel32.lib
   includelib comdlg32.lib
   includelib gdi32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD


.data
   ClassName	db "MainWinClass",0 ;窗口类名
   AppName	db "My Win32ASM Application",0 ;应用程序标题名
   editClass 	db	 "edit",0
   aboutApp 	db	 "小记事本，维唯为为，汇编语言编写",0
   ;exitStr		db	 "是否要退出程序？",0
   ;remind 	db 	"提示",0
   
   ;调用公共对话框所要的信息
   szFilter 	db "Text File(*.txt)",0,"*.txt",0,"All File(*.*)",0,"*.*",0,0
   szDefExt 	db "txt",0
   
   strFileBuf 	db 8192	dup(?)	
   ;有待改善，可通过获取要打开的文件的大小属性动态的分配内存空间
   ;用GlobalAlloc函数动态分配，GetFileSize获取文件大小后，再用GlobalReAlloc重新分配缓冲区内存

.data?
   hInstance HINSTANCE ? 			;应用程序的句柄
   CommandLine LPSTR ? 			;程序的命令行参数字符串
   hEdit 		HWND ?				;文本编辑框的窗口句柄
   strFile 		db MAX_PATH dup (?) 	;保存公共对话框中获取的文件名
   lpEditProc	HWND ?
  


.const
	APP_ICON 					equ 1200 ;应用程序的图标
	;Res\MainMenu.mnu
	IDR_MENU					equ 10000
	IDM_FILE						equ 10001
	IDM_FILE_OPEN					equ 10002
	IDM_FILE_SAVE					equ 10003
	IDM_LINE1					equ 10004
	IDM_FILE_EXIT					equ 10005
	IDM_EDIT					equ 10006
	IDM_EDIT_UNDO					equ 10007
	IDM_EDIT_REDO					equ 10008
	IDM_LINE2					equ 10009
	IDM_EDIT_CUT					equ 10010
	IDM_EDIT_COPY					equ 10011
	IDM_EDIT_PASTE					equ 10012
	IDM_HELP					equ 10013
	IDM_HELP_ABOUT					equ 10014


.code
; ---------------------------------------------------------------------------

;程序入口点
start:
	;为程序生成一个实例句柄
	invoke GetModuleHandle, NULL
	mov    hInstance,eax
	
	;为程序获取一个命令行参数
	invoke GetCommandLine
	mov    CommandLine,eax
	
	;调用windows的主函数
	invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess,eax
	

_ShowLineNum proc hwndEdit:HWND
;功能：显示文本的总行数
;参数：
;	hEdit:要显示行号的文本框，这里用RichEdit测试
;返回值：没有
	
	LOCAL	@stClientRect:RECT	;RichEdit的客户区大小
	LOCAL	@hDcEdit		;RichEdit的DC（设备环境）
	LOCAL	@Char_Height		;文本总行数
	LOCAL	@Line_Count		;字符高度
	LOCAL	@ClientHeight		;RichEdit的客户区高度
	LOCAL	@hdcBmp		;与RichEdit兼容的位图dc
	LOCAL	@hdcCpb			;与RichEdit兼容的Dc
	LOCAL	@CharFmt:CHARFORMAT	;RichEdit中的一个结构，用于获取字符的一系列信息
	LOCAL	@stBuf[10]:byte		;显示行号的缓冲区
	
	LOCAL	@szTest[64]:byte		;Test
	
	LOCAL	tm:TEXTMETRIC
	
	pushad		;保存一下所有的寄存器
	
	;获取RichEdit的Dc
	invoke GetDC,hEdit
	mov @hDcEdit,eax
	;获取RichEdit的客户区高度
	invoke GetClientRect,hEdit,addr @stClientRect
	mov ebx, @stClientRect.bottom
	sub ebx, @stClientRect.top
	mov @ClientHeight, ebx
	;创建与RichEdit兼容的Dc
	invoke CreateCompatibleDC,@hDcEdit
	mov @hdcCpb, eax
	;创建与RichEdit兼容的位图Dc,
	invoke	CreateCompatibleBitmap,@hDcEdit,40,@ClientHeight
	mov @hdcBmp,eax
	;将位图dc选入RichEdit环境中
	invoke SelectObject,@hdcCpb,@hdcBmp
	;创建一个实心画刷，用于下面的FillRect函数。
	invoke	CreateSolidBrush,000080ffh	;设置画刷的颜色
	;填充显示行号的dc的背景颜色。
	invoke	FillRect, @hdcCpb,addr @stClientRect,eax
	invoke	SetBkMode, @hdcCpb,TRANSPARENT
	;获取当前RichEdit文本中的总行数
	invoke	SendMessage, hEdit,EM_GETLINECOUNT,0,0
	mov	@Line_Count, eax
	
	;获取字符高度
	invoke	RtlZeroMemory, addr tm,sizeof tm
	invoke	GetTextMetrics, @hDcEdit,addr tm
	push	tm.tmHeight
	pop	@Char_Height
	
.data
	charFmt	byte	"%4u",0
.code
	invoke	RtlZeroMemory,addr  @stBuf,sizeof @stBuf
	;设置显示行号的前景色
	invoke	SetTextColor,@hdcCpb,0000000h
	mov ebx, @Char_Height
	mov @Char_Height,1
	
	;获取文本框中第一个可见的行号，没有这个行号显示不会跟着文本的滚动而滚动
	invoke	SendMessage,hEdit,EM_GETFIRSTVISIBLELINE,0,0
	mov edi, eax
	inc    edi
	;在位图dc中循环输出行号
	.while	edi<=@Line_Count
		invoke wsprintf,addr @stBuf,addr charFmt,edi  
		;int wsprintf,lpout(输出缓冲区),lpFmt(格式字符串),...(需要输出的参数)，返回值是写入的长度
		invoke TextOut,@hdcCpb,1,@Char_Height,addr @stBuf,eax  
		mov edx,@Char_Height
		add edx,ebx
		;add	edx,  4	;这里加上行间距，并不精确。
		mov  @Char_Height, edx
		inc	edi
		.break	.if	edx>@ClientHeight	
	.endw
	;将已“画好”位图真正“贴”到RichEdit中
	invoke BitBlt,@hDcEdit,0,0,40,@ClientHeight,@hdcCpb,0,0,SRCCOPY
	invoke DeleteDC,@hdcCpb
	invoke ReleaseDC,hEdit,@hDcEdit
	invoke DeleteObject,@hdcBmp
	
	popad
	
	ret

_ShowLineNum endp

COMMENT #
;--------------------------------------------------------------------------------
BitBlt
The BitBlt function performs a bit-block transfer of the color data corresponding to a rectangle 
of pixels from the specified source device context into a destination device context. 

BOOL BitBlt(
  HDC hdcDest, // handle to destination device context
  int nXDest,  // x-coordinate of destination rectangle's upper-left 
               // corner
  int nYDest,  // y-coordinate of destination rectangle's upper-left 
               // corner
  int nWidth,  // width of destination rectangle
  int nHeight, // height of destination rectangle
  HDC hdcSrc,  // handle to source device context
  int nXSrc,   // x-coordinate of source rectangle's upper-left 
               // corner
  int nYSrc,   // y-coordinate of source rectangle's upper-left 
               // corner
  DWORD dwRop  // raster operation code
);
;--------------------------------------------------------------------------------

#

_SubProcEdit proc hWnd,uMsg,wParam,lParam
;功能：截获RichEdit的WM_PAINT消息，用于当RichEdit刷新时显示行号。
;参数：
;	hWnd,uMsg,wParam,lParam 都为原有Windows发给RichEdit的消息和参数
;返回值：没有
;说明：当消息处理完毕后必须把消息回送给默认的RichEdit的窗口过程
;	lpEditProc为RichEdit的旧窗口地址
;--------------------------------------------------------------------------------	
	LOCAL	@stPS:PAINTSTRUCT
	LOCAL	@stEditRect:RECT
	
	.if uMsg==WM_PAINT
		invoke CallWindowProc,lpEditProc,hWnd,uMsg,wParam,lParam
		invoke BeginPaint,hEdit,addr @stPS
		
		;这个函数实现显示行号
		invoke  _ShowLineNum,hEdit
		
		invoke EndPaint,hEdit,addr @stPS
		ret
	.elseif uMsg==WM_KEYUP || uMsg==WM_KEYDOWN
		invoke GetClientRect,hEdit,addr @stEditRect
		mov @stEditRect.right,45
		invoke InvalidateRect,hEdit,addr @stEditRect,TRUE
	.endif
	
	invoke CallWindowProc,lpEditProc,hWnd,uMsg,wParam,lParam
	ret

_SubProcEdit endp


WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	
	
	;填充windows的窗口结构体
	mov   wc.cbSize,SIZEOF WNDCLASSEX ;表示窗口结构体的总大小
	mov   wc.style, CS_HREDRAW or CS_VREDRAW ;窗口类型
	mov   wc.lpfnWndProc, OFFSET WndProc ;OFFSET表示这个函数的首地址，相当于传指针
	mov   wc.cbClsExtra,NULL ;窗口类的附加数据
	mov   wc.cbWndExtra,NULL ;窗口类的附加数据
	
	push  hInstance ;传递程序的实例句柄给窗口类
	pop   wc.hInstance
	
	mov   wc.hbrBackground,COLOR_BTNFACE+1 ;创建窗口的背景
	mov   wc.lpszMenuName,IDR_MENU	;为此窗口建立一个主菜单
	mov   wc.lpszClassName,OFFSET ClassName ;窗口类的名称
	
	invoke LoadIcon,NULL,APP_ICON	;为此窗口建立一个图标
	mov   wc.hIcon,eax	
	mov   wc.hIconSm,eax
	
	invoke LoadCursor,NULL,IDC_ARROW	;指定窗口上的鼠标指针类型
	mov   wc.hCursor,eax
	
	;向Windows注册一个窗口
	invoke RegisterClassEx, addr wc ;注册窗口类
	;创建一个窗口
	INVOKE CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
           	WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
           	CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,\
           	hInst,NULL
	mov   hwnd,eax ;把窗口句柄赋值给hwnd变量
	
	invoke ShowWindow, hwnd,SW_SHOWNORMAL ;显示窗口
	invoke UpdateWindow, hwnd ;刷新一个窗口
	
	;消息循环
	.WHILE TRUE
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax) ;如果获取的消息的返回值为空
		invoke TranslateMessage, ADDR msg ;转换消息
		invoke DispatchMessage, ADDR msg ;分发消息
	.ENDW
	
	mov     eax,msg.wParam
	ret
WinMain endp


WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	LOCAL	winRect:RECT
	LOCAL	editWidth:DWORD
	LOCAL	editHeight:DWORD
	
	LOCAL 	ofn:OPENFILENAME	;定义一个打开文件的结构体
	LOCAL 	hFile:HANDLE
	LOCAL 	bytesRead:DWORD
	LOCAL 	bytesWrite:DWORD
	LOCAL 	textLen:DWORD
	
	
	.IF uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
		
	.ELSEIF uMsg==WM_CREATE
		;为窗口建立一个图标
		invoke LoadIcon,hInstance,APP_ICON
		invoke SendMessage,hWnd,WM_SETICON,ICON_BIG,eax ;发送设置图标消息
		
		;创建一个文本编辑框
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset editClass,\
		NULL,WS_CHILDWINDOW OR WS_VISIBLE OR WS_VSCROLL OR WS_HSCROLL \
		OR ES_AUTOHSCROLL OR ES_AUTOVSCROLL OR ES_MULTILINE OR WS_MAXIMIZE,\
		0,0,300,300,hWnd,NULL,hInstance,NULL
		mov hEdit,eax
		
		;设置RichEdit的文本编辑区域，留空一部分用于显示行号
		invoke SendMessage,hEdit,EM_SETMARGINS,EC_LEFTMARGIN OR EC_RIGHTMARGIN,00050005h+40
		
		;利用窗口子类技术，
		invoke SetWindowLong,hEdit,GWL_WNDPROC,addr _SubProcEdit
		mov lpEditProc,eax		;保存原来的RichEdit的窗口地址
		
		;invoke SendMessage,hEdit,EM_SETLIMITTEXT,81920,0
		
		;使窗口及窗口控件的大小随窗口的改变而改变
		
	.ELSEIF uMsg==WM_SIZE
		;获取当前窗体的x,y,top,bottom
		;invoke GetWindowRect,hWnd,addr winRect ;获取整个窗口区域大小
		invoke GetClientRect,hWnd,addr winRect ;获取客户区域大小
		
		;计算出当前窗体的宽度和高度
		mov eax,winRect.right
		sub eax,winRect.left
		;sub eax,6
		mov editWidth,eax
		
		mov eax,winRect.bottom
		sub eax,winRect.top
		;sub eax,28
		mov editHeight,eax
		
		;改变文本编辑框的宽度和高度
		invoke MoveWindow,hEdit,0,0,editWidth,editHeight,TRUE
		
	.ELSEIF	uMsg==WM_COMMAND
		mov eax,wParam
		;菜单响应---------------------------------------------------------------
		.if ax==IDM_FILE_OPEN
			;初始化公共对话框结构体
			invoke RtlZeroMemory,addr ofn,sizeof ofn
			invoke RtlZeroMemory,offset strFile,sizeof strFile ;对文件名变量清零
			mov ofn.lStructSize,sizeof ofn
			push hWnd		;ofn.hwndOwner=hWnd赋值操作
			pop ofn.hwndOwner		;两个内存变量不能直接赋值
			mov ofn.lpstrFile, offset strFile
			mov ofn.nMaxFile, MAX_PATH
			mov ofn.lpstrFilter, offset szFilter
			mov ofn.nFilterIndex, 1
			mov ofn.lpstrFileTitle, NULL
			mov ofn.nMaxFileTitle, 0
			mov ofn.lpstrInitialDir, NULL
			mov ofn.Flags, OFN_PATHMUSTEXIST OR OFN_FILEMUSTEXIST
			
			;调用打开文件的公共对话框
			invoke GetOpenFileName, addr ofn
			.if eax==TRUE
				;invoke MessageBox,hWnd,offset strFile,addr AppName,MB_OK OR MB_ICONINFORMATION
				;对这个文件进行处理
				invoke CreateFile,offset strFile,GENERIC_READ,FILE_SHARE_READ OR FILE_SHARE_WRITE,\
				NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
				.if  eax != INVALID_HANDLE_VALUE
					mov hFile ,eax
					;读内容之前要清空缓冲区
					invoke RtlZeroMemory,offset strFileBuf,sizeof strFileBuf
					;读取文件内容到缓冲区strFileBuf中
					invoke ReadFile,hFile,offset strFileBuf,sizeof strFileBuf,addr bytesRead,NULL
					;清空原有的文本内容，然后将strFileBuf中的内容显示到文本框
					invoke SendMessage,hEdit,WM_CLEAR,0,0
					invoke SetWindowText,hEdit,offset strFileBuf
					;关闭当前的文件句柄
					invoke CloseHandle,hFile
				.endif	
			.endif
			
		
			
		.elseif ax==IDM_FILE_SAVE
			;初始化公共对话框结构体
			invoke RtlZeroMemory,addr ofn,sizeof ofn
			invoke RtlZeroMemory,offset strFile,sizeof strFile ;对文件名变量清零
			mov ofn.lStructSize,sizeof ofn
			push hWnd		;ofn.hwndOwner=hWnd赋值操作
			pop ofn.hwndOwner		;两个内存变量不能直接赋值
			mov ofn.lpstrFile, offset strFile
			mov ofn.nMaxFile, MAX_PATH
			mov ofn.lpstrFilter, offset szFilter
			mov ofn.nFilterIndex, 1
			mov ofn.lpstrFileTitle, NULL
			mov ofn.nMaxFileTitle, 0
			mov ofn.lpstrInitialDir, NULL
			mov ofn.lpstrDefExt,offset szDefExt ;添加扩展名
			mov ofn.Flags, OFN_OVERWRITEPROMPT OR OFN_EXPLORER
			
			;调用打开文件的公共对话框
			invoke GetSaveFileName, addr ofn
			.if eax==TRUE
				;invoke MessageBox,hWnd,offset strFile,addr AppName,MB_OK OR MB_ICONINFORMATION
				
				;打开文件
				invoke CreateFile,offset strFile,GENERIC_WRITE,FILE_SHARE_READ,\
				NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
				.if eax != INVALID_HANDLE_VALUE
					mov hFile,eax	;获取文件句柄
					invoke RtlZeroMemory,offset strFileBuf,sizeof strFileBuf	;清空缓冲区
					invoke GetWindowTextLength,hEdit	;获取文本框内容长度
					mov textLen, eax
					invoke GetWindowText,hEdit,offset strFileBuf,sizeof strFileBuf	;将文本框内容传送到缓冲区
					
					;将文本内容写入文件
					invoke WriteFile,hFile,offset strFileBuf,sizeof textLen,addr bytesWrite,NULL
					invoke CloseHandle,hFile	;关闭文件句柄
					
				.endif
			.endif

			
		.elseif ax==IDM_FILE_EXIT
			invoke DestroyWindow,hWnd
			invoke PostQuitMessage,NULL
			
		.elseif ax==IDM_EDIT_UNDO
			invoke SendMessage,hEdit,EM_UNDO,0,0
			
		.elseif ax==IDM_EDIT_REDO
			invoke SendMessage,hEdit,EM_REDO,0,0
			
		.elseif ax==IDM_EDIT_CUT
			invoke SendMessage,hEdit,WM_CUT,0,0
		
		.elseif ax==IDM_EDIT_COPY
			invoke SendMessage,hEdit,WM_COPY,0,0
		
		.elseif ax==IDM_EDIT_PASTE
			invoke SendMessage,hEdit,WM_PASTE,0,0
		
		.elseif ax==IDM_HELP_ABOUT ;这些ID号只用了eax当中的低字节部分
			invoke MessageBox,hWnd,addr aboutApp,addr AppName,MB_OK OR MB_ICONINFORMATION

		.endif
		
	.ELSE
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
	
	xor eax,eax
	ret
WndProc endp


end start
