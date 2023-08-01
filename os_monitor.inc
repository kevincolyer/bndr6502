; zp needed for monitor program

;m_working set in rom_xmodem file.


; cold start entry for Monitor
MONITOR:
        ; init variables
        lda     #<userStart
        sta     m_working
        lda     #>userStart
        sta     m_working+1

        ; print monitor help mesg and prompt
        macro_putz msg_monitor_welcome

        ; monitor prompt (warm start entry point)
m_prompt:
        jsr     ACIA_putc_CRLF
        jsr     m_printPrompt   ;


m_monitorloop:
        jsr     CLEAR_OS_INPUT_BUF
        lda     #40
        sta     osCallArg0      ; set maximum linelength
        jsr     osLineEditInputBuf
        jmp     m_parse_input   ; all ending commands and syntax errors return to m_prompt


m_cmd_runat:
        jsr     ACIA_putc_CRLF
        lda     #<msg_running_at
        sta     R0
        lda     #>msg_running_at
        sta     R0+1
        jsr     ACIA_putc_z
        lda     m_working+1
        jsr     ACIA_putc_hex_byte
        lda     m_working
        jsr     ACIA_putc_hex_byte
        jsr     ACIA_putc_CRLF
        jmp     (m_working)

m_cmd_snake:
        jmp     os_snake_main

m_cmd_vttest:
        macro_putz osvt_test    ; send a fake escape code to run test pattern
        jmp     m_prompt

m_cmd_vtsetting:
        macro_putz osvt_settings;send a fake escape code to get my serial term into settings mode
        jmp     m_prompt

m_cmd_list8bytes:
        jsr     ACIA_putc_CRLF
        ldy     #0
.loop:
        lda     (m_working),y
        jsr     ACIA_putc_hex_byte
        lda     #SPACE
        jsr     ACIA_putc
        iny
        cpy     #8
        bne     .loop
        jsr     ACIA_putc_CRLF
        jmp     m_prompt

m_cmd_xmodem:
        jsr     ACIA_putc_CRLF
        jsr     osXModemDownload
        bcc     .go             ; no error so run
        jmp     m_prompt
.go:
        jmp     (FileLoadedPtr) ; start program just loaded (or crash if nonsense pointers!)

m_printPrompt:
        lda     #"$"
        jsr     ACIA_putc
        lda     m_working+1
        jsr     ACIA_putc_hex_byte
        lda     m_working
        jsr     ACIA_putc_hex_byte
        lda     #">"
        jsr     ACIA_putc
        rts


msg_monitor_welcome:
        .string "BNDR 6502 monitor", CR,LF
msg_monitor_syntaxerror:
        .string "syntax error" , CR,LF
msg_running_at:
        .string "running program at "


        ; hex indicated by @
        ; all comands complete with whitespace or newline
        ; except ? which marks as other chars possible
        .macro  macro_ct,cmdname
        .word   \1_cmd
        .word   \1
        .word   \1_help
        .word   .next\@         ; this is only userful for contiguous entries
        .next\@:
        .endm
m_cmd_table:
        macro_ct m_cmd_gotohex
        macro_ct m_cmd_snake
        macro_ct m_cmd_runat
        macro_ct m_cmd_list8bytes
        macro_ct m_cmd_xmodem
        macro_ct m_cmd_vttest
        macro_ct m_cmd_vtsetting
        macro_ct m_cmd_vtescape
        macro_ct m_cmd_clearusercommands
        macro_ct m_cmd_echo

        macro_ct m_cmd_load_exe
        macro_ct m_cmd_date

        macro_ct m_cmd_sd_ls
        macro_ct m_cmd_sd_run
        macro_ct m_cmd_sd_cd
        macro_ct m_cmd_sd_cat
        macro_ct m_cmd_sd_pwd
        macro_ct m_cmd_sd_init

        macro_ct m_cmd_puthex

        .word   m_cmd_help_cmd  ; help command at end of rom table - points to start of ram user table
        .word   m_cmd_help
        .word   m_cmd_help_help
        .word   osUserCmdTable  ; points to users command space


        .byte   0               ; end of table marker

        ;------------------------------
