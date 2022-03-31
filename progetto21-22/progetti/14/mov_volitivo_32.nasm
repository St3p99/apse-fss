%include 'sseutils32.nasm'


section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI    		equ		4
    UNROLL_COORDINATE		equ		2
    
    align 16
    v_meno_uno dd -1.0, -1.0, -1.0, -1.0

section .bss
    ;DEBUG
    ; alignb 16
    ; m resd p

section .text
    global mov_volitivo_asm

    input_x     equ     8
    input_np    equ     12
    input_d     equ     16
    padding_d   equ     20
    stepvol     equ     24 ; -> xmm7
    baricentro  equ     28
    direzione   equ     32 ; -> xmm6
    vector_r    equ     36
    
    ;DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

mov_volitivo_asm: 
    start

    ; eax   indirizzo matrice x
    ; ebx   baricentro
    ; ecx   contatore j-esima | padding_d
    ; edx   d*dim
    ; edi   pesce i-esimo (init a np-1; np--)
    ; esi   vector_r
    
    mov eax, [ebp+input_x]
    mov ebx, [ebp+baricentro]
    mov edx, [ebp+input_d]
    imul edx, dim              ; edx < d*dim
    mov edi, [ebp+input_np]
    mov esi, [ebp+vector_r]

    movss  xmm7, [ebp+stepvol]
    movss  xmm6, [ebp+direzione]
    
    mulss  xmm7, xmm6
    shufps xmm7, xmm7, 00000000b ; xmm7 <- [stepvol*direzione, stepvol*direzione, stepvol*direzione, stepvol*direzione]
    mulps  xmm7, [v_meno_uno]; xmm7 <- [-stepvol*direzione, -stepvol*direzione, -stepvol*direzione, -stepvol*direzione]

for_pesci:
    cmp     edi, UNROLL_PESCI ; pesce i-esimo < 0
    jl      fine_for_pesci

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        movaps xmm1, [eax+ecx-p*dim]                    ; x 0..3

        subps xmm0,  [ebx+ecx-p*dim*UNROLL_COORDINATE]     
        subps xmm1,  [ebx+ecx-p*dim]

        mulps  xmm0, xmm0
        mulps  xmm1, xmm1

        addps  xmm2, xmm0
        addps  xmm3, xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza
fine_for_distanza:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_coordinate
for_sing_distanza:
    movss xmm0, [eax+ecx]    
    mulss  xmm0, xmm0
    addss  xmm2, xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_distanza
next_coordinate:
    addps  xmm2, xmm3
    haddps xmm2, xmm2
    haddps xmm2, xmm2
    
    sqrtps xmm2, xmm2 ; distanza euclidea 
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata

    movups   xmm5,   [esi]            ; ri
    shufps   xmm4,   xmm5, 00000000b
    shufps   xmm4,   xmm4, 10101010b  ; random 0 su tutto xmm4
    
    
for_blocco_coordinate:
    cmp     ecx,    edx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate  ;   esci

    movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    ;x 0..3
    movaps xmm1, [eax+ecx-p*dim]                      ;x 4..7

    movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]    ;b 0..3
    movaps xmm6, [ebx+ecx-p*dim]                      ;b 4..7

    subps xmm3, xmm0                                  ;b - x (0..3)
    subps xmm6, xmm1                                  ;b - x (4..7)
    
    divps xmm3, xmm2                                  ;[b - x (0..3)]/dist
    divps xmm6, xmm2                                  ;[b - x (4..7)]/dist

    mulps xmm3, xmm7                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    mulps xmm6, xmm7                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    mulps xmm3, xmm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    mulps xmm6, xmm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    addps xmm0, xmm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    addps xmm1, xmm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    movaps [eax+ecx-p*dim*UNROLL_COORDINATE], xmm0
    movaps [eax+ecx-p*dim],                   xmm1

    add     ecx,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_2
for_sing_coordinate: 
    movss xmm0, [eax+ecx] ;xij    
    movss xmm3, [ebx+ecx] ;bj
    subss xmm3, xmm0      ; bj - xij
    divss xmm3, xmm2      ; (bj - xij)/dist
    mulss xmm3, xmm7      ; -stepvol*direzione*(bj - xij)/dist
    mulss xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    addss xmm0, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    movss [eax+ecx], xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate
