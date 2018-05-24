          .include "math.h"
          .include "zp.h"

          .code

.proc     mult16
          ; test first op
          lda #$80
          and wi + 1
          sta i ; store result
          beq next

          ; convert to pos if neg
          lda wi
          eor #$ff
          clc
          adc #1
          sta wi
          lda wi + 1
          eor #$ff
          adc #0
          sta wi + 1

          ; test next op
next:     lda #$80
          and wj + 1
          beq rsin

          ; convert to pos if neg
          tax
          lda wj
          eor #$ff
          clc
          adc #1
          sta wj
          lda wj + 1
          eor #$ff
          adc #0
          sta wj + 1
          txa

          ; determine sign of result
rsin:     eor i
          sta i

          jsr umult16
          lda i
          beq return

          ; convert to neg if needed
          lda wk
          eor #$ff
          clc
          adc #1
          sta wk
          lda wk + 1
          eor #$ff
          adc #0
          sta wk + 1

return:   rts
          .endproc

; umult16 multiplies two 16 bit integers
; input args are wi and wj
; 16 bit return value to wk
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

.proc     umult16
          ;result is calculated into 4 bytes,
          ; from msb - reg a, k, wk + 1, wk
          lda #0      ;Initialize result to 0
          sta k
          ldx #16     ;There are 16 bits in wj
L1:       lsr wj + 1  ;Get low bit of wj
          ror wj
          bcc L2      ;0 or 1?
          tay
          clc         ;If 1, add wk (hi byte of wk is in reg a)
          lda wi
          adc k
          sta k
          tya
          adc wi + 1
L2:       ror         ;"Stairstep" shift (catching carry from add)
          ror k
          ror wk + 1
          ror wk
          dex
          bne L1
          rts
          .endproc

; div16 divides two 16 bit integers
; input args are wi and wj
; return value to wi and remainder to wk
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

.proc     div16
          lda #0      ;Initialize wk to 0
          sta wk
          sta wk + 1
          ldx #16     ;There are 16 bits in wi
L1:       asl wi      ;Shift hi bit of wi into wk
          rol wi + 1
          rol wk
          rol wk + 1
          lda wk
          sec         ;Trial subtraction
          sbc wj
          tay
          lda wk + 1
          sbc wj + 1
          bcc L2      ;Did subtraction succeed?
          sta wk + 1  ;If yes, save it
          sty wk
          inc wi      ;and record a 1 in the quotient
L2:       dex
          bne L1
          rts
          .endproc
