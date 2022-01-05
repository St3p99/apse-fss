%include 'sseutils32.nasm'

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    meno_uno equ    -1
    tre     equ     3
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2
    align 16
    v_uno dd 1.0, 1.0, 1.0, 1.0
    align 16
    v_due dd 2.0, 2.0, 2.0, 2.0
    


section .bss
    ; DEBUG
    ; alignb 16
    ; m resd p

section .text
    global calcola_y_asm

    input_x     equ     8
    matrix_y    equ     12
    input_np    equ     16
    input_d     equ     20
    padding     equ     24
    stepind     equ     28 
    vector_r    equ     32
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

calcola_y_asm: 
    start
    ; eax <- matrice x
    ; ebx <- matrice y
    ; ecx <- coordinata j-esima | padding
    ; edx <- d*dim
    ; edi <- pesce i-esimo (init a np; np--)
    ; esi <- r

    mov eax, [ebp+input_x]	; indirizzo matrice x (init riga ultimo pesce da C)
    mov ebx, [ebp+matrix_y]	; indirizzo matrice y (init riga ultimo pesce da C)
	mov edx, [ebp+input_d]
    imul   edx,    dim        ; input_d*dim
    mov edi, [ebp+input_np]
    mov esi, [ebp+vector_r] ; esi <- indirizzo vettore baricentro
    
    movss  xmm7, [ebp+stepind]
    shufps  xmm7,   xmm7, 00000000b

    movaps xmm6, [v_due]
    movaps xmm5, [v_uno]
    

