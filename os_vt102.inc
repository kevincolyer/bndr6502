osvt_test:
        .byte   ESC,"[test",0
osvt_settings:
        .byte   ESC,"[settings",0

osvt_fgbg_reset:
        .byte   ESC,"[0m",0

        osvt_savecursor:
        .byte   ESC,"7",0
osvt_restorecursor:
        .byte   ESC,"8",0

osvt_cursoron:
        .byte   ESC,"[?25h",0
osvt_cursoroff:
        .byte   ESC,"[?25l",0

osvt_home:
        .byte   ESC,"[H",0
osvt_cls:
        .byte   ESC,"[2J",0

osvt_return_is_cr:
        .byte   ESC,"[20l",0
osct_return_is_cr_lf:
        .byte   ESC,"[20h",0

;         .byte   ESC,"[0m",ESC,"[H",ESC,"[2J" ; reset fg and bg, home and clear screen
; see https://fossies.org/linux/splitvt/escapes/vt102.codes

;Set Modes
;  Esc  [ <c> ; ... ; <c> h
;Reset Modes
;  Esc  [ <c> ; ... ; <c> l

;Where <c> is
;  '2'= Lock keyboard (set); Unlock keyboard (reset)
;  '4'= Insert mode (set); Replace mode (reset)
; '12'= Echo on (set); Echo off (reset)
; '20'= Return = CR+LF (set); Return = CR (reset)
; '?1'= Cursorkeys application (set); Cursorkeys normal (reset)
; '?2'= Ansi (set); VT52 (reset)
; '?3'= 132 char/row (set); 80 char/row (reset)
; '?4'= Jump scroll (set); Smooth scroll (reset)
; '?5'= Reverse screen (set); Normal screen (reset)
; '?6'= Sets relative coordinates (set); Sets absolute coordinates (reset)
; '?7'= Auto wrap (set); Auto wrap off (reset)
; '?8'= Auto repeat on (set); Auto repeat off (reset)
;'?18'= Send FF to printer after print screen (set); No char after PS (reset)
;'?19'= Print screen prints full screen (set); PS prints scroll region (reset)
;'?25'= Cursor on (set); Cursor off (reset)

osvt_fg_Black:
        .byte   ESC,"[30m",0
osvt_fg_Red:
        .byte   ESC,"[31m",0
osvt_fg_Green:
        .byte   ESC,"[32m",0
osvt_fg_Yellow:
        .byte   ESC,"[33m",0
osvt_fg_Blue:
        .byte   ESC,"[34m",0
osvt_fg_Magenta:
        .byte   ESC,"[35m",0
osvt_fg_Cyan:
        .byte   ESC,"[36m",0
osvt_fg_White:
        .byte   ESC,"[37m",0
osvt_bg_Black:
        .byte   ESC,"[40m",0
osvt_bg_Red:
        .byte   ESC,"[41m",0
osvt_bg_Green:
        .byte   ESC,"[42m",0
osvt_bg_Yellow:
        .byte   ESC,"[43m",0
osvt_bg_Blue:
        .byte   ESC,"[44m",0
osvt_bg_Magenta:
        .byte   ESC,"[45m",0
osvt_bg_Cyan:
        .byte   ESC,"[46m",0
osvt_bg_White:
        .byte   ESC,"[47m",0

        ifndef  symon
osvt_fg_default:
        .byte   ESC,"[39m",0    ; reset fg
osvt_bg_default:
        .byte   ESC,"[49m",0    ; reset bg
        ;
        ; If 16-color support:·bright versions of the ISO colors:

osvt_fg_bright_Black:
        .byte   ESC,"[90m" ,0
osvt_fg_bright_Red:
        .byte   ESC,"[91m" ,0
osvt_fg_bright_Green:
        .byte   ESC,"[92m" ,0
osvt_fg_bright_Yellow:
        .byte   ESC,"[93m" ,0
osvt_fg_bright_Blue:
        .byte   ESC,"[94m" ,0
osvt_fg_bright_Magenta:
        .byte   ESC,"[95m" ,0
osvt_fg_bright_Cyan:
        .byte   ESC,"[96m" ,0
osvt_fg_bright_White:
        .byte   ESC,"[97m" ,0
osvt_bg_bright_Black:
        .byte   ESC,"[100m",0
osvt_bg_bright_Red:
        .byte   ESC,"[101m",0
osvt_bg_bright_Green:
        .byte   ESC,"[102m",0
osvt_bg_bright_Yellow:
        .byte   ESC,"[103m",0
osvt_bg_bright_Blue:
        .byte   ESC,"[104m",0
osvt_bg_bright_Magenta:
        .byte   ESC,"[105m",0
osvt_bg_bright_Cyan:
        .byte   ESC,"[106m",0
osvt_bg_bright_White:
        .byte   ESC,"[107m",0
        endif
