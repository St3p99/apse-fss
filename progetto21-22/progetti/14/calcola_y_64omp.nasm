%include 'sseutils64.nasm'

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    meno_uno equ    -1
    tre     equ     3
    UNROLL_COORDINATE		equ		2
    align 32
    v_uno dq 1.0, 1.0, 1.0, 1.0
    align 32
    v_due dq 2.0, 2.0, 2.0, 2.0

section .bss
    ; DEBUG
    ; alignb 32
    ; m resq p

section .text
    global calcola_y_asm_omp
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

calcola_y_asm_omp: 
    start
    ; calcola_y_asm(
    ;     input->x,     RDI
    ;     y,            RSI
    ;     n_coordinate, RDX
    ;     copy_stepind, xmm0 (QUINDI ANCHE YMM0)
    ;     &(input->r[*ind_r]) rcx
    ; )

    imul   rdx,    dim        ; input_d*dim
    
    vpermilps   ymm7, ymm0, 01000100b
    vperm2f128  ymm7, ymm7, ymm7, 00000000b

    vmovapd ymm6, [v_due]
    vmovapd ymm5, [v_uno]


    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [rcx]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        
        vmovupd  ymm3,   [rcx+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5        

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,   p*dim*UNROLL_COORDINATE
        add     rcx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  return 
for_sing_coordinate:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [rcx]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add rcx, dim
    cmp r10, rdx
    jb  for_sing_coordinate
return:
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro