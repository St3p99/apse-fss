%include 'sseutils64.nasm'


section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI    		equ		4
    UNROLL_COORDINATE		equ		2
    
    align 32
    v_meno_uno dq -1.0, -1.0, -1.0, -1.0

section .bss
    ;DEBUG
    ; alignb 32
    ; m resq p

section .text
    global mov_volitivo_asm
    
    vector_r    equ     16
    
    ;DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

mov_volitivo_asm: 
    start

    ; mov_volitivo_asm(
    ;     input->x,             RDI
    ;     input->np,            RSI
    ;     input->d,             RDX
    ;     input->padding_d,     RCX
    ;     input->stepvol,       xmm0
	; 	  baricentro,           R8
    ;     direzione,            xmm1
    ;     &(input->r[ind_r])    R9
    ; );

    imul rdx, dim ; d*dim
    imul rcx, dim ; padding*dim
    add  rcx, rdx ; (d+padding)*dim
    
    vmulsd xmm0, xmm1 ; direzione*stepvol
    ; ymm0 <- [ ?, ?, ?,  stepvol*direzione]
    vpermilps   ymm0, ymm0, 01000100b
    ; ymm0 <- [ ?, ?, stepvol*direzione, stepvol*direzione]
    vperm2f128  ymm0, ymm0, ymm0, 00000000b
    ; ymm0 <- [stepvol*direzione, stepvol*direzione, stepvol*direzione, stepvol*direzione]
    vmulpd  ymm0, [v_meno_uno]
    ; ymm0 <- [-stepvol*direzione, -stepvol*direzione, -stepvol*direzione, -stepvol*direzione]
for_pesci:
    cmp     rsi, UNROLL_PESCI ; pesce i-esimo < 0
    jl      fine_for_pesci

    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vxorpd   ymm2,   ymm2 ; azzera ymm2 (accumuliamo somma distanza)
    vxorpd   ymm3,   ymm3 ; azzera ymm3 (accumuliamo somma distanza)
for_distanza:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        vmovapd ymm1, [rdi+r10-p*dim]                    ; x 0..3

        vsubpd ymm7,  [r8+r10-p*dim*UNROLL_COORDINATE]     
        vsubpd ymm1,  [r8+r10-p*dim]

        vmulpd  ymm7, ymm7
        vmulpd  ymm1, ymm1

        vaddpd  ymm2, ymm7

        vaddpd  ymm3, ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza
fine_for_distanza:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_coordinate
for_sing_distanza:
    vmovsd xmm7, [rdi+r10]    
    vsubsd xmm7, [r8+r10]     
    vmulsd xmm7, xmm7
    ; xmm7 -> [0, 0, 0, valore] dato che la mov azzera il resto di xmm7
    ; quindi possiamo fare la add packed tra ymm2 e ymm7
    vaddpd ymm2, ymm7  

    add r10, dim
    cmp r10, rdx
    jb  for_sing_distanza
next_coordinate:
    vaddpd  ymm2, ymm3
	VPERM2F128 ymm15, ymm2, ymm2, 00000001b
	vhaddpd ymm2, ymm15, ymm2
	vhaddpd ymm2, ymm2, ymm2
    vsqrtpd ymm2, ymm2 ; distanza euclidea 
   
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata

    vmovupd   ymm5,   [r9]            ; ri
    vpermilps   ymm4, ymm5, 01000100b
    vperm2f128  ymm4, ymm4, ymm4, 00000000b
for_blocco_coordinate:
    cmp     r10,    rdx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate  ;   esci

    vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    ;x 0..3
    vmovapd ymm1, [rdi+r10-p*dim]                      ;x 4..7

    vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]    ;b 0..3
    vmovapd ymm6, [r8+r10-p*dim]                      ;b 4..7

    vsubpd ymm3, ymm7                                  ;b - x (0..3)
    vsubpd ymm6, ymm1                                  ;b - x (4..7)
    
    vdivpd ymm3, ymm2                                  ;[b - x (0..3)]/dist
    vdivpd ymm6, ymm2                                  ;[b - x (4..7)]/dist

    vmulpd ymm3, ymm0                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    vmulpd ymm6, ymm0                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    vmulpd ymm3, ymm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    vmulpd ymm6, ymm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    vaddpd ymm7, ymm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    vaddpd ymm1, ymm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    vmovapd [rdi+r10-p*dim*UNROLL_COORDINATE], ymm7
    vmovapd [rdi+r10-p*dim],                   ymm1

    add     r10,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_2
