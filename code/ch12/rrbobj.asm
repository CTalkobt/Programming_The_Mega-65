; RRB object update: four 16x16 FCM objects on the screen
; at $50000 built by the BASIC program, 128 bytes per row
        * = $1600
objx    .word 0, 0, 0, 0        ; $1600: X, 0-319 or 1009-1023
objimg  .word 0, 0, 0, 0        ; $1608: first glyph of each image
objy    .byte 0, 0, 0, 0        ; $1610: Y, 0-199
oldrow  .byte $ff, $ff, $ff, $ff ; $1614: row last drawn, $FF = none
slot    .byte 80, 86, 92, 98    ; $1618: slot offset within a row

ptr     = $f0           ; four-byte flat pointer, base page $17
crow    = $f4
count   = $f5
gxlo    = $f6           ; GOTOX screen word
gxhi    = $f7
glo     = $f8           ; glyph of the left strip
ghi     = $f9
blank   = $1001         ; empty glyph, with another before it

        * = $1620
update  lda #$17
        tab             ; private base page at $1700
        ldx #3
uloop   jsr clear       ; take object X off its old rows
        jsr draw        ; and put it on its new ones
        dex
        bpl uloop
        lda #$00
        tab             ; base page 0 again for BASIC
        ldz #$00
        rts

rowptr  sta crow        ; A = character row, X = object
        lsr a
        sta ptr+1       ; row * 128, high byte
        lda #$00
        ror a           ; row * 128, low byte: $00 or $80
        ora slot,x      ; slot offsets are below 128: no carry
        sta ptr
        lda #$05
        sta ptr+2       ; bank 5
        lda #$00
        sta ptr+3
        lda #3
        sta count       ; an object covers three rows
        rts

nextrow lda ptr         ; add 128 to the pointer
        eor #$80
        sta ptr
        bmi samepg      ; bit 7 now set: no carry
        inc ptr+1
samepg  inc crow
        rts

clear   lda oldrow,x
        cmp #$ff
        beq cdone       ; never drawn
        jsr rowptr
cloop   lda crow
        cmp #25
        bcs cdone       ; below the last row
        lda #<blank
        ldz #2
        sta [ptr],z     ; left glyph, low byte
        ldz #4
        sta [ptr],z     ; right glyph, low byte
        lda #>blank
        ldz #3
        sta [ptr],z
        ldz #5
        sta [ptr],z
        jsr nextrow
        dec count
        bne cloop
cdone   rts

draw    lda objy,x
        lsr a
        lsr a
        lsr a           ; character row = Y / 8
        sta oldrow,x
        jsr rowptr
        lda objy,x
        asl a
        asl a
        asl a
        asl a
        asl a           ; Y AND 7 into bits 7-5
        ora #$10        ; bit 4: move the characters down
        sta gxhi
        txa
        asl a
        tay             ; Y register = 2 * object, for word tables
        lda objx+1,y
        and #$03
        ora gxhi        ; X bits 9-8 into bits 1-0
        sta gxhi
        lda objx,y
        sta gxlo
        lda objimg,y
        sta glo
        lda objimg+1,y
        sta ghi
        inw glo         ; skip the blank: left strip, top glyph
dloop   lda crow
        cmp #25
        bcs ddone
        ldz #0
        lda gxlo
        sta [ptr],z     ; GOTOX
        inz
        lda gxhi
        sta [ptr],z
        inz
        lda glo
        sta [ptr],z     ; left strip glyph
        inz
        lda ghi
        sta [ptr],z
        inz
        clc
        lda glo
        adc #3
        sta [ptr],z     ; right strip glyph, three glyphs on
        inz
        lda ghi
        adc #0
        sta [ptr],z
        inw glo         ; next glyph down the strip
        jsr nextrow
        dec count
        bne dloop
ddone   rts
