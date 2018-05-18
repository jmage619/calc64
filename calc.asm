chrout    = $ffd2
chrin     = $ffcf

; lowest zp vars for leaf subroutines
a         = $02
b         = a + $01
c         = a + $02

; word size zp vars
wa        = $10
wb        = wa + $02
wc        = wa + $04
wd        = wa + $06

; global zp vars
in_pos    = $20
coef_pos  = in_pos + $01
tmp16     = in_pos + $02
pflags    = in_pos + $04

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
          cpx #24
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

          jsr print16

          ; print new line
          lda #$0d
          jsr chrout

          jmp loop

pstr      .byte "input: "
+coef     .word 1,10,100,1000,10000

+input    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
          .)
parse_num .(
          ldx #0
          stx wd
          stx wd + 1
          stx pflags
next_digit
          lda coef,x
          sta wa
          inx
          lda coef,x
          sta wa + 1
          lda input,y
          cmp #$2a
          beq return

          ; if minus sign flip
          ; otherwise assume is a number
          cmp #$2d
          bne get_num
          lda wd
          eor #$ff
          clc
          adc #1
          sta wd
          lda wd + 1
          eor #$ff
          adc #0
          sta wd + 1

          jmp next

get_num   and #$0F
          sta wb
          lda #0
          sta wb + 1
          sty in_pos
          stx coef_pos
          jsr umult16

          lda wd
          clc
          adc wc
          sta wd
          lda wd + 1
          adc wc + 1
          sta wd + 1

          ldy in_pos
          ldx coef_pos
next      inx
          dey
          bpl next_digit

return    rts
          .)

print16   .(
          lda #$80
          bit wc + 1
          beq init

          ; if negative, make positive and print - sign
          lda wc
          eor #$ff
          clc
          adc #1
          sta wc
          lda wc + 1
          eor #$ff
          adc #0
          sta wc + 1

          lda #$2d
          jsr chrout

init      ldx #9
          lda #0
          sta a
next_digit
          lda wc
          sta wa
          lda wc + 1
          sta wa + 1
          lda coef,x
          sta wb + 1
          dex
          lda coef,x
          sta wb
          stx coef_pos
          jsr div16
          lda wa
          beq chk_z
          ldy #1
          sty a

print     ora #$30
          jsr chrout
iter      ldx coef_pos
          dex
          bpl next_digit
          rts

chk_z     ldy a
          beq iter
          jmp print
          .)

mult16    .(
          ; test first op
          lda #$80
          and wa + 1
          sta a ; store result
          beq next

          ; convert to pos if neg
          lda wa
          eor #$ff
          clc
          adc #1
          sta wa
          lda wa + 1
          eor #$ff
          adc #0
          sta wa + 1

          ; test next op
next      lda #$80
          and wb + 1
          beq rsin

          ; convert to pos if neg
          tax
          lda wb
          eor #$ff
          clc
          adc #1
          sta wb
          lda wb + 1
          eor #$ff
          adc #0
          sta wb + 1
          txa

          ; determine sign of result
rsin      eor a
          sta a

          jsr umult16
          lda a
          beq return

          ; convert to neg if needed
          lda wc
          eor #$ff
          clc
          adc #1
          sta wc
          lda wc + 1
          eor #$ff
          adc #0
          sta wc + 1

return    rts
          .)

; umult16 multiplies two 16 bit integers
; input args are wa and wb
; 16 bit return value to wc
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

umult16    .(
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