next_2:
    mov     ecx, [ebp+padding_d]  ; ecx <- padding_d
    imul    ecx, dim              ; ecx <- padding_d*dim
    add     ecx, edx              ; ecx <- (d + padding_d )*dim
    add     eax, ecx              ; indirizzo prossima riga (prossimo pesce)  
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza_2:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_2  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        movaps xmm1, [eax+ecx-p*dim]                    ; x 0..3

        subps xmm0,  [ebx+ecx-p*dim*UNROLL_COORDINATE]     
        subps xmm1,  [ebx+ecx-p*dim]

        mulps  xmm0, xmm0
        mulps  xmm1, xmm1

        addps  xmm2, xmm0
        addps  xmm3, xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_2
fine_for_distanza_2:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_coordinate_2
for_sing_distanza_2:
    movss xmm0, [eax+ecx]    
    mulss  xmm0, xmm0
    addss  xmm2, xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_distanza_2
next_coordinate_2:
    addps  xmm2, xmm3
    haddps xmm2, xmm2
    haddps xmm2, xmm2
    
    sqrtps xmm2, xmm2 ; distanza euclidea 
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    shufps   xmm4,   xmm5, 01010101b
    shufps   xmm4,   xmm4, 10101010b  ; random 0 su tutto xmm4
    
    
for_blocco_coordinate_2:
    cmp     ecx,    edx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_2  ;   esci

    movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    ;x 0..3
    movaps xmm1, [eax+ecx-p*dim]                      ;x 4..7

    movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]    ;b 0..3
    movaps xmm6, [ebx+ecx-p*dim]                      ;b 4..7

    subps xmm3, xmm0                                  ;b - x (0..3)
    subps xmm6, xmm1                                  ;b - x (4..7)
    
    divps xmm3, xmm2                                  ;[b - x (0..3)]/dist
    divps xmm6, xmm2                                  ;[b - x (4..7)]/dist

    mulps xmm3, xmm7                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    mulps xmm6, xmm7                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    mulps xmm3, xmm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    mulps xmm6, xmm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    addps xmm0, xmm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    addps xmm1, xmm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    movaps [eax+ecx-p*dim*UNROLL_COORDINATE], xmm0
    movaps [eax+ecx-p*dim],                   xmm1

    add     ecx,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_3
for_sing_coordinate_2: 
    movss xmm0, [eax+ecx] ;xij    
    movss xmm3, [ebx+ecx] ;bj
    subss xmm3, xmm0      ; bj - xij
    divss xmm3, xmm2      ; (bj - xij)/dist
    mulss xmm3, xmm7      ; -stepvol*direzione*(bj - xij)/dist
    mulss xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    addss xmm0, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    movss [eax+ecx], xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_2
next_3:
    mov     ecx, [ebp+padding_d]  ; ecx <- padding_d
    imul    ecx, dim              ; ecx <- padding_d*dim
    add     ecx, edx              ; ecx <- (d + padding_d )*dim
    add     eax, ecx              ; indirizzo prossima riga (prossimo pesce)  

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza_3:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_3  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    
        movaps xmm1, [eax+ecx-p*dim]                    

        subps xmm0,  [ebx+ecx-p*dim*UNROLL_COORDINATE]     
        subps xmm1,  [ebx+ecx-p*dim]

        mulps  xmm0, xmm0
        mulps  xmm1, xmm1

        addps  xmm2, xmm0
        addps  xmm3, xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_3
fine_for_distanza_3:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_coordinate_3
for_sing_distanza_3:
    movss xmm0, [eax+ecx]    
    mulss  xmm0, xmm0
    addss  xmm2, xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_distanza_3
next_coordinate_3:
    addps  xmm2, xmm3
    haddps xmm2, xmm2
    haddps xmm2, xmm2
    
    sqrtps xmm2, xmm2 ; distanza euclidea 
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    shufps   xmm4,   xmm5, 10101010b
    shufps   xmm4,   xmm4, 10101010b  ; random 0 su tutto xmm4
    
    
