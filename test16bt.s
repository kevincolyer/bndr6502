        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"
; osCall

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
; oscMonitorReturn                      ;jmp

; macro_store_symbol2word symbol,word

counter=userZp


        .org    userStart       ;+$1000
TestPrint16bit:
        lda     #1
        sta     counter
        stz     counter+1
.loop:
        ; print front half of message
        macro_store_symbol2word .message,osCallArg0
        macro_oscall oscPutZArg0

        ; print number in hex
        lda     counter+1       ; hi byte
        macro_oscall oscPutHexByte
        lda     counter         ; lo byte
        macro_oscall oscPutHexByte

        ; print next part of message
        macro_store_symbol2word .message2,osCallArg0
        macro_oscall oscPutZArg0

        ; print number in decimal
        lda     counter
        sta     osCallArg1
        lda     counter+1
        sta     osCallArg1+1
        macro_store_symbol2word .scratchbuff,osCallArg0
        lda     #"."
        sta     osCallArg2      ; padding
        ;stz osCallArg2 ; no padding
        macro_oscall oscWord2DecimalString
        ; print converted string to terminal
        macro_oscall oscPutZArg0

        ; print end of message and nl
        lda     #']'
        macro_oscall oscPutC
        macro_oscall oscPutCrLf

;         ;await a key press
; .wait:
;         macro_oscall oscGetC
;         bcc .wait

        ; shift counter - end when both zero
        asl     counter
        rol     counter+1
        lda     counter
        ora     counter+1
        bne     .loop

;farewell message
.bye:
        lda     #<.message3
        sta     osCallArg0
        lda     #>.message3
        sta     osCallArg0+1
        macro_oscall oscPutZArg0

        ldx     #oscMonitorReturn
        jmp     osCall


        .byte   "|"
.scratchbuff
        .byte   0,0,0,0,0,0,0,0,0,0
        .byte   "|"
.message:
        .byte   "Hex $",0
.message2:
        .byte   " Decimal [",0
.message3:
        .byte   "Bye!",CR,LF,0
