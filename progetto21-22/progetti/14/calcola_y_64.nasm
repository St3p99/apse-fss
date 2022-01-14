%include 'sseutils64.nasm'

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    meno_uno equ    -1
    tre     equ     3
    UNROLL_PESCI        	equ		4
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
    global calcola_y_asm
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

calcola_y_asm: 
    start
    ; calcola_y_asm(
    ;     input->x,     RDI
    ;     y,            RSI
    ;     n_pesci,      RDX
    ;     n_coordinate, RCX
    ;     padding_d,    R8
    ;     copy_stepind, ymm0 (QUINDI ANCHE YMM0)
    ;     &(input->r[*ind_r]) R9
    ; )

    imul   rcx,    dim        ; input_d*dim
    imul   r8,     dim        ; padding*dim
    add    r8, rcx            ; (d+padding)*dim +d
    
    vpermilps   ymm7, ymm0, 01000100b
    vperm2f128  ymm7, ymm7, ymm7, 00000000b

    vmovapd ymm6, [v_due]
    vmovapd ymm5, [v_uno]

for_pesci:
    cmp     rdx, UNROLL_PESCI ; pesce i-esimo < 4
    jl      fine_for_pesci

    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     r10,    rcx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [r9]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        vmovupd  ymm3,   [r9+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5        

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,   p*dim*UNROLL_COORDINATE
        add     r9,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je  next_2 
for_sing_coordinate:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [r9]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add r9, dim
    cmp r10, rcx
    jb  for_sing_coordinate
next_2:    
    ; aggiorna puntatori a pesce successivo
    add     rdi, r8    ; eax += (d+padding)*dim
    add     rsi, r8    ; ebx += (d+padding)*dim
        
    mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_2:
        cmp     r10,    rcx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci
        
        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [r9]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        vmovupd  ymm3,   [r9+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        add     r9,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je  next_3
for_sing_coordinate_2:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [r9]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add r9, dim
    cmp r10, rcx
    jb  for_sing_coordinate_2
next_3:
    ; aggiorna puntatori a pesce successivo
    add     rdi, r8    ; eax += (d+padding)*dim
    add     rsi, r8    ; ebx += (d+padding)*dim
        
    mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_3:
        cmp     r10,    rcx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci
        
        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [r9]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        vmovupd  ymm3,   [r9+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        add     r9,    p*dim*UNROLL_COORDINATE

        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je  next_4
for_sing_coordinate_3:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [r9]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add r9, dim
    cmp r10, rcx
    jb  for_sing_coordinate_3
next_4:
    ; aggiorna puntatori a pesce successivo
    add     rdi, r8    ; eax += (d+padding)*dim
    add     rsi, r8    ; ebx += (d+padding)*dim
        
    mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_4:
        cmp     r10,    rcx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [r9]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        vmovupd  ymm3,   [r9+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        add     r9,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je  next_pesci 
for_sing_coordinate_4:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [r9]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add r9, dim
    cmp r10, rcx
    jb  for_sing_coordinate_4
; fine for coordinate
next_pesci:
    ; aggiorna puntatori a pesce successivo
    add     rdi, r8    ; eax += (d+padding)*dim
    add     rsi, r8    ; ebx += (d+padding)*dim
    sub     rdx, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    cmp rdx, 0
    je  return
    
for_pesce:
    mov     r10, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     r10,    rcx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmovupd  ymm2,   [r9]       ; r[0..3]
        vmulpd   ymm2,   ymm6
        vsubpd   ymm2,   ymm5
        vmovupd  ymm3,   [r9+p*dim] ; r[4..7]
        vmulpd   ymm3,   ymm6
        vsubpd   ymm3,   ymm5

        vmulpd   ymm2,   ymm7        ; step_ind*r[0..3]
        vmulpd   ymm3,   ymm7        ; step_ind*r[4..7]

        vaddpd   ymm0,   ymm2        ; y[0..3]
        vaddpd   ymm1,   ymm3        ; y[4..7]
        
        vmovapd [rsi+r10-p*dim*UNROLL_COORDINATE], ymm0
        vmovapd [rsi+r10-p*dim], ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        add     r9,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je  next_pesce
for_sing_coordinate_extra:
    vmovsd  xmm0,   [rdi+r10] ; xij
    vmovsd  xmm2,   [r9]       ; ri
    vmulsd  xmm2, xmm6
    vsubsd  xmm2, xmm5
    
    vmulsd  xmm2, xmm7       ; step_ind*ri
    vaddsd  xmm0, xmm2       ; yij
    
    vmovsd [rsi+r10], xmm0

    add r10, dim
    add r9, dim
    cmp r10, rcx
    jb  for_sing_coordinate_extra
next_pesce:
    ; aggiorna puntatori a pesce precedente
    add     rdi, r8    ; eax -= (d+padding)*dim
    add     rsi, r8    ; ebx -= (d+padding)*dim
    
    dec     rdx
    cmp     rdx, zero 
    jg     for_pesce
return:
    
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro