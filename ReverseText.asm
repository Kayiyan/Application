    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        HIWORD eax  ; Lấy phần từ cao (notification code)
        cmp ax, EN_CHANGE
        jne process_default  ; Nhảy nếu không phải thông báo EN_CHANGE

        mov eax, wParam
        LOWORD eax  ; Lấy phần từ thấp (control ID)
        cmp ax, ID_EDIT_INPUT
        jne process_default  ; Nhảy nếu không phải từ control chỉnh sửa với ID_EDIT_INPUT

        ; Lấy chuỗi từ hEditInput
        invoke GetWindowText, hEditInput, ADDR buffer, sizeof buffer

        ; Đảo ngược chuỗi
        invoke lstrlen, ADDR buffer
        mov ecx, eax         ; Độ dài chuỗi làm số lần lặp

        lea esi, buffer      ; Nguồn
        lea edi, reversed    ; Đích
        add esi, ecx         ; Di chuyển tới kết thúc chuỗi nguồn
        dec esi              ; Trừ 1 để không bao gồm ký tự kết thúc null

    reverse_loop:
        dec ecx
        js  finish_reverse   ; Nhảy nếu đã xét hết chuỗi
        mov al, [esi]        ; Lấy ký tự từ nguồn
        dec esi
        mov [edi], al        ; Chép ký tự vào đích
        inc edi
        jmp reverse_loop

    finish_reverse:
        mov byte ptr [edi], 0   ; Kết thúc chuỗi với ký tự kết thúc null

        ; Đặt chuỗi đảo ngược vào hEditOutput
        invoke SetWindowText, hEditOutput, ADDR reversed