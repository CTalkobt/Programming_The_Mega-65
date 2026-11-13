        * = $1600
workpg  = $17           ; private base page at $1700
desc    = $00           ; flat pointer to the descriptor
text    = $04           ; flat pointer to the characters
length  = $08

spaces  pha             ; save A: low byte of the descriptor address
        lda #workpg
        tab
        pla
        sta desc
        stx desc+1
        sty desc+2
        stz desc+3
        ldz #$00
        lda [desc],z    ; descriptor byte 0: the length
        sta length
        inz
        lda [desc],z    ; byte 1: low byte of the text address
        sta text
        inz
        lda [desc],z    ; byte 2: high byte
        sta text+1
        lda #$01        ; the text is in bank 1
        sta text+2
        lda #$00
        sta text+3

        tax             ; X counts the spaces
        taz             ; Z indexes the characters
loop    cpz length
        beq done
        lda [text],z
        cmp #$20
        bne next
        inx
next    inz
        bne loop

done    lda #$00
        tab             ; restore base page 0 for BASIC
        taz
        txa             ; return the count in A
        rts
