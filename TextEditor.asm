.386
.model flat, stdcall
option casemap:none

;Include Libraries to import Windows Libraries MASM32

include C:\masm32\include\comdlg32.inc
includelib C:\masm32\lib\comdlg32.lib
include C:\masm32\include\windows.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\comctl32.inc
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\comctl32.lib

.data
    className db "MyWindowClass", 0
    windowTitle db "Simple Text Editor", 0
    editClass db "EDIT", 0
    buttonClass db "BUTTON", 0
    buttonTextSave  db "Save", 0
    buttonTextSaveAs db "Save As", 0
    buttonTextOpen db "Open", 0
    exitButtonText db "Exit", 0
    filterText db "Text Files (*.txt)",0,"*.txt",0,"All Files (*.*)",0,"*.*",0,0
    defExt db "txt", 0
    fileSaved dd 0
    unsavedChanges db 0

    ; Status bar formatting
    
    statusClass db "msctls_statusbar32",0
    statusFormat db "Length: %u | Words: %u",0

    ;Exit prompt Dialogue
    
    msgExitPrompt db "You have unsaved changes. Do you want to Exit anyway?",0
    msgConfirmExit db "Are you sure?",0

; Unique numbers assigned to know which command is triggered WMCommand

.const
    BTN_SAVE equ 1001
    BTN_SAVEAS equ 1002
    BTN_OPEN equ 1003
    BTN_EXIT equ 1004

.data?
    wc WNDCLASS <>
    msg MSG <>
    hEdit HWND ?
    bytesWritten DWORD ?
    filePath db 260 dup (?)      
    ofn OPENFILENAME <>
    buffer db 2048 dup (?)       
    hStatus HWND ?
    hBtnSave HWND ?
    hBtnSaveAs HWND ?
    hBtnOpen HWND ?
    hBtnExit HWND ?
    wndWidth DWORD ?
    wndHeight DWORD ?
    tempw DWORD ?
    temph DWORD ?

.code

; Word count

CountWords proc pBuffer:DWORD
    push ebx
    mov ebx, pBuffer
    mov eax, 0            ; word count
    mov cl, 0             ; in word flag

cw_nextchar:
    mov dl, [ebx]
    cmp dl, 0
    je cw_done
    cmp dl, ' '
    je cw_not_word
    cmp dl, 9
    je cw_not_word
    cmp dl, 10
    je cw_not_word
    cmp dl, 13
    je cw_not_word
    cmp cl, 0
    jne cw_still_word
    inc eax               ; new word found
    mov cl, 1
    jmp cw_still_word

cw_not_word:
    mov cl, 0

cw_still_word:
    inc ebx
    jmp cw_nextchar

cw_done:
    pop ebx
    ret
CountWords endp

; Status bar update

UpdateStatusBar proc
    LOCAL nLen:DWORD
    LOCAL nWords:DWORD
    LOCAL szStatus[64]:BYTE
    invoke GetWindowTextLength, hEdit
    mov nLen, eax
    invoke GetWindowText, hEdit, offset buffer, 2048
    mov eax, offset buffer
    invoke CountWords, eax
    mov nWords, eax
    invoke wsprintf, addr szStatus, offset statusFormat, nLen, nWords
    invoke SendMessage, hStatus, SB_SETTEXTA, 0, addr szStatus
    ret
