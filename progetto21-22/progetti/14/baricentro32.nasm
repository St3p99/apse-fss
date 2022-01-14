%include 'sseutils32.nasm'

; CALCOLA BARICENTRO

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2

section .bss
    ; DEBUG
    ; alignb 16
    ; m resd p

section .text
    global baricentro_asm

    input_x     equ     8
    input_np    equ     12
    input_d     equ     16
    pesi        equ     20
    baricentro  equ     24
    peso_tot    equ     28
    
    ; DEBUG
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

baricentro_asm: 
    start

    mov eax, [ebp+input_x]	; indirizzo matrice x
	mov edx, [ebp+input_d] 
    mov esi, [ebp+baricentro] ; esi <- indirizzo vettore baricentro

; azzera baricentro
    xorps xmm0, xmm0
    mov ebx, 0
    mov ecx, edx
ciclo_azzera_bar_8: 
    cmp ecx, p*UNROLL_COORDINATE
    jb  fine_ciclo_azzera_bar_8 ; jb salta se minore senza segno ;jl salta con segno
    
    movaps [esi+ebx], xmm0
    movaps [esi+ebx+p*dim], xmm0
    
    add ebx, p*dim*UNROLL_COORDINATE
    
    sub ecx, p*UNROLL_COORDINATE
    jmp ciclo_azzera_bar_8
fine_ciclo_azzera_bar_8:
    cmp ecx, zero
    je fine_ciclo_azzera_bar ;je senza segno

    movaps [esi+ebx], xmm0
fine_ciclo_azzera_bar:

xorps   xmm6,   xmm6
    
    imul   edx,    dim        ; input_d*dim
    mov    edi,    [ebp+input_np]
    mov     ebx,    UNROLL_PESCI          ; pesce i = 0

    ; eax <- matrice x
    ; ebx <- pesce i-esimo
    ; ecx <- coordinata j-esima
    ; edx <- d*dim
    ; edi <- np
    ; esi <- vettore pesi | baricentro (scambio una volta ogni 4 pesci)
