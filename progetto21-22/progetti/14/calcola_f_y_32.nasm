%include 'sseutils32.nasm'

; CALCOLA BARICENTRO

; per ogni pesce p [p=0]
    ; per ogni blocco da 8 coordinate
        ; XMM0 <- primo blocco da 4 (coordinate) [x00, x01, x02, x03]
        ; XMM1 <- secondo blocco da 4 (coordinate) [x04, x05, x06, x07]
        ; XMM2 <- peso[p] per tutti gli elementi del registro [w0]
        ; XMM0 <- XMM0*XMM2 [x00*w0, x01*w0, x02*w0, x03*w0]
        ; XMM1 <- XMM1*XMM2 [x04*w0, x05*w0, x06*w0, x07*w0]
        ; ADDPS MEM[blocco i], XMM0 [num0, num1, num2, num3]
        ; ADDPS MEM[blocco i+1], XMM1 [num4, num5, num6, num7]

;   0    1    2    3    4    5    6    7       8    9   10   11   12    13   14   15
; [x00, x01, x02, x03, x04, x05, x06, x07] - [x10, x11, x12, x13, x14, x15, x16, x17]

; Accesso alla matrice per riga [i][j] => [i*n_colonne+j]
; Inoltre, prendiamo blocchi di 4

section .data
    dim		equ		4       ; dimensione operandi float (4byte)
    p		equ		4       ; packed (4 elementi alla volta)

    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2
    

section .bss
    alignb 16
    m resd p

section .text
    global calcola_f_y_asm

    input_x        equ     8
    matrix_y       equ     12
    np             equ     16
    d_piu_padding  equ     20
    deltax         equ     24
    vector_c       equ     28 
    y_2            equ     32
    c_y            equ     36
    msg	           db	    'ECCOCIIIII!!!!!!!!!',32,0
    nl	           db	10,0
    ; prints msg
	; prints nl

calcola_f_y_asm: 
    start

mov eax, [ebp+input_x]; mi serve indirizzo ultima coordinata ultimo pesce +4
mov ebx, [ebp+matrix_y]; mi serve ultima coordinata ultimo pesce
mov ecx, [ebp+d_piu_padding] ; d+padding
mov edx, [ebp+np]
imul edx, dim
mov edi, [ebp+deltax]; stesso ragionamento di x e y (anche y_2 e c_y)
mov esi, [ebp+vector_c]; prendi ultimo elemento di c



for_pesci:
	cmp     edx, UNROLL_PESCI*dim
	jl      for_pesce
	
	xorps xmm0, xmm0 ; azzerando xmm3 per mantenere la somma parziale di x2
	xorps xmm1, xmm1 ; azzerando xmm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate:
	cmp ecx, p*UNROLL_COORDINATE ; se uguale a 0 salta  
	jl fine_blocco_coordinate

    sub ebx, p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax, p*dim
	movaps xmm3,[eax]; x

	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4, [esi]; ci

	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	sub ebx, p*dim
	movaps xmm6, [ebx] ;y
	movaps xmm5,xmm6 ; copia y

	sub eax, p*dim
	movaps xmm7,[eax]; x
	
	subps xmm5,xmm7 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
    addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
    sub ecx, p*UNROLL_COORDINATE
	jmp for_blocco_coordinate
fine_blocco_coordinate:
	cmp ecx, 0 
        je fine_coordinate
gestione_coordinate_rimanenti:
	sub ebx, p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax, p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

	sub ecx, p
    cmp ecx, 0
	jg gestione_coordinate_rimanenti

fine_coordinate:
	haddps xmm0, xmm0
	haddps xmm0, xmm0 ; y^2 tot
	
	mov ecx, [ebp+y_2]
	sub ecx, dim
	movss [ecx], xmm0 ; rivedere solo qui indicizzazione
	mov [ebp+y_2], ecx

	haddps xmm1,xmm1
	haddps xmm1,xmm1
	mov ecx, [ebp+c_y]
    sub ecx, dim
	movss [ecx],xmm1
	mov [ebp+c_y], ecx

	mov ecx, [ebp+d_piu_padding]
	mov esi, [ebp+vector_c]
	sub edx, dim

	xorps xmm0, xmm0
	xorps xmm1, xmm1
for_blocco_coordinate_2:
	cmp ecx, 8 ; se uguale a 0 salta  
	jl fine_blocco_coordinate_2

	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
        addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ebx,p*dim
	movaps xmm6, [ebx] ;y
	movaps xmm5,xmm6 ; copia y

	sub eax,p*dim
	movaps xmm7,[eax]; x
	
	subps xmm5,xmm7 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
        addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ecx, p*UNROLL_COORDINATE
    jmp for_blocco_coordinate_2
fine_blocco_coordinate_2:
	cmp ecx, 0 
        je fine_coordinate_2
gestione_coordinate_rimanenti_2:
	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
        addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

	sub ecx, p
    cmp ecx, 0
	jg gestione_coordinate_rimanenti_2

fine_coordinate_2:
	haddps xmm0,xmm0
	haddps xmm0,xmm0 ; y^2 tot
	
	mov ecx, [ebp+y_2]
    sub ecx, dim
	movss [ecx],xmm0
	mov [ebp+y_2], ecx ; rivedere solo qui indicizzazione

	haddps xmm1,xmm1
	haddps xmm1,xmm1
	mov ecx, [ebp+c_y]
    sub ecx, dim
	movss [ecx],xmm1
	mov [ebp+c_y], ecx

	mov ecx,[ebp+d_piu_padding]
	mov esi, [ebp+vector_c]
	sub edx, dim

	xorps xmm0, xmm0
	xorps xmm1, xmm1
