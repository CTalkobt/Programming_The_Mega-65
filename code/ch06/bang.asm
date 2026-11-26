        * = $1600
igone   = $0308         ; BASIC 65's statement vector
ierror  = $0300         ; BASIC 65's error vector
txtptr  = $3b           ; BASIC's text pointer, 32 bits

install lda igone       ; already installed?
        cmp #<wedge
        bne new
        lda igone+1
        cmp #>wedge
        beq exit        ; yes: keep the vector we saved before
new     lda igone       ; keep the old vector
        sta oldgone
        lda igone+1
        sta oldgone+1
        lda #<wedge     ; and point it at the wedge
        sta igone
        lda #>wedge
        sta igone+1
exit    rts

wedge   ldz #0
        jsr nextch      ; the statement's first character
        cmp #'!'        ; is it one of ours?
        bne old         ; no: let BASIC run it
        jsr nextch      ; the hex digit after the !
        jsr hexval
        bcs syntax
        sta $d020       ; set the border colour
        jsr nextch      ; the statement must end here
        cmp #0
        beq done
        cmp #':'
        bne syntax
done    dez             ; move txtptr to the byte before the end,
        tza             ; so that BASIC's CHRGET finds the end
        clc             ; of the statement and goes on to the next
        adc txtptr
        sta txtptr
        bcc old
        inc txtptr+1
old     jmp (oldgone)

syntax  ldx #11         ; SYNTAX ERROR
        jmp (ierror)

nextch  inz             ; the next character after txtptr+Z,
        lda [txtptr],z  ; skipping spaces
        cmp #' '
        beq nextch
        rts

hexval  sec             ; turn a hex digit in A into 0-15,
        sbc #'0'        ; with the carry clear if it was one
        cmp #10
        bcc ok
        sbc #7          ; skip the 7 characters between 9 and A
        cmp #10
        bcc bad
        cmp #16
        bcs bad
ok      clc
        rts
bad     sec
        rts

oldgone .word 0
