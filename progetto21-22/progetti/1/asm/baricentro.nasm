%include 'sseutils32.nasm'

; CALCOLA NUMERATORE BARICENTRO
; Al momento funziona SOLO per coordinate multiple di 8.
; È necessario gestire singolarmente le restanti coordinate

; Rimane da calcolare il denominatore

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

; section .data
;     align 16
;     inizio dd 0.3, 0.7, 0.3, 0.7
;     align 16
;     wi dd 5.0, 5.0, 5.0, 5.0

;     np      equ     65536
;     d		equ		4096
;     dim		equ		4
;     p		equ		4
;     UNROLL_PESCI        	equ		4
;     UNROLL_COORDINATE		equ		2

; section .bss
;     alignb 16
;     r resd d
;     alignb 16
;     x resd np*d
;     alignb 16
;     w resd np


section .data
    align 16
    x dd 0.118514,-0.005789,-0.043927,0.050299,-0.006771,0.055706,0.022781,-0.035088,-0.099046,-0.088440,-0.074675,0.028111,-0.044493,-0.121398,-0.116429,0.046918,-0.123355,0.054130,-0.112776,-0.004180,-0.010522,-0.005729,-0.116061,-0.083888,0.094159,-0.044261,0.117518,-0.095124,-0.036630,0.106961,-0.042848,0.006060
    align 16
    w dd 5.0, 5.0, 5.0, 5.0

    np      equ     4
    d		equ		8
    dim		equ		4
    p		equ		4
    UNROLL_PESCI        	equ		4
    UNROLL_COORDINATE		equ		2

section .bss
    alignb 16
    r resd d
    alignb 16
    m resd p

section .text
    global main
main: 
    start

; ; iniz. x
;     movaps xmm0, [inizio]
;     mov ebx, 0
;     mov ecx, np*d/p
; ciclo_x: movaps [x+ebx], xmm0
;     add ebx, p*dim
;     dec ecx
;     jnz ciclo_x

; ; iniz. w
;     movaps xmm0, [wi]
;     mov ebx, 0
;     mov ecx, np/p
; ciclo_w: movaps [w+ebx], xmm0
;     add ebx, p*dim
;     dec ecx
;     jnz ciclo_w

; azzera r
    xorps xmm0, xmm0
    mov ebx, 0
    mov ecx, d/p
ciclo_r: movaps [r+ebx], xmm0
    add ebx, p*dim
    dec ecx
    jnz ciclo_r

xorps   xmm6,   xmm6

    mov     ebx,    0       ; pesce = 0
for_pesci:  
    mov     ecx,    0          ; coordinata
    imul    edi,    ebx, d     ; pesce*d
    movaps  xmm5,   [w+ebx]
    addps   xmm6,   xmm5       ; somma parziale pesi
    shufps  xmm2,   xmm5, 00000000b
    shufps  xmm2,   xmm2, 10101010b  ; peso 0 su tutto xmm2
for_blocco_coordinate:
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]

        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm4, [r+ecx+p*dim]
        addps xmm4, xmm1
        movaps [r+ecx+p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        cmp     ecx,    d
        jb      for_blocco_coordinate
; fine for_blocco_coordinate
        mov     ecx,    0          ; coordinata
        add     edi,    d*dim    ; (pesce+1)*d
        shufps  xmm2,   xmm5, 01010101b  ; peso 1
        shufps  xmm2,   xmm2, 10101010b  ; peso 1 su tutto xmm2
for_blocco_coordinate_2:
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm4, [r+ecx+p*dim]
        addps xmm4, xmm1
        movaps [r+ecx+p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        cmp     ecx,    d
        jb      for_blocco_coordinate_2
; fine for_blocco_coordinate_2
        mov     ecx,    0          ; coordinata
        add     edi,    d*dim         ; (pesce+2)*d
        shufps  xmm2,   xmm5, 10101010b  ; peso 2
        shufps  xmm2,   xmm2, 10101010b  ; peso 2 su tutto xmm2
for_blocco_coordinate_3:  
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]
        
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm4, [r+ecx+p*dim]
        addps xmm4, xmm1
        movaps [r+ecx+p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        cmp     ecx,    d
        jb      for_blocco_coordinate_3
; fine for_blocco_coordinate_3
        mov     ecx,    0          ; coordinata
        add     edi,    d*dim         ; (pesce+3)*d
        shufps  xmm2,   xmm5, 11111111b  ; peso 3
        shufps  xmm2,   xmm2, 10101010b  ; peso 3 su tutto xmm2
for_blocco_coordinate_4:
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]
        
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm4, [r+ecx+p*dim]
        addps xmm4, xmm1
        movaps [r+ecx+p*dim], xmm4

        add     ecx,    p*dim*UNROLL_COORDINATE
        cmp     ecx,    d
        jb      for_blocco_coordinate_4
; fine for_blocco_coordinate_4
        add     ebx, dim*UNROLL_PESCI
        cmp     ebx, dim*np
        jb      for_pesci
; fine for_pesci

    haddps  xmm6, xmm6
    haddps  xmm6, xmm6

    mov ebx, 0
    mov ecx, d/p
for_div: 
    movaps xmm0,    [r+ebx]
    divps  xmm0,    xmm6
    movaps [r+ebx], xmm0

    movaps xmm1,          [r+ebx+p*dim]
    divps  xmm1,          xmm6
    movaps [r+ebx+p*dim], xmm1

    add ebx, p*dim*UNROLL_COORDINATE
    dec ecx
    jnz for_div

    printss r
    printss r+4
    printss r+8
    printss r+12
    printss r+16
    printss r+20
    printss r+24
    printss r+28
stop

; nasm -f elf32 ./asm/baricentro.nasm  -o ./asm/baricentro.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro.o -o ./asm/baricentro && time ./asm/baricentro