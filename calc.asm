chrout    =$ffd2
chrin     =$ffcf

; lowest zp vars for leaf subroutines

a         =$02
b         = a + $01
c         = a + $02

; zp vars for main

in_pos    =$20
coef_pos  = in_pos + $01

          .(
          .word $0801
          *=$0801
          .byte $0c, $08, $0a, $00, $9e, $20
          .byte $34, $30, $39, $36, $00, $00
          .byte $00
          .dsb $1000 - *

loop      lda #0
          sta data8

          ldx #0
clear     sta input,x
          inx
          cpx #5
          bne clear

          ; print prompt
          ldx #0
prompt    lda pstr,x
          jsr chrout
          inx
          cpx #7
          bne prompt


          ; get number from user
          ldy #$00
read      jsr chrin
          and #$0F
          sta input,y
          iny
          cmp #$0d
          bne read

          ; print new line
          lda #$0d
          jsr chrout

          ; set y to last digit index
          dey
          dey
          ldx #$00

          ; loop digits and aggregate
          ; value into data8
next_digit
          lda coef,x
          stx coef_pos
          tax
          lda input,y
          sty in_pos
          tay

          jsr mult8
          clc
          adc data8
          sta data8
          ldx coef_pos
          ldy in_pos
          inx
          dey
          bpl next_digit

          ; print parsed number
          tax
          ldy #100
          jsr div8
          ora #$30
          jsr chrout
          and #$0F

          ldy #10
          jsr div8
          ora #$30
          jsr chrout
          and #$0F

          txa
          ora #$30
          jsr chrout

          lda #$0d
          jsr chrout

          jmp loop

pstr      .byte "input: "
coef      .byte 1, 10, 100

input     .byte $00, $00, $00, $00, $00
data8     .byte $00
data      .word $0000
          .)

; mult8 multiplies two 8 bit integers
; input args are reg x and y
; return value to reg a
; a,x are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

mult8     .(
          stx a
          sty b
          lda #0       ;Initialize c to 0
          ldx #8       ;There are 8 bits in b
L1        lsr b     ;Get low bit of b
          bcc L2       ;0 or 1?
          clc          ;If 1, add a
          adc a
L2        ror        ;"Stairstep" shift (catching carry from add)
          ror c
          dex
          bne L1
          lda c
          rts
          .)

; div8 divides two 8 bit integers
; input args are reg x and y
; return value to reg a and remainder to x
; a,x are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

div8      .(
          stx a
          sty b
          lda #0      ;Initialize c to 0
          sta c
          ldx #8     ;There are 8 bits in a
L1        asl a    ;Shift hi bit of a into c
          rol c
          lda c
          sec         ;Trial subtraction
          sbc b
          bcc L2      ;Did subtraction succeed?
          sta c     ;If yes, save it
          inc a    ;and record a 1 in the quotient
L2        dex
          bne L1
          lda a
          ldx c
          rts
          .)
