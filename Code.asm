.386
.model flat, stdcall
option casemap:none

include \masm32\include\comdlg32.inc
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib

.data
    className db "MyWindowClass", 0
    windowTitle db "My First Window", 0
    newFileTitle db "My First Window - New File", 0
    windowTitleFull db 300 dup(?)
    dashTitle db " - ", 0
    editClass db "EDIT", 0
    buttonClass db "BUTTON", 0
    buttonTextSave  db "Save", 0
    buttonTextSaveAs db "Save As", 0
    buttonTextOpen db "Open", 0
    newBtnText db "New", 0
    exitBtnText db "Exit", 0
    statusText db "Ready", 0
    filterText db "Text Files (*.txt)",0,"*.txt",0,"All Files (*.*)",0,"*.*",0,0
    defExt db "txt", 0
    msg db "You have unsaved changes. Exit anyway?", 0
    titleMsg db "Exit Confirmation", 0
    empty db 0
    fileSaved dd 0
    fileChanged dd 0

.data?
    wc WNDCLASS <>
    msgStruct MSG <>
    hEdit HWND ?
    hStatus HWND ?
    bytesWritten DWORD ?
    filePath db 260 dup (?)
    ofn OPENFILENAME <>
    buffer db 2048 dup (?)

.const
    BTN_SAVE equ 1001
    BTN_SAVEAS equ 1002
    BTN_OPEN equ 1003
    BTN_NEW equ 1004
    BTN_EXIT equ 1005

.code

SetWindowTitle proc hWnd:HWND
    .if fileSaved == 0
        invoke SetWindowText, hWnd, offset newFileTitle
    .else
        invoke lstrcpy, offset windowTitleFull, offset windowTitle
        invoke lstrcat, offset windowTitleFull, offset dashTitle
        invoke lstrcat, offset windowTitleFull, offset filePath
        invoke SetWindowText, hWnd, offset windowTitleFull
    .endif
    ret
SetWindowTitle endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg == WM_CTLCOLORSTATIC || uMsg == WM_CTLCOLOREDIT
        invoke SetTextColor, wParam, 0FFFFFFh
        invoke SetBkMode, wParam, TRANSPARENT
        invoke GetStockObject, BLACK_BRUSH
        ret

    .elseif uMsg == WM_DESTROY
        .if fileChanged != 0
            invoke MessageBox, hWnd, offset msg, offset titleMsg, MB_YESNO or MB_ICONWARNING
            cmp eax, IDNO
            je skip_exit
        .endif
        invoke PostQuitMessage, 0
    skip_exit:
        xor eax, eax
        ret

    .elseif uMsg == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh

        .if eax == BTN_OPEN
            invoke RtlZeroMemory, addr ofn, sizeof OPENFILENAME
            invoke GetForegroundWindow
            mov ofn.lStructSize, sizeof OPENFILENAME
            mov ofn.hwndOwner, eax
            mov ofn.lpstrFilter, offset filterText
            mov ofn.lpstrFile, offset filePath
            mov byte ptr [filePath], 0
            mov ofn.nMaxFile, 260
            mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
            mov ofn.lpstrDefExt, offset defExt
            invoke GetOpenFileName, addr ofn
            .if eax != 0
                invoke CreateFile, addr filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                mov ebx, eax
                .if ebx != INVALID_HANDLE_VALUE
                    invoke RtlZeroMemory, addr buffer, 2048
                    invoke ReadFile, ebx, addr buffer, 2047, addr bytesWritten, NULL
                    mov eax, bytesWritten
                    mov byte ptr [buffer + eax], 0
                    invoke SetWindowText, hEdit, addr buffer
                    invoke CloseHandle, ebx
                    mov fileSaved, 1
                    mov fileChanged, 0
                    invoke SetWindowTitle, hWnd
                    invoke SetWindowText, hStatus, offset filePath
                .endif
            .endif

        .elseif eax == BTN_SAVE || eax == BTN_SAVEAS
            .if eax == BTN_SAVE && fileSaved != 0
                invoke GetWindowText, hEdit, addr buffer, 2048
                invoke CreateFile, addr filePath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                mov ebx, eax
                .if ebx != INVALID_HANDLE_VALUE
                    invoke lstrlen, addr buffer
                    mov ecx, eax
                    invoke WriteFile, ebx, addr buffer, ecx, addr bytesWritten, NULL
                    invoke CloseHandle, ebx
                    mov fileChanged, 0
                    invoke SetWindowText, hStatus, offset filePath
                .endif
            .else
                invoke RtlZeroMemory, addr ofn, sizeof OPENFILENAME
                invoke GetForegroundWindow
                mov ofn.lStructSize, sizeof OPENFILENAME
                mov ofn.hwndOwner, eax
                mov ofn.lpstrFilter, offset filterText
                mov ofn.lpstrFile, offset filePath
                mov byte ptr [filePath], 0
                mov ofn.nMaxFile, 260
                mov ofn.Flags, OFN_OVERWRITEPROMPT or OFN_PATHMUSTEXIST
                mov ofn.lpstrDefExt, offset defExt
                invoke GetSaveFileName, addr ofn
                .if eax != 0
                    invoke GetWindowText, hEdit, addr buffer, 2048
                    invoke CreateFile, addr filePath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                    mov ebx, eax
                    .if ebx != INVALID_HANDLE_VALUE
                        invoke lstrlen, addr buffer
                        mov ecx, eax
                        invoke WriteFile, ebx, addr buffer, ecx, addr bytesWritten, NULL
                        invoke CloseHandle, ebx
                        mov fileSaved, 1
                        mov fileChanged, 0
                        invoke SetWindowTitle, hWnd
                        invoke SetWindowText, hStatus, offset filePath
                    .endif
                .endif
            .endif

        .elseif eax == BTN_NEW
            invoke SetWindowText, hEdit, offset empty
            invoke SetWindowText, hStatus, offset statusText
            mov fileSaved, 0
            mov fileChanged, 0
            invoke SetWindowTitle, hWnd

        .elseif eax == BTN_EXIT
            invoke SendMessage, hWnd, WM_CLOSE, 0, 0

        .else
            mov edx, wParam
            shr edx, 16
            movzx edx, dx
            cmp edx, 0300h
            jne skip_text_change
            mov fileChanged, 1
        skip_text_change:
        .endif
    .endif

    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
