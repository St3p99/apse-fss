%include 'sseutils64.nasm'

section .data
    dim                     equ     8
    p                       equ     4
    UNROLL_COORDINATE       equ     2

section .bss
    alignb 32
    m resq p

section .text
    global calcola_val_f_asm_omp

    msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl
    
    ; input_x    -> RDI
    ; input_d    -> rsi
    ; vector_c   -> rdx
    ; ret_x_2    -> rcx
    ; ret_c_x    -> r8

calcola_val_f_asm_omp:
    start
    
    imul rsi, dim

    vxorpd ymm4,     ymm4
    vxorpd ymm5,     ymm5
    vxorpd ymm6,     ymm6
    vxorpd ymm7,     ymm7
    
    mov R10,  p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8:
    cmp  R10, rsi
    jg  fine_for_blocco_coordinate_8

    vmovapd  ymm0,   [RDI+R10-p*dim*UNROLL_COORDINATE]   ;x[x0,x1,x2,x3]
    vmovapd  ymm1,   [RDI+R10-p*dim]                     ;x[x4,x5,x6,x7]

    vmovapd  ymm2,   [rdx+R10-p*dim*UNROLL_COORDINATE]    ;c[c0,c1,c2,c3]
    vmovapd  ymm3,   [rdx+R10-p*dim]                      ;c[c4,c5,c6,c7]

    vmulpd ymm2,     ymm0 ;c*x
    vmulpd ymm3,     ymm1

    vmulpd ymm0,     ymm0 ;x^2
    vmulpd ymm1,     ymm1

    vaddpd ymm4,     ymm2 ;ADD C*X 0..3
    vaddpd ymm5,     ymm3 ;ADD C*X 4..7

    vaddpd ymm6,     ymm0 ;ADD X^2 0..3
    vaddpd ymm7,     ymm1 ;ADD X^2 4..7

    add R10, p*dim*UNROLL_COORDINATE
    jmp for_blocco_coordinate_8
fine_for_blocco_coordinate_8:
    sub R10, p*dim*UNROLL_COORDINATE
    cmp R10, rsi
    je  fine
;blocco_coordinate_extra:
    vmovapd  ymm0,   [RDI+R10] ; xj
    vmovapd  ymm1,   [rdx+R10] ; cj

    vmulpd   ymm1,   ymm0
    vmulpd   ymm0,   ymm0

    vaddpd   ymm4,   ymm1
    vaddpd   ymm6,   ymm0

fine:
    vaddpd ymm4, ymm5
	VPERM2F128 ymm15, ymm4, ymm4, 00000001b
	vhaddpd ymm4, ymm15, ymm4
	vhaddpd ymm4, ymm4, ymm4

    vaddpd ymm6, ymm7
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

    vmovsd [r8],    xmm4
    vmovsd [rcx],    xmm6
return:
    stop