for_sing_coordinate: 
    vmovsd xmm7, [rdi+r10] ;xij    
    vmovsd xmm3, [r8+r10] ;bj
    vsubsd xmm3, xmm7      ; bj - xij
    vdivsd xmm3, xmm2      ; (bj - xij)/dist
    vmulsd xmm3, xmm0      ; -stepvol*direzione*(bj - xij)/dist
    vmulsd xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    vaddsd xmm7, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    vmovsd [rdi+r10], xmm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_coordinate
next_2:
    add     rdi, rcx              ; indirizzo prossima riga (prossimo pesce)  
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vxorpd   ymm2,   ymm2 ; azzera ymm2 (accumuliamo somma distanza)
    vxorpd   ymm3,   ymm3 ; azzera ymm3 (accumuliamo somma distanza)
for_distanza_2:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_2  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        vmovapd ymm1, [rdi+r10-p*dim]                    ; x 0..3

        vsubpd ymm7,  [r8+r10-p*dim*UNROLL_COORDINATE]     
        vsubpd ymm1,  [r8+r10-p*dim]

        vmulpd  ymm7, ymm7
        vmulpd  ymm1, ymm1

        vaddpd  ymm2, ymm7
        vaddpd  ymm3, ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_2
fine_for_distanza_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_coordinate_2
for_sing_distanza_2:
    vmovsd xmm7, [rdi+r10]    
    vsubsd xmm7, [r8+r10]     
    vmulsd xmm7, xmm7
    vaddpd ymm2, ymm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_distanza_2
next_coordinate_2:
    vaddpd  ymm2, ymm3
	VPERM2F128 ymm15, ymm2, ymm2, 00000001b
	vhaddpd ymm2, ymm15, ymm2
	vhaddpd ymm2, ymm2, ymm2
    
    vsqrtpd ymm2, ymm2 ; distanza euclidea 
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vpermilps   ymm4, ymm5, 11101110b
    vperm2f128  ymm4, ymm4, ymm4, 00000000b
for_blocco_coordinate_2:
    cmp     r10,    rdx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_2  ;   esci

    vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    ;x 0..3
    vmovapd ymm1, [rdi+r10-p*dim]                      ;x 4..7

    vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]    ;b 0..3
    vmovapd ymm6, [r8+r10-p*dim]                      ;b 4..7

    vsubpd ymm3, ymm7                                  ;b - x (0..3)
    vsubpd ymm6, ymm1                                  ;b - x (4..7)
    
    vdivpd ymm3, ymm2                                  ;[b - x (0..3)]/dist
    vdivpd ymm6, ymm2                                  ;[b - x (4..7)]/dist

    vmulpd ymm3, ymm0                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    vmulpd ymm6, ymm0                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    vmulpd ymm3, ymm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    vmulpd ymm6, ymm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    vaddpd ymm7, ymm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    vaddpd ymm1, ymm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    vmovapd [rdi+r10-p*dim*UNROLL_COORDINATE], ymm7
    vmovapd [rdi+r10-p*dim],                   ymm1

    add     r10,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_3
for_sing_coordinate_2: 
    vmovsd xmm7, [rdi+r10] ;xij    
    vmovsd xmm3, [r8+r10] ;bj
    vsubsd xmm3, xmm7      ; bj - xij
    vdivsd xmm3, xmm2      ; (bj - xij)/dist
    vmulsd xmm3, xmm0      ; -stepvol*direzione*(bj - xij)/dist
    vmulsd xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    vaddsd xmm7, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    vmovsd [rdi+r10], xmm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_coordinate_2
next_3:
    add     rdi, rcx              ; indirizzo prossima riga (prossimo pesce)  
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vxorpd   ymm2,   ymm2 ; azzera ymm2 (accumuliamo somma distanza)
    vxorpd   ymm3,   ymm3 ; azzera ymm3 (accumuliamo somma distanza)
for_distanza_3:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_3  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    
        vmovapd ymm1, [rdi+r10-p*dim]                    

        vsubpd ymm7,  [r8+r10-p*dim*UNROLL_COORDINATE]     
        vsubpd ymm1,  [r8+r10-p*dim]

        vmulpd  ymm7, ymm7
        vmulpd  ymm1, ymm1

        vaddpd  ymm2, ymm7
        vaddpd  ymm3, ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_3
fine_for_distanza_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_coordinate_3
for_sing_distanza_3:
    vmovsd xmm7, [rdi+r10]    
    vsubsd xmm7, [r8+r10]     
    vmulsd xmm7, xmm7
    vaddpd ymm2, ymm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_distanza_3
