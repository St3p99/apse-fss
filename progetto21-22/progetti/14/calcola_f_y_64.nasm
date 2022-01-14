%include 'sseutils64.nasm'

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)

    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2
    

section .bss
    alignb 32
	np_meno_unroll resd 1
	
	alignb 32
	m resq p

section .text
    global calcola_f_y_asm

    y_2            equ     16
    c_y            equ     24
    
	msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl

calcola_f_y_asm: 
    start

; mov rdi, [ebp+input_x]; mi serve indirizzo ultima coordinata ultimo pesce +4
; mov rsi, [ebp+matrix_y]; mi serve ultima coordinata ultimo pesce
; mov ecx, [ebp+d_piu_padding] ; d+padding
; mov r8, [ebp+deltax]; stesso ragionamento di x e y (anche y_2 e c_y)
; mov esi, [ebp+vector_c]; prendi ultimo elemento di c

; calcola_f_y_asm(
; 	input->x, 					RDI
; 	y, 							RSI
; 	n_pesci, 					RDX
; 	n_coordinate+padding_d, 	RCX
; 	deltax, 					R8
; 	input->c, 					R9
; 	y_quadro, 					// r11 -- STACK: RBP+8
; 	c_per_y						// r11 -- STACK: RBP+16
; )

imul rcx, dim
sub rdx, UNROLL_PESCI
xor rax, rax
for_pesci:
	cmp     rax, rdx
	jg      fine_for_pesci

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate:
	cmp     r10,    rcx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r9+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [r8+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		r8,     p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate
fine_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je fine_coordinate

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot	
	
	add rsi, p*dim
	add rdi, p*dim
	add r8, p*dim
fine_coordinate:
	;// ymm0 = [ x3		x2 		x1		x0 ]
	;// ymm15 = [ x1     x0 		x3		x2 ]
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	mov r11, [rbp+y_2]
	vmovsd [r11+rax*dim], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	mov r11, [rbp+c_y]
	vmovsd [r11+rax*dim], xmm1

	inc rax ; prossimo pesce

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate_2:
	cmp     r10,    rcx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate_2

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r9+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [r8+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		r8,    p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate_2
fine_blocco_coordinate_2:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je fine_coordinate_2

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	add rsi, p*dim
	add rdi, p*dim
	add r8, p*dim
fine_coordinate_2:
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	mov r11, [rbp+y_2]
	vmovsd [r11+rax*dim], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	mov r11, [rbp+c_y]
	vmovsd [r11+rax*dim], xmm1

	inc rax ; prossimo pesce

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate_3:
	cmp     r10,    rcx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate_3

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r9+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [r8+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		r8,    p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate_3
fine_blocco_coordinate_3:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je fine_coordinate_3

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	add rsi, p*dim
	add rdi, p*dim
	add r8, p*dim
fine_coordinate_3:
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	mov r11, [rbp+y_2]
	vmovsd [r11+rax*dim], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	mov r11, [rbp+c_y]
	vmovsd [r11+rax*dim], xmm1

	inc rax ; prossimo pesce

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate_4:
	cmp     r10,    rcx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate_4

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r9+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [r8+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		r8,    p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate_4
fine_blocco_coordinate_4:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je fine_coordinate_4

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	add rsi, p*dim
	add rdi, p*dim
	add r8, p*dim
fine_coordinate_4:
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	mov r11, [rbp+y_2]
	vmovsd [r11+rax*dim], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	mov r11, [rbp+c_y]
	vmovsd [r11+rax*dim], xmm1
	
	inc rax ; prossimo pesce

	jmp for_pesci
;;;;;;;; gestione singolo pesce ne restano  da 3 a 1
fine_for_pesci:

add rdx, UNROLL_PESCI ; rdx == np
for_pesce:
	cmp     rax, rdx  ; 
	jge     fine_for_pesce

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate_extra:
	cmp     r10,    rcx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate_extra

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r9+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [r8+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		r8,    p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate_extra
fine_blocco_coordinate_extra:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rcx
    je fine_coordinate_extra

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [r8], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r9+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	add rsi, p*dim
	add rdi, p*dim
	add r8, p*dim
fine_coordinate_extra:
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	mov r11, [rbp+y_2]
	vmovsd [r11+rax*dim], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	mov r11, [rbp+c_y]
	vmovsd [r11+rax*dim], xmm1
	
	inc rax ; prossimo pesce

	jmp for_pesce
fine_for_pesce:

stop
