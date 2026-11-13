        * = $2001
        .word next      ; BASIC header: 10 BANK0:SYS$2012
        .word 10
        .byte $fe, $02  ; BANK
        .text "0:"
        .byte $9e       ; SYS
        .text "$2012"
        .byte 0
next    .word 0

start   sei             ; the takeover skeleton
        lda #$35
        sta $01
        lda #$00
        tax
        tay
        taz
        map
        lda #$47
        sta $d02f
        lda #$53
        sta $d02f
        lda #$00
        sta $d030
        lda #<nmi
        sta $fffa
        lda #>nmi
        sta $fffb
        lda #<irq
        sta $fffe
        lda #>irq
        sta $ffff
        eom
        lda #$00
        tab
        see
        ldx #$ff
        txs
        ldy #$01
        tys
        cld
        lda #$41
        sta $00
        lda #$7f
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda $dd0d

        lda #$00        ; the raster interrupt
        sta line        ; first interrupt at line 0
        sta $d012
        lda $d011
        and #$7f        ; compare bit 8 = 0
        sta $d011
        lda #$01
        sta $d01a       ; enable raster interrupt
        sta $d019       ; clear any pending one
        cli

main    jmp main        ; the main program runs here

irq     pha
        lda line
        bne lower
        lda #$06        ; blue at the top
        sta $d020
        lda #$90
        bra set
lower   lda #$02        ; red from line $90 down
        sta $d020
        lda #$00
set     sta line
        sta $d012       ; next interrupt line
        lda #$01
        sta $d019       ; acknowledge
        pla
        rti

nmi     rti             ; ignore RESTORE

line    .byte 0
