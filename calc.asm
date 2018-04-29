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

          ; print parsed number
          tax
          ldy #100
          jsr div8
          eor #$30
          jsr chrout
          and #$0F

          ldy #10
          jsr div8
          eor #$30
          jsr chrout
          and #$0F

          txa
          eor #$30
          jsr chrout

          rts

prompt    .byte "input: "
coef      .byte 1, 10, 100

input     .byte $00, $00, $00, $00, $00
data8     .byte $00
data      .word $0000
          .)

; mult8 multiplies two 8 bit integers
; input args are reg x and y
; return value to reg a
; a,y are modified

mult8     .(
          lda #0
          sta c ; return val
          stx a ; input a

shift_b   tya
          beq return
          lsr
          tay

          bcs accum

shift_a   asl a
          jmp shift_b

return    lda c
          rts

accum     lda c
          clc
          adc a
          sta c
          jmp shift_a
          .)

; div8 divides two 8 bit integers
; input args are reg x and y
; return value to reg a and remainder to x
; a,x,y are modified

div8      .(
          lda #0
          sta c ; return val
          stx a ; input a

          tya

          ldy #0

shift_max iny
          clc
          asl
          bcc shift_max

          ror

next_digit
          asl c
          cmp a
          bcs check_eq

eq        inc c

          ; tmp store val b to subtract it from a
          sta b
          lda a
          sec
          sbc b
          sta a ; store result
          lda b ; reload val b

          jmp continue

check_eq  beq eq

continue  lsr
          dey
          bne next_digit

          ldx a
          lda c
          rts
          .)