m_cmd_load_exe_cmd:
        .string "load?"
m_cmd_load_exe_help:
        .string "load [file]-load and run prg from sd card",CR,LF

m_cmd_date_cmd:
        .string "date?"
m_cmd_date_help:
        .string "date [set]-date and time",CR,LF
m_cmd_gotohex_cmd:
        .string "@@@@"
m_cmd_gotohex_help:
        .string "hhhh-point to hex addr",CR,LF

m_cmd_snake_cmd:
        .string "snake"
m_cmd_snake_help:
        .string "snake-play snake",CR,LF

m_cmd_help_cmd:
        .string "h"
m_cmd_help_help:
        .string "h-help",CR,LF

m_cmd_runat_cmd:
        .string "r"
m_cmd_runat_help:
        .string "r-run at current addr",CR,LF

m_cmd_list8bytes_cmd:
        .string "l"
m_cmd_list8bytes_help:
        .string "l-list 8 bytes at addr",CR,LF

m_cmd_xmodem_cmd:
        .string "x"
m_cmd_xmodem_help:
        .string "x-xmodem",CR,LF

m_cmd_vttest_cmd:
        .string "t"
m_cmd_vttest_help:
        .string "t-VT test",CR,LF

m_cmd_vtsetting_cmd:
        .string "v"
m_cmd_vtsetting_help:
        .string "v-VT setting",CR,LF

m_cmd_vtescape_cmd:
        .string "esc?"
m_cmd_vtescape_help:
        .string "esc-send ESC [ ...",CR,LF

m_cmd_clearusercommands_cmd:
        .string "c"
m_cmd_clearusercommands_help:
        .string "c-clears user commands",CR,LF

m_cmd_echo_cmd:
        .string "echo?"
m_cmd_echo_help:
        .string "echo-prints text",CR,LF

m_cmd_puthex_cmd:
        .string ":@@?"
m_cmd_puthex_help:
        .string ":hh-put hex at addr, auto inc.",CR,LF

m_cmd_sd_ls_cmd:
        .byte   "ls?",0
m_cmd_sd_ls_help:
        .byte   "ls-sd card dir list",CR,LF,0

m_cmd_sd_run_cmd:
        .byte   "run?",0
m_cmd_sd_run_help:
        .byte   "run [file]-sd load prg file",CR,LF,0

m_cmd_sd_cd_cmd:
        .byte   "cd?",0
m_cmd_sd_cd_help:
        .byte   "cd [...]-change directory",CR,LF,0

m_cmd_sd_cat_cmd:
        .byte   "cat?",0
m_cmd_sd_cat_help:
        .byte   "cat [file]-print contents of file",CR,LF,0

m_cmd_sd_pwd_cmd:
        .byte   "pwd",0
m_cmd_sd_pwd_help:
        .byte   "pwd-print working directory",CR,LF,0

m_cmd_sd_init_cmd:
        .byte   "init?",0
m_cmd_sd_init_help:
        .byte   "init-init -(i)2c (s)d card (f)at32 (d)izzybox subsystems",CR,LF,0


; searches command table for prefixes of commands
; jmps to code to process the next part of the input buffer
m_cmd_help:

.printVec=osR2
.maxWidth=osR3
.onlyCount=osR3+1

        stz     .maxWidth
        stz     .onlyCount      ; 0 for count $ff for print
.load_table:
        lda     #<m_cmd_table
        sta     osR0
        lda     #>m_cmd_table
        sta     osR0+1

        ; search for high byte of next entry (should never be 0)
.read_entry:
        ldy     #1
        lda     (osR0),y        ; check at end of table?
        bne     .countOrPrint   ; not at end

        ; at end of table
        lda     .onlyCount      ; was this a counting run?
        bne     .quit           ; no, were done
        dec     .onlyCount      ; signal yes - now print
        inc     .maxWidth       ; small adjustments
        inc     .maxWidth
        bra     .load_table     ; do again with printing

