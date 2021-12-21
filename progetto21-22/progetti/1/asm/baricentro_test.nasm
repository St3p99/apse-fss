%include 'sseutils32.nasm'

; CALCOLA NUMERATORE BARICENTRO
; Al momento funziona SOLO per coordinate multiple di 8.
; È necessario gestire singolarmente le restanti coordinate

; Rimane da calcolare il denominatore

section .data
    align 16
    inizio dd 0.3, 0.7, 0.3, 0.7
    align 16
    wi dd 5.0, 5.0, 5.0, 5.0

    np      equ     65536
    d		equ		4096
    dim		equ		4
    p		equ		4
    UNROLL		equ		2

section .bss
    alignb 16
    r resd d
    alignb 16
    m resd p
    alignb 16
    x resd np*d
    alignb 16
    w resd np

section .text
    global main
main: 
    start
    
; iniz. x
    movaps xmm0, [inizio]
    mov ebx, 0
    mov ecx, np*d/4
ciclo: movaps [x+ebx], xmm0
    add ebx, 16
    dec ecx
    jnz ciclo

; iniz. w
    movaps xmm0, [wi]
    mov ebx, 0
    mov ecx, np/4
ciclo1: movaps [w+ebx], xmm0
    add ebx, 16
    dec ecx
    jnz ciclo1

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

; azzera r
    xorps xmm0, xmm0
    mov ebx, 0
    mov ecx, d/4
ciclo: movaps [r+ebx], xmm0
    add ebx, 16
    dec ecx
    jnz ciclo

        mov     ebx,    0       ; pesce = 0
for_pesci:  
        mov     ecx,    0          ; coordinata
        imul    edi,    ebx, d     ; pesce*d
        movss   xmm2,   [w+ebx]
        shufps  xmm2,   xmm2, 00000000b
        ; movaps  xmm5,   xmm2
for_blocco_coordinate:  
        movaps  xmm0,   [x+edi+ecx]
        movaps  xmm1,   [x+edi+ecx+p*dim]
        
        mulps   xmm0,   xmm2
        mulps   xmm1,   xmm2
        ; mulps   xmm1,   xmm5
        
        movaps xmm3, [r+ecx]
        addps xmm3, xmm0
        movaps [r+ecx], xmm3
        
        movaps xmm4, [r+ecx+p*dim]
        addps xmm4, xmm1
        movaps [r+ecx+p*dim], xmm4

        add     ecx,    p*dim*UNROLL
        cmp     ecx,    d
        jb      for_blocco_coordinate
; fine for_blocco_coordinate
        add     ebx, dim
        cmp     ebx, dim*np
        jb      for_pesci
; fine for_pesci
stop

; nasm -f elf32 ./asm/baricentro_test.nasm  -o ./asm/baricentro_test.o && gcc -m32 -no-pie sseutils32.o ./asm/baricentro_test.o -o ./asm/baricentro_test && time ./asm/baricentro_test