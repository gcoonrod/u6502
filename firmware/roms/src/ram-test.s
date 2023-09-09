;  Basic RAM and address tests for the u6502 SBC rev 0
; (c) 2023 by Greg Coonrod

.feature string_escapes
.feature org_per_seg
.feature c_comments
.pc02
.debuginfo

.segment "VECTORS"
.org $FFFA
    nmi:
        .word $EAEA
    reset:
        .word $8000
    irq:
        .word $EAEA
    
.segment "CODE"
.org $8000

    init_stack:
        cld
        sei
        ldx #$FF
        txs

    init_zero_page:
        sta $00,x
        dex
        bne init_zero_page
        jmp main

    ; Test the RAM by writing a pattern to it and reading it back. Do this at the start, middle, 
    ; and end of the RAM. If the RAM is bad, the test will fail and the program will hang.
    ; RAM is located between $0200 and $3FFF.
    main:
        lda #$55
        sta $0200
        lda #$AA
        sta $3FFF
        lda $0200
        cmp #$55
        bne fail
        lda $3FFF
        cmp #$AA
        bne fail

    end:
        nop
        nop
        jmp end

    fail:
        nop
        nop
        nop
        nop
        jmp fail

    
        
