
; LCD Pin Mapping
; LCD:  RS  RW  E   D4  D5  D6  D7
; VIA:  PA4 PA5 PA6 PA0 PA1 PA2 PA3

; LCD Control Pin Masks
LCD_RS = %00010000
LCD_RW = %00100000
LCD_E  = %01000000

; LCD Date Nibble Mask
LCD_DATA = %00001111

; LCD Commands Codes
LCD_SETDDRAMADDR = $80

; LCD DDRAM Offsets
LCD_LINE0 = $00
LCD_LINE1 = $40

; LCD Command Functions

; LCD_Init
; Initializes the LCD for 4-bit mode
; Inputs: None
; Outputs: None
; Clobbers: A
lcd_init:
    lda #%00000010 ; 4-bit mode
    sta LCD_PORT
    ora #LCD_E
    sta LCD_PORT
    and #LCD_DATA
    sta LCD_PORT
    rts

; LCD_Wait
; Waits for the LCD to be ready to receive data
; Inputs: None
; Outputs: None
; Clobbers: None
lcd_wait:
    pha
    lda #%11110000 ; set data pins to input
    sta LCD_DDR
lcd_busy:
    lda #LCD_RW
    sta LCD_PORT
    lda #(LCD_RW | LCD_E)
    sta LCD_PORT
    lda LCD_PORT        ; read high nibble
    pha                 ; and put on stack since it has the busy flag
    lda #LCD_RW
    sta LCD_PORT
    lda #(LCD_RW | LCD_E)
    sta LCD_PORT
    lda LCD_PORT        ; read low nibble
    pla                 ; get high nibble from stack
    and #%00001000      ; mask busy flag
    bne lcd_busy        ; if busy, loop

    lda #LCD_RW         ; otherwise, set RW low and return the data pins to output
    sta LCD_PORT
    lda #%11111111;     ; set data pins to output
    sta LCD_DDR
    pla
    rts

; LCD_Instruction
; Sends an instruction to the LCD
; Inputs: A = Instruction
; Outputs: None
; Clobbers: None
lcd_instruction:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr             ; shift to high nibble
    sta LCD_PORT
    ora #LCD_E          ; set E high and send instruction
    sta LCD_PORT
    eor #LCD_E          ; clear E
    sta LCD_PORT
    pla
    and #LCD_DATA   ; mask low nibble and send
    sta LCD_PORT
    ora #LCD_E
    sta LCD_PORT
    eor #LCD_E
    sta LCD_PORT
    rts

; LCD_Send_Char
; Sends a character to the LCD
; Inputs: A = Character
; Outputs: None
; Clobbers: None
lcd_send_char:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr             ; shift to high nibble
    ora #LCD_RS         ; set RS high and send character
    sta LCD_PORT
    ora #LCD_E
    sta LCD_PORT
    eor #LCD_E          ; clear E
    sta LCD_PORT
    pla
    and #LCD_DATA   ; mask low nibble and send
    ora #LCD_RS
    sta LCD_PORT
    ora #LCD_E
    sta LCD_PORT
    eor #LCD_E
    sta LCD_PORT
    rts
    
; LCD_Set_Cursor
; Sets the cursor position
; Inputs: A = Column + Row Offset
; Outputs: None
; Clobbers: Flags, A
.macro lcd_set_cursor row_offset, col
    pha
    php
    lda #row_offset     ; Load the row offset into A, 
    clc
    adc #col            ; then add the column (TODO: Handle overflow)
    ora #LCD_SETDDRAMADDR
    jsr lcd_instruction
    plp
    pla
.endmacro