for_blocco_coordinate_3:
    cmp     ecx,    edx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_3  ;   esci

    movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    ;x 0..3
    movaps xmm1, [eax+ecx-p*dim]                      ;x 4..7

    movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]    ;b 0..3
    movaps xmm6, [ebx+ecx-p*dim]                      ;b 4..7

    subps xmm3, xmm0                                  ;b - x (0..3)
    subps xmm6, xmm1                                  ;b - x (4..7)
    
    divps xmm3, xmm2                                  ;[b - x (0..3)]/dist
    divps xmm6, xmm2                                  ;[b - x (4..7)]/dist

    mulps xmm3, xmm7                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    mulps xmm6, xmm7                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    mulps xmm3, xmm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    mulps xmm6, xmm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    addps xmm0, xmm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    addps xmm1, xmm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    movaps [eax+ecx-p*dim*UNROLL_COORDINATE], xmm0
    movaps [eax+ecx-p*dim],                   xmm1

    add     ecx,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_4
for_sing_coordinate_3: 
    movss xmm0, [eax+ecx] ;xij    
    movss xmm3, [ebx+ecx] ;bj
    subss xmm3, xmm0      ; bj - xij
    divss xmm3, xmm2      ; (bj - xij)/dist
    mulss xmm3, xmm7      ; -stepvol*direzione*(bj - xij)/dist
    mulss xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    addss xmm0, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    movss [eax+ecx], xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_3
next_4:
    
    mov     ecx, [ebp+padding_d]  ; ecx <- padding_d
    imul    ecx, dim              ; ecx <- padding_d*dim
    add     ecx, edx              ; ecx <- (d + padding_d )*dim
    add     eax, ecx              ; indirizzo prossima riga (prossimo pesce)  
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza_4:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_4  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        movaps xmm1, [eax+ecx-p*dim]                    ; x 0..3

        subps xmm0,  [ebx+ecx-p*dim*UNROLL_COORDINATE]     
        subps xmm1,  [ebx+ecx-p*dim]

        mulps  xmm0, xmm0
        mulps  xmm1, xmm1

        addps  xmm2, xmm0
        addps  xmm3, xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_4
fine_for_distanza_4:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_coordinate_4
for_sing_distanza_4:
    movss xmm0, [eax+ecx]    
    mulss  xmm0, xmm0
    addss  xmm2, xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_distanza_4
next_coordinate_4:
    addps  xmm2, xmm3
    haddps xmm2, xmm2
    haddps xmm2, xmm2
    
    sqrtps xmm2, xmm2 ; distanza euclidea 
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    shufps   xmm4,   xmm5, 11111111b
    shufps   xmm4,   xmm4, 10101010b  ; random 0 su tutto xmm4
    
    
for_blocco_coordinate_4:
    cmp     ecx,    edx                ; if( i+8 > n_coordinate )
    jg      fine_for_blocco_coordinate_4  ;   esci

    movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    ;x 0..3
    movaps xmm1, [eax+ecx-p*dim]                      ;x 4..7

    movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]    ;b 0..3
    movaps xmm6, [ebx+ecx-p*dim]                      ;b 4..7

    subps xmm3, xmm0                                  ;b - x (0..3)
    subps xmm6, xmm1                                  ;b - x (4..7)
    
    divps xmm3, xmm2                                  ;[b - x (0..3)]/dist
    divps xmm6, xmm2                                  ;[b - x (4..7)]/dist

    mulps xmm3, xmm7                                  ;-stepvol*direzione*[b - x (0..3)]/dist
    mulps xmm6, xmm7                                  ;-stepvol*direzione*[b - x (4..7)]/dist

    mulps xmm3, xmm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
    mulps xmm6, xmm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

    addps xmm0, xmm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
    addps xmm1, xmm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

    movaps [eax+ecx-p*dim*UNROLL_COORDINATE], xmm0
    movaps [eax+ecx-p*dim],                   xmm1

    add     ecx,    p*dim*UNROLL_COORDINATE
    jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesci
for_sing_coordinate_4: 
    movss xmm0, [eax+ecx] ;xij    
    movss xmm3, [ebx+ecx] ;bj
    subss xmm3, xmm0      ; bj - xij
    divss xmm3, xmm2      ; (bj - xij)/dist
    mulss xmm3, xmm7      ; -stepvol*direzione*(bj - xij)/dist
    mulss xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    addss xmm0, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    movss [eax+ecx], xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_4

