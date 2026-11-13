        * = $2001
        .word next      ; BASIC header: 10 BANK0:SYS$2012
        .word 10        ; line number
        .byte $fe, $02  ; BANK
        .text "0:"
        .byte $9e       ; SYS
        .text "$2012"
        .byte 0         ; end of line
next    .word 0         ; end of program

start   ldx #$00        ; $2012
outer   ldz #$00
middle  ldy #$00
inner   inc $d020       ; next border colour
        dey
        bne inner
        dez
        bne middle
        dex
        bne outer
        rts             ; back to BASIC
