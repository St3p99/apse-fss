%include 'sseutils32.nasm'

section .data
    dim                     equ     4
    p                       equ     4
    UNROLL_COORDINATE       equ     2

section .bss

section .text
    global calcola_val_f_asm_omp
    
    input_x     equ     8
    input_d     equ     12
    vector_c    equ     16
    ret_x_2     equ     20
    ret_c_x     equ     24
        
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl


calcola_val_f_asm_omp:
    start

    ;eax <- matrice X
    ;ebx <- d*dim
    ;ecx <- matrice coefficienti
    ;edx <- ret_x_2
    ;edi <- ret_y_2

    mov     eax,    [ebp+input_x]
    mov     edx,    [ebp+input_d]
    imul    edx,    dim
    mov     ecx,    [ebp+vector_c]
    mov     esi,    [ebp+ret_x_2]
    mov     edi,    [ebp+ret_c_x]

    xorps XMM4,XMM4
    xorps XMM5,XMM5
    xorps XMM6,XMM6
    xorps XMM7,XMM7

    mov ebx, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_8:
    cmp ebx, edx
    jg  fine_for_blocco_coordinate_8

    movaps  XMM0,   [eax+ebx-p*dim*UNROLL_COORDINATE]   ;x[x0,x1,x2,x3]
    movaps  XMM1,   [eax+ebx-p*dim]                     ;x[x4,x5,x6,x7]

    movaps  XMM2,   [ecx+ebx-p*dim*UNROLL_COORDINATE]   ;c[c0,c1,c2,c3]
    movaps  XMM3,   [ecx+ebx-p*dim]                     ;c[c4,c5,c6,c7]

    mulps XMM2,     XMM0 ;c*x
    mulps XMM3,     XMM1

    mulps XMM0,     XMM0 ;x^2
    mulps XMM1,     XMM1

    addps XMM4,     XMM2 ;ADD C*X 0..3
    addps XMM5,     XMM3 ;ADD C*X 4..7

    addps XMM6,     XMM0 ;ADD X^2 0..3
    addps XMM7,     XMM1 ;ADD X^2 4..7

    add ebx, p*dim*UNROLL_COORDINATE
    jmp for_blocco_coordinate_8
fine_for_blocco_coordinate_8:
    sub ebx, p*dim*UNROLL_COORDINATE
    cmp ebx, edx
    je return

    movaps  XMM0,   [eax+ebx] ; xj
    movaps  XMM1,   [ecx+ebx] ; cj
    
    mulps   XMM1,   XMM0 ; c*x
    mulps   XMM0,   XMM0 ; x^2

    addps XMM4,     XMM1
    addps XMM6,     XMM0
return:
    addps   XMM4,   XMM5
    haddps  XMM4,   XMM4
    haddps  XMM4,   XMM4
    
    addps   XMM6,   XMM7
    haddps  XMM6,   XMM6
    haddps  XMM6,   XMM6

    movss [edi],    XMM4
    movss [esi],    XMM6

stop