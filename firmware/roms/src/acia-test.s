; Basic Serial tests for the u6502 SBC rev 0
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

; Variables
ASCII_MSB = $0000
ASCII_LSB = $0001

.segment "CODE"
.org $8000
.include "lcd.s"
.include "serial.s"

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

init_serial:
    jsr init_acia

start:
    ldx #0
print_message:
    lda message,x
    beq acia_read_status
    jsr lcd_send_char
    jsr acia_send_char
    inx
    jmp print_message

; TODO Check the ACIA status register and see if it is actually responding to commands
acia_read_status:
    lcd_set_cursor $40, $00
    lda ACIA_STATUS
    jsr convert_byte_to_ascii
    lda ASCII_MSB
    jsr lcd_send_char
    lda ASCII_LSB
    jsr lcd_send_char

acia_send_loop:
    ldx #0
acia_loop:
    lda message,x
    beq acia_send_loop
    jsr acia_send_char
    inx
    jmp acia_loop

halt:
    jmp halt       ; Loop forever

convert_byte_to_ascii:
    ; Convert the byte in A to ASCII and store in zero page
    pha
    lsr
    lsr
    lsr
    lsr     ; A now contains the high nibble
    jsr convert_nibble_to_ascii
    sta ASCII_MSB
    pla
    and #$0F
    jsr convert_nibble_to_ascii
    sta ASCII_LSB
    rts
    
convert_nibble_to_ascii:
    cmp #$0A
    bcc @is_digit
    adc #$07
@is_digit:
    adc #$30
    rts

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