for_blocco_coordinate_3:
	cmp ecx, 8 ; se uguale a 0 salta  
	jl fine_blocco_coordinate_3

	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
        addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ebx,p*dim
	movaps xmm6, [ebx] ;y
	movaps xmm5,xmm6 ; copia y

	sub eax,p*dim
	movaps xmm7,[eax]; x
	
	subps xmm5,xmm7 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
        addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ecx, p*UNROLL_COORDINATE
    jmp for_blocco_coordinate_3
fine_blocco_coordinate_3:
	cmp ecx, 0 
        je fine_coordinate_3
gestione_coordinate_rimanenti_3:
	
	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
        addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

	sub ecx, p
    cmp ecx, 0
	jg gestione_coordinate_rimanenti_3

fine_coordinate_3:
	haddps xmm0,xmm0
	haddps xmm0,xmm0 ; y^2 tot
	
	mov ecx, [ebp+y_2]
    sub ecx, dim
	movss [ecx],xmm0
mov [ebp+y_2], ecx ; rivedere solo qui indicizzazione

	haddps xmm1,xmm1
	haddps xmm1,xmm1
	mov ecx, [ebp+c_y]
    sub ecx, dim
	movss [ecx],xmm1
mov [ebp+c_y], ecx

	mov ecx,[ebp+d_piu_padding]
	mov esi, [ebp+vector_c]
	sub edx, dim

	xorps xmm0, xmm0
	xorps xmm1, xmm1
for_blocco_coordinate_4:
	cmp ecx, 8 ; se uguale a 0 salta  
	jl fine_blocco_coordinate_4

	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ebx,p*dim
	movaps xmm6, [ebx] ;y
	movaps xmm5,xmm6 ; copia y

	sub eax,p*dim
	movaps xmm7,[eax]; x
	
	subps xmm5,xmm7 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
        addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ecx, p*UNROLL_COORDINATE
    jmp for_blocco_coordinate_4
fine_blocco_coordinate_4:
	cmp ecx, 0 
        je fine_coordinate_4
gestione_coordinate_rimanenti_4:
	
	sub ebx,p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax,p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim 
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

	sub ecx, p
    cmp ecx, 0
	jg gestione_coordinate_rimanenti_4
fine_coordinate_4:
	haddps xmm0,xmm0
	haddps xmm0,xmm0 ; y^2 tot
	
	mov ecx, [ebp+y_2]
    sub ecx, dim
	movss [ecx], xmm0 ; rivedere solo qui indicizzazione
	mov [ebp+y_2], ecx

	haddps xmm1,xmm1
	haddps xmm1,xmm1
	mov ecx, [ebp+c_y]
    sub ecx, dim
	movss [ecx],xmm1
	mov [ebp+c_y], ecx

	mov ecx,[ebp+d_piu_padding]
	mov esi, [ebp+vector_c]
	sub edx, dim
	jmp for_pesci

;;;;;;;; gestione singolo pesce ne restano  da 3 a 1
for_pesce:
	cmp     edx, 0  ; 
	je      fine_for_pesce
	
	xorps xmm0, xmm0 ; azzerando xmm3 per mantenere la somma parziale di x2
	xorps xmm1, xmm1 ; azzerando xmm3 per mantenere la somma parziale di c_per_x
for_blocco_coordinate_end:
	cmp ecx, p*UNROLL_COORDINATE ; se uguale a 0 salta  
	jl fine_blocco_coordinate_end

    sub ebx, p*dim
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax, p*dim
	movaps xmm3,[eax]; x

	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4, [esi]; ci

	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot
	;--
	sub ebx, p*dim
	movaps xmm6, [ebx] ;y
	movaps xmm5,xmm6 ; copia y

	sub eax, p*dim
	movaps xmm7,[eax]; x
	
	subps xmm5,xmm7 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm6 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm6,xmm6 ; yi*yi
    addps xmm0,xmm6 ; tengo la somma parziale al fine di calcolare y^2 tot
	
	sub ecx, p*UNROLL_COORDINATE
    jmp for_blocco_coordinate_end
fine_blocco_coordinate_end:
	cmp ecx, 0 
    je fine_coordinate_end
gestione_coordinate_rimanenti_end:
	movaps xmm2, [ebx] ;y
	movaps xmm5,xmm2 ; copia y

	sub eax, p*dim
	movaps xmm3,[eax]; x
	
	subps xmm5,xmm3 ; y-x
	sub edi, p*dim
	movaps [edi], xmm5 ; y-x -> deltax
	
	sub esi, p*dim
	movaps xmm4,[esi]; ci
	mulps xmm4,xmm2 ; ci*yi
	addps xmm1,xmm4 ; tengo la somma parziale al fine di calcolare c*y tot

	mulps xmm2,xmm2 ; yi*yi
    addps xmm0,xmm2 ; tengo la somma parziale al fine di calcolare y^2 tot

	sub ecx, p
    cmp ecx, 0
	jg gestione_coordinate_rimanenti_end
fine_coordinate_end:
	haddps xmm0,xmm0
	haddps xmm0,xmm0 ; y^2 tot
	
	mov ecx, [ebp+y_2]
    sub ecx, dim
	movss [ecx],xmm0
	mov [ebp+y_2], ecx ; rivedere solo qui indicizzazione

	haddps xmm1,xmm1
	haddps xmm1,xmm1
	mov ecx, [ebp+c_y]
    sub ecx, dim
	movss [ecx],xmm1
	mov [ebp+c_y], ecx

	mov ecx,[ebp+d_piu_padding]
	mov esi, [ebp+vector_c]

	sub edx, dim
	jmp for_pesce
fine_for_pesce:

stop