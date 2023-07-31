counterzp=$20

        *=      $2000
        lda     #1
        ldx     #1
        dec     $20
        dec     counterzp
        dec     counterzp,x
        dec     counter
        dec     counter,x
        jmp     $8000
counter:
        .byte   $ff

