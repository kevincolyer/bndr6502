; simple snake game for playing on vt terminal
; uses terminal emulation escape command. y and x are 1 indexed.
; Esc  [ <y> ; <x> H

os_snake_main:
.snake_x        = osInputBuffer
.snake_y        = osInputBuffer+$80
;osVariables
.sx=osLastZp
.sy=osLastZp+1
.snakedir=osLastZp+2
.counter=osLastZp+3
.snaketaily=osLastZp+4
.snake_rb_h=osLastZp+5          ; ringbuffer of snake segments - head pointer
.snake_rb_t=osLastZp+6          ; ringbuffer of snake segments - tail pointer
.snake_win=osLastZp+7           ; 0 playing, 1 win
.scorelo=osLastZp+8
.scorehi=osLastZp+9
.gx=osLastZp+10
.gy=osLastZp+11
.randomseed=osLastZp+12
.snake_grow_by=osLastZp+13

.MINX=1
.MINY=2
.MAXX=40
.MAXY=20
.MAXXBCD=$40
.MAXYBCD=$20

        ; intialise


        jsr     k_clear_os_output_buffer

        ; cursor off, home and cls
        macro_putz osvt_home
        macro_putz osvt_cls
        macro_putz osvt_cursoroff
.restartpoint:
        jsr     .snake_draw_screen
        jsr     .snake_await_player
        cmp     #'q'
        beq     .exit
        ; init variables and snake
        ldx     #0
.iloop:
        stz     osLastZp,x      ; zero all variables
        inx
        cpx     #15
        bne     .iloop

        macro_putz osvt_bg_Black
        macro_putz osvt_fg_Green
        ; prepare snake
        ldx     #5
        stx     .snake_rb_h     ; headpointer
        ldy     #5
.iloop2:
        txa
        sta     .snake_x,x      ; copy segment coords places to x buffer
        sta     .sx
        tya
        sta     .snake_y,x      ; y buffer
        sta     .sy
        jsr     .printVTmovecursor
        lda     #'o'
        jsr     k_putc_os_output_buf
        dex
        cpx     #1
        bne     .iloop2
        inx                     ; needed becayse of screen origin 1,1
        stx     .snake_rb_t     ; tail pointer
        lda     #1
        sta     .snakedir       ; set direction of snake to right
        jsr     k_ACIA_print_os_output_buf
        jsr     k_clear_os_output_buffer
        macro_putz osvt_fg_White
        jsr     .print_score    ; (also puts and flushes output buffer)

        lda     #10
        sta     .counter
        jsr     .new_goodie

.mainloop:
        clc
        jsr     k_ACIA_getc
        bcc     .nokey
        cmp     #"q"
        beq     .exit
        ; search for direction key
        ldx     #3              ; got a key
.changedirloop:
        cmp     .keys,x         ; check index of keys to directions
        beq     .newdirection   ; got new direction
        dex
        bpl     .changedirloop
        bra     .nokey          ; not known key
.newdirection:
        ; check not opposite direction...
        txa
        inc
        inc
        and     #$3
        cmp     .snakedir
        beq     .nokey          ; add 2 to direction mod 4 to check not requesting opposite direction...
        stx     .snakedir       ; store direction
        bra     .nokey
.exit:
        ; reset cursor, color, home and clear screen
        macro_putz osvt_cursoron
        macro_putz osvt_fgbg_reset
        macro_putz osvt_home
        macro_putz osvt_cls
        jmp     k_monitor_prompt

.nokey:
        ; move snake
        macro_putz osvt_bg_Black
        macro_putz osvt_fg_Green
        ; load head
        ldx     .snake_rb_h
        lda     .snake_x,x
        sta     .sx
        lda     .snake_y,x
        sta     .sy
        jsr     .printVTmovecursor
        ; paint head with a segment
        lda     #'o'
        jsr     k_putc_os_output_buf
        ; move in given direction
        ; .sx and .sy have old head - now move to new head.
        lda     .snakedir
        jsr     .sxsydir
        jsr     .printVTmovecursor
        ; paint head
        jsr     k_ACIA_print_os_output_buf
        macro_putz osvt_fg_Red
        lda     #'@'
        jsr     k_putc_os_output_buf
        ; push into buffer
        ldx     .snake_rb_h
        inx
        bpl     .headmovepush1  ; wrap around 128 byte ring buffer
        ldx     #0
.headmovepush1:
        stx     .snake_rb_h
        lda     .sx
        sta     .snake_x,x
        lda     .sy
        sta     .snake_y,x
        ; load tail
        ldx     .snake_rb_t
        lda     .snake_x,x
        sta     .sx
        lda     .snake_y,x
        sta     .sy
        ; remove from buffer (if not growing!)
        lda     .snake_grow_by  ; are we growing?
        beq     .tail_moving
        dec                     ; yes - so dec growth counter
        sta     .snake_grow_by
        bra     .flush_buffers  ; jump straight to flush buffer
.tail_moving:
        inx
        bpl     .tailmovepush1
        ldx     #0
.tailmovepush1:
        stx     .snake_rb_t
        ; paint with space
        jsr     .printVTmovecursor
        lda     #SPACE
        jsr     k_putc_os_output_buf
.flush_buffers
        jsr     k_ACIA_print_os_output_buf
        jsr     k_clear_os_output_buffer
        ; handle collisions
        ldx     .snake_rb_h
        lda     .snake_x,x
        pha
        lda     .snake_y,x
        tay
        plx
        jsr     .collision
        cmp     #'S'
        beq     .die
        cmp     #'W'
        beq     .die
        cmp     #'G'
        bne     .no_colls
        ; goodie munch!
        lda     #1
        jsr     .add_score
        lda     #1
        sta     .snake_grow_by
        jsr     .new_goodie
.no_colls
        ; sleep and finish loop
        lda     #7
        jsr     k_sleep_10_ms   ; sleep 7x10ms
        jmp     .mainloop       ; back to top
        ; end main loop

.die:

        jsr     .display_dead
        cmp     #'q'
        bne     .die_restart    ; are we quitting?
        jmp     .exit           ; yes!
.die_restart:
        jmp     .restartpoint   ; no, play again!




; preserves X and Y (as does k_putc_os_output_buf)
.printbcd:
        phx
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda     .decimals,x
        cmp     #'0'
        beq     .skiptens       ; avoid leading zeros.
        jsr     k_putc_os_output_buf
.skiptens:
        pla
        and     #$f
        tax
        lda     .decimals,x
        plx
        jmp     k_putc_os_output_buf
.decimals:
        .byte   "0123456789abcdef"
.dx:
        .byte   0   ,1, 0, $ff  ; u,r,d,l
.dy:
        .byte   $ff ,0, 1, 0
.keys:
        .byte   "w","d","s","a"

.snake_topline_msg:
        .byte   "~~~ Snake ~~~  keys: w a s d  score:0",0
;                1234567890123456789012345678901234567890
.snake_win_msg:
        .byte   "**  You Win!  **",0; 16 chars
.snake_lose_msg:
        .byte   "** Game  Over **",0
.snake_start_msg:
        .byte   "press s to start",0
.snake_erase_msg:
        .byte   "                ",0

.printVTmovecursor:
        lda     #ESC            ; print cursor move sequence
        jsr     k_putc_os_output_buf
        lda     #"["
        jsr     k_putc_os_output_buf
        lda     .sy
        jsr     .printbcd
        lda     #";"
        jsr     k_putc_os_output_buf
        lda     .sx
        jsr     .printbcd
        lda     #"H"
        jmp     k_putc_os_output_buf

; .savecursor:
;         .byte   ESC,"7",0
; .restorecursor:
;         .byte   ESC,"8",0

; X Y hold coords of snake segment
; push onto ring buffer
.snake_push_xy:
        phx
        phy
        lda     .snake_rb_h     ; get head
        inc                     ; inc
        and     #$7f            ; wrap at $80 length
        cmp     .snake_rb_t     ; is it at tail pointer?
        beq     .snake_too_long ; yes, buffer full - you win!
        tay                     ; use as index to x and y arrays
        pla
        sta     .snake_x,y
        pla
        sta     .snake_y,y
        sty     .snake_rb_h
        rts
.snake_too_long:
        macro_putz osvt_home
        macro_putz osvt_fgbg_reset
        macro_putz .snake_win_msg
        lda     #$80
        jsr     k_sleep_10_ms
        jmp     .exit

.snake_draw_screen:

        lda     #.MINX
        sta     .sx
        lda     #1
        sta     .sy
        jsr     .printVTmovecursor
        jsr     k_ACIA_print_os_output_buf
        macro_putz osvt_fg_White
        macro_putz .snake_topline_msg

        lda     #.MINY
        sta     .sy
        jsr     .printVTmovecursor
        jsr     k_ACIA_print_os_output_buf
        macro_putz osvt_bg_Green
        macro_putz osvt_fg_White
        ; skip a line for score
        inc     .sy
        ; draw top fence
        ldx     #.MAXX+1
.sds_loop1:
        lda     #'#'
        jsr     k_ACIA_putc
        dex
        cpx     #.MINX
        bne     .sds_loop1
        jsr     k_ACIA_putc_crlf
        inc     .sy
        ; draw mid fences
        ldy     #.MAXY-.MINY+1+2
.sds_loop2:
        lda     #'#'
        jsr     k_ACIA_putc
        phy
        macro_putz osvt_fgbg_reset
        ply
        ldx     #.MAXX
.sds_loop2i:
        lda     #SPACE
        jsr     k_ACIA_putc
        dex
        cpx     #.MINX+1
        bne     .sds_loop2i
        phy
        phx
        macro_putz osvt_bg_Green
        macro_putz osvt_fg_White
        plx
        ply
        lda     #'#'
        jsr     k_ACIA_putc
        jsr     k_ACIA_putc_crlf
        dey
        cpy     .sy
        bne     .sds_loop2
        ; draw bottom fence
        ldx     #.MAXX+1
.sds_loop3:
        lda     #'#'
        jsr     k_ACIA_putc
        dex
        cpx     #.MINX
        bne     .sds_loop3
        jsr     k_ACIA_putc_crlf
        rts

; adds A to score
.add_score:
        sed
        clc
        adc     .scorelo
        sta     .scorelo
        lda     .scorehi
        adc     #0
        sta     .scorehi
        cld
        ; run on as we always want to update the score as we go!
.print_score:
        macro_putz osvt_fg_White
        lda     #$37
        sta     .sx
        lda     #1
        sta     .sy
        jsr     .printVTmovecursor

        lda     .scorehi
        beq     .scoreskip
        jsr     .printbcd
.scoreskip:
        lda     .scorelo
        jsr     .printbcd
        jsr     k_ACIA_print_os_output_buf
        jmp     k_clear_os_output_buffer

; collision detection
; X holds x coord and Y coord - they are BCD but just comparing eqaulity
; returns in A W=wall, S=snake and G=goodie 0=no collision
.collision:
        lda     #'G'            ; goodie
        stx     .sx
        sty     .sy
        cpx     .gx
        bne     .collision_next1; no, not on x so fast fail
        cpy     .gy
        beq     .collisionhit   ; yes, so return
.collision_next1
        lda     #'W'            ; wall
        cpx     #.MINX
        beq     .collisionhit   ; yes, hit minx
        cpx     #.MAXXBCD
        beq     .collisionhit   ; yes, hit maxx
        cpy     #.MINY
        beq     .collisionhit   ; yes, hit min y
        cpy     #.MAXYBCD
        beq     .collisionhit   ; yes, hit max y
        ; check for collisions through the snake
        ; move from tail to head along ring buffer
        ; check for x hit and then y
        ldx     .snake_rb_t     ; prepare to loop through snake segs
.snakecollloop:
        lda     .snake_x,x
        cmp     .sx             ; hit x?
        bne     .snakecollnext
        lda     .snake_y,x
        cmp     .sy             ; hit y?
        bne     .snakecollnext  ; nope, branch to increment counter
        lda     #'S'            ; hit segment!
        bra     .collisionhit
.snakecollnext:
        inx
        bpl     .snakecollnext1 ; continue if not ready to wrap around
        ldx     #0              ; wrap around ring buffer condition
.snakecollnext1:
        cpx     .snake_rb_h     ; have we reached head?
        bne     .snakecollloop  ; no
        lda     #0              ; got this far then no collision!
.collisionhit:
        rts


.new_goodie:
        stz     .gx
        stz     .gy
        lda     #.MAXX-.MINX-2
        jsr     k_random_up_to
        sec
        adc     #.MINX
        jsr     k_bin_to_bcd
        sta     .sx
        lda     #.MAXY-.MINY-2
        jsr     k_random_up_to
        sec
        adc     #.MINY+1
        jsr     k_bin_to_bcd
        sta     .sy
        ldx     .sx
        tay
        jsr     .collision      ; check it is not a collision
        bne     .new_goodie     ; drat, was a collision - restart
        lda     .sx
        sta     .gx
        lda     .sy
        sta     .gy
        macro_putz osvt_bg_Black
        macro_putz osvt_fg_Red
        jsr     .printVTmovecursor
        lda     #'%'
        jsr     k_putc_os_output_buf
        jsr     k_ACIA_print_os_output_buf
        jmp     k_clear_os_output_buffer

; call with coords in .sx and .sy and A holding direction index
.sxsydir:
        tay                     ; move direction index to y
        sed
        clc
        ; x coord first
        lda     .dx,y           ; get dx
        bmi     .sxsy1          ; if neg skip
        adc     .sx             ; add non neg (1) to .sx
        sta     .sx
        bra     .sxsy2          ; do sy now
.sxsy1:
        sec
        lda     .sx             ; prep for subtraction
        sbc     #1              ; subtract
        sta     .sx             ; finished
.sxsy2:
        ; y coord
        clc
        lda     .dy,y           ; repeat for y
        bmi     .sxsy3
        adc     .sy
        sta     .sy
        bra     .sxsy4
.sxsy3:
        sec
        lda     .sy
        sbc     #1
        sta     .sy
.sxsy4:
        cld
        rts




.snake_await_player:
        ; print start message
        jsr     .centertext
        macro_putz .snake_start_msg
.snake_await_loop:
        inc     .randomseed     ; get some entropy from user
        lda     .randomseed
        jsr     k_seed_random
        jsr     k_ACIA_getc
        bcc     .snake_await_loop; no key
        cmp     #'q'
        beq     .snakeawaitend  ; on return checks for 'q' in A
.snake_await_next:
        cmp     #'s'
        bne     .snake_await_loop
        ; ready to go!
        jsr     .cleartext
.snakeawaitend:
        rts

.centertext:
        lda     #.MAXY
        lsr                     ;div2
        jsr     k_bin_to_bcd
        sta     .sy
        lda     #.MAXX
        sec
        sbc     #16
        lsr
        jsr     k_bin_to_bcd
        sta     .sx
        jsr     .printVTmovecursor
        jsr     k_ACIA_print_os_output_buf
        jsr     k_clear_os_output_buffer
        rts

.cleartext:
        macro_putz osvt_fgbg_reset
        jsr     .centertext
        macro_putz .snake_erase_msg
        rts

.display_dead:
        ; print start message
        macro_putz osvt_fg_White
        macro_putz osvt_bg_Green

        jsr     .centertext
        macro_putz .snake_lose_msg
        lda     #$40
        jsr     k_sleep_10_ms   ; little pause!
.dd_await_loop:
        jsr     k_ACIA_getc
        bcc     .dd_await_loop  ; no key
        cmp     #'q'
        beq     .dd_await_end   ; on return checks for 'q' in A
        cmp     #'s'
        bne     .dd_await_loop
        lda     #0
        ; ready to go!
.dd_await_end:
        pha
        jsr     .centertext
        macro_putz osvt_fgbg_reset

        jsr     .cleartext
        pla
        rts