.quit:
        jmp     m_prompt

.countOrPrint:
        ldy     #4              ; lo byte of
        lda     (osR0),y        ; load the help text to check
        sta     .printVec
        iny
        lda     (osR0),y
        sta     .printVec+1
        ldy     #0

.countOrPrintLoop:
        lda     (.printVec),y
        cmp     #'-'
        beq     .setTabs        ; - means we need to set some tabs

        ; count
        cpy     .maxWidth       ; gte max width?
        bcc     .not_a_max      ;
        sty     .maxWidth       ; yes

.not_a_max:
        bit     .onlyCount      ; do we print?
        bpl     .next           ; no
.print:
        jsr     ACIA_putc       ; yes
.next:
        iny
        bra     .countOrPrintLoop; back into loop

.setTabs:
        bit     .onlyCount      ; are we counting only?
        bpl     .next_entry     ; yes, so next_entry
        phy                     ; cache y
        lda     #SPACE
        ; pretty print tab
.tabs:
        jsr     ACIA_putc
        iny
        cpy     .maxWidth       ; print to max number of spaces
        bcc     .tabs
        lda     #'-'            ; print '- '
        jsr     ACIA_putc
        lda     #SPACE
        jsr     ACIA_putc
        ply                     ; pull it back
        ; print remainder of help message
.printRest:
        iny                     ; (to skip the '-' )
        lda     (.printVec),y
        beq     .next_entry
        jsr     ACIA_putc
        bra     .printRest

.next_entry:
        ldy     #6
        lda     (osR0),y
        pha
        iny
        lda     (osR0),y
        sta     osR0+1
        pla
        sta     osR0
        bra     .read_entry
;
; parse input buffer and seach commands
; search user commands before system commands (till I fix the prefix matching "feature"!)
;

m_parse_input:
.cmdtable=osR0
.matchfound=osR2
.following=osR2+1
.cmpVec=osR3

        lda     #<m_cmd_table
        sta     .cmdtable
        lda     #>m_cmd_table
        sta     .cmdtable+1
        jmp     .m_parse_input_main
        ; if we have reached here then we have not made a match so quit with error
.syntaxerror:
        macro_putz msg_monitor_syntaxerror
        jmp     m_prompt


.m_parse_input_main:
        ; check not at end of cmd table (high byte of entry - never a zerp)
        ldy     #1              ; index of cmds
        lda     (.cmdtable),y   ; check table
        beq     .syntaxerror    ; end of table - no matches
        ; prepare search
        stz     .matchfound     ; used to see if match found
        stz     .following
        ; No so load cmd to compare with
        sta     .cmpVec+1
        ldy     #0
        lda     (.cmdtable),y
        sta     .cmpVec
        ldy     #$ff
        ldx     #$ff            ; index of input
.search1:
        iny
        inx
        lda     (.cmpVec),y     ; check table
        ; check entry for a match
        beq     .is_cmd_found   ; end of cmd marker 0 check to see if we have match

        cmp     osInputBuffer,x ; does it match a char in buffer?
        beq     .match          ; yes
        ; special chars
        cmp     #'@'            ; shpould we check for hex digit?
        beq     .checkhex       ; yes

        cmp     #'?'            ; are there any more chars or spaces to check?
        bne     .skip_to_next_cmd; no, nothing else to check for so skip to next command
        dec     .following      ; yes so set flag that we are expecting more chars to follow (not an exact match)
        bra     .search1        ; and keep looking in this cmd entry...

.checkhex:
        lda     osInputBuffer,x
        jsr     osIsHexByte     ; is it hex?
        bcc     .match          ; yes
        ; no match in this case
        bcs     .skip_to_next_cmd


.match:
        lda     #$80
        sta     .matchfound     ; note we have a partialmatch
        bra     .search1        ; keep looking

.is_cmd_found:
        bit     .matchfound
        bpl     .skip_to_next_cmd; no_match
        ; yes, we have a match
        ; but are there more input chars to be consumed?
        lda     osInputBuffer,x
        beq     .got_cmd        ; no more chars
        ; yes, more chars
        ; but are we accepting a .following char (marked ?)
        bit     .following
        bpl     .skip_to_next_cmd; no, so this is a prefix, check next command
        ; yes, so we must have a command
.got_cmd:
        ; found match so load vector
        ldy     #2
        lda     (.cmdtable),y
        sta     osR1
        iny
        lda     (.cmdtable),y
        sta     osR1+1
        ; and jump!
        jmp     (osR1)

.skip_to_next_cmd:
        ldy     #6
        lda     (.cmdtable),y
        pha
        iny
        lda     (.cmdtable),y
        sta     .cmdtable+1
        pla
        sta     .cmdtable
        ; jump down through the table to the next entry
        bra     .m_parse_input_main


; monitor command
; sends test chars to vt
m_cmd_vtescape:
        lda     #ESC
        jsr     ACIA_putc
        lda     #'['
        jsr     ACIA_putc
        ldx     #3
.loop:
        lda     osInputBuffer,x
        beq     .done
        inx
        cmp     #SPACE
        beq     .loop           ; parse out spaces
        jsr     ACIA_putc
        bra     .loop
.done:
        jmp     m_prompt


m_cmd_echo:
        ldx     #4
.loop:
        lda     osInputBuffer,x
        beq     .done
        inx
        cmp     #SPACE
        beq     .loop           ; parse out spaces
        jsr     ACIA_putc
        bra     .loop
.done:
        jmp     m_prompt


; monitor command
; load address for monitor to work on
m_cmd_gotohex:
        ldx     #0
m_cmd_gotohex2:
        lda     osInputBuffer,x
        sta     osOutputBuffer,x
        jsr     osIsHexByte
        asl
        asl
        asl
        asl
        sta     m_working+1     ; hi byte upper nybble
        inx
        lda     osInputBuffer,x
        sta     osOutputBuffer,x
        jsr     osIsHexByte
        ora     m_working+1     ; hi byte lower nybble
        sta     m_working+1
        ; now do the lower byte
        inx
        lda     osInputBuffer,x
        sta     osOutputBuffer,x
        jsr     osIsHexByte
        asl
        asl
        asl
        asl
        sta     m_working
        inx
        lda     osInputBuffer,x
        sta     osOutputBuffer,x
        jsr     osIsHexByte
        ora     m_working
        sta     m_working
        jmp     m_prompt        ; back to monitor

m_cmd_puthex:
        ; match pattern of two hex digits and space. end at buffer end or 8 hex bytes.
        ; store bytes in output buffer
        ; assume x has index to osInputBuffer
        ldx     #1
        ldy     #0              ; index to outputbuffer
.getnexthexbyte:
        lda     osInputBuffer,x
        beq     .endofinput
        jsr     osIsHexByte
        sta     osOutputBuffer+16,y; ; debug
        bcs     .syntaxerror
        asl
        asl
        asl
        asl
        sta     osOutputBuffer,y
        inx
        lda     osInputBuffer,x
        jsr     osIsHexByte
        sta     osOutputBuffer+16,y; debug
        bcs     .syntaxerror
        ora     osOutputBuffer,y
        sta     osOutputBuffer,y
.skip_space:
        inx
        lda     osInputBuffer,x
        beq     .endofinput
        cmp     #SPACE
        beq     .skip_space     ; keep eating spaces till end of input
        iny                     ; not a space so check count of bytes processed
        cpy     #8
        beq     .syntaxerror    ; more than 8 bytes processes
        bne     .getnexthexbyte

.endofinput:
        phy                     ; cache count
.copyloop:
        lda     osOutputBuffer,y
        sta     (m_working),y
        dey
        bpl     .copyloop
        ; inc m_working
        pla                     ; retreive cache
        sec                     ; add one so we are in the next useful location
        adc     m_working
        sta     m_working
        bcc     .done
        inc     m_working+1
        bra     .done
.syntaxerror:
        macro_putz msg_monitor_syntaxerror
.done:
        jmp     m_prompt

; add a user command to the user command table
; copy from osCallArg0
m_add_user_cmd:
.cmpVec=osR0
.cmpVec2=osR1
.atEnd=osR2                     ; 0 = yes, 1 = no

; search table. Check cmd against all entries. replace or add if last
        ldx     #0
        stx     .atEnd
.loop:
        lda     osUserCmdTable+1,x; at end of table?
        beq     .addHere        ; yes, add entry here

        ; no, so compare the command with the one we are adding
        lda     osUserCmdTable,x
        sta     .cmpVec
        lda     osUserCmdTable+1,x
        sta     .cmpVec+1
        ldy     #0
        lda     (osCallArg0),y
        sta     .cmpVec2
        iny
        lda     (osCallArg0),y
        sta     .cmpVec2+1
        dey
.cmploop:
        lda     (.cmpVec2),y
        cmp     (.cmpVec),y     ; are they the same?
        bne     .cmpFail        ; no
        ora     (.cmpVec),y     ; yes - both zero?
        beq     .cmpMatch       ; yes, so go to addhere
        iny
        bra     .cmploop        ; no, keep comparing

        ; matched but not at end of table
.cmpMatch:
        inc     .atEnd
        bra     .addHere

.cmpFail:
        ; no, so move to next entry
        txa
        clc
        adc     #8
        tax
        bra     .loop

.addHere:
        ldy     #0
.addHereLoop:
        lda     (osCallArg0),y
        sta     osUserCmdTable,x
        inx
        iny
        cpy     #6
        bne     .addHereLoop

        inx
        inx
        txa                     ; jump to +8
        sta     osUserCmdTable-2,x; store vectore of next entry - lo
        lda     #>osUserCmdTable
        sta     osUserCmdTable-1,x; hi
        ; at end?
        lda     .atEnd
        bne     .quit
        ; at end so store a zero to indicate end of table in next but one entry
        stz     osUserCmdTable,x

.quit:
        ; print commands
        ldy     #4
        lda     (osCallArg0),y
        sta     .cmpVec2
        iny
        lda     (osCallArg0),y
        sta     .cmpVec2+1

        lda     #<msg_monitor_cmdtable_added
        sta     R0
        lda     #>msg_monitor_cmdtable_added
        sta     R0+1
        jsr     ACIA_putc_z

        ldy     #0
.print_loop:
        lda     (.cmpVec2),y
        cmp     #'-'
        beq     .pl_done
        jsr     ACIA_putc
        iny
        bne     .print_loop


.pl_done:
        jsr     ACIA_putc_CRLF
        rts


m_cmd_clearusercommands:
        stz     osUserCmdTable+1
        macro_putz msg_monitor_clearedusercommands
        jmp     m_prompt

m_cmd_date:
        ldy     #0
        ldx     #4
.parse_loop:
        lda     osInputBuffer,x
        beq     .just_print
        cmp     .parse_set,y
        bne     .just_print
        inx
        iny
        cpy     #4
        bne     .parse_loop
        ; Ok- we are in set mode so get user date and parse
        jsr     k_rtc_set_i2c
        bcs     .quit           ; error in parsing or setting
.just_print:
        jsr     k_print_date_time
.quit
        jmp     m_prompt
.parse_set:
        .byte   " set"          ;reverse order

m_cmd_load_exe:
        macro_putz msg_not_implimented
        jmp     m_prompt

msg_monitor_clearedusercommands:
        .string "User commands cleared",CR,LF

msg_not_implimented:
        .string "Command not implimented",CR,LF

msg_monitor_cmdtable_added:
        .string "Command added: "

msg_monitor_ok:
        .string "OK",CR,LF

