.word $0801
*=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00
.dsb $1000 - *

chrout = $ffd2
chrin = $ffcf

; print prompt
ldx #0
ploop lda prompt,x
jsr chrout
inx
cpx #7
bne ploop

; get number from user
ldy #$00
rloop jsr chrin
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
next_digit lda coef,x
stx coef_pos
tax
lda input,y
sty in_len
tay

jsr mult8
clc
adc data8
sta data8
ldx coef_pos
ldy in_len
inx
dey
bpl next_digit

rts

; mult8 multiplies to 8 bit integers
; input args are x and y registers
; return value to a register
; a,y are modified
mult8
.(
input_a = scratch
ret_val = scratch + 1
lda #0
sta ret_val
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
coef .byte 1, 10, 100

scratch .byte $00, $00

input .byte $00, $00, $00, $00, $00
in_len .byte $00
coef_pos .byte $00
data8 .byte $00
data .word $0000
