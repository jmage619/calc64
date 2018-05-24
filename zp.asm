          .zeropage

; lowest zp vars for leaf subroutines
i         = $02
j         = i + $01
k         = i + $02

; word size zp vars
wi        = $10
wj        = wi + $02
wk        = wi + $04
wl        = wi + $06

; global zp vars
in_pos    = $20
coef_pos  = in_pos + $01
tmp16     = in_pos + $02
pflags    = in_pos + $04
