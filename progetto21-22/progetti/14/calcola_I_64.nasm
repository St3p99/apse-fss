%include 'sseutils64.nasm'

; CALCOLA VETTORE I (Movimento istintivo)

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2

section .bss
    ; DEBUG
    ; alignb 32
    ; m resq p

section .text
    global calcola_I_asm

    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

    
calcola_I_asm: 
    start

    ; rdi-> deltax
    ; rsi -> np
    ; rdx -> d+dpadding
    ; rcx -> deltaf
    ; r8 -> I
; azzera vector_i
    vxorpd ymm0, ymm0, ymm0
    mov rax, 0
    mov r10, rdx
ciclo_azzera_vector_i_8: 
    cmp r10, p*UNROLL_COORDINATE
    jb  fine_ciclo_azzera_vector_i_8 ; jb salta se minore senza segno ;jl salta con segno
    
    vmovapd [r8+rax], ymm0
    vmovapd [r8+rax+p*dim], ymm0
    
    add rax, p*dim*UNROLL_COORDINATE
    
    sub r10, p*UNROLL_COORDINATE
    jmp ciclo_azzera_vector_i_8
fine_ciclo_azzera_vector_i_8:
    cmp r10, zero
    je fine_ciclo_azzera_vector_i ;je senza segno

    vmovapd [r8+rax], ymm0
fine_ciclo_azzera_vector_i:

    vxorpd   ymm6,   ymm6
    
    imul   rdx,    dim        ; input_d*dim
    mov    rax,    UNROLL_PESCI          ; pesce i = 0

for_pesci:
    cmp     rax, rsi ; pesce+4 > n_pesci
    jg      fine_for_pesci

    vmovapd  ymm5,   [rcx+rax*dim-UNROLL_PESCI*dim]        ; [deltafi, deltafii+1, deltafii+2, deltafii+3]

    vaddpd   ymm6,   ymm5             ; somma parziale delta_f

    vpermilps   ymm2, ymm5, 01000100b
    vperm2f128  ymm2, ymm2, ymm2, 00000000b
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmulpd   ymm0,   ymm2
        vmulpd   ymm1,   ymm2
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]
        vaddpd ymm3, ymm0
        vmovapd [r8+r10-p*dim*UNROLL_COORDINATE], ymm3
        
        vmovapd ymm4, [r8+r10-p*dim]
        vaddpd ymm4, ymm1
        vmovapd [r8+r10-p*dim], ymm4

        add     r10,    p*dim*UNROLL_COORDINATE

        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_2

    vmovapd ymm0, [rdi+r10]
    vmulpd  ymm0, ymm2

    vmovapd ymm3,      [r8+r10]
    vaddpd  ymm3,      ymm0
    vmovapd [r8+r10], ymm3
next_2:
        mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
        vpermilps   ymm2, ymm5, 11101110b  ; delta_f 1
        vperm2f128  ymm2, ymm2, ymm2, 00000000b; delta_f 1 su tutto ymm2
for_blocco_coordinate_2:
        cmp     r10,  rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmulpd   ymm0,   ymm2
        vmulpd   ymm1,   ymm2
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]
        vaddpd ymm3, ymm0
        vmovapd [r8+r10-p*dim*UNROLL_COORDINATE], ymm3

        vmovapd ymm4, [r8+r10-p*dim]
        vaddpd ymm4, ymm1
        vmovapd [r8+r10-p*dim], ymm4

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_3
    
    vmovapd ymm0, [rdi+r10]
    vmulpd  ymm0, ymm2

    vmovapd ymm3,      [r8+r10]
    vaddpd  ymm3,      ymm0
    vmovapd [r8+r10], ymm3
next_3:
        mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     rdi,    rdx
        vpermilps   ymm2, ymm5, 01000100b  ; delta_f 2
        vperm2f128  ymm2, ymm2, ymm2, 00010001b  ; delta_f 2 su tutto ymm2
