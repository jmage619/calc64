chrout     =$ffd2
chrin      =$ffcf

          .(
          .word $0801
          *=$0801
          .byte $0c, $08, $0a, $00, $9e, $20
          .byte $34, $30, $39, $36, $00, $00
          .byte $00
          .dsb $1000 - *

          ; print prompt
          ldx #0
ploop     lda prompt,x
          jsr chrout
          inx
          cpx #7
          bne ploop

          ; get number from user
          ldy #$00
rloop     jsr chrin
          and #$0F
          sta input,y
          iny
          cmp #$0d
          bne rloop

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

          rts

prompt    .byte "input: "
coef      .byte 1, 10, 100

input     .byte $00, $00, $00, $00, $00
in_pos    .byte $00
coef_pos  .byte $00
data8     .byte $00
data      .word $0000
          .)

; mult8 multiplies two 8 bit integers
; input args are reg x and y
; return value to reg a
; a,y are modified

mult8     .(
          lda #0
          sta $03 ; return val
          stx $02 ; input a

shift_b   tya
          beq return
          lsr
          tay

          bcs accum

shift_a   asl $02
          jmp shift_b

return    lda $03
          rts

accum     lda $03
          clc
          adc $02
          sta $03
          jmp shift_a
          .)

; div8 divides two 8 bit integers
; input args are reg x and y
; return value to reg a and remainder to x
; a,x,y are modified

div8      .(
          lda #0
          sta ret_val
          stx input_a

          tya

          ldy #0

shift_max iny
          clc
          asl
          bcc shift_max

          ror

next_digit
          asl ret_val
          cmp input_a
          bcs check_eq

eq        inc ret_val

          pha
          lda input_a
          tsx
          sec
          sbc $0100+1,x
          sta input_a
          pla

          jmp continue

check_eq  beq eq

continue  lsr
          dey
          bne next_digit

          ldx input_a
          lda ret_val
          rts

input_a   .byte 0
ret_val   .byte 0
          .)