WndProc endp

start:
    invoke GetModuleHandle, NULL
    mov ebx, eax

    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov wc.hInstance, ebx
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET className

    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax

    invoke RegisterClass, addr wc

    invoke CreateWindowEx, 0, addr className, addr windowTitle, WS_OVERLAPPEDWINDOW,
           CW_USEDEFAULT, CW_USEDEFAULT, 500, 470,
           NULL, NULL, ebx, NULL
    mov esi, eax

    invoke CreateWindowEx, 0, addr editClass, NULL,
        WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL or ES_WANTRETURN or WS_VSCROLL,
        20, 50, 440, 250, esi, NULL, ebx, NULL
    mov hEdit, eax

    invoke CreateWindowEx, 0, addr buttonClass, addr buttonTextSave,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        20, 320, 100, 30, esi, BTN_SAVE, ebx, NULL

    invoke CreateWindowEx, 0, addr buttonClass, addr buttonTextSaveAs,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        140, 320, 100, 30, esi, BTN_SAVEAS, ebx, NULL

    invoke CreateWindowEx, 0, addr buttonClass, addr buttonTextOpen,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        260, 320, 100, 30, esi, BTN_OPEN, ebx, NULL

    invoke CreateWindowEx, 0, addr buttonClass, addr newBtnText,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        380, 320, 80, 30, esi, BTN_NEW, ebx, NULL

    invoke CreateWindowEx, 0, addr buttonClass, addr exitBtnText,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        380, 360, 80, 30, esi, BTN_EXIT, ebx, NULL

    invoke CreateWindowEx, 0, addr buttonClass, offset statusText,
        WS_CHILD or WS_VISIBLE or SS_LEFT,
        20, 410, 460, 20, esi, 0, ebx, NULL
    mov hStatus, eax

    invoke ShowWindow, esi, SW_SHOWNORMAL
    invoke UpdateWindow, esi

message_loop:
    invoke GetMessage, addr msgStruct, NULL, 0, 0
    test eax, eax
    jz end_program
    invoke TranslateMessage, addr msgStruct
    invoke DispatchMessage, addr msgStruct
    jmp message_loop

end_program:
    invoke ExitProcess, 0

end start
