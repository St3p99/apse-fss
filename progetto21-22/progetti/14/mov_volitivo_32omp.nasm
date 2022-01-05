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
    alignb 16
    m resd p

section .text
    global mov_volitivo_asm_omp

    input_x     equ     8  ; riga del pesce i-esimo
    input_d     equ     12
    stepvol     equ     16 ; -> xmm7
    baricentro  equ     20
    direzione   equ     24 ; -> xmm6
    vector_r    equ     28
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

mov_volitivo_asm_omp: 
    start

    ; eax   indirizzo matrice x
    ; ebx   baricentro
    ; ecx   contatore j-esima
    ; edx   d*dim
    ; esi   vector_r
    
    mov eax, [ebp+input_x]
    mov ebx, [ebp+baricentro]
    mov edx, [ebp+input_d]
    imul edx, dim              ; edx < d*dim
    mov esi, [ebp+vector_r]

    movss  xmm7, [ebp+stepvol]
    movss  xmm6, [ebp+direzione]
    
    mulss  xmm7, xmm6
    shufps xmm7, xmm7, 00000000b ; xmm7 <- [stepvol*direzione, stepvol*direzione, stepvol*direzione, stepvol*direzione]
    mulps  xmm7, [v_meno_uno]; xmm7 <- [-stepvol*direzione, -stepvol*direzione, -stepvol*direzione, -stepvol*direzione]

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
    xorps   xmm2,   xmm2 ; azzera xmm2 (accumuliamo somma distanza)
    xorps   xmm3,   xmm3 ; azzera xmm3 (accumuliamo somma distanza)
for_distanza:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_distanza  ;   esci

        movaps xmm0, [eax+ecx-p*dim*UNROLL_COORDINATE]    
        movaps xmm1, [eax+ecx-p*dim]

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
    movss   xmm4,   [esi]            ; ri
    shufps  xmm4,   xmm4, 00000000b ; xmm4 <- [ri, ri, ri, ri]
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
    je  return
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
return:

stop