for_pesci:
    cmp     ebx, edi ; pesce+4 > n_pesci
    jg      fine_for_pesci

    mov     esi,    [ebp+pesi]       ; esi <- indirizzo vettore pesi
    movaps  xmm5,   [esi+ebx*dim-UNROLL_PESCI*dim]        ; [wi, wi+1, wi+2, wi+3]

    mov     esi,    [ebp+baricentro] ; esi <- indirizzo vettore baricentro
    addps   xmm6,   xmm5             ; somma parziale pesi
    shufps  xmm2,   xmm5, 00000000b
    shufps  xmm2,   xmm2, 10101010b  ; peso 0 su tutto xmm2

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [esi+ecx-p*dim*UNROLL_COORDINATE]
        addps xmm3, xmm0
        movaps [esi+ecx-p*dim*UNROLL_COORDINATE], xmm3
        
        movaps xmm4, [esi+ecx-p*dim]
        addps xmm4, xmm1
        movaps [esi+ecx-p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_2
    
    movaps xmm0, [eax+ecx]
    mulps  xmm0, xmm2

    movaps xmm3,      [esi+ecx]
    addps  xmm3,      xmm0
    movaps [esi+ecx], xmm3
next_2:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx        ; (pesce+1)*d = pesce*d + d
        shufps  xmm2,   xmm5, 01010101b  ; peso 1
        shufps  xmm2,   xmm2, 10101010b  ; peso 1 su tutto xmm2
for_blocco_coordinate_2:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [esi+ecx-p*dim*UNROLL_COORDINATE]
        addps xmm3, xmm0
        movaps [esi+ecx-p*dim*UNROLL_COORDINATE], xmm3

        movaps xmm4, [esi+ecx-p*dim]
        addps xmm4, xmm1
        movaps [esi+ecx-p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_3
    
    movaps xmm0, [eax+ecx]
    mulps  xmm0, xmm2

    movaps xmm3,      [esi+ecx]
    addps  xmm3,      xmm0
    movaps [esi+ecx], xmm3
next_3:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx
        shufps  xmm2,   xmm5, 10101010b  ; peso 2
        shufps  xmm2,   xmm2, 10101010b  ; peso 2 su tutto xmm2
for_blocco_coordinate_3:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
    
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [esi+ecx-p*dim*UNROLL_COORDINATE]
        addps xmm3, xmm0
        movaps [esi+ecx-p*dim*UNROLL_COORDINATE], xmm3
        
        movaps xmm4, [esi+ecx-p*dim]
        addps xmm4, xmm1
        movaps [esi+ecx-p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_4
    
    movaps xmm0, [eax+ecx]
    mulps  xmm0, xmm2

    movaps xmm3,      [esi+ecx]
    addps  xmm3,      xmm0
    movaps [esi+ecx], xmm3
next_4:
        mov     ecx,    p*dim*UNROLL_COORDINATE          ; coordinata
        add     eax,    edx
        shufps  xmm2,   xmm5, 11111111b  ; peso 3
        shufps  xmm2,   xmm2, 10101010b  ; peso 3 su tutto xmm2
for_blocco_coordinate_4:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [esi+ecx-p*dim*UNROLL_COORDINATE]
        addps xmm3, xmm0
        movaps [esi+ecx-p*dim*UNROLL_COORDINATE], xmm3
        
        movaps xmm4, [esi+ecx-p*dim]
        addps xmm4, xmm1
        movaps [esi+ecx-p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesci
    
    movaps xmm0, [eax+ecx]
    mulps  xmm0, xmm2

    movaps xmm3,      [esi+ecx]
    addps  xmm3,      xmm0
    movaps [esi+ecx], xmm3
; fine for coordinate
next_pesci:
    add     eax,    edx ; indirizzo riga prossimo pesce
    add     ebx, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    sub ebx, UNROLL_PESCI
    cmp ebx, edi
    je  next_div
    
    mov     esi,    [ebp+pesi]       ; esi <- indirizzo vettore pesi    
    movaps   xmm5,   [esi+ebx*dim]        ; [wi, wi+1, wi+2, wi+3]
    addps   xmm6,   xmm5             ; somma parziale pesi
    mov     esi,    [ebp+baricentro] ; esi <- indirizzo vettore baricentro
for_pesce:
    shufps  xmm2,   xmm5, 00000000b
    shufps  xmm2,   xmm2, 10101010b  ; peso 0 su tutto xmm2
    shufps  xmm5,   xmm5, 00111001b  ; shift left circolare

    mov     ecx, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [esi+ecx-p*dim*UNROLL_COORDINATE]
        addps xmm3, xmm0
        movaps [esi+ecx-p*dim*UNROLL_COORDINATE], xmm3
        
        movaps xmm4, [esi+ecx-p*dim]
        addps xmm4, xmm1
        movaps [esi+ecx-p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesce
    
    movaps xmm0, [eax+ecx]
    mulps  xmm0, xmm2

    movaps xmm3,      [esi+ecx]
    addps  xmm3,      xmm0
    movaps [esi+ecx], xmm3
next_pesce:
    add     eax,  edx ; indirizzo riga prossimo pesce
    add     ebx,  1 ; aggiorna contatore pesci
    cmp     ebx, edi ; pesce+1 > n_pesci
    jb      for_pesce

next_div:
    haddps  xmm6, xmm6
    haddps  xmm6, xmm6

for_div_8: 
    cmp edx, p*dim*UNROLL_COORDINATE
    jb  last_div ; jb salta se minore senza segno ;jl salta con segno

    movaps xmm0,  [esi]
    divps  xmm0,  xmm6
    movaps [esi], xmm0

    movaps xmm1,  [esi+p*dim]
    divps  xmm1,  xmm6
    movaps [esi+p*dim], xmm1
    
    add esi,  p*dim*UNROLL_COORDINATE
    sub edx,  p*dim*UNROLL_COORDINATE

    jmp for_div_8
last_div:
    cmp edx, zero
    je aggiorna_peso_tot_corrente ;je senza segno

    movaps xmm0, [esi]
    divps xmm0, xmm6
    movaps [esi], xmm0

aggiorna_peso_tot_corrente:
    mov   eax,  [ebp+peso_tot]
    movss [eax], xmm6
    
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro