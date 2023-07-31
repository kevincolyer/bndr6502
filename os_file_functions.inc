; call this first
k_fat32_open_root_dir:
        stz     os_file_error
        jsr     _k_fat32_init
        bcs     .endnow
        jsr     fat32_openroot
        bcc     .endnow
        lda     #E_OPEN_DIR_FAIL
        sta     os_file_error
.endnow:
        rts

;Find subdirectory by name
; x, y have fileneame
k_fat32_find_open_dir_ent:
        stz     os_file_error
;         ldx     #<subdirname
;         ldy     #>subdirname
        jsr     fat32_finddirent
        bcc     .foundsubdir

        ; Subdirectory not found
        lda     #E_DIR_NOT_FOUND
        sta     os_file_error
        rts
.foundsubdir:
        jsr     fat32_opendirent
        ;         bcc     .all_ok
        ;         lda     #E_FS_READ_ERROR
        ;         sta     os_file_error
        ; .all_ok:
        rts


; preserves x and y
k_fat32_iterate_dir:
        phy
        phx
        jsr     fat32_readdirent
        ; a holds entry attribute bit
        ; carry set means no more entries
        bcs     .quit
        pha                     ; stash for while
        lda     zp_sd_address
        sta     osCallArg0
        lda     zp_sd_address+1
        sta     osCallArg0+1
        pla
.quit:
        plx
        ply
        rts

; Find file by name
; x and y have filenamek_fat32_load_file
; assumes a root or dir is opened


; NOTE DO NOT USE! use k_fat32_find_open_dir_ent

k_fat32_open_file:
        stz     os_file_error
        jsr     fat32_finddirent
        bcc     .foundfile
        lda     #E_FILE_NOT_FOUND
        sta     os_file_error
.foundfile:
        rts

; x lo byte of where to load to
; y hi byte of where to load to
; only up to 64k (fat32_bytesremaining word has length if assume starts at zero)
k_fat32_load_file:
        stz     os_file_error
        clc
        stx     fat32_address
        sty     fat32_address+1
        jsr     fat32_file_read
        rts

; read s one byte from an open file
; carry set at eof
k_fat32_read_byte:
        jmp     fat32_file_readbyte


; not supported yet
k_fat32_write_file:
        stz     os_file_error
        rts

k_fat32_close_file:
        stz     os_file_error
        jsr     _k_fat32_init
        rts

; loads a .prg (first bytes hold load address. Run a load address)
; returns load address in osCallArg0
; exits with carry set on error
k_executable_load:
.load_address=osCallArg0
.load=osR0
        stz     os_file_error
        jsr     fat32_file_readbyte
        bcs     .error
        sta     .load_address
        sta     .load
        jsr     fat32_file_readbyte
        bcs     .error
        sta     .load_address+1
        sta     .load+1
        ; sanity check here
        ; hi < userStart
        cmp     #>userStart
        bcc     .headererror
        ; hi > romStart
        cmp     #>romStart
        bcc     .startload
        ; bcs .startload
.headererror:
        lda     #E_FILE_HEADER  ; nope wierd data here
        sta     os_file_error
        sec
        rts
.startload:
        ; load byte at a time
.loop:
        jsr     fat32_file_readbyte

        bcs     .eof
        sta     (.load)
        inc     .load
        bne     .loop
        inc     .load+1
        bne     .loop
.eof:

        rts                     ; all ok, end of file
.error:
        sec
        lda     #E_FS_READ_ERROR
        sta     os_file_error
        rts

k_executable_relocate:
        rts

k_executable_run:
        rts

; constants
k_file_MAXCHARS=11
k_file_find_file=0
k_file_find_dir=$10

; see constants inc
; E_OK=0  ;
; E_ERROR=1                       ;
; E_SD_NOT_FOUND=2
; E_DIR_NOT_FOUND=3
; E_FILE_NOT_FOUND=4
; E_FS_READ_ERROR=5
; E_FS_WRITE_ERROR=6
; E_EOF=7
; E_NAME_TOO_LONG=8
; E_FAT32_INIT_ERROR=9
; E_INVALID_FILENAME_CHAR=10


_k_fat32_init:
        stz     os_file_error   ; set error to E_OK
        jsr     os_sd_init
        bcc     .sd_ok
        lda     #E_SD_NOT_FOUND
        sta     os_file_error
        rts
.sd_ok:
        jsr     fat32_init
        bcc     .initsuccess
        lda     #E_FAT32_INIT_ERROR
        sta     os_file_error
        rts
.initsuccess:
        rts

k_fat32_valid_filename_chars:
        .string " .0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'()-@^_`{}~",0


; ; osCallArg0 holds a zero terminated filename
; ; carry set = failure
; ; c clear = valid filename
; ; skips a . at place 9
; ; skips trailing spaces (ignores internal spaces)
; ; requires osR0
; k_fat32_is_filename_valid:
; .count=osR0
; .compare=osR0+1
;         stz     os_file_error
;         lda     #k_file_MAXCHARS
;         sta     .count
;
;         ldy     #0
;         clc
; .loop:
;         lda     (osCallArg0),y
;         beq     .ok             ; end of string so ok
;         sta     .compare        ; stash
;         cpy     #8              ; are we at 9th char?
;         bne     .prep_cmp_loop  ; no
;         cmp     #'.'            ; is it a .
;         bne     .prep_cmp_loop  ; no
;         iny                     ; yes, so skip
;         beq     .loop           ; check next
; .prep_cmp_loop
;         ldx     #0
; .cmp_loop:
;         lda     k_fat32_valid_filename_chars,x
;         beq     .failure        ; we have come to end of valid chars, so fail
;         cmp     .compare        ; no so compare with current match
;         beq     .next           ; yes matches - go to next
;         inx
;         bra     .cmp_loop       ; loop
;         ; ok, so lets get next char
; .next:
;         iny                     ; next to seek
;         inc     .count
;         lda     .count          ; does count equal
;         cmp     #k_file_MAXCHARS; max number of chars in a filename?
;         bne     .loop           ; no, so loop
;         lda     #E_NAME_TOO_LONG
;         sta     os_file_error
;         sec
;         rts
; .failure:
;         lda     #E_INVALID_FILENAME_CHAR
;         sta     os_file_error
;         sec
; .ok:
;         rts

; preserves x,y
; usess osR2
k_fat32_is_valid_filename_char:
        clc
        sta     osR2            ; to compare
        phx
        ldx     #0
.loop:
        lda     k_fat32_valid_filename_chars,x; at end of valid list?
        beq     .fail           ; yes, fail
        cmp     osR2            ; is this in list?
        beq     .pass           ; yes, pass
        inx
        bra     .loop
.fail:
        sec
        lda     #E_INVALID_FILENAME_CHAR
        plx
        rts
.pass:
        clc
        plx
        rts