next_coordinate_3:
    vaddpd  ymm2, ymm3
	VPERM2F128 ymm15, ymm2, ymm2, 00000001b
	vhaddpd ymm2, ymm15, ymm2
	vhaddpd ymm2, ymm2, ymm2
    
    vsqrtpd ymm2, ymm2 ; distanza euclidea 
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vpermilps   ymm4, ymm5, 01000100b
    vperm2f128  ymm4, ymm4, ymm4, 00010001b
for_blocco_coordinate_3:
    cmp     r10,    rdx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_3  ;   esci

    vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    ;x 0..3
    vmovapd ymm1, [rdi+r10-p*dim]                      ;x 4..7

    vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]    ;b 0..3
    vmovapd ymm6, [r8+r10-p*dim]                      ;b 4..7

    vsubpd ymm3, ymm7                                  ;b - x (0..3)
    vsubpd ymm6, ymm1                                  ;b - x (4..7)
    
    vdivpd ymm3, ymm2                                  ;[b - x (0..3)]/dist
    vdivpd ymm6, ymm2                                  ;[b - x (4..7)]/dist

    vmulpd ymm3, ymm0                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    vmulpd ymm6, ymm0                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    vmulpd ymm3, ymm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    vmulpd ymm6, ymm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    vaddpd ymm7, ymm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    vaddpd ymm1, ymm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    vmovapd [rdi+r10-p*dim*UNROLL_COORDINATE], ymm7
    vmovapd [rdi+r10-p*dim],                   ymm1

    add     r10,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_4
for_sing_coordinate_3: 
    vmovsd xmm7, [rdi+r10] ;xij    
    vmovsd xmm3, [r8+r10] ;bj
    vsubsd xmm3, xmm7      ; bj - xij
    vdivsd xmm3, xmm2      ; (bj - xij)/dist
    vmulsd xmm3, xmm0      ; -stepvol*direzione*(bj - xij)/dist
    vmulsd xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    vaddsd xmm7, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    vmovsd [rdi+r10], xmm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_coordinate_3
next_4:
    add     rdi, rcx              ; indirizzo prossima riga (prossimo pesce)  
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vxorpd   ymm2,   ymm2 ; azzera ymm2 (accumuliamo somma distanza)
    vxorpd   ymm3,   ymm3 ; azzera ymm3 (accumuliamo somma distanza)
for_distanza_4:
        cmp     r10,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_4  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        vmovapd ymm1, [rdi+r10-p*dim]                    ; x 0..3

        vsubpd ymm7,  [r8+r10-p*dim*UNROLL_COORDINATE]     
        vsubpd ymm1,  [r8+r10-p*dim]

        vmulpd  ymm7, ymm7
        vmulpd  ymm1, ymm1

        vaddpd  ymm2, ymm7
        vaddpd  ymm3, ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_4
fine_for_distanza_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_coordinate_4
for_sing_distanza_4:
    vmovsd xmm7, [rdi+r10]    
    vsubsd xmm7, [r8+r10]     
    vmulsd xmm7, xmm7
    vaddpd ymm2, ymm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_distanza_4
next_coordinate_4:
    vaddpd  ymm2, ymm3
	VPERM2F128 ymm15, ymm2, ymm2, 00000001b
	vhaddpd ymm2, ymm15, ymm2
	vhaddpd ymm2, ymm2, ymm2
    
    vsqrtpd ymm2, ymm2 ; distanza euclidea 
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vpermilps   ymm4, ymm5, 11101110b
    vperm2f128  ymm4, ymm4, ymm4, 00010001b
for_blocco_coordinate_4:
    cmp     r10,    rdx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_4  ;   esci

    vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    ;x 0..3
    vmovapd ymm1, [rdi+r10-p*dim]                      ;x 4..7

    vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]    ;b 0..3
    vmovapd ymm6, [r8+r10-p*dim]                      ;b 4..7

    vsubpd ymm3, ymm7                                  ;b - x (0..3)
    vsubpd ymm6, ymm1                                  ;b - x (4..7)
    
    vdivpd ymm3, ymm2                                  ;[b - x (0..3)]/dist
    vdivpd ymm6, ymm2                                  ;[b - x (4..7)]/dist

    vmulpd ymm3, ymm0                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    vmulpd ymm6, ymm0                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    vmulpd ymm3, ymm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    vmulpd ymm6, ymm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    vaddpd ymm7, ymm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    vaddpd ymm1, ymm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    vmovapd [rdi+r10-p*dim*UNROLL_COORDINATE], ymm7
    vmovapd [rdi+r10-p*dim],                   ymm1

    add     r10,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_pesci
