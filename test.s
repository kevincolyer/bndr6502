        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"


; oscPutC=0
; oscGetC=2
; oscPutZ=4
; oscPutCrLf=6
; oscClearOutBuf=8
; oscPutZOutBuf=10
; oscPushByteToOutBuf=12
; oscCmpStringWithOutBuf=14
; oscMonitorReturn=16
; oscPutHexByte=18
; oscPutZArg0=20
; oscCleanInputBuf=22             ;
; oscLineEditInput=24             ;
; oscWord2DecimalString=26
; oscZStrCopy=28



        .org    userStart
        lda     #$de
        macro_oscall oscPutHexByte

        lda     #$ad
        macro_oscall oscPutHexByte

        lda     #' '
        macro_oscall oscPutC

        lda     #<.message
        sta     osCallArg0
        lda     #>.message
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

        lda     #<.message2
        sta     osCallArg0
        lda     #>.message2
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

.getkeyloop:
        macro_oscall oscGetC
        bcc     .getkeyloop
        cmp     #'q'
        beq     .end
        macro_oscall oscPutHexByte
        bra     .getkeyloop

.end:
        macro_oscall oscPutCrLf


; test line input buffer
        lda     #<.message4
        sta     osCallArg0
        lda     #>.message4
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

        stz     osCallArg0      ; set input buffer max length
        macro_oscall oscLineEditInput
        ; echo back message
        lda     #<.message5
        sta     osCallArg0
        lda     #>.message5
        sta     osCallArg0+1
        macro_oscall oscPutZArg0
        ;echo back input buffer
        lda     #<osInputBuffer
        sta     osCallArg0
        lda     #>osInputBuffer
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

        lda     #"'"
        macro_oscall oscPutC

        macro_oscall oscPutCrLf
;  test printing 16bit decimal.
        lda     #$ff
        sta     osCallArg1
        lda     #$ff
        sta     osCallArg1+1    ; number to convert
        ; buffer to store it
        macro_store_symbol2word .scratchbuff,osCallArg0
        lda     #'.'
        sta     osCallArg2      ; no padding
        ; call!
        macro_oscall oscWord2DecimalString

        ; print it!
        lda     #"["
        macro_oscall oscPutC

        macro_oscall oscPutZArg0

        lda     #"]"
        macro_oscall oscPutC
        macro_oscall oscPutCrLf

        bra     .next

        .byte   "["
.scratchbuff
        .byte   0,0,0,0,0,0,0,0,0,0
        .byte   "]"


;farewell message
.next:
        lda     #<.message3
        sta     osCallArg0
        lda     #>.message3
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

        ldx     #oscMonitorReturn
        jmp     osCall
.message:
        .byte   "Kevin rocks",CR,LF,0
.message2:
        .byte   "Press keys - q ends",CR,LF,0
.message3:
        .byte   "Bye!",CR,LF,0

.message4:
        .byte   "Please type a line and press return",CR,LF,0
.message5:
        .byte   "You wrote: '",0
