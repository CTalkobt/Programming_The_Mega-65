        * = $1600
buf     = $1700         ; six bytes for the saved map
window  = $4000         ; block 2 of the CPU's 64KB

peek    sei             ; nothing else runs while the window is open
        ldy #>buf
        lda #$74        ; get_mapping: save the map at $1700-$1705
        sta $d640
        clv

        lda #$80        ; megabyte $80 for the lower half
        ldx #$0f
        ldy buf+3       ; upper half exactly as it was, so the
        ldz buf+2       ; KERNAL and I/O stay in place
        map
        lda #$c0        ; lower offset $FC000, block 2 enabled:
        ldx #$4f        ; $4000-$5FFF now shows $8000000-$8001FFF
        map             ; Y and Z still hold the upper half
        eom

        lda window      ; the first byte of attic RAM
        sta value

        ldy #>buf
        lda #$76        ; set_mapping: put the saved map back
        sta $d640
        clv
        ldz #$00
        lda value       ; return the byte in A
        cli
        rts

value   .byte 0