UpdateStatusBar endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    .if uMsg == WM_CREATE
        ; Create controls: buttons on top, edit below

        invoke CreateWindowEx, 0, offset buttonClass, offset buttonTextOpen,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            10, 10, 100, 32, hWnd, BTN_OPEN, wc.hInstance, NULL
        mov hBtnOpen, eax

        invoke CreateWindowEx, 0, offset buttonClass, offset buttonTextSave,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            120, 10, 100, 32, hWnd, BTN_SAVE, wc.hInstance, NULL
        mov hBtnSave, eax

        invoke CreateWindowEx, 0, offset buttonClass, offset buttonTextSaveAs,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            230, 10, 100, 32, hWnd, BTN_SAVEAS, wc.hInstance, NULL
        mov hBtnSaveAs, eax

        invoke CreateWindowEx, 0, offset buttonClass, offset exitButtonText,
            WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
            340, 10, 100, 32, hWnd, BTN_EXIT, wc.hInstance, NULL
        mov hBtnExit, eax

        ; Edit control (below buttons)
        invoke CreateWindowEx, 0, offset editClass, NULL,
            WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL or ES_WANTRETURN or WS_VSCROLL,
            10, 52, 670, 400, hWnd, NULL, wc.hInstance, NULL
        mov hEdit, eax

        ; Status bar (bottom)
        invoke CreateWindowEx, 0, offset statusClass, NULL,
            WS_CHILD or WS_VISIBLE or SBARS_SIZEGRIP,
            0,0,0,0, hWnd, 0, wc.hInstance, NULL
        mov hStatus, eax
        invoke SendMessage, hStatus, SB_SETTEXTA, 0, offset statusFormat

        invoke UpdateStatusBar

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
        xor eax, eax
        ret

    .elseif uMsg == WM_SIZE
        mov eax, lParam
        and eax, 0FFFFh
        mov wndWidth, eax
        mov eax, lParam
        shr eax, 16
        mov wndHeight, eax

        mov eax, wndHeight
        sub eax, 100    ; 52 for buttons + 48 for status bar
        mov temph, eax

        mov eax, wndWidth
        sub eax, 20
        mov tempw, eax

        invoke MoveWindow, hEdit, 10, 52, tempw, temph, TRUE

        ; Move status bar
        invoke SendMessage, hStatus, WM_SIZE, 0, 0

        jmp _endWndProc

    .elseif uMsg == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh

        .if eax == BTN_OPEN
            invoke RtlZeroMemory, offset ofn, sizeof OPENFILENAME
            invoke GetForegroundWindow
            mov ofn.lStructSize, sizeof OPENFILENAME
            mov ofn.hwndOwner, eax
            mov ofn.hInstance, NULL
            mov ofn.lpstrFilter, offset filterText
            mov ofn.lpstrFile, offset filePath
            mov byte ptr [filePath], 0
            mov ofn.nMaxFile, 260
            mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
            mov ofn.lpstrDefExt, offset defExt

            invoke GetOpenFileName, offset ofn
            .if eax != 0
                invoke CreateFile, offset filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
                mov ebx, eax
                .if ebx != INVALID_HANDLE_VALUE
                    invoke RtlZeroMemory, offset buffer, 2048
                    invoke ReadFile, ebx, offset buffer, 2047, offset bytesWritten, NULL
                    mov eax, bytesWritten
                    mov byte ptr [buffer + eax], 0
                    invoke SetWindowText, hEdit, offset buffer
                    invoke CloseHandle, ebx
                    mov fileSaved, 1
                    mov unsavedChanges, 0
                    invoke UpdateStatusBar
                .endif
            .endif

        .elseif eax == BTN_SAVE || eax == BTN_SAVEAS
            .if eax == BTN_SAVE && fileSaved != 0
                invoke GetWindowText, hEdit, offset buffer, 2048
                invoke CreateFile, offset filePath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                mov ebx, eax
                .if ebx != INVALID_HANDLE_VALUE
                    invoke lstrlen, offset buffer
                    mov ecx, eax
                    invoke WriteFile, ebx, offset buffer, ecx, offset bytesWritten, NULL
                    invoke CloseHandle, ebx
                    mov fileSaved, 1
                    mov unsavedChanges, 0
                    invoke UpdateStatusBar
                .endif
            .else
                invoke RtlZeroMemory, offset ofn, sizeof OPENFILENAME
                invoke GetForegroundWindow
                mov ofn.lStructSize, sizeof OPENFILENAME
                mov ofn.hwndOwner, eax
                mov ofn.hInstance, NULL
                mov ofn.lpstrFilter, offset filterText
                mov ofn.lpstrFile, offset filePath
                mov byte ptr [filePath], 0
                mov ofn.nMaxFile, 260
                mov ofn.Flags, OFN_OVERWRITEPROMPT or OFN_PATHMUSTEXIST
                mov ofn.lpstrDefExt, offset defExt
                invoke GetSaveFileName, offset ofn
                .if eax != 0
                    invoke GetWindowText, hEdit, offset buffer, 2048
                    invoke CreateFile, offset filePath, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
                    mov ebx, eax
                    .if ebx != INVALID_HANDLE_VALUE
                        invoke lstrlen, offset buffer
                        mov ecx, eax
                        invoke WriteFile, ebx, offset buffer, ecx, offset bytesWritten, NULL
                        invoke CloseHandle, ebx
                        mov fileSaved, 1
                        mov unsavedChanges, 0
                        invoke UpdateStatusBar
                    .endif
                .endif
            .endif

        .elseif eax == BTN_EXIT
            cmp unsavedChanges, 0
            je no_prompt_exit
            invoke MessageBox, hWnd, offset msgExitPrompt, offset msgConfirmExit, MB_YESNO or MB_ICONQUESTION
            cmp eax, IDNO
            je _endWndProc
        no_prompt_exit:
            invoke PostQuitMessage, 0
            xor eax, eax
            ret
        .endif

        ; Detect EN_CHANGE
        mov eax, wParam
        shr eax, 16
        cmp eax, EN_CHANGE
        jne _endWndProc
        mov unsavedChanges, 1
        invoke UpdateStatusBar
    .endif

_endWndProc:
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

    invoke RegisterClass, offset wc

    invoke InitCommonControls

    invoke CreateWindowEx, 0, offset className, offset windowTitle, WS_OVERLAPPEDWINDOW,
           CW_USEDEFAULT, CW_USEDEFAULT, 700, 530,
           NULL, NULL, ebx, NULL
    mov esi, eax

    invoke ShowWindow, esi, SW_SHOWNORMAL
    invoke UpdateWindow, esi

    invoke UpdateStatusBar

message_loop:
    invoke GetMessage, offset msg, NULL, 0, 0
    test eax, eax
    jz end_program
    invoke TranslateMessage, offset msg
    invoke DispatchMessage, offset msg
    jmp message_loop

end_program:
    invoke ExitProcess, 0

end start