; prints message passed in A
; preserves x,y
; will print CR,LF at end unless A hi bit set
m_print_error_message:
        phx
        phy
        sta     R0
        and     #$7f
        tay
        ldx     #0
.find_message:
        lda     msg_error_enum_list,x
        bmi     .done
        beq     .end_of_message
        inx
        bne     .find_message
.end_of_message:
        inx
        dey                     ; dec message counter
        bne     .find_message
        ; got message so print!
.print_loop:
        lda     msg_error_enum_list,x
        beq     .done_print_loop
        jsr     ACIA_putc
        inx                     ;inc index
        bne     .print_loop
.done_print_loop:
        bit     R0
        bmi     .done
        jsr     ACIA_putc_CRLF
.done
        ply
        plx
        rts

msg_error_enum_list:
        .string "E_OK"
        .string "E_ERROR"
        .string "E_SD_NOT_FOUND"
        .string "E_DIR_OR_FILE_NOT_FOUND"
        .string "E_FILE_NOT_FOUND"
        .string "E_FS_READ_ERROR"
        .string "E_FS_WRITE_ERROR"
        .string "E_EOF"
        .string "E_NAME_TOO_LONG"
        .string "E_FAT32_INIT_ERROR"
        .string "E_INVALID_FILENAME_CHAR"
        .string "E_OPEN_DIR_FAIL"
        .string "E_FILE_HEADER"
        .string "E_BAD_FILENAME"
        .string "E_OPERATION_INTERRUPTED"
        .string "E_SYNTAX_ERROR"
        .byte   $ff

_syntax_error:
        lda     #E_SYNTAX_ERROR
        sta     os_file_error
_die_with_os_file_error:
        lda     os_file_error
        jsr     m_print_error_message
        jmp     m_prompt

m_cmd_sd_init:
        ldy     #4
        jsr     _get_and_copy_args
        bcs     .got_args       ; found an arg
.syntax_e:
        jmp     _syntax_error
.got_args:
        ldy     #0
        lda     osOutputBuffer,y
        cmp     #'-'
        bne     .syntax_e
        lda     osOutputBuffer+1,y

        cmp     #'i'
        bne     .next1
        jsr     i2c_init
        bra     .end

.next1:
        cmp     #'s'
        bne     .next2
        jsr     k_SPI_init
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
        macro_putz msg_monitor_ok
        jmp     m_prompt

; isolate arg
; send to dizzybox_cd
m_cmd_sd_cd:
        ldy     #2
        jsr     _get_and_copy_args
.call_dizzybox:
        jsr     dizzybox_cd
        bcc     .end

        jmp     _die_with_os_file_error
.end:
        jmp     m_prompt





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
m_cmd_sd_ls:
        ldy     #2
        jsr     _get_and_copy_args
        bcc     .skip_syntax_error; should not have args (not implimented yet)
        jmp     _syntax_error
.skip_syntax_error:
        jsr     dizzybox_ls
        bcc     .end
        lda     os_file_error
        beq     .end
        jmp     _die_with_os_file_error
.end:
        jmp     m_prompt


; isolate arg
; make canonical
; iterate opening existing path from root
; find and open - check not a DIR
; do executable stuff
m_cmd_sd_run:
        ldy     #4
        jsr     _get_and_copy_args
.call_dizzybox:
        jsr     dizzybox_load
        bcc     .end
        lda     os_file_error
        beq     .end
        jmp     _die_with_os_file_error
.end:
        ; all loaded well so run executable
        jmp     (osCallArg0)

; isolate arg
m_cmd_sd_cat:
        ldy     #3
        jsr     _get_and_copy_args
        bcc     .end            ; no args nothing to do
.call_dizzybox:
        jsr     dizzybox_cat
        bcc     .end
        jmp     _die_with_os_file_error
.end:
        jmp     m_prompt

; syntax_error:
;         lda #E_SYNTAX_ERROR
;         jsr m_print_error_message
;         jmp m_prompt

; just do it!
m_cmd_sd_pwd:
        jsr     dizzybox_pwd
        jmp     m_prompt



