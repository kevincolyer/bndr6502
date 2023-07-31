; macro's for USERLAND

; os return to monitor
        .macro  os_monitor_return
        ldx     #oscMonitorReturn
        jmp     osCall
        .endm

; simple print immediate
        .macro  macro_print,text
        macro_store_symbol2word .lable\@,osCallArg0
        macro_oscall oscPutZArg0
        jmp     .continue\@
.lable\@:
        .string \text
.continue\@:
        .endm

; simple print one char
        .macro  macro_print_c,char
        lda     #\char
        macro_oscall oscPutC
        .endm

; macro_PutZArg0 symbol
        .macro  macro_putzarg0,symbol
        lda     #<\symbol
        sta     osCallArg0
        lda     #>\symbol
        sta     osCallArg0+1
        macro_oscall oscPutZArg0
        .endm



; os call simplifier
        .macro  macro_oscall,call
        phx
        phy
        ldx     #\call
        jsr     osCall
        ply
        plx
        .endm


        .include "os_macro_general.inc"
