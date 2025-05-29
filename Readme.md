# Simple Text Editor

This project is a simple text editor implemented in assembly language using MASM32 for Windows. It demonstrates basic file I/O, text manipulation, and user interaction with a graphical window interface.
## Features
- Open, edit, and save text files
- Basic navigation (move cursor, insert, delete)
- Simple graphical user interface (Windows application)
- Help and About buttons for additional user guidance
- Responsive resizing for better usability on different screen sizes
- Open, edit, and save text files
- Basic navigation (move cursor, insert, delete)


## Requirements

- MASM32 SDK
- Windows operating system

## Usage

1. Assemble and link the code using MASM32 tools:
    ```sh
    ml /c /coff TextEditor.asm
    link /SUBSYSTEM:WINDOWS TextEditor.obj
    ```
2. Run the executable in Windows:
    ```sh
    TextEditor.exe
    ```

## File Structure

- `TextEditor.asm` — Main assembly source code

## Notes

- This editor is for educational purposes and demonstrates low-level Windows programming concepts.
- Limited to basic text editing due to assembly constraints.

