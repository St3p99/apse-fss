%include 'sseutils64.nasm'

; CALCOLA VETTORE I (Movimento istintivo)


section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)
    zero    equ     0
    UNROLL_COORDINATE		equ		2

section .bss
    ; DEBUG
    ; alignb 16
    ; m resd p

section .text
    global mov_istintivo_asm_omp

    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

mov_istintivo_asm_omp: 
    start

    ; rdi -> x
    ; rsi -> d+padding
    ; rdx -> I
    
    imul    rsi,    dim                                    ; input_d*dim
    mov     r11,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     r11,    rsi                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rdx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rdx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1                   ; [xi+4, ...,      xi+7]

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rsi
    je  return
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rdx+r11]
    vmovapd [rdi+r11],  ymm0 

; fine for coordinate

return:
    stop