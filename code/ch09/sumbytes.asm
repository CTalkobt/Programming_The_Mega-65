        * = $1600
count   .word 0         ; set by BASIC
result  .byte 0, 0, 0   ; returned to BASIC

        * = $1610
ptr     = $00           ; offset in the private base page
workpg  = $17           ; private base page at $1700

sum     pha             ; save A: low byte of the array address
        lda #workpg
        tab             ; base page = $1700
        pla
        sta ptr         ; store the flat address of the array
        stx ptr+1
        sty ptr+2
        stz ptr+3       ; STZ stores the Z register
        ldz #$00
        lda #$00
        sta result
        sta result+1
        sta result+2

loop    lda count       ; finished when count reaches zero
        ora count+1
        beq done
        clc
        lda [ptr],z     ; next element of the array
        adc result
        sta result
        bcc next
        inc result+1
        bne next
        inc result+2
next    inw ptr         ; advance the pointer
        lda count       ; count = count - 1
        bne nodec
        dec count+1
nodec   dec count
        bra loop

done    lda #$00
        tab             ; restore base page 0 for BASIC
        sec             ; report success
        rts
