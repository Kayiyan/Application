include C:\masm32\include\masm32rt.inc

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data
    className db "Win32ASMWindowClass",0
    appName db "Win32 ASM",0

.data?
    hInstance HINSTANCE ?
    cmdLine LPSTR ?

.code
start:
    invoke GetModuleHandle, NULL
    mov hInstance,eax
    invoke GetCommandLine
    mov cmdLine,eax
    invoke WinMain, hInstance, NULL, cmdLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hWnd:HWND

    mov wc.cbSize,SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra,NULL
    mov wc.cbWndExtra,NULL
    push hInst
    pop wc.hInstance
    mov wc.hbrBackground,COLOR_WINDOW+1
    mov wc.lpszMenuName,NULL
    mov wc.lpszClassName,OFFSET className
    invoke LoadIcon,NULL,IDI_APPLICATION
    mov wc.hIcon,eax
    mov wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,eax
    invoke RegisterClassEx, addr wc
    invoke CreateWindowEx, NULL, ADDR className, ADDR appName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 500, 300, NULL, NULL, hInst, NULL
    mov hWnd,eax
    invoke ShowWindow, hWnd, CmdShow
    invoke UpdateWindow, hWnd

    .WHILE TRUE
        invoke GetMessage, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW

    mov eax,msg.wParam
    ret

WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL
    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor eax,eax
    ret
WndProc endp

end start
