%include 'sseutils32.nasm'

section .data
    dim                     equ     4
    p                       equ     4
    UNROLL_COORDINATE       equ     2
    UNROLL_PESCI            equ     4

section .bss
    alignb 16
	np_meno_unroll resd 1

section .text
    global calcola_val_f_asm
    
    input_x     equ     8
    input_np    equ     12
    input_d     equ     16
    vector_c    equ     20
    ret_x_2     equ     24
    ret_c_x     equ     28
    
    ;DEBUG
    ; msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	           db	10,0
    ; prints msg
	; prints nl

calcola_val_f_asm:
    start

    ;eax <- matrice X
    ;ebx <- d*dim
    ;ecx <- matrice coefficienti
    ;edx <- ret_x_2
    ;edi <- ret_y_2

    mov     eax,    [ebp+input_x]
    mov     ecx,    [ebp+vector_c]
    mov     edx,    [ebp+input_d]
    
    mov     ebx,    [ebp+ret_x_2]
    mov     edi,    [ebp+ret_c_x]

    mov esi, [ebp+input_np]
    sub esi, UNROLL_PESCI
    mov [np_meno_unroll], esi

    xor esi, esi
for_pesci:
    cmp esi,  [np_meno_unroll] ;np>=4
    jg for_pesce_extra ;np<4 
    
    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
for_blocco_coordinate_8:
    cmp edx, p*UNROLL_COORDINATE
    jl  fine_for_blocco_coordinate_8

    movaps  XMM0,   [eax]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    sub edx, p*UNROLL_COORDINATE
    add eax, p*dim*UNROLL_COORDINATE
    add ecx, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8
fine_for_blocco_coordinate_8:
    cmp edx, 0
    je next_2
;blocco_coordinate_extra:
    movaps  XMM0,   [eax] ; xj
    movaps  XMM1,   [ecx] ; cj
    
    add eax, p*dim

    mulps   XMM1,   XMM0
    mulps   XMM0,   XMM0

    addps XMM4,     XMM1
    addps XMM6,     XMM0
next_2:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi+esi*dim],    XMM4
    movss [ebx+esi*dim],    XMM6
    inc esi

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
    
    mov ecx, [ebp+vector_c]
    mov edx, [ebp+input_d]
for_blocco_coordinate_8_2:
    cmp edx, p*UNROLL_COORDINATE
    jl  fine_for_blocco_coordinate_8_2

    movaps  XMM0,   [eax]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    sub edx, p*UNROLL_COORDINATE
    add eax, p*dim*UNROLL_COORDINATE
    add ecx, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_2
fine_for_blocco_coordinate_8_2:
    cmp edx, 0
    je next_3
;blocco_coordinate_extra:
    movaps  XMM0,   [eax] ; xj
    movaps  XMM1,   [ecx] ; cj
    
    add eax, p*dim

    mulps   XMM1,   XMM0
    mulps   XMM0,   XMM0

    addps XMM4,     XMM1
    addps XMM6,     XMM0
next_3:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi+esi*dim],    XMM4
    movss [ebx+esi*dim],    XMM6
    inc esi

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
    
    mov ecx, [ebp+vector_c]
    mov edx, [ebp+input_d]
for_blocco_coordinate_8_3:
    cmp edx, p*UNROLL_COORDINATE
    jl  fine_for_blocco_coordinate_8_3

    movaps  XMM0,   [eax]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    sub edx, p*UNROLL_COORDINATE
    add eax, p*dim*UNROLL_COORDINATE
    add ecx, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_3
fine_for_blocco_coordinate_8_3:
    cmp edx, 0
    je next_4
;blocco_coordinate_extra:
    movaps  XMM0,   [eax] ; xj
    movaps  XMM1,   [ecx] ; cj
    
    add eax, p*dim

    mulps   XMM1,   XMM0
    mulps   XMM0,   XMM0

    addps XMM4,     XMM1
    addps XMM6,     XMM0
next_4:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi+esi*dim],    XMM4
    movss [ebx+esi*dim],    XMM6
    inc esi

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
    
    mov ecx, [ebp+vector_c]
    mov edx, [ebp+input_d]
for_blocco_coordinate_8_4:
    cmp edx, p*UNROLL_COORDINATE
    jl  fine_for_blocco_coordinate_8_4

    movaps  XMM0,   [eax]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    sub edx, p*UNROLL_COORDINATE
    add eax, p*dim*UNROLL_COORDINATE
    add ecx, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_4
fine_for_blocco_coordinate_8_4:
    cmp edx, 0
    je next_pesci
;blocco_coordinate_extra:
    movaps  XMM0,   [eax] ; xj
    movaps  XMM1,   [ecx] ; cj
    
    add eax, p*dim

    mulps   XMM1,   XMM0
    mulps   XMM0,   XMM0

    addps XMM4,     XMM1
    addps XMM6,     XMM0
next_pesci:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi+esi*dim],    XMM4
    movss [ebx+esi*dim],    XMM6
    
    inc esi

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
    
    mov ecx, [ebp+vector_c]
    mov edx, [ebp+input_d]
    jmp     for_pesci

for_pesce_extra:
    cmp esi, [ebp+input_np]
    je  return

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7

    mov edx, [ebp+input_d]
for_blocco_coordinate_8_extra:
    cmp edx, p*UNROLL_COORDINATE
    jl  fine_for_blocco_coordinate_8_extra

    movaps  XMM0,   [eax]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    sub edx, p*UNROLL_COORDINATE
    add eax, p*dim*UNROLL_COORDINATE
    add ecx, p*dim*UNROLL_COORDINATE

    jmp for_blocco_coordinate_8_extra
fine_for_blocco_coordinate_8_extra:
    cmp edx, 0
    je next_pesce
;blocco_coordinate_extra:
    movaps  XMM0,   [eax] ; xj
    movaps  XMM1,   [ecx] ; cj
    
    add eax, p*dim

    mulps   XMM1,   XMM0
    mulps   XMM0,   XMM0

    addps XMM4,     XMM1
    addps XMM6,     XMM0
next_pesce:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi+esi*dim],    XMM4
    movss [ebx+esi*dim],    XMM6

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7
    
    inc esi
    mov ecx, [ebp+vector_c]
    jmp for_pesce_extra

return:

stop