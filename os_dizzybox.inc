

dizzybox_init:
        lda     #'/'
        sta     current_path
        stz     current_path+1
        lda     #1
        sta     current_path_len
        stz     filename
        stz     subdirname
        stz     os_file_error
        stz     dizzybox_case_insensitive; 0 = insesnitive
        bit     os_in_testing_mode
        bmi     .skip
        jsr     k_fat32_open_root_dir
        lda     os_file_error
        sta     dizzybox_init_ok
        bcc     .skip
        lda     os_file_error
        jsr     m_print_error_message
.skip:

        rts

; make canonical and check (do simple permutations)
; iterate opening existing path from root
; find and open - check not a file
; add dir to path
; dirname (raw) passed in osCallArg0
dizzybox_cd:
        phx
        phy

        bit     os_in_testing_mode
        bmi     .skip_next

        jsr     _open_current_path
        bcc     .skip_next
        jmp     .do_exit        ; problem opening current path
.skip_next:
        ldy     #0
        lda     (osCallArg0),y
        beq     .go_to_root     ; empty so assume means 'home' or / in our case
        cmp     #'/'            ; handles '/'
        beq     .go_to_root
        cmp     #'.'
        bne     .try_to_open
        iny
        lda     (osCallArg0),y
        beq     .do_good_exit   ; handles '.'
        cmp     #'.'            ; handles '..'
        beq     .go_to_parent
        ; 'subfolder' case
.try_to_open:

        jsr     _parse_and_format_8_3
        bcs     .do_exit
        bit     os_in_testing_mode
        bmi     .skip_if_testing

        ldx     #<filename
        ldy     #>filename
        jsr     k_fat32_find_open_dir_ent
.skip_if_testing:
        bcc     .foundsubdir    ; no error
        bra     .do_exit        ; let caller handle error
.foundsubdir:
        ldy     #0
        ldx     current_path_len
.add_dir_to_path:

        lda     filename,y
        sta     current_path,x
        ;         jsr k_ACIA_putc
        inx
        iny
        cpy     #11
        bne     .add_dir_to_path
        lda     #'/'
        sta     current_path,x
        inx
        stz     current_path,x
        stx     current_path_len
        bra     .do_good_exit

.go_to_root:

        jsr     dizzybox_init
.do_good_exit:
        clc
        bra     .do_exit

.go_to_parent:

        lda     current_path_len; look at path length
        cmp     #13             ; if at 1+8+3(+1)
        bcc     .go_to_root     ; then we go to root
        ; subract 12 to go down a dir.
        sec
        sbc     #12
        sta     current_path_len; truncate path by 12
        tax
        stz     current_path,x  ; stick a zero at end

        bit     os_in_testing_mode
        bmi     .skip_if_testing2

        jsr     _open_current_path; get path opened

.skip_if_testing2:
.do_exit:
        ply
        plx
        rts

dizzybox_ls:
; preserves x, y
        phx
        phy
        stz     os_file_error
        lda     dizzybox_init_ok
        bne     .quit
        jsr     _open_current_path
        bcs     .quit
.printloop:
        jsr     k_fat32_iterate_dir
        bcs     .quit
        ldx     #SPACE
        and     #$10
        beq     .notefile
        ldx     #'d'
.notefile
        txa                     ; swap in d or space
        jsr     k_ACIA_putc
        k_macro_print_c SPACE
        ldy     #0
.printname:
        lda     (zp_sd_address),y
        jsr     k_ACIA_putc
        iny
        cpy     #8
        bne     .printname
        k_macro_print_c '.'
.printext:
        lda     (zp_sd_address),y
        jsr     k_ACIA_putc
        iny
        cpy     #11
        bne     .printext
        jsr     k_ACIA_putc_crlf
        bra     .printloop
.quit:
        ply
        plx
        rts

; preserves x, y
dizzybox_load:
        phx
        phy
        stz     os_file_error

        jsr     _open_current_path
        bcs     .return

        jsr     _parse_and_format_8_3
        bcs     .return

        ldx     #<filename
        ldy     #>filename
        jsr     k_fat32_find_open_dir_ent
        bcs     .return

        jsr     k_executable_load
        bcs     .return
        clc
.return
        ply
        plx
        rts

; assumes current path is open and filename is opened
; handles paging with A='m' (quits on esc or ctrl-c)
; handles files > 256 bytes
; does not wrap! (could? if width known)
; preserves x, y
; fat32_file_readbyte (has 32bit reading! fat32_bytesremaining long!)

