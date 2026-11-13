        * = $1600
buffer  = $1700         ; the 256 bytes to save and load
bufend  = $1800         ; one past the last byte

        jmp save        ; SYS $1600 saves the buffer
                        ; SYS $1603 loads it back
load    jsr setup
        lda #$00        ; 0 = load, 1 = verify
        ldx #<buffer    ; load address, used because the
        ldy #>buffer    ; secondary address is 0
        jsr $ffd5       ; LOAD
        rts             ; C = 1: error code in A

save    jsr setup
        ldx $fb         ; borrow two base page bytes for
        phx             ; the pointer SAVE wants
        ldx $fc
        phx
        lda #<buffer
        sta $fb
        lda #>buffer
        sta $fc
        lda #$fb        ; A = where the start address is
        ldx #<bufend    ; X/Y = end address + 1
        ldy #>bufend
        jsr $ffd8       ; SAVE
        plx             ; put the two bytes back; PLX and
        stx $fc         ; STX leave A and the carry alone
        plx
        stx $fb
        rts             ; C = 1: error code in A

setup   lda #$00        ; data in bank 0
        tax             ; file name in bank 0
        jsr $ff6b       ; SETBNK
        lda #$00        ; logical file: not used by LOAD and SAVE
        ldx #$08        ; device 8
        ldy #$00        ; secondary address 0
        jsr $ffba       ; SETLFS
        lda #nameend-name
        ldx #<name
        ldy #>name
        jmp $ffbd       ; SETNAM

        .enc "ascii"    ; store capitals as $41-$5A, the
        .cdef " ~", 32  ; codes the keyboard gives
name    .text "BLOCK"
nameend
