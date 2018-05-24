          .include "math.inc"

          .include "zp.asm"

          .code

chrout    = $ffd2
chrin     = $ffcf

loop:     lda #0

          ldx #0
clear:    sta input,x
          inx
          cpx #24
          bne clear

          ; print prompt
          ldx #0
prompt:   lda pstr,x
          jsr chrout
          inx
          cpx #7
          bne prompt

          ; get number from user
          ldy #$00
read:     jsr chrin
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
          lda wl
          sta tmp16
          lda wl + 1
          sta tmp16 + 1

          dey ; skip * char

          ; get 1st operand
          jsr parse_num
          lda wl
          sta wi
          lda wl + 1
          sta wi + 1

          ; perform multiplication
          lda tmp16
          sta wj
          lda tmp16 + 1
          sta wj + 1

          jsr mult16

          jsr print16

          ; print new line
          lda #$0d
          jsr chrout

          jmp loop



.proc     parse_num
          ldx #0
          stx wl
          stx wl + 1
          stx pflags
next_digit:
          lda coef,x
          sta wi
          inx
          lda coef,x
          sta wi + 1
          lda input,y
          cmp #$2a
          beq return

          ; if minus sign flip
          ; otherwise assume is a number
          cmp #$2d
          bne get_num
          lda wl
          eor #$ff
          clc
          adc #1
          sta wl
          lda wl + 1
          eor #$ff
          adc #0
          sta wl + 1

          jmp next

get_num:  and #$0F
          sta wj
          lda #0
          sta wj + 1
          sty in_pos
          stx coef_pos
          jsr umult16

          lda wl
          clc
          adc wk
          sta wl
          lda wl + 1
          adc wk + 1
          sta wl + 1

          ldy in_pos
          ldx coef_pos
next:     inx
          dey
          bpl next_digit

return:   rts
          .endproc

.proc     print16
          ; special case just print 0 if 0
          lda wk
          bne chk_n
          lda wk + 1
          bne chk_n
          lda #$30
          jsr chrout
          rts

chk_n:    lda #$80
          bit wk + 1
          beq init

          ; if negative, make positive and print - sign
          lda wk
          eor #$ff
          clc
          adc #1
          sta wk
          lda wk + 1
          eor #$ff
          adc #0
          sta wk + 1

          lda #$2d
          jsr chrout

init:     ldx #9
          lda #0
          sta i
next_digit:
          lda wk
          sta wi
          lda wk + 1
          sta wi + 1
          lda coef,x
          sta wj + 1
          dex
          lda coef,x
          sta wj
          stx coef_pos
          jsr div16
          lda wi
          beq chk_z
          ldy #1
          sty i

print:    ora #$30
          jsr chrout
next:     ldx coef_pos
          dex
          bpl next_digit
          rts

chk_z:    ldy i
          beq next
          jmp print
          .endproc

          .rodata
pstr:     .byte "input: "
coef:     .word 1,10,100,1000,10000

          .bss
input:    .res 24, $00
