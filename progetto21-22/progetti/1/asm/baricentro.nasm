%include 'sseutils32.nasm'

; CALCOLA NUMERATORE BARICENTRO
; Al momento funziona SOLO per coordinate multiple di 8.
; È necessario gestire singolarmente le restanti coordinate

; Rimane da calcolare il denominatore

section .data
    align 16
    x dd 0.118514,-0.005789,-0.043927,0.050299, -0.006771,0.055706,0.022781,-0.035088,     -0.099046, -0.088440, -0.074675, 0.028111,   -0.044493, -0.121398, -0.116429, 0.046918
    ; x dd 1,1,1,1,1,1,1,1, 2,2,2,2, 2,2,2,2
    align 16
    w dd 5.0, 5.0

    np      equ     2
    d		equ		8
    dim		equ		4
    p		equ		4
    UNROLL		equ		2

section .bss
    alignb 16
    r resd d
    m resd p

section .text
    global main
main: 
    start
    
; ricordarsi macro per allocazione dinamica

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

xorps   xmm0, xmm0
movaps [r], xmm0
movaps [r+16], xmm0

            mov     ebx,    0       ; pesce = 0
for_pesci:  
        mov     ecx,    0          ; coordinata
        imul    edi,    ebx, d     ; pesce*d
        movss   xmm2,   [w+ebx]
        shufps  xmm2,   xmm2, 00000000b
for_blocco_coordinate:  
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]
        
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm3, [r+ecx+p*dim]
        addps xmm3, xmm1
        movaps [r+ecx+p*dim], xmm3

        printps r, 2

        add     ecx,    p*dim*UNROLL
        cmp     ecx,    d
        jb      for_blocco_coordinate

        add     ebx, dim
        cmp     ebx, dim*np
        jb      for_pesci
 
        printss r
        printss r+4
        printss r+8
        printss r+12
        printss r+16
        printss r+20
        printss r+24
        printss r+28
stop