; make canonical (input in osCallArg0)
; iterate opening existing path from root
; find and open - check not a DIR
; print to terminal
; add option -m for more! (more - with pager?)

dizzybox_cat:
        ; try to read a page at a time until done
        ; check for a key press to cancel
        phy
        phx
        clc

        jsr     _open_current_path
        bcs     .return_sec

        jsr     _parse_and_format_8_3
        bcs     .return_sec

        ldx     #<filename
        ldy     #>filename
        jsr     k_fat32_find_open_dir_ent
        bcs     .return_sec

        ldy     #0
.loop:
        phy
        jsr     fat32_file_readbyte
        ply
        bcs     .return         ; found end of file marker
        pha
        jsr     k_ACIA_putc
        pla
        cmp     #NL
        bne     .move_on
        lda     #CR             ; add extra CR if we fine a NL in case of unix endings
        jsr     k_ACIA_putc
.move_on
        iny
        cpy     #80             ; todo paging here?
        bne     .loop
        jsr     k_ACIA_putc_crlf
        ldy     #0
        ; check keypress
        jsr     k_ACIA_getc
        bcc     .loop
        ; get out keys?
        cmp     #ESC
        beq     .interrupted
        cmp     #ETX
        bne     .loop
.interrupted:
        lda     #E_OPERATION_INTERRUPTED
        sta     os_file_error
.return_sec:
        sec
        plx
        ply
        rts
.return:
        clc
        plx
        ply
        rts
        ; preserves x, y
        ; does not change underlying fat32 state
dizzybox_pwd:
        macro_store_symbol2word current_path,osCallArg2
        macro_store_symbol2word filename,osCallArg1
        macro_store_symbol2word osOutputBuffer,osCallArg0
        jsr     _make_iterate_path

        k_macro_print_c '/'

.loop:
        jsr     _iterate_path
        bcs     .done

        jsr     _format_8_dot_3
        jsr     k_ACIA_putz_osCallArg0;macro_oscall oscPutZArg0
        k_macro_print_c '/'
        bra     .loop
.done:
        jsr     k_ACIA_putc_crlf
        rts

; make a path iterator with path in osCallArg2 and output filename at osCallArg1
; assumes path is terminated with 0
; index kept in osR2 NOTE: do not let other routines overwrite this!!!
_make_iterate_path:
.index=osR2
        lda     #1
        sta     .index          ;skip initial root /
        rts

; iterates path in osCallArg2 putting to osCallArg1. C set on exhausted
; index kept in osR2 NOTE: do not let other routines overwrite this!!!
_iterate_path:
.index=osR2
.ind_out=osR2+1
        phy
        stz     .ind_out
        ldy     .index
        lda     (osCallArg2),y  ; hit end?
        beq     .exhausted      ; yes
.loop:
        ldy     .index          ; look in path
        lda     (osCallArg2),y
        ldy     .ind_out        ; store char in output
        sta     (osCallArg1),y
        inc     .ind_out
        inc     .index
        cmp     #'/'            ; is this the end of a dir?
        bne     .loop
        lda     #0
        sta     (osCallArg1),y  ; write over / with zero (y is o1 less than .ind_out)
        clc
        bra     .return         ; our work is done

.exhausted:
        ldy     .ind_out
        lda     #0
        sta     (osCallArg1),y
        sec
.return
        ply
        rts

; parses from osCallArg0 to filename - zero, terminated
; handles
; CASE a '1'           => '1          '
; CASE b '1.123'       => '1       123'
; CASE c '1.1234'      => error bad filename           ; length after .
; CASE d '1.12'        => '1       12 '
; CASE e '12345678'    => '12345678   '
; CASE f '123456789'   => error bad filename           ; length before .
; CASE g '12345678.123'=> '12345678123'
; CASE h '12345678.1234' => error bad filename         ; check length
; case i '.'            => error bed filename
_parse_and_format_8_3:
.parse=osCallArg0
.length=osR0
.dot=osR0+1
.dots_seen=osR1
        stz     .length
        stz     .dots_seen
        stz     .dot
        stz     os_file_error

        ; filename fill with spaces
        lda     #SPACE
        ldx     #0
.fill_loop:
        sta     filename,x
        inx
        cpx     #11
        bne     .fill_loop
        stz     filename,x

        ; prep counting
        ldy     #0
.count_loop:
        lda     (osCallArg0),y
        beq     .check_count
        ;         jsr k_ACIA_putc
        lda     (osCallArg0),y
        ; check is a legal char
        jsr     _case_insensitise
        jsr     k_fat32_is_valid_filename_char
        bcc     .char_is_ok
        jmp     .other_error    ; nope, so die
.char_is_ok:
        lda     (osCallArg0),y
        cmp     #'.'
        bne     .count_loop_continue
        inc     .dots_seen
        sty     .dot            ; store index of last dot
.count_loop_continue:
        iny
        bne     .count_loop
.check_count:
        cpy     #8+1+3+1
        bcs     .bad_file_name  ; filename too Long!
        sty     .length
        ; dot checking
        lda     .dots_seen
        beq     .no_dots_seen
        cmp     #2              ; 1 or more dots?
        bcs     .bad_file_name  ; 2+ is too many dots!
        lda     .dot            ; where is dot?
        beq     .bad_file_name  ; dot is on first char
        ; extension length
        tya
        sec
        sbc     .dot
        cmp     #3+1+1
        bcs     .bad_file_name  ; extension too long!
        bcc     .prep_copy
.no_dots_seen:
        lda     .length
        cmp     #9
        bcs     .bad_file_name  ; filename before dot too long
.prep_copy:
        ; prepare for copy filename
        ldx     #0
        ldy     #0
.copy_loop:
        lda     (osCallArg0),y
        beq     .all_done
        cmp     #'.'
        beq     .skip_next
        jsr     _case_insensitise
        sta     filename,x
        inx
        iny
        bpl     .copy_loop
.skip_next:
        ldx     #8
        iny
        bpl     .copy_loop

.all_done:

        clc
        rts

.bad_file_name:
        lda     #E_BAD_FILENAME
.other_error:
        sec
        sta     os_file_error
        rts

_case_insensitise:
        phx
        tax
        lda     dizzybox_case_insensitive
        bne     .quit
        txa
        cmp     #'a'
        bcc     .quit
        cmp     #'z'+1
        bcs     .quit
        sec
        sbc     #$20
.quit:

        plx
        rts

; takes osCallArg1 with filename internal and copies to osCallArg0 in human form
_format_8_dot_3:
.arg_in=osR0
.arg_out=osR0+1
.do_dot=osR1
        phy
        phx
        stz     .arg_in
        stz     .arg_out
        stz     .do_dot
        ldy     #0
        lda     (osCallArg1),y  ; is buffer empty?
        beq     .done           ; yes, nothing for me to do here...
        ldx     #0
        ldy     #8
        lda     (osCallArg1),y  ; is there a space at index 9?
        cmp     #SPACE
        beq     .loop           ; yes
        dec     .do_dot         ; no, so we need a dot
.loop:
        cpx     #8              ; are we at the dot index?
        bne     .continue       ; no
        bit     .do_dot         ; do we do a dot here?
        bpl     .continue       ; no
        lda     #'.'            ; yes
        ldy     .arg_out
        sta     (osCallArg0),y
        inc     .arg_out
.continue
        ldy     .arg_in
        lda     (osCallArg1),y
        cmp     #SPACE
        beq     .skip_space
        ldy     .arg_out
        sta     (osCallArg0),y
        inc     .arg_out
.skip_space:
        inc     .arg_in         ; move to next in char
        inx
        cpx     #12             ; are we at the end of the filename?
        bne     .loop
        ; done so store
        ldy     .arg_out
        iny
        lda     #0
        sta     (osCallArg0),y  ; add  terminating zero
.done:
        plx
        ply
        rts

; takes current_path and opens each dir
; fails with c = 1
; returns with open path and c =0
;preserves x,y
_open_current_path:
        phx
        phy
        stz     os_file_error

        jsr     k_fat32_open_root_dir
        bcs     .return_error
        lda     os_file_error
        sta     dizzybox_init_ok
        ldx     #1              ; skip initial /
        ; for each path segment
.path_loop:

        cpx     current_path_len
        beq     .return

        ldy     #0
        ; copies path segment to filename
.copy_path:
        lda     current_path,x
        sta     filename,y
        ;jsr k_ACIA_putc
        iny
        inx
        cpy     #11             ; at end of 8+3+1 ? (so we skip trailing /)
        bne     .copy_path
        lda     #0
        sta     filename,y      ; terminate with zero
        inx                     ; skip /
        ; open it, stashing x and y

        phx
        phy
        ldx     #<filename
        ldy     #>filename
        jsr     k_fat32_find_open_dir_ent
        ply
        plx
        bcs     .return_error
        bcc     .path_loop
.return_error:

        sec
        bra     .quit
.return:

        clc
.quit:
        ply
        plx
        ;jsr k_ACIA_putc_crlf
        rts
