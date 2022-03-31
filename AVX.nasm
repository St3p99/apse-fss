%include 'sseutils64.nasm'
; AVX: Advanced Vector Extensions
; 8 nuovi registri a 256 YMM0... YMM7 		a 32 bit
; YMM0... YMM15 a 64 bit
; i registri YMM sono l'estensione dei corrispondenti X

section .data
	align 32
	v	dd	1.2, 2.3, 5.4, 6.5, 7.3, 6.4, 7.5, 8.6
	align 32
	w	dd	2.2, 4.3, 3.4, 4.5, 5.3, 8.4, 9.5, 14.6
	align 32
	t	dd	3, 2, 0, 1, 0, 3, 1, 2

section .bss
	alignb 32
	s	resd	8
section .text
	global main
main:
	start
	
	; AVX: la maggior parte aggiungono il previsso V
	VMOVAPS		YMM0, [v]
	VMOVAPS		[s], YMM0
	printps		s, 2
	VMOVAPS		YMM1, [w]
	VMOVAPS		[s], YMM1
	printps		s, 2

	; SE LE ISTRUZIONI AVX SONO ESEGUITE SU REGISTRI X
	; LA PARTE ALTA DI Y SI AZZERA
	VMOVAPS		YMM0, [v]
	VMOVAPS		XMM0, [w]
	VMOVAPS		[s], YMM0
	printps		s, 2
	
	; SE ESEGUO ISTRUZIONI SSE
	; LA PARTE ALTA RESTA INALTERATA
	VMOVAPS		YMM0, [v]
	MOVAPS		XMM0, [w]
	VMOVAPS		[s], YMM0
	printps		s, 2
	
	; NON ESISTE VMOVSS SU REGISTRI Y
	;VMOVSS		YMM0, [v]

	; VMOVSS SU X AZZERA PARTE ALTA DI X E DI Y
	VMOVAPS		YMM0, [v]
	VMOVSS		XMM0, [v]
	VMOVAPS		[s], YMM0
	printps		s, 2

	; MOVSS AZZERA PARTE ALTA DI X E LASCIA PARTE ALTA DI Y
	VMOVAPS		YMM0, [v]
	MOVSS		XMM0, [v]
	VMOVAPS		[s], YMM0
	printps		s, 2

	; NON MESCOLARE AVX E SSE!!!
	
	; In AVX esistono versioni a pi� parametri con destinazione separata
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	VADDPS		YMM0, YMM1
	VADDPS		YMM2, YMM0, YMM1
	VADDPS		XMM0, XMM1
	ADDPS		XMM0, XMM1
	VMOVAPS		[s], YMM0
	printps		s, 2
	
	; SEMANTICA STANDARD DI AVX:
	; LE ISTRUZIONI LAVORANO COME SE FOSSERO
	; CHIAMATE SSE SEPARATE SULLE DUE PARTI DI Y
	
	; VPERM2F128 <dst> <srg1> <srg2> <imm8>
	; ogni sorgente � composta da due parti a 128 bit
	; [srg2_1 srg2_0 srg1_1 srg1_0]
	; le quattro parti cos� ottenute sono indicizzate da 0 a 3
	; [srg2_1 srg2_0 srg1_1 srg1_0]
	; [    11     10     01     00]
	; L'istruzione copia in destinazione i campi delle sorgenti in base agli ID
	; imm8: [az1, X, id1, az0, X, id0];
	; az0 (1 bit) azzera parte bassa di <dst>
	; az1 (1 bit) azzera parte alta di <dst>
	; id1 (2 bit), id0 (2 bit) sono in {00,01,10,11}
	; id0 specifica quale parte copiare nella parte bassa di <dest>
	; id1 specifica quale parte copiare nella parte alta di <dest>
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	VPERM2F128	YMM2, YMM0, YMM1, 00110000b
	;0		0		11		0	  0		  00  b
    ;az1    X		id1		az0	  X		  id0
	VMOVAPS	[s], YMM2
	printps	s, 2

	; HADD LAVORA SULLE DUE PARTI DI Y in accordo alla semantica std
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	VHADDPS		YMM2, YMM1, YMM0
	VHADDPS		YMM0, YMM0, YMM0
	VHADDPS		YMM0, YMM0, YMM0
	
	; PRODOTTO SCALARE
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	VMULPS		YMM0, YMM1
	VHADDPS		YMM0, YMM0, YMM0
	VHADDPS		YMM0, YMM0, YMM0
	VPERM2F128	YMM1, YMM0, YMM0, 00010001b
	VADDSS		XMM1, XMM0
	VMOVSS		[s], XMM1
	printps		s, 2
	
	; ISTRUZIONI CHE COINVOLGONO OPERANDI IN MEMORIA
	
	; BLEND{PS, PD} <dst>, <srg, mem>, <imm8>
	; <dst>[i] = <dst>[i] se imm8[i] = 0, <srg> se imm8[i] = 1
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	BLENDPS		XMM1, XMM0, 0001b
	BLENDPS		XMM1, [v], 0101b
	VBLENDPS	XMM1, XMM0, 0001b
	VBLENDPS	XMM2, XMM1, XMM0, 0001b
	VBLENDPS	YMM2, YMM1, YMM0, 01100001b
	VMOVAPS		[s], YMM1
	printps		s, 2
	
	; INSERTPS <dst>, <srg mem>, <imm8>, PD NON ESISTE!
	; se <srg> in memoria specifico solo la posizione dove scrivere in <dst> con i bit d1 d0
	; imm8: [ X X d1 d0 az3 az2 az1 az0 ]
	; azi azzera la parte i di <dst>
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	INSERTPS	XMM1, [v], 010000b
	VINSERTPS	XMM1, [v], 010000b
	VMOVAPS	[s], YMM1
	printps		s, 2
	
	; INSERTPS <dst>, <srg>, <imm8>, PD NON ESISTE!
	; se <srg> registro specifico anche quale posizione copiare con i bit s1 s0
	; [ s1 s0 d1 d0 az3 az2 az1 az0 ]
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	INSERTPS	XMM1, XMM0, 11010000b
	VINSERTPS	XMM1, XMM0, 11010000b
	;VMOVAPS	[s], YMM1
	;printps		s, 1
	
	
	; VINSERTF128 <dst>, <srg1>, <srg2/mem>, 0/1
	; VINSERTF128 <dst/srg1>, <srg2/mem>, 0/1
	; VINSERTF128 <dst/srg1>, <srg2/XMM>, 0/1
	; COPIA SRG1 in DST e la parte meno significativa di SRG2 nella parte di DST specificata dall'immediato
	VINSERTF128	YMM1, [v], 1
	VINSERTF128	YMM1, XMM0, 1
	VINSERTF128	YMM2, YMM1, [v], 1
	;VMOVAPS		[s], YMM2
	;printps		s, 2
	
	; EXTRACTPS <dst reg32/mem32>, <srg xmm>, <imm8>, PD NON ESISTE!
	; il campo imm8 di SRG va in DST.
	EXTRACTPS	EAX, XMM0, 0
	VEXTRACTPS	EAX, XMM0, 0
	; VEXTRACTF128 <dst reg128/mem128>, <srg xmm>, <imm8: 0/1>
	VEXTRACTF128	XMM0, YMM1, 0
	
	; VBROADCAST{SS, SD, F128} YMM, MEM
	; COPIA MEM in boradcst nelle varie locazioni
	VBROADCASTSS	YMM0, [v]
	VBROADCASTSD	YMM0, [v]
	VBROADCASTF128	YMM0, [v]
	VMOVAPS		[s], YMM0
	printps		s, 2
	
	; VMASKMOV{PS,PD} <dst/srg> <mask> <srg>
	; se <srg> in memoria
	; copia da sorgente alla destinazione in base alla maschera, altri campi a 0
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	VCMPLEPS	YMM2, YMM1, YMM0
	
	VMASKMOVPS	YMM1, YMM2, [v]
	VMOVAPS		[s], YMM1
	printps		s, 2

	; VMASKMOV{PS,PD} <dst/srg> <mask> <srg>
	; se <srg> in registro
	; copia da sorgente alla destinazione in base alla maschera, altri campi inalterati
	VMASKMOVPS	[v], YMM2, YMM1
	printps		v, 2
	
	; VPERMILPS <dst> <srg reg> <mask: reg/mem>	2 maschere ossia legge 8 valori a 2 bit
	; vengono presi dalla mask 8 coppie di bit
	; (i due bit meno significativi degli 8 interi che compongono la maschera)
	; [ srg7 srg6 srg5 srg4 | srg3 srg2 srg1 srg0 ]
	; [ msk7 msk6 msk5 msk4 | msk3 msk2 msk1 msk0 ]
	; [ dst7 dst6 dst5 dst4 | dst3 dst2 dst1 dst0 ]
	; nella parte alta di <dst> si considera la parte alta di <srg>
	; e si usano le 4 coppie nella parte alta di mask
	; quindi in dst7 viene copiato uno tra {srg7 srg6 srg5 srg4} in base al valore dei bit di mask7
	; quindi in dst6 viene copiato uno tra {srg7 srg6 srg5 srg4} in base al valore dei bit di mask6
	; ...
	; nella parte bassa di <dst> si considera la parte bassa di <srg>
	; e si usano le 4 coppie nella parte bassa di mask
	; quindi in dst4 viene copiato uno tra {srg3 srg2 srg1 srg0} in base al valore dei bit di mask4
	; quindi in dst3 viene copiato uno tra {srg3 srg2 srg1 srg0} in base al valore dei bit di mask3
	; ...

	; VPERMILPS <dst> <srg mem> <imm8>		1 maschera applicata 2 volte
	; la maschera � composta da 4 coppie di bit, ossia � a 8 bit
	; [ srg7 srg6 srg5 srg4 | srg3 srg2 srg1 srg0 ]
	;            [ msk3 msk2 msk1 msk0 ]
	; [ dst7 dst6 dst5 dst4 | dst3 dst2 dst1 dst0 ]
	; quindi in dst7 viene copiato uno tra {srg7 srg6 srg5 srg4} in base al valore dei bit di msk3
	; quindi in dst6 viene copiato uno tra {srg7 srg6 srg5 srg4} in base al valore dei bit di msk2
	; ...
	; quindi in dst3 viene copiato uno tra {srg3 srg2 srg1 srg0} in base al valore dei bit di msk3
	; quindi in dst2 viene copiato uno tra {srg3 srg2 srg1 srg0} in base al valore dei bit di msk2
	; ...
	VMOVAPS		YMM0, [t]
	VMOVAPS		YMM1, [w]
	VPERMILPS	YMM2, YMM!, [t] ; versione a 2 maschere
	VMOVAPS		[s], YMM2
	printps		s, 2
	VPERMILPS	YMM2, [w], 00000001b ; versione a 1 maschera
	VMOVAPS		[s], YMM2
	printps		s, 2
	
	; ISTRUZIONI DI INTERLACCIAMENTO

	; {V}UNPCK{L,U}{PS,PD} <dst {x,y}mm> <srg {x,y}mm/mem>
	; interlaccia le parti basse o le parti alte
	VMOVAPS		YMM0, [v]
	VMOVAPS		YMM1, [w]
	UNPCKLPS	XMM0, XMM1
	;UNPCKHPS	XMM0, XMM1
	;UNPCKLPD	XMM0, XMM1
	;UNPCKLPD	XMM0, XMM1
	;VUNPCKLPS	YMM0, YMM1
	;VUNPCKLPD	YMM0, YMM1
	;VUNPCKLPD	XMM0, XMM1
	;VUNPCKLPD	YMM2, YMM0, YMM1
	VMOVAPS	[s], YMM0
	printps	s, 2

	stop