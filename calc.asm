chrout    =$ffd2
chrin     =$ffcf

; lowest zp vars for leaf subroutines

a         = $02
b         = a + $01
c         = a + $02

; word size zp vars
wa        = $10
wb        = wa + $02
wc        = wa + $04
wd        = wa + $06

; zp vars for main

in_pos    = $20
coef_pos  = in_pos + $01

          .(
          .word $0801
          *=$0801
          .byte $0c, $08, $0a, $00, $9e, $20
          .byte $34, $30, $39, $36, $00, $00
          .byte $00
          .dsb $1000 - *

loop      lda #0

          ldx #0
clear     sta input,x
          inx
          cpx #20
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
          sta input,y
          iny
          cmp #$0d
          bne read

          ; print new line
          lda #$0d
          jsr chrout

          ; set y to last digit index, parsing input
          ; backwards to convert decimcal chars to words
          dey
          dey

          ; get 2nd operand
          jsr parse_num
          lda wd
          sta tmp16
          lda wd + 1
          sta tmp16 + 1

          dey ; skip * char

          ; get 1st operand
          jsr parse_num
          lda wd
          sta wa
          lda wd + 1
          sta wa + 1

          ; perform multiplication
          lda tmp16
          sta wb
          lda tmp16 + 1
          sta wb + 1

          jsr mult16

          rts

;          ldx #$00
;
;          ; loop digits and aggregate
;          ; value into data8
;next_digit
;          lda coef,x
;          tax
;          lda input,y
;          sty in_pos
;          tay
;
;          jsr mult8
;          clc
;          adc data8
;          sta data8
;          ldx coef_pos
;          ldy in_pos
;          inx
;          dey
;          bpl next_digit
;
;          ; print parsed number
;          tax
;          ldy #100
;          jsr div8
;          ora #$30
;          jsr chrout
;          and #$0F
;
;          ldy #10
;          jsr div8
;          ora #$30
;          jsr chrout
;          and #$0F
;
;          txa
;          ora #$30
;          jsr chrout
;
;          lda #$0d
;          jsr chrout

          jmp loop

pstr      .byte "input: "
+coef      .word 1,10,100,1000,10000

+input     .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
tmp16      .word 0
result     .word 0
;data8     .byte $00
;data      .word $0000
          .)

parse_num .(
          ldx #0
          stx wd
          stx wd + 1
next_digit
          lda coef,x
          sta wa
          inx
          lda coef,x
          sta wa + 1
          lda input,y
          cmp #$2a
          beq return

          and #$0F
          sta wb
          lda #0
          sta wb + 1
          sty in_pos
          stx coef_pos
          jsr mult16

          lda wd
          clc
          adc wc
          sta wd
          lda wd + 1
          adc wc + 1
          sta wd + 1

          ldy in_pos
          ldx coef_pos
          inx
          dey
          bpl next_digit

return    rts
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

; mult16 multiplies two 16 bit integers
; input args are wa and wb
; 16 bit return value to wc
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

mult16    .(
          ;result is calculated into 4 bytes,
          ; from msb - reg a, c, wc + 1, wc
          lda #0      ;Initialize result to 0
          sta c
          ldx #16     ;There are 16 bits in wb
L1        lsr wb + 1  ;Get low bit of wb
          ror wb
          bcc L2      ;0 or 1?
          tay
          clc         ;If 1, add wa (hi byte of wc is in reg a)
          lda wa
          adc c
          sta c
          tya
          adc wa + 1
L2        ror         ;"Stairstep" shift (catching carry from add)
          ror c
          ror wc + 1
          ror wc
          dex
          bne L1
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

; div16 divides two 16 bit integers
; input args are wa and wb
; return value to wa and remainder to wc
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

div16     .(
          lda #0      ;Initialize wc to 0
          sta wc
          sta wc + 1
          ldx #16     ;There are 16 bits in wa
L1        asl wa      ;Shift hi bit of wa into wc
          rol wa + 1
          rol wc
          rol wc + 1
          lda wc
          sec         ;Trial subtraction
          sbc wb
          tay
          lda wc + 1
          sbc wb + 1
          bcc L2      ;Did subtraction succeed?
          sta wc + 1  ;If yes, save it
          sty wc
          inc wa      ;and record a 1 in the quotient
L2        dex
          bne L1
          rts
          .)
