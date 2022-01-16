%include 'sseutils64.nasm'

section .data
    dim		equ		8       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)

    UNROLL_COORDINATE		equ		2
    

section .bss
    alignb 32
	np_meno_unroll resd 1
	
	alignb 32
	m resq p

section .text
    global calcola_f_y_asm_omp

    c_y            equ     16
    
	msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl

calcola_f_y_asm_omp: 
    start

; mov rdi, [ebp+input_x]; mi serve indirizzo ultima coordinata ultimo pesce +4
; mov rsi, [ebp+matrix_y]; mi serve ultima coordinata ultimo pesce
; mov ecx, [ebp+d_piu_padding] ; d+padding
; mov rcx, [ebp+deltax]; stesso ragionamento di x e y (anche y_2 e c_y)
; mov esi, [ebp+vector_c]; prendi ultimo elemento di c

; calcola_f_y_asm(
; 	input->x, 					RDI
; 	y, 							RSI
; 	n_coordinate+padding_d, 	RDX
; 	deltax, 					rcx 
; 	input->c, 					r8 
; 	y_quadro, 					// r9
; 	c_per_y						// r11 -- STACK: RBP+16 
; )

	imul rdx, dim

	mov r11, [rbp+c_y]

	mov     r10,    p*dim*UNROLL_COORDINATE                ; coordinata
	vxorpd ymm0, ymm0 ; azzerando ymm3 per mantenere la somma parziale di x2
	vxorpd ymm1, ymm1 ; azzerando ymm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate:
	cmp     r10,    rdx                ; if( i+8 > n_coordinate )
	jg fine_blocco_coordinate

	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x

	vsubpd ymm5, ymm3 ; y-x
	vmovapd [rcx], ymm5 ; y-x -> deltax
	
	vmovapd ymm4, [r8+r10-p*dim*UNROLL_COORDINATE]; ci

	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	vmovapd ymm6, [rsi+p*dim] ;y
	vmovapd ymm5, ymm6 ; copia y

	vmovapd ymm7, [rdi+p*dim]; x
	
	vsubpd ymm5,ymm7 ; y-x
	vmovapd [rcx+p*dim], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r8+r10-p*dim]; ci
	vmulpd ymm4,ymm6 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm6,ymm6 ; yi*yi
    vaddpd ymm0,ymm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    add		rsi,    p*dim*UNROLL_COORDINATE
	add		rdi,    p*dim*UNROLL_COORDINATE
	add		rcx,     p*dim*UNROLL_COORDINATE
	add     r10,    p*dim*UNROLL_COORDINATE
	jmp for_blocco_coordinate
fine_blocco_coordinate:
    sub r10, p*dim*UNROLL_COORDINATE
    cmp r10, rdx
    je fine_coordinate

; gestione_coordinate_rimanenti
	vmovapd ymm2, [rsi] ;y
	vmovapd ymm5, ymm2 ; copia y

	vmovapd ymm3, [rdi]; x
	
	vsubpd ymm5,ymm3 ; y-x
	vmovapd [rcx], ymm5 ; y-x -> deltax
	
	vmovapd ymm4,[r8+r10]; ci
	
	vmulpd ymm4,ymm2 ; ci*yi
	vaddpd ymm1,ymm4 ; tengo la somma parziale al fine di calcolare c*y tot

	vmulpd ymm2,ymm2 ; yi*yi
    vaddpd ymm0,ymm2 ; tengo la somma parziale al fine di calcolare y^2 tot	
	
	add rsi, p*dim
	add rdi, p*dim
	add rcx, p*dim
fine_coordinate:
	;// ymm0 = [ x3		x2 		x1		x0 ]
	;// ymm15 = [ x1     x0 		x3		x2 ]
	VPERM2F128 ymm15, ymm0, ymm0, 00000001b
	vhaddpd ymm0, ymm15, ymm0
	vhaddpd ymm0, ymm0, ymm0

	vmovsd [r9], xmm0 ; rivedere solo qui indicizzazione
	
	VPERM2F128 ymm15, ymm1, ymm1, 00000001b
	vhaddpd ymm1, ymm15, ymm1
	vhaddpd ymm1, ymm1, ymm1
	
	vmovsd [r11], xmm1



stop
