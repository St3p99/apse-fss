%include 'sseutils32.nasm'

; CALCOLA VETTORE I (Movimento istintivo)


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
    global mov_istintivo_asm

    input_x     equ     8
    input_np    equ     12
    input_d     equ     16
    vector_i  equ     20
    
    ; DEBUG
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

mov_istintivo_asm: 
    start

    mov eax, [ebp+input_x]	; indirizzo della matrice input_x
	mov edx, [ebp+input_d] 
    mov esi, [ebp+vector_i] ; esi <- indirizzo vettore I
    
    imul    edx,    dim        ; input_d*dim
    mov     edi,    [ebp+input_np]
    mov     ebx,    UNROLL_PESCI          ; pesce i = 0
for_pesci:
    cmp     ebx, edi ; pesce+4 > n_pesci
    jg      fine_for_pesci

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
    je  next_2
    
    movaps xmm0, [eax+ecx]
    movaps xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
    addps  xmm0,  xmm3
    movaps [eax+ecx],  xmm0 
next_2:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx        ; (pesce+1)*d = pesce*d + d
for_blocco_coordinate_2:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        movaps  xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
        movaps  xmm4,   [esi+ecx-p*dim]

        addps  xmm0,  xmm3
        addps  xmm1,  xmm4

        movaps  [eax+ecx-p*dim*UNROLL_COORDINATE],  xmm0                      ; [xi, xi+1, xi+2, xi+3]
        movaps  [eax+ecx-p*dim],                    xmm1 

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_3
    
    movaps xmm0, [eax+ecx]
    movaps xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
    addps  xmm0,  xmm3
    movaps [eax+ecx],  xmm0 
next_3:
        mov     ecx,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     eax,    edx
for_blocco_coordinate_3:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        movaps  xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
        movaps  xmm4,   [esi+ecx-p*dim]

        addps  xmm0,  xmm3
        addps  xmm1,  xmm4

        movaps  [eax+ecx-p*dim*UNROLL_COORDINATE],  xmm0                      ; [xi, xi+1, xi+2, xi+3]
        movaps  [eax+ecx-p*dim],                    xmm1 

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_4
    
    movaps xmm0, [eax+ecx]
    movaps xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
    addps  xmm0,  xmm3
    movaps [eax+ecx],  xmm0 
next_4:
        mov     ecx,    p*dim*UNROLL_COORDINATE          ; coordinata
        add     eax,    edx
for_blocco_coordinate_4:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        movaps  xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
        movaps  xmm4,   [esi+ecx-p*dim]

        addps  xmm0,  xmm3
        addps  xmm1,  xmm4

        movaps  [eax+ecx-p*dim*UNROLL_COORDINATE],  xmm0                      ; [xi, xi+1, xi+2, xi+3]
        movaps  [eax+ecx-p*dim],                    xmm1 

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesci
    
    movaps xmm0, [eax+ecx]
    movaps xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
    addps  xmm0,  xmm3
    movaps [eax+ecx],  xmm0 
; fine for coordinate
next_pesci:
    add     eax,    edx ; indirizzo riga prossimo pesce
    add     ebx, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    sub ebx, UNROLL_PESCI
    cmp ebx, edi
    je  return
    
    addps   xmm6,   xmm5             ; somma parziale delta_f
    mov     esi,    [ebp+vector_i] ; esi <- indirizzo vettore vector_i
for_pesce:
    mov     ecx, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     ecx,    edx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        movaps  xmm0,   [eax+ecx-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        movaps  xmm1,   [eax+ecx-p*dim]                   ; [xi+4, ...,      xi+7]
        
        movaps  xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
        movaps  xmm4,   [esi+ecx-p*dim]

        addps  xmm0,  xmm3
        addps  xmm1,  xmm4

        movaps  [eax+ecx-p*dim*UNROLL_COORDINATE],  xmm0                      ; [xi, xi+1, xi+2, xi+3]
        movaps  [eax+ecx-p*dim],                    xmm1                   ; [xi+4, ...,      xi+7]

        add     ecx,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub ecx, p*dim*UNROLL_COORDINATE
    cmp ecx, edx
    je  next_pesce
    
    movaps xmm0, [eax+ecx]
    movaps xmm3,   [esi+ecx-p*dim*UNROLL_COORDINATE]
    addps  xmm0,  xmm3
    movaps [eax+ecx],  xmm0 
next_pesce:
    add     eax,  edx ; indirizzo riga prossimo pesce
    add     ebx,  1 ; aggiorna contatore pesci
    cmp     ebx, edi ; pesce+1 > n_pesci
    jb      for_pesce

return:

stop