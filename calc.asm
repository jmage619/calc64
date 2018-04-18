.word $0801
*=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00
.dsb $1000 - *

chrout = $ffd2
chrin = $ffcf

;ldx #0
;ploop lda prompt,x
;jsr chrout
;inx
;cpx #7
;bne ploop
;
;ldy #0
;rloop jsr chrin
;and #$3F
;sta input,y
;iny
;cmp #$0d
;bne rloop
;
;lda #$0d
;jsr chrout

ldx #4
ldy #5
jsr mult8

rts

mult8
.(
input_a = scratch
ret_val = scratch + 1
stx input_a

shift_b tya
cmp #$0
beq return
lsr
tay

bcs accum

shift_a asl input_a
jmp shift_b

return lda ret_val
rts

accum lda ret_val
clc
adc input_a
sta ret_val
jmp shift_a
.)

prompt .byte "input: "
coef .byte 100, 10, 1

scratch .byte $00, $00

input .byte $15, $0C, $00, $00, $00
len .byte $00
data .word $0000
