%include 'sseutils32.nasm'

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    meno_uno equ    -1
    tre     equ     3
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
    global calcola_y_asm_omp

    input_x     equ     8  ; riga del x[i] pesce i-esima
    matrix_y    equ     12 ; riga del y[i] pesce i-esima
    input_d     equ     16
    stepind     equ     20 
    vector_r    equ     24
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

calcola_y_asm_omp: 
    start
    ; eax <- matrice x
    ; ebx <- matrice y
    ; ecx <- coordinata j-esima
    ; edx <- d*dim
    ; edi <- pesce i-esimo (init a np; np--)
    ; esi <- r

    mov eax, [ebp+input_x]	; indirizzo matrice x (init riga ultimo pesce da C)
    mov ebx, [ebp+matrix_y]	; indirizzo matrice y (init riga ultimo pesce da C)
	mov edx, [ebp+input_d]
    imul   edx,    dim        ; input_d*dim

    mov esi, [ebp+vector_r] ; esi <- indirizzo vettore baricentro
    
    movss  xmm7, [ebp+stepind]
    shufps  xmm7,   xmm7, 00000000b

    movaps xmm6, [v_due]
    movaps xmm5, [v_uno]
    
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
    je  return 
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
return:
    
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro