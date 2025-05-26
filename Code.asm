org 100h              ; COM file starts at offset 100h

mov ah, 09h
mov dx, offset intro_msg
int 21h               ; Display intro message

start_loop:
    mov ah, 01h       ; Function to read character from keyboard
    int 21h
    cmp al, 27        ; ASCII 27 = ESC key
    je exit_editor

    mov ah, 0Eh       ; BIOS teletype output
    int 10h           ; Show character

    jmp start_loop

exit_editor:
    mov ah, 4Ch       ; Terminate program
    int 21h

intro_msg db 'Simple Text Editor - Press ESC to Exit$', 0
