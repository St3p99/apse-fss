%include 'sseutils64.nasm'

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    UNROLL        	equ		4

section .bss
    ; DEBUG
    ; alignb 32
    ; m resq p

section .text
    global alimenta_asm

    ; input_np    equ     8
    ; delta_f     equ     12
    ; pr8        equ     16
    ; min_delta_f equ     20
    
    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

alimenta_asm:
    start
    ; rdx: indirizzo pr8
    ; rsi: indirizzo deltaf
    ; rdi: np*dim
    ; ymm0: min_delta_f replicato
    ; r8: pesce i-r8mo

    ; alimenta_asm(
    ;     input->np+input->padding_np,      //RDI
    ;     deltaf,                           //RSI
    ;     pr8,                             //RDX
    ;     mindeltaf                         // ymm0
    ; )

    imul    rdi,     dim

    ; ymm0 <-- [x, x, x, min_delta_f]
    vpermilps   ymm7, ymm0, 01000100b
    ; ymm7 <-- [x, x, min_delta_f, min_delta_f]
    vperm2f128  ymm7, ymm7, ymm7, 00000000b
    ; ymm7 <-- [min_delta_f, min_delta_f, min_delta_f, min_delta_f]
    
    mov     r8,    p*dim*UNROLL 
for_pesci:
    cmp r8, rdi    ; i+16 > np esci
    jg fine_for_pesci

    vmovapd  ymm0,   [rsi+r8-p*dim*UNROLL]     ; [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]
    vmovapd  ymm1,   [rsi+r8-p*dim*(UNROLL-1)]   ; [deltaf_i+4, deltaf_i+5, deltaf_i+6, deltaf_i+7]
    vmovapd  ymm2,   [rsi+r8-p*dim*(UNROLL-2)]
    vmovapd  ymm3,   [rsi+r8-p*dim]

    vdivpd   ymm0,   ymm7 ; deltaf_[i  ,..,i+3]/min_deltaf
    vdivpd   ymm1,   ymm7 ; deltaf_[i+4,..,i+7]/min_deltaf
    vdivpd   ymm2,   ymm7 
    vdivpd   ymm3,   ymm7 

    vaddpd   ymm0,   [rdx+r8-p*dim*UNROLL]   ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    vaddpd   ymm1,   [rdx+r8-p*dim*(UNROLL-1)] ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    vaddpd   ymm2,   [rdx+r8-p*dim*(UNROLL-2)] 
    vaddpd   ymm3,   [rdx+r8-p*dim]   

    vmovapd  [rdx+r8-p*dim*UNROLL],   ymm0
    vmovapd  [rdx+r8-p*dim*(UNROLL-1)], ymm1
    vmovapd  [rdx+r8-p*dim*(UNROLL-2)], ymm2
    vmovapd  [rdx+r8-p*dim],          ymm3

    add r8, p*dim*UNROLL
    jmp for_pesci
fine_for_pesci:    
    sub r8, p*dim*UNROLL
    cmp r8, rdi
    je return

for_pesce:
    vmovsd  xmm0,   [rsi+r8] ; [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]
    vdivsd  xmm0,   xmm7      ; deltaf_[i  ,..,i+3]/min_deltaf
    vaddsd  xmm0,   [rdx+r8] ; [wi, wi+1, wi+2, wi+3]  + [deltaf_i, deltaf_i+1, deltaf_i+2, deltaf_i+3]/min_delta_f
    vmovsd  [rdx+r8],   xmm0

    add r8, dim
    cmp r8, rdi
    jb for_pesce
return:

stop


    