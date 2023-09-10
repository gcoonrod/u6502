;  Basic LCD tests for the u6502 SBC rev 0
; (c) 2023 by Greg Coonrod

.feature string_escapes
.feature org_per_seg
.feature c_comments
.pc02
.debuginfo

; VIA1 registers
PORTB   = $6000
PORTA   = $6001
DDRB    = $6002
DDRA    = $6003
T1CL    = $6004
T1CH    = $6005
T1LL    = $6006
T1LH    = $6007
T2CL    = $6008
T2CH    = $6009
SR      = $600A
ACR     = $600B
PCR     = $600C
IFR     = $600D
IER     = $600E
RA      = $600F

LCD_PORT = PORTA
LCD_DDR  = DDRA

.segment "CODE"
.org $8000
.include "lcd.s"

; Initialize the CPU
init:
    sei
    cld
    ldx #$FF
    txs

init_via1:
    lda #%01111111
    sta IER
    lda #$FF
    sta DDRB
    sta DDRA

init_display:
    jsr lcd_init
    lda #%00101000      ; Set 4-bit mode, 2 lines, 5x8 font
    jsr lcd_instruction
    lda #%00001110      ; Display on, cursor on, blink off
    jsr lcd_instruction
    lda #%00000110      ; Increment and shift cursor; don't shift display
    jsr lcd_instruction
    lda #%00000001      ; Clear display
    jsr lcd_instruction

start:
    ldx #0
print_message:
    lda message,x
    beq print_second_message
    jsr lcd_send_char
    inx
    jmp print_message

print_second_message:
    ldx #0
    lcd_set_cursor $40, $00  ; Set cursor to second line
print_second_message_loop:
    lda message,x
    beq halt
    jsr lcd_send_char
    inx
    jmp print_second_message_loop

halt:
    jmp halt       ; Loop forever

; Data
message: .asciiz "Hello, world!"

.segment "VECTORS"
.org $FFFA
    nmi:
        .word $EAEA
    reset:
        .word init
    irq:
        .word $EAEA