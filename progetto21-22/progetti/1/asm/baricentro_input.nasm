%include 'sseutils32.nasm'

; CALCOLA NUMERATORE BARICENTRO
; Al momento funziona SOLO per coordinate multiple di 8.
; È necessario gestire singolarmente le restanti coordinate

; Rimane da calcolare il denominatore

; ricordarsi macro per allocazione dinamica

; per ogni pesce p [p=0]
    ; per ogni blocco da 8 coordinate
        ; XMM0 <- primo blocco da 4 (coordinate) [x00, x01, x02, x03]
        ; XMM1 <- secondo blocco da 4 (coordinate) [x04, x05, x06, x07]
        ; XMM2 <- peso[p] per tutti gli elementi del registro [w0]
        ; XMM0 <- XMM0*XMM2 [x00*w0, x01*w0, x02*w0, x03*w0]
        ; XMM1 <- XMM1*XMM2 [x04*w0, x05*w0, x06*w0, x07*w0]
        ; ADDPS MEM[blocco i], XMM0 [num0, num1, num2, num3]
        ; ADDPS MEM[blocco i+1], XMM1 [num4, num5, num6, num7]

;   0    1    2    3    4    5    6    7       8    9   10   11   12    13   14   15
; [x00, x01, x02, x03, x04, x05, x06, x07] - [x10, x11, x12, x13, x14, x15, x16, x17]

; Accesso alla matrice per riga [i][j] => [i*n_colonne+j]
; Inoltre, prendiamo blocchi di 4

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2

section .bss
    alignb 16
    m resd p

section .text
    global baricentro_asm

    input_x     equ     8
    input_np    equ     12
    input_d     equ     16
    pesi        equ     20
    baricentro  equ     24
    peso_tot    equ     28
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

baricentro_asm: 
    start

    mov eax, [ebp+input_x]	; indirizzo della struttura contenente i parametri
	mov edx, [ebp+input_d] 
    mov esi, [ebp+baricentro] ; esi <- indirizzo vettore baricentro

; azzera baricentro
    xorps xmm0, xmm0
    mov ebx, 0
    mov ecx, edx
ciclo_azzera_bar_8: 
    cmp ecx, p*UNROLL_COORDINATE
    jb  ciclo_azzera_bar ; jb salta se minore senza segno ;jl salta con segno
    
    movaps [esi+ebx], xmm0
    movaps [esi+ebx+p*dim], xmm0
    
    add ebx, p*dim*UNROLL_COORDINATE
    
    sub ecx, p*UNROLL_COORDINATE
    jmp ciclo_azzera_bar_8
ciclo_azzera_bar:
    cmp ecx, zero
    je fine_ciclo_azzera_bar ;je senza segno

    movss [esi+ebx], xmm0
    add   ebx, dim
    dec   ecx
    jmp   ciclo_azzera_bar
fine_ciclo_azzera_bar:

xorps   xmm6,   xmm6
    ; edx < input_d
    imul   edx,    dim        ; input_d*dim
    mov    edi,    [ebp+input_np]
    ; imul   edi,    dim         ; input_np*dim
    mov     ebx,    0          ; pesce i = 0
for_pesci:
    mov     esi,    [ebp+pesi]       ; esi <- indirizzo vettore pesi
    
    movaps  xmm5,   [esi+ebx*dim]        ; [wi, wi+1, wi+2, wi+3]

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
for_sing_coordinate:
    movss xmm0,    [eax+ecx]
    mulss xmm0,    xmm2

    movss xmm3,    [esi+ecx]
    addss xmm3,    xmm0
    movss [esi+ecx], xmm3
    
    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate
next_2:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx        ; (pesce+1)*d = pesce*d + d
        shufps  xmm2,   xmm5, 01010101b  ; peso 1
        shufps  xmm2,   xmm2, 10101010b  ; peso 1 su tutto xmm2
for_blocco_coordinate_2:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci

        movups  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movups  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

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
for_sing_coordinate_2:
    movss xmm0,    [eax+ecx]
    mulss xmm0,    xmm2

    movss xmm3,    [esi+ecx]
    addss xmm3,    xmm0
    movss [esi+ecx], xmm3

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_2
next_3:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx
        shufps  xmm2,   xmm5, 10101010b  ; peso 2
        shufps  xmm2,   xmm2, 10101010b  ; peso 2 su tutto xmm2
for_blocco_coordinate_3:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci

        movups  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movups  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
    
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
for_sing_coordinate_3:
    movss xmm0,    [eax+ecx]
    mulss xmm0,    xmm2

    movss xmm3,    [esi+ecx]
    addss xmm3,    xmm0
    movss [esi+ecx], xmm3

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_3
next_4:
        mov     ecx,    p*dim*UNROLL_COORDINATE          ; coordinata
        add     eax,    edx
        shufps  xmm2,   xmm5, 11111111b  ; peso 3
        shufps  xmm2,   xmm2, 10101010b  ; peso 3 su tutto xmm2
for_blocco_coordinate_4:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        movups  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movups  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]

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
    je  next_pesce
for_sing_coordinate_4:
    movss xmm0,    [eax+ecx]
    mulss xmm0,    xmm2

    movss xmm3,    [esi+ecx]
    addss xmm3,    xmm0
    movss [esi+ecx], xmm3

    add ecx, dim
    cmp ecx, edx
    jb  for_sing_coordinate_4
; fine for coordinate
next_pesce:
    add     eax,    edx ; indirizzo riga prossimo pesce
    add     ebx, UNROLL_PESCI ; aggiorna contatore pesci
    cmp     ebx, edi ; pesce < n_pesci
    jb      for_pesci
; fine for_pesci

    haddps  xmm6, xmm6
    haddps  xmm6, xmm6

for_div_8: 
    cmp edx, p*dim*UNROLL_COORDINATE
    jb  for_div ; jb salta se minore senza segno ;jl salta con segno

    movaps xmm0,  [esi]
    divps  xmm0,  xmm6
    movaps [esi], xmm0

    movaps xmm1,  [esi+p*dim]
    divps  xmm1,  xmm6
    movaps [esi+p*dim], xmm1
    
    add esi,  p*dim*UNROLL_COORDINATE
    sub edx,  p*dim*UNROLL_COORDINATE

    jmp for_div_8
for_div:
    cmp edx, zero
    je aggiorna_peso_tot_corrente ;je senza segno

    movss xmm0, [esi]
    divss xmm0, xmm6
    movss [esi], xmm0

    add esi, dim
    sub edx, dim
    jmp for_div

aggiorna_peso_tot_corrente:
    mov   eax,  [ebp+peso_tot]
    movss [eax], xmm6

    
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro