%include 'sseutils64.nasm'

section .data
    dim                     equ     8
    p                       equ     4
    UNROLL_COORDINATE       equ     2
    UNROLL_PESCI            equ     4

section .bss
    alignb 32
	np_meno_unroll resd 1
    alignb 32
    m resq p

section .text
    global calcola_val_f_asm

    msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl
    
    ; input_x    -> RDI
    ; input_np   -> RSI
    ; input_d    -> RDX
    ; vector_c   -> RCX
    ; ret_x_2    -> R8
    ; ret_c_x    -> R9

calcola_val_f_asm:
    start
    
    mov r11, RSI
    sub r11, UNROLL_PESCI ; np-4
    
    xor  RSI, RSI ; contatore pesce corrente

    imul rdx, dim
for_pesci:
    cmp RSI,  r11 ;i <= np-4
    jg fine_for_pesci ;i > np-4 
    
    vxorpd ymm4,     ymm4
    vxorpd ymm5,     ymm5
    vxorpd ymm6,     ymm6
    vxorpd ymm7,     ymm7
    
    mov r10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8:
    cmp  r10, RDX
    jg  fine_for_blocco_coordinate_8

    vmovapd  ymm0,   [RDI+r10-p*dim*UNROLL_COORDINATE]                           ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+r10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [RCX+r10-p*dim*UNROLL_COORDINATE]                            ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [RCX+r10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7

    add r10, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8
fine_for_blocco_coordinate_8:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_2
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+r10] ; xj
    vmovapd  ymm1,   [RCX+r10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0
next_2:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r9+RSI*dim],    xmm4
    vmovsd [r8+RSI*dim],    xmm6
    
    inc RSI
    add     rdi,    rdx        ; prossima riga

    vxorpd ymm4,ymm4
    vxorpd ymm5,ymm5
    vxorpd ymm6,ymm6
    vxorpd ymm7,ymm7

    mov r10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8_2:
    cmp  r10, RDX
    jg fine_for_blocco_coordinate_8_2


    vmovapd  ymm0,   [RDI+r10-p*dim*UNROLL_COORDINATE]                           ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+r10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [RCX+r10-p*dim*UNROLL_COORDINATE]                            ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [RCX+r10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7
    
    add r10, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_2
fine_for_blocco_coordinate_8_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_3
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+r10] ; xj
    vmovapd  ymm1,   [RCX+r10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0
next_3:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r9+RSI*dim],    xmm4
    vmovsd [r8+RSI*dim],    xmm6
    
    inc RSI
    add     rdi,    rdx        ; prossima riga

    vxorpd ymm4,ymm4
    vxorpd ymm5,ymm5
    vxorpd ymm6,ymm6
    vxorpd ymm7,ymm7
    
    mov r10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8_3:
    cmp  r10, RDX
    jg fine_for_blocco_coordinate_8_3


    vmovapd  ymm0,   [RDI+r10-p*dim*UNROLL_COORDINATE]                           ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+r10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [RCX+r10-p*dim*UNROLL_COORDINATE]                            ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [RCX+r10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7

    add r10, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_3
fine_for_blocco_coordinate_8_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_4
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+r10] ; xj
    vmovapd  ymm1,   [RCX+r10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0
next_4:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r9+RSI*dim],    xmm4
    vmovsd [r8+RSI*dim],    xmm6
    
    inc RSI
    add     rdi,    rdx        ; prossima riga

    vxorpd ymm4,ymm4
    vxorpd ymm5,ymm5
    vxorpd ymm6,ymm6
    vxorpd ymm7,ymm7
    mov r10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8_4:
    cmp  r10, RDX
    jg fine_for_blocco_coordinate_8_4


    vmovapd  ymm0,   [RDI+r10-p*dim*UNROLL_COORDINATE]                           ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+r10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [RCX+r10-p*dim*UNROLL_COORDINATE]                            ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [RCX+r10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7

    add r10, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_4
fine_for_blocco_coordinate_8_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_pesci
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+r10] ; xj
    vmovapd  ymm1,   [RCX+r10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0
next_pesci:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r9+RSI*dim],    xmm4
    vmovsd [r8+RSI*dim],    xmm6
    
    inc RSI
    add     rdi,    rdx        ; prossima riga
    
    jmp     for_pesci
fine_for_pesci:
    add r11, UNROLL_PESCI

for_pesce_extra:
    cmp RSI, r11
    je  return

    vxorpd ymm4,ymm4
    vxorpd ymm5,ymm5
    vxorpd ymm6,ymm6
    vxorpd ymm7,ymm7

    mov r10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8_extra:
    cmp  r10, RDX
    jg fine_for_blocco_coordinate_8_extra

    vmovapd  ymm0,   [RDI+r10-p*dim*UNROLL_COORDINATE]                           ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+r10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [RCX+r10-p*dim*UNROLL_COORDINATE]                            ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [RCX+r10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7

    add r10, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_extra
fine_for_blocco_coordinate_8_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_extra
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+r10] ; xj
    vmovapd  ymm1,   [RCX+r10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0
next_extra:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r9+RSI*dim],    xmm4
    vmovsd [r8+RSI*dim],    xmm6
    
    inc RSI
    add     rdi,    rdx        ; prossima riga
    
    jmp for_pesce_extra
return:

stop