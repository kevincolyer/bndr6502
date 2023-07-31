; test program

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
; oscMonitorReturn      ; JMP!

; macro_store_symbol2word symbol,word

temp            = userZp

        .org    userStart
userstart:
        jsr     tRed

        lda     #"P"
        macro_oscall oscPutC
        jsr     tReset

        macro_store_symbol2word hello,osCallArg0
        macro_oscall oscPutZArg0


;         bra     .end
.loop
        macro_oscall oscGetC
        bcc     .loop           ; loop if nothing
        cmp     #'s'
        beq     .end
        cmp     #'S'
        beq     .end            ; start tests if s or S
        macro_oscall oscPutC
        bra     .loop           ; try again

.end
        jsr     tests           ; run tests

        ; prepare screen for return
        macro_oscall oscPutCrLf
        os_monitor_return       ; back to monitor

hello:
        .byte   "lease press s to start tests"
crlf:
        .byte   CR,LF,0

ansi_reset:
        .byte   ESC,"[0m",0
ansi_red:
        .byte   ESC,"[31;40m",0
ansi_green:
        .byte   ESC,"[32;40m",0

passtext:
        .byte   "PASS",CR,LF,0
failtext:
        .byte   "FAIL",CR,LF,0

tGreen:
        macro_store_symbol2word ansi_green,osCallArg0
        macro_oscall oscPutZArg0
        rts

tRed:
        macro_store_symbol2word ansi_red,osCallArg0
        macro_oscall oscPutZArg0
        rts

tReset:
        macro_store_symbol2word ansi_reset,osCallArg0
        macro_oscall oscPutZArg0
        rts

PASS:
        jsr     tGreen
        macro_store_symbol2word passtext,osCallArg0
        macro_oscall oscPutZArg0

        jmp     tReset

FAIL:
        jsr     tRed
        macro_store_symbol2word failtext,osCallArg0
        macro_oscall oscPutZArg0
        jmp     tReset

Space:
        lda     #SPACE
        macro_oscall oscPutC
        rts
; run tests
tests:
        jsr     testkLowerCase
        jsr     testkUpperCase
;         jsr     testIsHex
;         jsr     testHexPrinting
;         jsr     testosBuffer
        rts


testkLowerCase:
        macro_store_symbol2word testdataU2Lname,osCallArg0
        macro_oscall oscPutZArg0
        ldy     #0
.loop
        lda     testdataU2Lname,y
        beq     .next
        jsr     kLowerCase
        macro_oscall oscPutC
        iny
        bra     .loop
.next
        lda     #'1'
        jsr     kLowerCase
        cmp     #'1'
        bne     .fail
        lda     #'['
        jsr     kLowerCase
        cmp     #'['
        bne     .fail
        lda     #'k'
        jsr     kLowerCase
        cmp     #'k'
        bne     .fail
        lda     #'K'
        jsr     kLowerCase
        cmp     #'k'
        bne     .fail
.end
        jmp     PASS
.fail
        jmp     FAIL

testkUpperCase:
        macro_store_symbol2word testdataL2Uname,osCallArg0
        macro_oscall oscPutZArg0
        ldy     #0
.loop
        lda     testdataL2Uname,y
        beq     .next
        jsr     kUpperCase
        macro_oscall oscPutC
        iny
        bra     .loop
.next
        lda     #'1'
        jsr     kUpperCase
        cmp     #'1'
        bne     .fail
        lda     #'['
        jsr     kUpperCase
        cmp     #'['
        bne     .fail
        lda     #'K'
        jsr     kUpperCase
        cmp     #'K'
        bne     .fail
        lda     #'k'
        jsr     kUpperCase
        cmp     #'K'
        bne     .fail
.end
        jmp     PASS
.fail
        jmp     FAIL


testdataL2Uname:
        .byte   "TO Uppercase ",0
testdataU2Lname:
        .byte   "TO Lowercase ",0
testishexname:
        .byte   "is Hex ",0
testishexdata:
        .byte   "0123456789abcdeF",0
testhexprinting:
        .byte   "Hex Printing 5 56 567 dead beef ",0
testosbuffer:
        .byte   "os output buffer ",0
testosbuffercmpprefix:
        .byte   "prefix",0
testosbuffercmpexact:
        .byte   "pre",0
testosbuffercmpfail:
        .byte   "prx",0
testosbuffercmpfail2:
        .byte   0