for_sing_coordinate_4: 
    vmovsd xmm7, [rdi+r10] ;xij    
    vmovsd xmm3, [r8+r10] ;bj
    vsubsd xmm3, xmm7      ; bj - xij
    vdivsd xmm3, xmm2      ; (bj - xij)/dist
    vmulsd xmm3, xmm0      ; -stepvol*direzione*(bj - xij)/dist
    vmulsd xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    vaddsd xmm7, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    vmovsd [rdi+r10], xmm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_coordinate_4

next_pesci:    
    add     r9, UNROLL_PESCI*dim ; prossimi random
    add     rdi, rcx              ; indirizzo prossima riga (prossimo pesce)  
    sub     rsi, UNROLL_PESCI
    jmp     for_pesci
fine_for_pesci:
    cmp rsi, 0
    je  return

for_pesce:
    mov     r10, p*dim*UNROLL_COORDINATE

    vxorpd   ymm2,   ymm2 ; azzera ymm2 (accumuliamo somma distanza)
    vxorpd   ymm3,   ymm3 ; azzera ymm3 (accumuliamo somma distanza)
for_distanza_extra:
        cmp     r10,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_extra  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        vmovapd ymm1, [rdi+r10-p*dim]                    ; x 0..3

        vsubpd ymm7,  [r8+r10-p*dim*UNROLL_COORDINATE]     
        vsubpd ymm1,  [r8+r10-p*dim]

        vmulpd  ymm7, ymm7
        vmulpd  ymm1, ymm1

        vaddpd  ymm2, ymm7
        vaddpd  ymm3, ymm1

        add     r10,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_extra
fine_for_distanza_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_coordinate_extra
for_sing_distanza_extra:
    vmovsd xmm7, [rdi+r10]    
    vsubsd xmm7, [r8+r10]     
    vmulsd xmm7, xmm7
    vaddpd ymm2, ymm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_distanza_extra
next_coordinate_extra:
    vaddpd  ymm2, ymm3
	VPERM2F128 ymm15, ymm2, ymm2, 00000001b
	vhaddpd ymm2, ymm15, ymm2
	vhaddpd ymm2, ymm2, ymm2
    
    vsqrtpd ymm2, ymm2 ; distanza euclidea
    
    mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
    vmovsd   xmm4,   [r9]            ; ri
    vpermilps   ymm4, ymm4, 01000100b
    vperm2f128  ymm4, ymm4, ymm4, 00000000b
for_blocco_coordinate_extra:
        cmp     r10,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        vmovapd ymm7, [rdi+r10-p*dim*UNROLL_COORDINATE]    ;x 0..3
        vmovapd ymm1, [rdi+r10-p*dim]                      ;x 4..7    vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]    ;b 0..3
        
        vmovapd ymm3, [r8+r10-p*dim*UNROLL_COORDINATE]                      ;b 4..7
        vmovapd ymm6, [r8+r10-p*dim]                      ;b 4..7

        vsubpd ymm3, ymm7                                  ;b - x (0..3)
        vsubpd ymm6, ymm1                                  ;b - x (4..7)


        vdivpd ymm3, ymm2                                  ;[b - x (0..3)]/dist
        vdivpd ymm6, ymm2                                  ;[b - x (4..7)]/dist
        vmulpd ymm3, ymm0                                  ;-stepvol*direzione*[b - x (0..3)]/dist
        vmulpd ymm6, ymm0                                  ;-stepvol*direzione*[b - x (4..7)]/dist

        vmulpd ymm3, ymm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
        vmulpd ymm6, ymm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

        vaddpd ymm7, ymm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
        vaddpd ymm1, ymm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

        vmovapd [rdi+r10-p*dim*UNROLL_COORDINATE], ymm7
        vmovapd [rdi+r10-p*dim],                   ymm1

        add     r10,    p*dim*UNROLL_COORDINATE

        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je  next_pesce
for_sing_coordinate_extra:
    vmovsd xmm7, [rdi+r10] ;xij    
    vmovsd xmm3, [r8+r10] ;bj
    vsubsd xmm3, xmm7      ; bj - xij
    vdivsd xmm3, xmm2      ; (bj - xij)/dist
    vmulsd xmm3, xmm0      ; -stepvol*direzione*(bj - xij)/dist
    vmulsd xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    vaddsd xmm7, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    vmovsd [rdi+r10], xmm7

    add r10, dim
    cmp r10, rdx
    jb  for_sing_coordinate_extra

next_pesce:
    add     r9, dim              ; prossimo random
    add     rdi, rcx              ; indirizzo prossima riga (prossimo pesce)  
    
    dec     rsi
    cmp     rsi, zero ; pesce+1 > n_pesci
    jg     for_pesce
return:

stop