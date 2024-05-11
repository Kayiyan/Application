.386
.model flat, stdcall
option casemap :none

include                 C:\masm32\include\windows.inc
include                 C:\masm32\include\user32.inc
include                 C:\masm32\include\kernel32.inc
include                 C:\masm32\include\comctl32.inc
include                 C:\masm32\macros\macros.asm

includelib              C:\masm32\lib\user32.lib
includelib              C:\masm32\lib\kernel32.lib
includelib              C:\masm32\lib\comctl32.lib

WndProc                 proto  :DWORD,:DWORD,:DWORD,:DWORD 
List                    proto  :DWORD,:DWORD
ScanFiles  proto  :HWND

.const
IDD_DIALOG              equ 1000
IDC_EDITPATH            equ 1001
IDC_BUTTON              equ 1002
IDC_LISTBOX             equ 1003

.data
szTitle                 db "ScanFiles",0
szIDBQuit               db "Quit",0
MsgBoxCaption           db "Success",0
szFilter                db "*.*",0
dpath                   db 256 dup (?)
IDB_START               db "START", 0
IDB_STOP                db "STOP", 0


.data?
hInstance               HINSTANCE ? 
ThreadID                dd ?
hthread                 dd ?
fpath                   db 256 dup (?)

.code
start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke DialogBoxParam, hInstance, IDD_DIALOG, NULL, addr WndProc, NULL
    invoke ExitProcess, eax

WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg == WM_INITDIALOG
        invoke SetWindowText, hWin, addr szTitle
        invoke SetDlgItemText, hWin, IDC_BUTTON, addr IDB_START
        xor eax, eax
        ret
    .elseif uMsg == WM_COMMAND
        .if wParam == IDC_BUTTON           
            invoke GetDlgItemText, hWin, IDC_EDITPATH, addr dpath, sizeof dpath
            invoke SetDlgItemText, hWin, IDC_BUTTON, addr IDB_START
            invoke SetCurrentDirectory, ADDR dpath
            invoke CreateThread, NULL, NULL, offset ScanFiles, hWin, NULL, ADDR ThreadID
            mov hthread, eax
        .endif
    .elseif uMsg == WM_CLOSE
        invoke EndDialog, hWin, 0
    .endif
    xor eax, eax
    ret
WndProc endp

List proc hWin:HWND, pMsg:DWORD
    invoke SendDlgItemMessage, hWin, IDC_LISTBOX, LB_ADDSTRING, 0, pMsg
    invoke SendDlgItemMessage, hWin, IDC_LISTBOX, WM_VSCROLL, SB_BOTTOM, 0
    ret
List endp

ScanFiles proc hWnd:HWND
    LOCAL fnd      :WIN32_FIND_DATA
    LOCAL hFind    :DWORD
    invoke FindFirstFile, addr szFilter, addr fnd
    .if eax != INVALID_HANDLE_VALUE
        mov hFind, eax
        .repeat
            invoke lstrcat, addr fpath, addr dpath
            invoke lstrcat, addr fpath, chr$("\")
            invoke lstrcat, addr fpath, addr fnd.cFileName
            invoke List, hWnd, addr fpath
            invoke RtlZeroMemory, addr fpath, sizeof fpath
            invoke FindNextFile, hFind, addr fnd
        .until eax == 0
        invoke FindClose, hFind
    .endif
    ret
ScanFiles endp

end start