; testosBuffer:
;         ldx     #<testosbuffer
;         ldy     #>testosbuffer
;         jsr     PUTZ
;         jsr     CLEAROSOUTPUTBUF
;         lda     #"t"
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         bcs     .fail
;         lda     #"o"
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         lda     #" "
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         bcs     .fail
;         jsr     PUTOSOUTPUTBUF
; ; compare empty buffers
;         lda     #<testosbuffercmpfail2
;         ldx     #>testosbuffercmpfail2
;         jsr     CMPSTRINGWITHOSOUTPUTBUF
;         bcc     .fail
; ; compare pre on buffer
;         lda     #'p'            ; setup buffer
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         lda     #'r'
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         lda     #'e'
;         jsr     PUSHBYTETOOSOUTPUTBUF
;
;         lda     #<testosbuffercmpfail
;         ldx     #>testosbuffercmpfail
;         jsr     CMPSTRINGWITHOSOUTPUTBUF
;         bcs     .fail           ; should NOT match
;         lda     #<testosbuffercmpprefix
;         ldx     #>testosbuffercmpprefix
;         jsr     CMPSTRINGWITHOSOUTPUTBUF
;         bcs     .fail           ; prefix should NOT match
;         lda     #<testosbuffercmpexact
;         ldx     #>testosbuffercmpexact
;         jsr     CMPSTRINGWITHOSOUTPUTBUF
;         bcc     .fail           ; should! match
;         lda     #SPACE
;         jsr     PUSHBYTETOOSOUTPUTBUF
;         jsr     PUTOSOUTPUTBUF
; .end
;         jmp     PASS
; .fail
;         jsr     CLEAROSOUTPUTBUF
;         jmp     FAIL
;
; testIsHex:
;         ldx     #<testishexname
;         ldy     #>testishexname
;         jsr     PUTZ
;         ldx     #0
; .loop
;         lda     testishexdata,x
;         beq     .pass
;         jsr     kIsHex
;         stx     temp
;         cmp     temp
;         bne     .fail
;         inx
;         bra     .loop
; .pass
;         jmp     PASS
; .fail
;         jmp     FAIL
;
; testHexPrinting:
;         ldx     #<testhexprinting
;         ldy     #>testhexprinting
;         jsr     PUTZ
;         lda     #$5
;         jsr     kPrintHexNybble
;         jsr     Space
;         lda     #$56
;         jsr     kPrintHexByte
;         jsr     Space
;         lda     #$05
;         ldx     #$67
;         jsr     kPrintHexWord
;         jsr     Space
;         lda     #$de
;         ldx     #$ad
;         jsr     kPrintHexWord
;         jsr     Space
;         lda     #$be
;         ldx     #$af
;         jsr     kPrintHexWord
;         jsr     Space
;         jsr     PASS
;         rts
;
;
; ------------------------------routines--------------------------------------------------------------

; tests A for ascii char. Makes lower if needed
; Preserves X, Y
kLowerCase:
        cmp     #'A'
        bcc     .done           ; <
        cmp     #'Z'+1
        bcs     .done           ; >=
        ora     #$20            ; make lower
.done
        rts

; tests A for asscii char. Makes higher if needed
; Preserves X, Y
kUpperCase:
        cmp     #"a"
        bcc     .done           ; <
        cmp     #'z'+1
        bcs     .done           ; >=
        sec
        sbc     #$20
.done
        rts

; tests if A is hex. Carry set on success A holds value if success.
; Preserves X, Y
kIsHex:
        phx
        clc
        jsr     kUpperCase      ; make the potential hex digit uppercase
        ldx     #15
.loop
        cmp     hexdigits,x
        beq     .found
        dex
        bpl     .loop
        sec                     ; not found
        rts
.found
        txa
        plx
        rts

hexdigits
        .byte   "0123456789ABCDEF",0

; ; prints a hex byte
; ; preserves X Y
; kPrintHexByte:
;         pha
;         lsr
;         lsr
;         lsr
;         lsr
;         jsr     kPrintHexNybble
;         pla
;         and     #$0f
;         jsr     kPrintHexNybble
;         rts
;
; ; Prints a lower nybble $F
; ; Preserves X, Y
; kPrintHexNybble:
;         phx
;         tax
;         lda     hexdigits,x
;         jsr     PUTC
;         plx
;         rts
;
; ; prints a hex word little endian
; ; A X hold MSB LSB. Preserves Y
; kPrintHexWord:
;         jsr     kPrintHexByte
;         txa
;         jsr     kPrintHexByte
;         rts
;
; kPrintDecByte:
; kPrintDecWord:
