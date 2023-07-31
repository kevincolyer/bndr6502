; from https://github.com/gfoot/sdcard6502/blob/master/src/test_dumpfile.s
; define  DEBUGSD if needed
        .include "os_memorymap.inc"
        .include "os_constants.inc"
        .include "os_calls.inc"
        .include "os_macro.inc"

buffer=$2000

        .org    userStart       ; expected org

; userZp - origin of user zero page
; userLowMem - origin of user low mem space ~$600 to userStart

main:
        ; load monitor command to monitor
        macro_store_symbol2word sdoldtest,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_ls,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_run,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_cd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_cat,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_pwd,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_test,osCallArg0
        macro_oscall oscMonitorAddCmd
        macro_store_symbol2word sd_init,osCallArg0
        macro_oscall oscMonitorAddCmd

        jsr     dizzybox_init
        bcs     .quit

        macro_print "Dizzybox initialised",CR,LF

.quit:
        os_monitor_return

        ; TODO remove and return k_ functions to os_
        .include "os_file_functions.inc"
        .include "libfat32.inc"
        .include "os_dizzybox.inc"

sdoldtest:
        .word   sdoldtest_cmd_cmd
        .word   sdoldtest_cmd
        .word   sdoldtest_cmd_help

sdoldtest_cmd_cmd:
        .byte   "sdold",0
sdoldtest_cmd_help:
        .byte   "sdold-test sd card read (old)",CR,LF,0

sdoldtest_msg:
        .byte   "sd test ok",CR,LF,0

sd_test:
        .word   sd_test_cmd_cmd
        .word   sd_test_cmd
        .word   sd_test_cmd_help

sd_test_cmd_cmd:
        .byte   "test",0
sd_test_cmd_help:
        .byte   "test-run test suite",CR,LF,0




;---------------------TODO move later

sd_ls:
        .word   sd_ls_cmd_cmd
        .word   sd_ls_cmd
        .word   sd_ls_cmd_help
sd_run:
        .word   sd_run_cmd_cmd
        .word   sd_run_cmd
        .word   sd_run_cmd_help
sd_cd:
        .word   sd_cd_cmd_cmd
        .word   sd_cd_cmd
        .word   sd_cd_cmd_help
sd_cat:
        .word   sd_cat_cmd_cmd
        .word   sd_cat_cmd
        .word   sd_cat_cmd_help
sd_pwd:
        .word   sd_pwd_cmd_cmd
        .word   sd_pwd_cmd
        .word   sd_pwd_cmd_help
sd_init:
        .word   sd_init_cmd_cmd
        .word   sd_init_cmd
        .word   sd_init_cmd_help


sd_ls_cmd_cmd:
        .byte   "ls?",0
sd_ls_cmd_help:
        .byte   "ls-sd card dir list",CR,LF,0

sd_run_cmd_cmd:
        .byte   "run?",0
sd_run_cmd_help:
        .byte   "run-sd load prg file",CR,LF,0

sd_cd_cmd_cmd:
        .byte   "cd?",0
sd_cd_cmd_help:
        .byte   "cd-change directory",CR,LF,0

sd_cat_cmd_cmd:
        .byte   "cat?",0
sd_cat_cmd_help:
        .byte   "cat-print contents of file",CR,LF,0

sd_pwd_cmd_cmd:
        .byte   "pwd",0
sd_pwd_cmd_help:
        .byte   "pwd-print working directory",CR,LF,0

sd_init_cmd_cmd:
        .byte   "init?",0
sd_init_cmd_help:
        .byte   "init-init -(i)2c (s)d card (f)fat32 (d)dizzybox subsystems",CR,LF,0

mysubdirname:
        .asciiz "SUBFOLDR   "
myfilename:
        .asciiz "DEEPFILETXT"



; helper sub
die_with_os_file_error_and_stage:
        macro_print_c 'S'
        macro_print_c '$'
        lda     stage
        macro_oscall oscPutHexByte
die_with_os_file_error:
        jsr     print_os_file_error
        os_monitor_return

print_os_file_error:
        macro_print_c '$'
        lda     os_file_error
        macro_oscall oscPutHexByte
        macro_putzarg0 msg_os_file_error
        rts

sdoldtest_cmd:
        stz     stage

        macro_putzarg0 msg_initialising


        ; Open root directory
        ; stage 1
        inc     stage
        jsr     k_fat32_open_root_dir
        bcc     .open_root_ok
        jmp     die_with_os_file_error_and_stage
