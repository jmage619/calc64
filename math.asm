          .include "zp.h"

          .code

; umult16 multiplies two 16 bit integers
; input args are wi and wj
; 16 bit return value to wk
; a,x,y are modified
; taken from:
; http://www.llx.com/~nparker/a2/mult.html

umult16:  .scope
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
          .endscope
