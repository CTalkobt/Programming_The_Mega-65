        * = $1600
getadr  = $5f9c         ; FAC to integer: A = high byte, Y = low byte
nosflt  = $5c3c         ; integer in A (high) and Y (low) to FAC
                        ; both addresses are for ROM 920413 only

usr     jsr getadr      ; the argument, as a 16-bit integer
        sta high
        sty low
        ldx #$00        ; X counts the bits that are set
        ldy #16
loop    asl low
        rol high
        bcc skip
        inx
skip    dey
        bne loop
        txa
        tay             ; result: low byte in Y,
        lda #$00        ; high byte in A
        jmp nosflt      ; float it and return to BASIC

low     .byte 0
high    .byte 0