for_blocco_coordinate_3:
        cmp     r10,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]
    
        vmulpd   ymm0,   ymm2
        vmulpd   ymm1,   ymm2
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]
        vaddpd ymm3, ymm0
        vmovapd [r8+r10-p*dim*UNROLL_COORDINATE], ymm3
        
        vmovapd ymm4, [r8+r10-p*dim]
        vaddpd ymm4, ymm1
        vmovapd [r8+r10-p*dim], ymm4

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_4
    
    vmovapd ymm0, [rdi+r10]
    vmulpd  ymm0, ymm2

    vmovapd ymm3,      [r8+r10]
    vaddpd  ymm3,      ymm0
    vmovapd [r8+r10], ymm3
next_4:
        mov     r10,    p*dim*UNROLL_COORDINATE          ; coordinata
        add     rdi,    rdx
        vpermilps   ymm2, ymm5, 11101110b  ; delta_f 3
        vperm2f128  ymm2, ymm2, ymm2, 00010001b  ; delta_f 3 su tutto ymm2
for_blocco_coordinate_4:
        cmp     r10,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmulpd   ymm0,   ymm2
        vmulpd   ymm1,   ymm2
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]
        vaddpd ymm3, ymm0
        vmovapd [r8+r10-p*dim*UNROLL_COORDINATE], ymm3
        
        vmovapd ymm4, [r8+r10-p*dim]
        vaddpd ymm4, ymm1
        vmovapd [r8+r10-p*dim], ymm4

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_pesci
    
    vmovapd ymm0, [rdi+r10]
    vmulpd  ymm0, ymm2

    vmovapd ymm3,      [r8+r10]
    vaddpd  ymm3,      ymm0
    vmovapd [r8+r10], ymm3
; fine for coordinate
next_pesci:
    add     rdi,    rdx ; indirizzo riga prossimo pesce
    add     rax, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    sub rax, UNROLL_PESCI
    cmp rax, rsi
    je  next_div
    
    vmovapd  ymm5,   [rcx+rax*dim]        
    vaddpd   ymm6,   ymm5  

for_pesce:
    vmovsd  xmm2,   [rcx+rax*dim]        
    vpermilps   ymm2, ymm2, 01000100b
    vperm2f128  ymm2, ymm2, ymm2, 00000000b

    mov     r10, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     r10,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        vmovapd  ymm0,   [rdi+r10-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r10-p*dim]                   ; [xi+4, ...,      xi+7]

        vmulpd   ymm0,   ymm2
        vmulpd   ymm1,   ymm2
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]
        vaddpd ymm3, ymm0
        vmovapd [r8+r10-p*dim*UNROLL_COORDINATE], ymm3
        
        vmovapd ymm4, [r8+r10-p*dim]
        vaddpd ymm4, ymm1
        vmovapd [r8+r10-p*dim], ymm4

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_pesce
    
    vmovapd ymm0, [rdi+r10]
    vmulpd  ymm0, ymm2

    vmovapd ymm3,      [r8+r10]
    vaddpd  ymm3,      ymm0
    vmovapd [r8+r10], ymm3
next_pesce:
    add     rdi,  rdx ; indirizzo riga prossimo pesce
    add     rax,  1 ; aggiorna contatore pesci
    cmp     rax, rsi ; pesce+1 > n_pesci
    jb      for_pesce

next_div:
	VPERM2F128 ymm15, ymm6, ymm6, 00000001b
	vhaddpd ymm6, ymm15, ymm6
	vhaddpd ymm6, ymm6, ymm6

for_div_8: 
    cmp rdx, p*dim*UNROLL_COORDINATE
    jb  last_div ; jb salta se minore senza segno ;jl salta con segno

    vmovapd ymm0,  [r8]
    vdivpd  ymm0,  ymm6
    vmovapd [r8], ymm0

    vmovapd ymm1,  [r8+p*dim]
    vdivps  ymm1,  ymm6
    vmovapd [r8+p*dim], ymm1
    
    add r8,  p*dim*UNROLL_COORDINATE
    sub rdx,  p*dim*UNROLL_COORDINATE

    jmp for_div_8
last_div:
    cmp rdx, zero
    je return ;je senza segno

    vmovapd ymm0, [r8]
    vdivpd ymm0, ymm6
    vmovapd [r8], ymm0

return:

stop