.open_root_ok:

        ; Find subdirectory by name
        ; stage 2
        inc     stage
        ldx     #<mysubdirname
        ldy     #>mysubdirname
        jsr     k_fat32_find_open_dir_ent
        bcc     .foundsubdir

        ; Subdirectory not found

        macro_putzarg0 msg_subd_not_found

        jmp     die_with_os_file_error_and_stage

.foundsubdir:
        macro_oscall oscPutCrLf

;       stage 3
        inc     stage
        ; Find file by name
        ldx     #<myfilename
        ldy     #>myfilename
        jsr     k_fat32_find_open_dir_ent
        bcc     .foundfile

        ; File not found
        macro_putzarg0 msg_file_not_found

        jmp     die_with_os_file_error_and_stage

.foundfile:

        ; Read file contents into buffer
        ;stage 4
        inc     stage
        ldx     #<buffer
        ldy     #>buffer
        jsr     k_fat32_load_file
        ;         bcc     .file_read_ok
        ;         jmp
        ; .file_read_ok:

        ; Dump data to console
        macro_store_symbol2word buffer,osCallArg0

.loopprintfile:
        lda     (osCallArg0)
        beq     .endprintfile
        macro_oscall oscPutC

        inc     osCallArg0
        bne     .loopprintfile
        inc     osCallArg0+1
        bra     .loopprintfile

; ----- part 2
.endprintfile:
        macro_oscall oscPutCrLf
        lda     #$20
        sta     stage

        ;------------------------------------------
        ; list a directory

        jsr     k_fat32_open_root_dir
        jsr     dizzybox_ls
        macro_oscall oscPutCrLf



; ----- part 3
        ;------------------------------------------
        ; try to execute a file
        macro_putzarg0 msg_loadandrun


        jsr     k_fat32_open_root_dir

        ldx     #<exename
        ldy     #>exename
        jsr     k_fat32_find_open_dir_ent
        bcc     .foundfile2

        ; File not found
        macro_putzarg0 msg_file_not_found

        jmp     die_with_os_file_error_and_stage
.foundfile2
        ; t16.PRG is assembled to $2000 with PRG header.
        ;         ldx     #<buffer
        ;         ldy     #>buffer
        ;         jsr     k_fat32_load_file

        jsr     k_executable_load
        bcc     .execute
        lda     os_file_error   ; was the error eof?
        beq     .execute        ; yes
        jmp     die_with_os_file_error_and_stage
.execute
        lda     osCallArg0+1
        macro_oscall oscPutHexByte
        lda     osCallArg0
        macro_oscall oscPutHexByte
        ldx     #0
.printloop:
        lda     msg_file_loaded,x
        beq     .run
        phx
        macro_oscall oscPutC
        plx
        inx
        bne     .printloop
.run:
        jmp     (osCallArg0)


msg_file_loaded:
        .string ": loaded file ok",CR,LF
exename:
        .string "T16     PRG"

msg_initialising:
        .string "Initialising ",CR,LF


msg_ok:
        .string " OK",CR,LF
msg_not_ok:
        .string " FAIL",CR,LF

msg_initialising_spi:
        .string " spi bus:"

msg_initialising_sd:
        .string " sd card to spi mode:"

msg_initialising_fat32:
        .string " fat32 init:"

msg_fat32_init_error:
        .string " fat32 init error",CR,LF

msg_file_not_found:
        .string " file not found",CR,LF

msg_os_file_error:
        .string ": os file error",CR,LF

msg_subd_not_found:
        .string " subdirectory not found",CR,LF

msg_dirlisting:
        .string "Listing Directory",CR,LF

msg_loadandrun:
        .string "Loading and running a program from SD card",CR,LF

sd_init_cmd:
        ldy     #4
        jsr     _get_and_copy_args
        bcs     .got_args       ; found an arg
.syntax_e:
        jmp     syntax_error
.got_args:
        ldy     #0
        lda     osOutputBuffer,y
        cmp     #'-'
        bne     .syntax_e
        lda     osOutputBuffer+1,y

        cmp     #'i'
        bne     .next1
        ; TODO jsr     i2c_init ;uncomment when in k space
        bra     .end

.next1:
        cmp     #'s'
        bne     .next2
        ; TODO jsr     k_SPI_init ;uncomment when in k space
        jsr     sd_init
        bra     .end

.next2:
        cmp     #'f'
        bne     .next3
        jsr     fat32_init
        bra     .end

.next3:
        cmp     #'d'
        bne     .syntax_e
        jsr     dizzybox_init
.end:
        macro_print "OK",CR,LF
        os_monitor_return

; isolate arg
; send to dizzybox_cd
sd_cd_cmd:
        ldy     #2
        jsr     _get_and_copy_args
.call_dizzybox:
        jsr     dizzybox_cd
        bcc     .end
;         lda os_file_error
;         beq .end
        jmp     die_with_os_file_error
.end:
        os_monitor_return





; y holds index of next char of osInputBuffer to check
; returns updated osCallArg1 with  Y with last char indexed
; copies arg to osOutputBuffer and z terminates
; uses osInputBuffer and osCallArg1 and osCallArg0
; returns with osCallArg0 pointing to arg
; preserves x
; no arg c=0, arg c=1
_get_and_copy_args:
        macro_store_symbol2word osInputBuffer,osCallArg1
        jsr     _get_arg
        phy                     ;stash for later
        bcc     .no_arg
        ; copy to osOutputBuffer
        lda     #0
        sta     osOutputBuffer+1,y; store teminating zero after last entry
.copy_loop:
        lda     (osCallArg1),y  ; copy backwards
        sta     osOutputBuffer,y
        dey
        bpl     .copy_loop
        sec
        bcs     .return
.no_arg:
        stz     osOutputBuffer
.return:
        macro_store_symbol2word osOutputBuffer,osCallArg0
        ply
        rts




; takes osCallArg1 with buffer and index in y
; returns osCallArg1 with updated buffer with y holding last char of arg
; c is 0 if no arg
; c is 1 if arg
; trims spaces up to arg. End is noted by space or nul.
; preserves X
; Assumes buffer is no longer than 256 bytes!!! and page aligned
_get_arg:
.found=osR0
        phx
        clc
        stz     .found
        ; trim spaces
.trim_loop:
        lda     (osCallArg1),y
        beq     .done           ; eol so nothing found
        cmp     #SPACE
        bne     .found_wordchar ; not a space so found word boundry
        iny
        bne     .trim_loop
.found_wordchar:
        tya
        clc
        adc     osCallArg1      ; update the pointer
        sta     osCallArg1
        ldy     #1              ; reset index, one past the char we found
.arg_loop:
        lda     (osCallArg1),y
        beq     .done_and_found ; eol, job done
        cmp     #SPACE
        beq     .done_and_found ; space, job done for this arg (may be more!)
        iny
        bne     .arg_loop
.done_and_found:
        dey                     ; rewind a tad
        sec
.done:
        plx
        rts


; iterate opening existing path from root
; list directory
sd_ls_cmd:
        ldy     #2
        jsr     _get_and_copy_args
        bcc     .skip_syntax_error; should not have args (not implimented yet)
        jmp     syntax_error
.skip_syntax_error:
        jsr     dizzybox_ls
        bcc     .end
        lda     os_file_error
        beq     .end
        jmp     die_with_os_file_error
.end:
        os_monitor_return


; isolate arg
; make canonical
; iterate opening existing path from root
; find and open - check not a DIR
; do executable stuff
sd_run_cmd:
        ldy     #4
        jsr     _get_and_copy_args
.call_dizzybox:
        jsr     dizzybox_load
        bcc     .end
        lda     os_file_error
        beq     .end
        jmp     die_with_os_file_error
.end:
        ; all loaded well so run executable
        jmp     (osCallArg0)

; isolate arg
sd_cat_cmd:
        ldy     #3
        jsr     _get_and_copy_args
        bcc     .end            ; no args nothing to do
.call_dizzybox:
        jsr     dizzybox_cat
        bcc     .end
        jmp     die_with_os_file_error
.end:
        os_monitor_return

syntax_error:
        ;TODO
        macro_print "TODO proper syntax error",CR,LF

        os_monitor_return

; just do it!
sd_pwd_cmd:
        jsr     dizzybox_pwd
        os_monitor_return




; ===================================================
sd_test_cmd:
        jsr     dizzybox_init
        macro_putzarg0 .msg_test
        macro_putzarg0 .msg_test_p_and_f
        ldx     #0
.testloop:
        ldy     #0
        macro_oscall oscGetC
        bcc     .no_key
        bra     .early_quit
.no_key:
        lda     .p_and_f_test,x
        bpl     .not_done_testing; $ff marks end of strings
.early_quit:
        jmp     .done_testing
        ;
.not_done_testing:
        sta     osOutputBuffer,y
        beq     .done_copy      ; if z terminated done
        iny
        inx
        bne     .no_key
.done_copy:
        inx
        macro_print_c "'"
        macro_putzarg0 osOutputBuffer
        macro_putzarg0 .arrow
        stz     os_file_error
        macro_store_symbol2word osOutputBuffer,osCallArg0
        phx
        jsr     _parse_and_format_8_3
        plx
        macro_putzarg0 filename
        macro_print_c "'"

        lda     os_file_error   ; E_OK?
        beq     .pass           ; yes
        ; fail message
        macro_print_c SPACE
        lda     os_file_error
        macro_oscall oscPutHexByte
        macro_putzarg0 .msg_fail
        jmp     .testloop
        ; passing means we can give a roundtrip test too
.pass:
        macro_putzarg0 .msg_pass
.next_loop:
        macro_store_symbol2word filename,osCallArg1
        macro_store_symbol2word osOutputBuffer,osCallArg0
        jsr     _format_8_dot_3 ; test  roundtrip
        macro_print_c "'"
        macro_putzarg0 osOutputBuffer
        macro_print_c "'"
        macro_oscall oscPutCrLf
        jmp     .testloop

.done_testing:
        jsr     more_testing
        os_monitor_return

.msg_test:
        .string "running test "
.msg_test_p_and_f:
        .string "_parse_and_format_8_3",CR,LF
.msg_test_pwd:
        .string "dizzybox_pwd",CR,LF
.msg_test_cd:
        .string "dizzybox_cd",CR,LF
.arrow:
        .string "' => '"
.msg_fail:
        .string " FAIL",CR,LF
.msg_pass:
        .string " PASS "

.p_and_f_test:
        ; test parse and _parse_and_format_8_3
        .string "1"
        .string "1.123"
        .string "1.12"
        .string "12345678"
        .string "12345678.123"
        .string "."
        .string "123456789"
        .string "1234 567.TXT"
        .string "fail.txt"
        .string "fail?*.txt"
        .string "1.1234"
        .string "12345678.1234"
        .byte   $ff

more_testing:
        macro_putzarg0 .msg_testing_cd
        lda     #$ff
        sta     os_in_testing_mode; needed for testing of cd routine  TODO - check I may move opening dirs to iterate path...
        ldx     #0
.testloop:
        lda     .cd_tests,x
        bpl     .not_done
        jmp     .done
.not_done:
        macro_putzarg0 .msg_test

        ldy     #0
        ; load test
.loop2:
        lda     .cd_tests,x
        sta     osOutputBuffer,y
        beq     .start_test
        inx
        iny
        bne     .loop2

.start_test:
        sta     osOutputBuffer,y; final terminating zero

        macro_putzarg0 osOutputBuffer
        macro_putzarg0 .msg_test_arrow

        macro_store_symbol2word osOutputBuffer,osCallArg0
        jsr     dizzybox_cd

        bcc     .cont           ; error?
        lda     os_file_error
        beq     .cont           ; no error really. TODO why was carry set?
        lda     #'$'
        macro_oscall oscPutC
        lda     os_file_error
        macro_oscall oscPutHexByte
        lda     #SPACE
        macro_oscall oscPutC
.cont:
        jsr     dizzybox_pwd

        inx
        iny
        jmp     .testloop       ; no!
.done:
        stz     os_in_testing_mode
        macro_oscall oscPutCrLf
        rts
.cd_tests:
        .string "."
        .string ".."
        .string "/"
        .string "123"
        .string "/"
        .string "12345678.123"
        .string ".."
        .string "123"
        .string "456"
        .string "789"
        .string ".."
        .string "1234.12"
        .string ""              ; nothing = go to home
        .byte   $ff
.msg_testing_cd:
        .string "Testing cd command:",CR,LF
.msg_test:
        .string "cd "
.msg_test_arrow:
        .string " => "


; TODO - move to memorymap
stage:
        .byt
        .align  8               ; align to page boundary
current_path:
        .blk    128
current_path_len:
        .byt


