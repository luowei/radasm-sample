include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib

WinMain				PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc				PROTO :DWORD,:DWORD,:DWORD,:DWORD

IDD_DIALOG			equ 1000

IDM_MENU			equ 10000
IDM_FILE_EXIT		equ 10001
IDM_HELP_ABOUT		equ 10101

IDI_APP_MAIN		EQU 0
IDI_WIN_MAIN		EQU 100

IDC_IMG_SHOWPIC					equ 1001
IDC_STC_POS_X					equ 1002
IDC_STC_POS_Y					equ 1003
IDC_EDT_POS_X					equ 1004
IDC_EDT_POS_Y					equ 1005
IDC_IMG_COLOR					equ 1006

.const

ClassName			db 'DLGCLASS',0
AppName				db 'Dialog as main',0
AboutMsg			db 'MASM32 RadASM Dialog as main',13,10,'Copyright ?MASM32 2001',0

.data?

hInstance			dd ?
CommandLine			dd ?
hWnd				dd ?
