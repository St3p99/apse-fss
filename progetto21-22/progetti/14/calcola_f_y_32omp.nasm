%include 'sseutils32.nasm'

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)

    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2
    

section .bss


section .text
    global calcola_f_y_asm_omp

    input_x        equ     8
    matrix_y       equ     12
    d_piu_padding  equ     16
    deltax         equ     20
    vector_c       equ     24 
    y_2            equ     28
    c_y            equ     32
    
	; DEBUG
	msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl

calcola_f_y_asm_omp: 
    start

mov eax, [ebp+input_x]; mi serve indirizzo ultima coordinata ultimo pesce +4
mov ebx, [ebp+matrix_y]; mi serve ultima coordinata ultimo pesce
mov ecx, [ebp+d_piu_padding] ; d+padding
mov edi, [ebp+deltax]; stesso ragionamento di x e y (anche y_2 e c_y)
mov esi, [ebp+vector_c]; prendi ultimo elemento di c

	xorps xmm0, xmm0 ; azzerando xmm3 per mantenere la somma parziale di x2
	xorps xmm1, xmm1 ; azzerando xmm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate:
	cmp ecx, p*UNROLL_COORDINATE ; se uguale a 0 salta  
	jl fine_blocco_coordinate

	movaps xmm2, [ebx] ;y
	movaps xmm5, xmm2 ; copia y

	movaps xmm3,[eax]; x

	subps xmm5, xmm3 ; y-x
	movaps [edi], xmm5 ; y-x -> deltax
	
	movaps xmm4, [esi]; ci

	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	movaps xmm6, [ebx+p*dim] ;y
	add ebx, p*dim*UNROLL_COORDINATE
	movaps xmm5, xmm6 ; copia y

	movaps xmm7, [eax+p*dim]; x
	add eax, p*dim*UNROLL_COORDINATE
	
	subps xmm5,xmm7 ; y-x
	movaps [edi+p*dim], xmm5 ; y-x -> deltax
	add edi, p*dim*UNROLL_COORDINATE
	
	movaps xmm4,[esi+p*dim]; ci
	add esi, p*dim*UNROLL_COORDINATE
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
    addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    sub ecx, p*UNROLL_COORDINATE
	jmp for_blocco_coordinate
fine_blocco_coordinate:
	cmp ecx, 0 
    je fine_coordinate
; gestione_coordinate_rimanenti
	movaps xmm2, [ebx] ;y
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x	
	movaps [edi], xmm5 ; y-x -> deltax
	
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

fine_coordinate:
	haddps xmm0, xmm0
	haddps xmm0, xmm0 ; y^2 tot

	mov esi, [ebp+y_2]
	movss [esi], xmm0 ; rivedere solo qui indicizzazione
	
	haddps xmm1,xmm1
	haddps xmm1,xmm1

	mov esi, [ebp+c_y]
	movss [esi],xmm1

stop