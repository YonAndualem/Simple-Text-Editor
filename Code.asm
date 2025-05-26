org 100h

mov ah, 09h
mov dx, offset intro_msg
int 21h           ; Display message

start_loop:
    mov ah, 00h
    int 16h       ; Read character from keyboard (no echo)
    cmp al, 27    ; ESC key?
    je exit_editor

    mov ah, 0Eh
    int 10h       ; Manually print character

    jmp start_loop

exit_editor:
    mov ah, 4Ch
    int 21h

intro_msg db 'Simple Text Editor - Press ESC to Exit$', 0
