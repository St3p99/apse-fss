%include 'sseutils64.nasm'

; CALCOLA VETTORE I (Movimento istintivo)


section .data
    dim		equ		8       ; dimensione operandi float (4byte)
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

    ; DEBUG
    ; msg	db	'ECCOCIIIII!!!!!!!!!',32,0
    ; nl	db	10,0
    ; prints msg
	; prints nl

mov_istintivo_asm: 
    start

    ; rdi -> x
    ; rsi-> np
    ; rdx -> d+padding
    ; rcx -> I

    imul    rdx,    dim        ; input_d*dim
    mov     r10,    UNROLL_PESCI          ; pesce i = 0
for_pesci:
    cmp     r10, rsi ; pesce+4 > n_pesci
    jg      fine_for_pesci

    mov     r11,    p*dim*UNROLL_COORDINATE                ; coordinata
for_blocco_coordinate:
        cmp     r11,    rdx                ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate  ;   esci
        
        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rcx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rcx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1                   ; [xi+4, ...,      xi+7]

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate
fine_for_blocco_coordinate:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rdx
    je  next_2
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rcx+r11]
    vmovapd [rdi+r11],  ymm0 
next_2:
        mov     r11,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     rdi,    rdx        ; (pesce+1)*d = pesce*d + d
for_blocco_coordinate_2:
        cmp     r11,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_2  ;   esci

        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rcx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rcx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1 

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_2
fine_for_blocco_coordinate_2:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rdx
    je  next_3
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rcx+r11]
    vmovapd [rdi+r11],  ymm0 
next_3:
        mov     r11,    p*dim*UNROLL_COORDINATE         ; coordinata
        add     rdi,    rdx
for_blocco_coordinate_3:
        cmp     r11,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_3  ;   esci

        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rcx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rcx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1 

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_3
fine_for_blocco_coordinate_3:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rdx
    je  next_4
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rcx+r11]
    vmovapd [rdi+r11],  ymm0 
next_4:
        mov     r11,    p*dim*UNROLL_COORDINATE          ; coordinata
        add     rdi,    rdx
for_blocco_coordinate_4:
        cmp     r11,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_4  ;   esci

        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rcx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rcx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1 

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_4
fine_for_blocco_coordinate_4:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rdx
    je  next_pesci
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rcx+r11]
    vmovapd [rdi+r11],  ymm0 
; fine for coordinate
next_pesci:
    add     rdi,    rdx ; indirizzo riga prossimo pesce
    add     r10, UNROLL_PESCI ; aggiorna contatore pesci
    jmp     for_pesci

fine_for_pesci:
    sub r10, UNROLL_PESCI
    cmp r10, rsi
    je  return
    
    vaddpd   ymm6,   ymm5             ; somma parziale delta_f
for_pesce:
    mov     r11, p*dim*UNROLL_COORDINATE
for_blocco_coordinate_extra:
        cmp     r11,    rdx                 ; if( i+8 > n_coordinate )
        jg      fine_for_blocco_coordinate_extra  ;   esci

        vmovapd  ymm0,   [rdi+r11-p*dim*UNROLL_COORDINATE] ; [xi, xi+1, xi+2, xi+3]
        vmovapd  ymm1,   [rdi+r11-p*dim]                   ; [xi+4, ...,      xi+7]
        
        vmovapd  ymm3,   [rcx+r11-p*dim*UNROLL_COORDINATE]
        vmovapd  ymm4,   [rcx+r11-p*dim]

        vaddpd  ymm0,  ymm3
        vaddpd  ymm1,  ymm4

        vmovapd  [rdi+r11-p*dim*UNROLL_COORDINATE],  ymm0                      ; [xi, xi+1, xi+2, xi+3]
        vmovapd  [rdi+r11-p*dim],                    ymm1                   ; [xi+4, ...,      xi+7]

        add     r11,    p*dim*UNROLL_COORDINATE
        jmp     for_blocco_coordinate_extra
fine_for_blocco_coordinate_extra:
    sub r11, p*dim*UNROLL_COORDINATE
    cmp r11, rdx
    je  next_pesce
    
    vmovapd ymm0, [rdi+r11]
    vaddpd  ymm0,  [rcx+r11]
    vmovapd [rdi+r11],  ymm0 
next_pesce:
    add     rdi,  rdx ; indirizzo riga prossimo pesce
    add     r10,  1 ; aggiorna contatore pesci
    cmp     r10, rsi ; pesce+1 > n_pesci
    jb      for_pesce

return:

stop