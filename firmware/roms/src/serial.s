; ACIA Include File

ACIA_DATA   = $4400
ACIA_STATUS = $4401
ACIA_CMD    = $4402
ACIA_CTRL   = $4403

.segment "CODE"

init_acia:
    pha
    stz ACIA_STATUS ; clear status register
    lda #%00011110  ; 8-N-1, 9600 baud
    sta ACIA_CTRL   ; set control register
    lda #%00001011  ; No parity or rcv echo, RTS true, receive IRQ but no
    sta ACIA_CMD    ; set command register
    pla
    rts

acia_send_char:
    pha
    sta ACIA_DATA
    lda #$FF
@tx_delay:
    dec
    bne @tx_delay
    pla
    rts
    