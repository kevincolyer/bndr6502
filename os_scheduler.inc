

k_yield:
        lda     os_yield_countdown
        bne     .nothing_to_do
        lda     #10
        sta     os_yield_countdown; reset os_yield_countdown

        jsr     k_random        ; shuffle rng a bit

.nothing_to_do
        rts
