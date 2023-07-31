; os calls = osc - see osCallVectorTable
osCall=romStart

oscPutC=0                       ; put a char
oscGetC=2                       ; get a char
oscPutZ=4                       ; dont use this needs x and y
oscPutCrLf=6                    ; put CRLF combo
oscClearOutBuf=8                ; clear output buffer
oscPutZOutBuf=10                ; print outbuffer
oscPushByteToOutBuf=12          ; push byte to out buffer
oscCmpStringWithOutBuf=14       ; cmp string with out buffer
oscMonitorReturn=16             ; NOTE always call this as a JMP not a JSR!
oscPutHexByte=18                ; output a hex byte
oscPutZArg0=20                  ; print a zstring in oscCallArg0
oscCleanInputBuf=22             ; clear input buffer
oscLineEditInput=24             ; enter line edit mode (input length wanted in oscCallArg0, input buffer on entry)
oscWord2DecimalString=26        ; convert a word to a decimal - ready to print in oscCallArg0
oscZStrCopy=28                  ; copy a zstring from oscCallArg0 to oscCallArg1
oscMonitorAddCmd=30             ; add cmd table endry in oscCallArg0 to cmd table
oscBinToBcd=32                  ; Byte in Binary <100 to BCD mode. Print with PutHexbyte



;------------------------------------------------------------------
; jmp table
;------------------------------------------------------------------
osJmpTable=romStart+$100

        .include "os_jmp_table.inc"
