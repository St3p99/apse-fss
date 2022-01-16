%include 'sseutils64.nasm'

; CALCOLA BARICENTRO

section .data
    dim		equ		8       ; dimensione operandi double (8byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2

section .bss
    ; DEBUG
    ; alignb 32
    ; m resq p

section .text
    global baricentro_asm_omp

	; baricentro_asm(
	; 	input->x,  ; intero RDI (eax)
	; 	input->np, ; intero RSI (edi)
	; 	input->d+input->padding_d, ; intero RDX (edx)
	; 	pesi, ; intero RCX (esi)
	; 	baricentro, ; intero R8 (esi)
	; 	&peso_tot_cur ;intero R9
	; );
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

baricentro_asm_omp: 
    start

    ; mov eax, [ebp+input_x]	; indirizzo matrice x
	; mov edx, [ebp+input_d] 
    ; mov esi, [ebp+baricentro] ; esi <- indirizzo vettore baricentro

; azzera baricentro
    vxorpd ymm0, ymm0, ymm0
    mov rax, 0
    mov r10, rdx
ciclo_azzera_bar_8: 
    cmp r10, p*UNROLL_COORDINATE
    jb  fine_ciclo_azzera_bar_8 ; jb salta se minore senza segno ;jl salta con segno
    
    vmovapd [r8+rax], ymm0
    vmovapd [r8+rax+p*dim], ymm0
    
    add rax, p*dim*UNROLL_COORDINATE
    
    sub r10, p*UNROLL_COORDINATE
    jmp ciclo_azzera_bar_8
fine_ciclo_azzera_bar_8:
    cmp r10, zero
    je fine_ciclo_azzera_bar ;je senza segno

    vmovapd [r8+rax], ymm0
fine_ciclo_azzera_bar:

    vxorpd   ymm6,   ymm6
    
    imul   rdx,    dim        ; input_d*dim
    mov     rax,    UNROLL_PESCI          ; pesce i = 0

    ; rdi <- matrice x
    ; rax <- pesce i-esimo
    ; r10 <- coordinata j-esima
    ; rdx <- d*dim
    ; rsi <- np
    ; rcx <- vettore pesi 
    ; r8  <- baricentro
for_pesci:
    cmp     rax, rsi ; pesce+4 > n_pesci
    jg      fine_for_pesci

    vmovapd  ymm5,   [rcx+rax*dim-UNROLL_PESCI*dim]        ; [wi, wi+1, wi+2, wi+3]
    
    vaddpd   ymm6,   ymm5             ; somma parziale pesi
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
        vpermilps   ymm2, ymm5, 11101110b
        vperm2f128  ymm2, ymm2, ymm2, 00000000b
for_blocco_coordinate_2:
        cmp     r10,   rdx                 ; if( i+8 > n_coordinate )
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
        add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
        vpermilps   ymm2, ymm5, 01000100b
        vperm2f128  ymm2, ymm2, ymm2, 00010001b
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
        mov     r10,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
        vpermilps   ymm2, ymm5, 11101110b
        vperm2f128  ymm2, ymm2, ymm2, 00010001b
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
    add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
    add     rax, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    sub rax, UNROLL_PESCI
    cmp rax, rsi
    je  next_div
    
    vmovapd  ymm5,   [rcx+rax*dim]        ; [wi, wi+1, wi+2, wi+3]
    vaddpd   ymm6,   ymm5             ; somma parziale pesi
for_pesce:
    vmovsd  xmm2,   [rcx+rax*dim]        ; [wi, wi+1, wi+2, wi+3]
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
    add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
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
    vdivpd  ymm1,  ymm6
    vmovapd [r8+p*dim], ymm1
    
    add r8,  p*dim*UNROLL_COORDINATE
    sub rdx,  p*dim*UNROLL_COORDINATE

    jmp for_div_8
last_div:
    cmp rdx, zero
    je aggiorna_peso_tot_corrente ;je senza segno

    vmovapd ymm0, [r8]
    vdivpd ymm0, ymm6
    vmovapd [r8], ymm0

aggiorna_peso_tot_corrente:
    vmovsd [r9], xmm6
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro