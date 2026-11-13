        * = $1600
        jmp install     ; SYS $1600 starts the split
                        ; SYS $1603 stops it
remove  sei
        lda oldirq
        sta $0314
        lda oldirq+1
        sta $0315
        cli
        rts

install sei
        lda $0314       ; remember the KERNAL's handler
        sta oldirq
        lda $0315
        sta oldirq+1
        lda #<raster
        sta $0314
        lda #>raster
        sta $0315
        lda #$00
        sta line        ; next interrupt at line 0
        sta $d012
        lda $d011
        and #$7f        ; compare bit 8 = 0
        sta $d011
        cli
        rts

raster  lda $d019
        and #$01
        beq chain       ; not the raster: leave it to the KERNAL
        lda line
        bne lower
        lda #$06        ; line 0: blue border
        sta $d020
        lda #$90
        sta line
        sta $d012       ; next interrupt at line $90
chain   jmp (oldirq)    ; the KERNAL's 50/60 Hz work, once a frame

lower   lda #$02        ; line $90: red border
        sta $d020
        lda #$00
        sta line
        sta $d012       ; next interrupt at line 0
        lda #$01
        sta $d019       ; acknowledge: the KERNAL never sees this one
        pla             ; undo the KERNAL's pushes: B,
        tab
        plz             ; then Z, Y, X and A
        ply
        plx
        pla
        rti

oldirq  .word 0
line    .byte 0
