include C:\masm32\include\masm32rt.inc

.data
    className db "Win32App",0
    buttonClassName db "BUTTON",0
    editClassName db "EDIT",0
    windowTitle db "Show message",0
    buttonText db "Show",0
    editID dd 1001
    buttonID dd 1002

.data?
    hInstance HINSTANCE ?
    hEdit HWND ?
    hButton HWND ?
    hWndMain HWND ?

DlgProc proto :DWORD,:DWORD,:DWORD,:DWORD

.code
start:
    invoke GetModuleHandle, NULL
    mov    hInstance, eax
    call MainProcedure 

MainProcedure proc hInst:HINSTANCE
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, NULL
    mov wc.cbWndExtra, NULL
    push hInst
    pop wc.hInstance
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET className
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    invoke RegisterClassEx, addr wc
    
    invoke CreateWindowEx, NULL, ADDR className, ADDR windowTitle, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 500, 300, NULL, NULL, hInst, NULL
    mov hWndMain, eax
    invoke ShowWindow, hWndMain, SW_SHOW
    invoke UpdateWindow, hWndMain
    
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW

    mov eax, msg.wParam
    ret
MainProcedure endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL buffer[256]:BYTE
    .IF uMsg==WM_CREATE
        invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR editClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL, 10, 10, 280, 20, hWnd, editID, hInstance, NULL
        mov hEdit, eax
        invoke CreateWindowEx, NULL, ADDR buttonClassName, ADDR buttonText, WS_CHILD or WS_VISIBLE or WS_TABSTOP, 300, 10, 80, 20, hWnd, buttonID, hInstance, NULL
        mov hButton, eax
    .ELSEIF uMsg==WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh ; Ensure we're only dealing with the LOWORD.
        cmp eax, buttonID
        jne SkipCommand
        invoke GetWindowText, hEdit, ADDR buffer, 256
        invoke MessageBox, hWnd, ADDR buffer, ADDR windowTitle, MB_OK
SkipCommand:
    .ELSEIF uMsg==WM_DESTROY
        invoke PostQuitMessage, 0
    .ELSE
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    .ENDIF
    ret
WndProc endp

end start
