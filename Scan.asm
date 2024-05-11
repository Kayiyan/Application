.386
.model flat, stdcall
option casemap :none

include C:\masm32\include\windows.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\comctl32.inc
include C:\masm32\macros\macros.asm

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\comctl32.lib

IDD_FILE_LIST_DIALOG equ 1001
ID_EDIT_PATH equ 101
ID_BUTTON_START equ 102
ID_LISTVIEW_FILES equ 103
WM_ADDITEM equ WM_USER + 1

.data
isScanning dd 0
hScanThread dd 0
cs CRITICAL_SECTION <>
hInstance dd 0
szButtonStart db "Start", 0
szButtonStop db "Stop", 0
szFilePath db "File Path", 0
szDialogClass db "ScanFilesDlg", 0
szDialogTitle db "File Scanner", 0

.code
start:
    
    invoke InitCommonControlsEx, addr icex
    mov icex.dwICC, ICC_LISTVIEW_CLASSES

    
    invoke RegisterDialogClass
    invoke CreateDialogParam, hInstance, IDD_FILE_LIST_DIALOG, 0, addr DialogProc, 0

    
    .while TRUE
        invoke GetMessage, addr msg, 0, 0, 0
        .break .if !eax
        invoke IsDialogMessage, hwndDialog, addr msg
        .if !eax
            invoke TranslateMessage, addr msg
            invoke DispatchMessage, addr msg
        .endif
    .endw
    invoke ExitProcess, msg.wParam


DialogProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg == WM_COMMAND
        .if lParam == ID_BUTTON_START
            .if !isScanning
                invoke StartScanning, hDlg
            .else
                invoke StopScanning, hDlg
            .endif
        .endif
    .elseif uMsg == WM_ADDITEM
        invoke AddItemToListView, GetDlgItem(hDlg, ID_LISTVIEW_FILES), lParam
        invoke LocalFree, lParam
    .elseif uMsg == WM_INITDIALOG
        invoke InitializeListView, GetDlgItem(hDlg, ID_LISTVIEW_FILES)
        mov eax, TRUE
    .elseif uMsg == WM_DESTROY
        invoke StopScanning, hDlg
        invoke PostQuitMessage, 0
    .elseif uMsg == WM_CLOSE
        invoke DestroyWindow, hDlg
    .else
        mov eax, FALSE
    .endif
    ret
DialogProc endp


InitializeListView proc hwndListView:HWND
    
    lvc LVCOLUMN <>
    mov lvc.mask, LVCF_FMT or LVCF_WIDTH or LVCF_TEXT or LVCF_SUBITEM
    mov lvc.fmt, LVCFMT_LEFT
    mov lvc.iSubItem, 0
    mov lvc.pszText, offset szFilePath
    mov lvc.cx, 200
    invoke ListView_InsertColumn, hwndListView, 0, addr lvc
    ret
InitializeListView endp


StartScanning proc hDlg:HWND
    
    invoke GetDlgItemText, hDlg, ID_EDIT_PATH, addr path, MAX_PATH
    invoke ListView_DeleteAllItems, GetDlgItem(hDlg, ID_LISTVIEW_FILES)

    
    mov isScanning, TRUE
    invoke EnableWindow, GetDlgItem(hDlg, ID_EDIT_PATH), FALSE
    invoke SetDlgItemText, hDlg, ID_BUTTON_START, offset szButtonStop

    
    invoke CreateThread, NULL, 0, addr ScanFiles, hDlg, 0, NULL
    mov hScanThread, eax
    ret
StartScanning endp


StopScanning proc hDlg:HWND
    
    mov isScanning, FALSE
    invoke SetDlgItemText, hDlg, ID_BUTTON_START, offset szButtonStart
    invoke EnableWindow, GetDlgItem(hDlg, ID_EDIT_PATH), TRUE
    
    .if hScanThread
        invoke WaitForSingleObject, hScanThread, INFINITE
        invoke CloseHandle, hScanThread
        mov hScanThread, NULL
    .endif
    ret
StopScanning endp


ScanFiles proc lpParameter:LPVOID
    
    mov hDlg, lpParameter
    invoke GetDlgItemText, hDlg, ID_EDIT_PATH, addr basePath, MAX_PATH
    invoke ScanDirectory, hDlg, addr basePath
    invoke PostMessage, hDlg, WM_COMMAND, MAKEWPARAM(ID_BUTTON_START, BN_CLICKED), 0
    ret
ScanFiles endp

ScanDirectory proc hwnd:HWND, basePath:LPWSTR
    local searchPath[MAX_PATH]:BYTE
    local findData:WIN32_FIND_DATA
    local hFind:HANDLE

    invoke wsprintf, addr searchPath, "%s\\*", basePath
    invoke FindFirstFile, addr searchPath, addr findData
    mov hFind, eax

    .if hFind != INVALID_HANDLE_VALUE
        .repeat
            .if !isScanning
                break
            .endif
            .if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                invoke wcscmp, findData.cFileName, "."
                .if eax != 0
                    invoke wcscmp, findData.cFileName, ".."
                    .if eax != 0
                        invoke wsprintf, addr nextPath, "%s\\%s", basePath, findData.cFileName
                        invoke ScanDirectory, hwnd, addr nextPath
                    .endif
                .endif
            .else
                invoke LocalAlloc, LPTR, MAX_PATH
                mov fullPath, eax
                invoke wsprintf, fullPath, "%s\\%s", basePath, findData.cFileName
                invoke PostMessage, hwnd, WM_ADDITEM, 0, fullPath
            .endif
        .until FindNextFile(hFind, addr findData) == 0
        invoke FindClose, hFind
    .endif
    ret
ScanDirectory endp
