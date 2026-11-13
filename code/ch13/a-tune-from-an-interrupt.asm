        * = $2001
        .word next          ; BASIC header: 10 BANK0:SYS$2012
        .word 10
        .byte $fe, $02
        .text "0:"
        .byte $9e
        .text "$2012"
        .byte 0
next    .word 0

sid     = $d460             ; SID 4, which PLAY leaves alone
frames  = 12                ; frames for each note

        jmp start           ; $2012: SYS here to start
        jmp stop            ; $2015: SYS here to stop

start   sei
        lda $0314           ; keep the KERNAL's handler
        sta oldirq
        lda $0315
        sta oldirq+1
        lda #<tick
        sta $0314
        lda #>tick
        sta $0315
        lda #$0f
        sta sid+$18         ; volume 15, no filter
        lda #$09
        sta sid+$05         ; attack 0, decay 9
        lda #$00
        sta sid+$06         ; sustain 0, release 0
        sta note
        lda #1
        sta wait            ; first note on the next frame
        cli
        rts

stop    sei
        lda oldirq
        sta $0314
        lda oldirq+1
        sta $0315
        lda #$00
        sta sid+$04         ; silence the voice
        cli
        rts

tick    dec wait            ; called once a frame
        beq play
        lda wait
        cmp #2
        bne chain
        lda #$20
        sta sid+$04         ; gate off two frames early
        bra chain
play    lda #frames
        sta wait
        ldx note
        lda freqlo,x
        sta sid+$00
        lda freqhi,x
        sta sid+$01
        lda #$21
        sta sid+$04         ; sawtooth, gate on
        inx
        cpx #count
        bcc keep
        ldx #0              ; back to the start of the tune
keep    stx note
chain   jmp (oldirq)        ; on to the KERNAL's handler

oldirq  .word 0
wait    .byte 0
note    .byte 0

; C D E G A G E D in octave 4, PAL values
freqlo  .byte <4455, <5001, <5613, <6675, <7493, <6675, <5613, <5001
freqhi  .byte >4455, >5001, >5613, >6675, >7493, >6675, >5613, >5001
count   = freqhi - freqlo