for_pesci:
    cmp     edi, UNROLL_PESCI ; pesce i-esimo < 4
    jl      fine_for_pesci

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        movups  xmm2,   [esi]       ; r[0..3]
        mulps   xmm2,   xmm6
        subps   xmm2,   xmm5
        movups  xmm3,   [esi+p*dim] ; r[4..7]
        mulps   xmm3,   xmm6
        subps   xmm3,   xmm5

        mulps   xmm2,   xmm7        ; step_ind*r[0..3]
        mulps   xmm3,   xmm7        ; step_ind*r[4..7]

        addps   xmm0,   xmm2        ; y[0..3]
        addps   xmm1,   xmm3        ; y[4..7]
        
        movaps [ebx+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [ebx+ecx-p*dim], xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        add     esi,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_2 
for_sing_coordinate:
    movss  xmm0,   [eax+ecx] ; xij
    movss  xmm2,   [esi]       ; ri
    mulss  xmm2, xmm6
    subss  xmm2, xmm5

    mulss  xmm2,   xmm7       ; step_ind*ri
    addss  xmm0,   xmm2       ; yij
    
    movss [ebx+ecx], xmm0

    add ecx, dim
    add esi, dim
    cmp ecx, edx
    jb  for_sing_coordinate
next_2:
    mov     ecx, [ebp+padding] 
    imul     ecx, dim    ; padding*dim
    ; aggiorna puntatori a pesce precedente
    add     ecx, edx    ;(d+padding)*dim        
    add     eax, ecx    ; eax -= (d+padding)*dim
    add     ebx, ecx    ; ebx -= (d+padding)*dim
        
    mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_2:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci
        
        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        movups  xmm2,   [esi]       ; r[0..3]
        mulps   xmm2,   xmm6
        subps   xmm2,   xmm5
        
        movups  xmm3,   [esi+p*dim] ; r[4..7]
        mulps   xmm3,   xmm6
        subps   xmm3,   xmm5

        mulps   xmm2,   xmm7        ; step_ind*r[0..3]
        mulps   xmm3,   xmm7        ; step_ind*r[4..7]

        addps   xmm0,   xmm2        ; y[0..3]
        addps   xmm1,   xmm3        ; y[4..7]
        
        movaps [ebx+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [ebx+ecx-p*dim], xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        add     esi,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_3
for_sing_coordinate_2:
    movss  xmm0,   [eax+ecx] ; xij
    movss  xmm2,   [esi]       ; ri
    mulss  xmm2, xmm6
    subss  xmm2, xmm5

    mulss  xmm2,   xmm7       ; step_ind*ri
    addss  xmm0,   xmm2       ; yij
    
    movss [ebx+ecx], xmm0

    add ecx, dim
    add esi, dim
    cmp ecx, edx
    jb  for_sing_coordinate_2
next_3:
    mov     ecx, [ebp+padding] 
    imul     ecx, dim    ; padding*dim
    ; aggiorna puntatori a pesce precedente
    add     ecx, edx    ;(d+padding)*dim
    add     eax, ecx    ; eax -= (d+padding)*dim
    add     ebx, ecx    ; ebx -= (d+padding)*dim
        
    mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_3:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci
        
        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        movups  xmm2,   [esi]       ; r[0..3]
        mulps   xmm2,   xmm6
        subps   xmm2,   xmm5
        movups  xmm3,   [esi+p*dim] ; r[4..7]
        mulps   xmm3,   xmm6
        subps   xmm3,   xmm5
        
        mulps   xmm2,   xmm7        ; step_ind*r[0..3]
        mulps   xmm3,   xmm7        ; step_ind*r[4..7]

        addps   xmm0,   xmm2        ; y[0..3]
        addps   xmm1,   xmm3        ; y[4..7]
        
        movaps [ebx+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [ebx+ecx-p*dim], xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        add     esi,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_4
for_sing_coordinate_3:
    movss  xmm0,   [eax+ecx] ; xij    
    movss  xmm2,   [esi]       ; ri
    mulss  xmm2, xmm6
    subss  xmm2, xmm5

    mulss  xmm2,   xmm7       ; step_ind*ri
    addss  xmm0,   xmm2       ; yij
    
    movss [ebx+ecx], xmm0

    add ecx, dim
    add esi, dim
    cmp ecx, edx
    jb  for_sing_coordinate_3
next_4:
    mov     ecx, [ebp+padding] 
    imul     ecx, dim    ; padding*dim
    ; aggiorna puntatori a pesce precedente
    add     ecx, edx    ;(d+padding)*dim
    add     eax, ecx    ; eax -= (d+padding)*dim
    add     ebx, ecx    ; ebx -= (d+padding)*dim
        
    mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
for_blocco_coordinate_4:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci
        
        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        movups  xmm2,   [esi]       ; r[0..3]
        mulps   xmm2,   xmm6
        subps   xmm2,   xmm5
        movups  xmm3,   [esi+p*dim] ; r[4..7]
        mulps   xmm3,   xmm6
        subps   xmm3,   xmm5

        mulps   xmm2,   xmm7        ; step_ind*r[0..3]
        mulps   xmm3,   xmm7        ; step_ind*r[4..7]

        addps   xmm0,   xmm2        ; y[0..3]
        addps   xmm1,   xmm3        ; y[4..7]
        
        movaps [ebx+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [ebx+ecx-p*dim], xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        add     esi,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesci 
for_sing_coordinate_4:
    movss  xmm0,   [eax+ecx] ; xij
    movss  xmm2,   [esi]       ; ri
    mulss  xmm2, xmm6
    subss  xmm2, xmm5

    mulss  xmm2,   xmm7       ; step_ind*ri
    addss  xmm0,   xmm2       ; yij
    
    movss [ebx+ecx], xmm0

    add ecx, dim
    add esi, dim
    cmp ecx, edx
    jb  for_sing_coordinate_4
; fine for coordinate
next_pesci:
    mov     ecx, [ebp+padding] 
    imul     ecx, dim    ; padding*dim
    ; aggiorna puntatori a pesce precedente
    add     ecx, edx    ;(d+padding)*dim
    add     eax, ecx    ; eax -= (d+padding)*dim
    add     ebx, ecx    ; ebx -= (d+padding)*dim
    sub     edi, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    cmp edi, 0
    je  return
    
for_pesce:
    mov     ecx, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        movups  xmm2,   [esi]       ; r[0..3]
        mulps   xmm2,   xmm6
        subps   xmm2,   xmm5
        movups  xmm3,   [esi+p*dim] ; r[4..7]
        mulps   xmm3,   xmm6
        subps   xmm3,   xmm5

        mulps   xmm2,   xmm7        ; step_ind*r[0..3]
        mulps   xmm3,   xmm7        ; step_ind*r[4..7]

        addps   xmm0,   xmm2        ; y[0..3]
        addps   xmm1,   xmm3        ; y[4..7]
        
        movaps [ebx+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [ebx+ecx-p*dim], xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        add     esi,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesce
for_sing_coordinate_extra:
    movss  xmm0,   [eax+ecx] ; xij
    
    movss  xmm2,   [esi]       ; ri
    mulss  xmm2, xmm6
    subss  xmm2, xmm5

    mulss  xmm2,   xmm7       ; step_ind*ri
    addss  xmm0,   xmm2       ; yij
    
    movss [ebx+ecx], xmm0

    add ecx, dim
    add esi, dim
    cmp ecx, edx
    jb  for_sing_coordinate_extra
next_pesce:
    mov     ecx, [ebp+padding] 
    imul     ecx, dim    ; padding*dim
    ; aggiorna puntatori a pesce precedente
    add     ecx, edx    ;(d+padding)*dim
    add     eax, ecx    ; eax -= (d+padding)*dim
    add     ebx, ecx    ; ebx -= (d+padding)*dim
    
    dec     edi
    cmp     edi, zero ; pesce+1 > n_pesci
    jg     for_pesce
return:
    
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro