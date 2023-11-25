

k_yield:
        lda     os_yield_countdown
        bne     .nothing_to_do
        lda     #10
        sta     os_yield_countdown; reset os_yield_countdown

        lda     yieldVec0+1
        beq     .noyv0

        jsr     _yv0
.noyv0:
        lda     yieldVec1+1
        beq     .noyv1

        jsr     _yv1
.noyv1:
        jsr     k_random        ; shuffle rng a bit

.nothing_to_do
        rts

init_yield:
        stz     yieldVec0+1
        stz     yieldVec1+1
        rts

_yv0:
        jmp yieldVec0
_yv1:
        jmp yieldVec1
