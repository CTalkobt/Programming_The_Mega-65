        * = $2001
        .word next      ; BASIC header: 10 BANK0:SYS$2012
        .word 10
        .byte $fe, $02  ; BANK
        .text "0:"
        .byte $9e       ; SYS
        .text "$2012"
        .byte 0
next    .word 0

load    ldy #>fname     ; page of the file name
        lda #$2e        ; hyppo_setname
        sta $d640
        clv
        bcc error

        ldx #$00        ; load address $0040000
        ldy #$00
        ldz #$04
        lda #$36        ; hyppo_loadfile
        sta $d640
        clv
        bcc error
        lda #$05        ; green border: the file is in bank 4
        bra done

error   sta errcode     ; A holds the error code, e.g. $88 file not found
        lda #$02        ; red border: it is not
done    sta $d020
        ldz #$00        ; BASIC and the KERNAL expect Z = 0
        rts

errcode .byte 0

        .enc "ascii"    ; store the name as ASCII, not PETSCII
        .cdef " ~", 32
        .align 256      ; the name must start a page
fname   .text "LEVEL1.BIN", 0
