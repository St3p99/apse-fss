%include 'sseutils32.nasm'

; CALCOLA VETTORE I (Movimento istintivo)


section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_COORDINATE		equ		2

section .bss
    ; DEBUG
    ; alignb 16
    ; m resd p

section .text
    global mov_istintivo_asm_omp

    input_x     equ     8
    input_d     equ     12
    vector_i  equ     16
    
    ; DEBUG
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

mov_istintivo_asm_omp: 
    start

    mov eax, [ebp+input_x]	; indirizzo della matrice input_x
	mov edx, [ebp+input_d] 
    mov esi, [ebp+vector_i] ; esi <- indirizzo vettore I
    
    imul    edx,    dim        ; input_d*dim

    mov     ecx,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     ecx,    edx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        movaps  xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
        movaps  xmm4,   [esi+ecx-p*dim]

        addps  xmm0,  xmm3
        addps  xmm1,  xmm4

        movaps  [eax+ecx-p*dim*UNROLL_COORDINATE],  xmm0                      ; [xi, xi+1, xi+2, xi+3]
        movaps  [eax+ecx-p*dim],                    xmm1                   ; [xi+4, ...,      xi+7]

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  return
    
    movaps xmm0, [eax+ecx]
    addps  xmm0,  [esi+ecx]
    movaps [eax+ecx],  xmm0 
return:

stop