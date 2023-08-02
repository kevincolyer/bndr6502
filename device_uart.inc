;======================================================================
;  I/O Device Specific Routines
;
;  Two routines are used to communicate with the I/O device.
;
; "Get_Chr" routine will scan the input port for a character.  It will
; return without waiting with the Carry flag CLEAR if no character is
; present or return with the Carry flag SET and the character in the "A"
; register if one was present.
;
; "Put_Chr" routine will write one byte to the output port.  Its alright
; if this routine waits for the port to be ready.  its assumed that the
; character was send upon return from this routine.
;
; Here is an example of the routines used for a standard 6551 ACIA.
; You would call the ACIA_Init prior to running the xmodem transfer
; routine.



ACIA_Data       = ACIA0+$0000   ; Adjust these addresses to point
ACIA_Status     = ACIA0+$0001   ; to YOUR 6551!
ACIA_Command    = ACIA0+$0002   ;
ACIA_Control    = ACIA0+$0003   ;

ACIA_Init:                      ;
        lda     #$1F            ; 0 10 1 1111  1 stop bit / 8 bits / baud rate / 19200
        sta     ACIA_Control    ; control reg
        lda     #$0B            ; 00001011  odd parity rcvd / parity enabled / echo off / rts low irq off / irq disabled / dtr active low
        sta     ACIA_Command    ; command reg
        rts                     ; done

        ;
        ; input chr from ACIA (no waiting)
        ; Pereserves x and y
k_ACIA_getc:
Get_Chr:
        clc                     ; clear = no chr present
        lda     ACIA_Status     ; get Serial port status
        and     #$08            ; mask rcvr full bit
        beq     .Get_Chr2       ; if not chr, done
        lda     ACIA_Data       ; else get chr
        sec                     ; and set the Carry Flag
.Get_Chr2:
        rts                     ; done
        ;
        ; output to OutPut Port
        ;
k_ACIA_putc:
Put_Chr:
        pha                     ; save registers
.Put_Chr1:
        lda     ACIA_Status     ; serial port status
        and     #$10            ; is tx buffer empty
        beq     .Put_Chr1       ; no, go back and test it again
        pla                     ; yes, get chr to send
        sta     ACIA_Data       ; put character to Port
        rts                     ; done