next_pesci:    
    add     esi, UNROLL_PESCI*dim ; prossimi random
    mov     ecx, [ebp+padding_d]  ; ecx <- padding_d
    imul    ecx, dim              ; ecx <- padding_d*dim
    add     ecx, edx              ; ecx <- (d + padding_d )*dim
    add     eax, ecx              ; indirizzo prossima riga (prossimo pesce)  
    sub     edi, UNROLL_PESCI
    jmp     for_pesci
fine_for_pesci:
    cmp edi, 0
    je  return


for_pesce:
    mov     ecx, p*dim*UNROLL_COORDINATE

    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza_extra:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_distanza_extra  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]  ; x 0..3  
        movaps xmm1, [eax+ecx-p*dim]                    ; x 0..3

        subps xmm0,  [ebx+ecx-p*dim*UNROLL_COORDINATE]     
        subps xmm1,  [ebx+ecx-p*dim]

        mulps  xmm0, xmm0
        mulps  xmm1, xmm1

        addps  xmm2, xmm0
        addps  xmm3, xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_distanza_extra
fine_for_distanza_extra:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_coordinate_extra
for_sing_distanza_extra:
    movss xmm0, [eax+ecx]    
    mulss  xmm0, xmm0
    addss  xmm2, xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_distanza_extra
next_coordinate_extra:
    addps  xmm2, xmm3
    haddps xmm2, xmm2
    haddps xmm2, xmm2
    
    sqrtps xmm2, xmm2 ; distanza euclidea
    
    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    movss   xmm4,   [esi]            ; ri
    shufps  xmm4,   xmm4, 00000000b ; xmm4 <- [ri, ri, ri, ri]
    

for_blocco_coordinate_extra:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    ;x 0..3
        movaps xmm1, [eax+ecx-p*dim]                      ;x 4..7    movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]    ;b 0..3
        
        movaps xmm3, [ebx+ecx-p*dim*UNROLL_COORDINATE]                      ;b 4..7
        movaps xmm6, [ebx+ecx-p*dim]                      ;b 4..7

        subps xmm3, xmm0                                  ;b - x (0..3)
        subps xmm6, xmm1                                  ;b - x (4..7)


        divps xmm3, xmm2                                  ;[b - x (0..3)]/dist
        divps xmm6, xmm2                                  ;[b - x (4..7)]/dist
        mulps xmm3, xmm7                                  ;-stepvol*direzione*[b - x (0..3)]/dist
        mulps xmm6, xmm7                                  ;-stepvol*direzione*[b - x (4..7)]/dist

        mulps xmm3, xmm4                                 ;-stepvol*direzione*rand*[b - x (0..3)]/dist
        mulps xmm6, xmm4                                 ;-stepvol*direzione*rand*[b - x (4..7)]/dist

        addps xmm0, xmm3                                 ;xi 0..3 += -stepvol*direzione*rand(b - x (0..3))/dist
        addps xmm1, xmm6                                 ;xi 4..7 += -stepvol*direzione*rand(b - x (4..7))/dist

        movaps [eax+ecx-p*dim*UNROLL_COORDINATE], xmm0
        movaps [eax+ecx-p*dim],                   xmm1

        add     ecx,    p*dim*UNROLL_COORDINATE

        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesce
for_sing_coordinate_extra:
    movss xmm0, [eax+ecx] ;xij    
    movss xmm3, [ebx+ecx] ;bj
    subss xmm3, xmm0      ; bj - xij
    divss xmm3, xmm2      ; (bj - xij)/dist
    mulss xmm3, xmm7      ; -stepvol*direzione*(bj - xij)/dist
    mulss xmm3, xmm4      ; -stepvol*direzione*rand(bj - xij)/dist
    addss xmm0, xmm3      ; xij += -stepvol*direzione*rand(bj - xij)/dist
    movss [eax+ecx], xmm0

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_extra

next_pesce:
    add     esi, dim              ; prossimo random
    mov     ecx, [ebp+padding_d]  ; ecx <- padding_d
    imul    ecx, dim              ; ecx <- padding_d*dim
    add     ecx, edx              ; ecx <- (d + padding_d )*dim
    add     eax, ecx              ; indirizzo prossima riga (prossimo pesce)
    
    dec     edi
    cmp     edi, zero ; pesce+1 > n_pesci
    jg     for_pesce
return:

stop