%include 'sseutils32.nasm'

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    UNROLL        	equ		4

section .bss
    alignb 16
    m resd p

section .text
    global alimenta_asm

    input_np    equ     8
    delta_f     equ     12
    pesi        equ     16
    min_delta_f equ     20
    msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    nl	db	10,0
    ; prints msg
	; prints nl

alimenta_asm:
    start
    ; eax: indirizzo pesi
    ; ebx: indirizzo deltaf
    ; ecx: np*dim
    ; xmm0: min_delta_f replicato
    ; esi: pesce i-esimo

    mov     eax,    [ebp+pesi]
    mov     ebx,    [ebp+delta_f]
    mov     ecx,    [ebp+input_np]
    imul    ecx,    dim
    movss   xmm7,   [ebp+min_delta_f]
    ; xmm7 <-- [min_delta_f, x, x, x]
    shufps  xmm7,   xmm7, 00000000b 
    ; xmm7 <-- [min_delta_f, min_delta_f, min_delta_f, min_delta_f]
    
    mov     esi,    p*dim*UNROLL ; 16
for_pesci:
    cmp esi, ecx    ; i+16 > np esci
    jg fine_for_pesci

    movaps  xmm0,   [ebx+esi-p*dim*UNROLL]     ; [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]
    movaps  xmm1,   [ebx+esi-p*dim*(UNROLL-1)]   ; [deltaf_i+4, deltaf_i+5, deltaf_i+6, deltaf_i+7]
    movaps  xmm2,   [ebx+esi-p*dim*(UNROLL-2)]
    movaps  xmm3,   [ebx+esi-p*dim]

    divps   xmm0,   xmm7 ; deltaf_[i  ,..,i+3]/min_deltaf
    divps   xmm1,   xmm7 ; deltaf_[i+4,..,i+7]/min_deltaf
    divps   xmm2,   xmm7 
    divps   xmm3,   xmm7 

    addps   xmm0,   [eax+esi-p*dim*UNROLL]   ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    addps   xmm1,   [eax+esi-p*dim*(UNROLL-1)] ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    addps   xmm2,   [eax+esi-p*dim*(UNROLL-2)] 
    addps   xmm3,   [eax+esi-p*dim]   

    movaps  [eax+esi-p*dim*UNROLL],   xmm0
    movaps  [eax+esi-p*dim*(UNROLL-1)], xmm1
    movaps  [eax+esi-p*dim*(UNROLL-2)], xmm2
    movaps  [eax+esi-p*dim],          xmm3

    add esi, p*dim*UNROLL
    jmp for_pesci
fine_for_pesci:    
    sub esi, p*dim*UNROLL
    cmp esi, ecx
    je return

for_pesce:
    movss  xmm0,   [ebx+esi] ; [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]
    divss   xmm0,   xmm7      ; deltaf_[i  ,..,i+3]/min_deltaf
    addss   xmm0,   [eax+esi] ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    movss  [eax+esi],   xmm0

    add esi, dim
    cmp esi, ecx
    jb for_pesce
return:

stop


    