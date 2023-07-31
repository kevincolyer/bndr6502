        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

        .org    userStart
main:
        ; load monitor command to monitor
        macro_store_symbol2word testcmd,osCallArg0
        macro_oscall oscMonitorAddCmd

        macro_store_symbol2word testcmd2,osCallArg0
        macro_oscall oscMonitorAddCmd

        ; back to monitor
        os_monitor_return
        ;-----------------------------------------
testcmd:
        .word   miscfunction_cmd
        .word   miscfunction
        .word   miscfunction_help

miscfunction_cmd:
        .byte   "misc",0
miscfunction_help:
        .byte   "misc-test function",CR,LF,0

miscfunction:
        macro_store_symbol2word testcmd_msg,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

testcmd_msg:
        .byte   "misc function works well",CR,LF,0


;-----------------------------------------

testcmd2:
        .word   csimfunction_cmd
        .word   csimfunction
        .word   csimfunction_help

csimfunction_cmd:
        .byte   "csim",0
csimfunction_help:
        .byte   "csim-test function",CR,LF,0

csimfunction:
        macro_store_symbol2word testcmd2_msg,osCallArg0
        macro_oscall oscPutZArg0
        os_monitor_return

testcmd2_msg:
        .byte   "csim function works well",CR,LF,0
