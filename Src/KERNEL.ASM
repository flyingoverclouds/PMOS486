;***************************************************************
;*                        KERNEL.ASM                           *
;*                                                             *
;*           procedure basique de gestion du 80386             *
;*                    en mode PROTEGE                          *
;*                                                             *
;*         ATTENTION : NECESSITE UN ASSEMBLAGE EN MODE         *
;*                        386 PROTEGE                          *
;*                                                             *
;*           NECESSITE LA PRESENCE DE 'KERNEL3.DEF'            *
;*                                                             *
;*             (c) Nicolas CLERC <> Mars 1993                  *
;***************************************************************
assume ds:data



;*******************************************************************
;*      INIT_GDT : procedure d'initialisation d'un descripteur GDT
;*              DI:SI   = Adresse du seg ss forme SEG:OFS ou SEL:OFS
;*              AL      = Droit d'acces et type de segment
;*              BX      = numero d'entre dans la GDT
;*              DX      = Taille du segment
;*      Neccessite que la GDT s'appelle __GDT_TAB__ ou alors, faire
;*         un  "__GDT_TAB__ equ <nom_de_votre_GDT>"
init_gdt PROC
	pushall   ; pour la conservation de l'environnement de travail
	shl bx,3
	add bx,OFFSET __GDT_TAB__
assume bx:PTR desc_seg_s
	mov [bx].seg_acces,al
	mov [bx].seg_limite,dx
       ;calcul adr sur 24 bits
	mov dx,di
	shl di,4
	shr dh,4
	add di,si
	jnc init_limit1
	inc dh
init_limit1:
	mov [bx].seg_base_lo,di
	mov [bx].seg_base_hi,dh
	popall
	ret
init_gdt ENDP

;*******************************************************************
;*      INIT_IDT : procedure d'initialisation d'un descripteur IDT
;*              DI      = Selecteur du seg contenant la proc d'int
;*              SI      = Offset du point d'entree de la proc d'int
;*              AL      = Droit d'acces et type de segment
;*              BX      = numero d'interruption
;*      Neccessite que la IDT s'appelle __IDT_TAB__ ou alors, faire
;*         un  "__IDT_TAB__ equ <nom_de_votre_IDT>"

init_idt PROC
assume bx:PTR desc_int_s
	pushall
	shl bx,3
	add bx,OFFSET __IDT_TAB__
	mov [bx].int_acces,al
	mov [bx].int_selecteur,di
	mov [bx].int_offset,si
	popall
	ret
init_idt ENDP


;***********************************************************************
;*      INIT_BACK_REAL : initialisation des var pr retour au mode reel
;*          et detournement du vecteur ERREUR PROCESSEUR
;*              DI:SI   = adresse du point de retour ( SEG:OFS )
init_back_real PROC far ;push sur la pile cd CS:IP
;        cli
;        in al,70h
;        mov [anc70],al
;        in al,71h
;        mov [anc71],al
;        sti
;        xor ax,ax
;        mov es,ax
;        mov ax,es:[469h]
;        mov [anc_seg_retour],ax
;        mov ax,es:[467h]
;        mov [anc_ofs_retour],ax
;        mov es:[469h],di
;        mov es:[467h],si
	mov ax,sp
	add ax,4        ; car il y les 2 valeur de retour de la proc  !!!!!
	mov [sauv_SP],ax
	mov ax,ss
	mov [sauv_SS],ax
	retf  
init_back_real ENDP


;***********************************************************************
;*      RESTORE_BACK_REAL : remise en place de la pile et des vecteurs
restore_back_real PROC far
	cli
;        mov al,[anc70]
;        out 70h,al
;        mov al,[anc71]
;        out 71h,al
	pop bx ; on recupere l'adresse de retour
	pop cx
	mov ax,[sauv_SS]
	mov ss,ax
	mov ax,[sauv_SP]
	mov sp,ax
	push cx ; on replace l'adresse de retour sur la pile du mode reel
	push bx
	sti
;        xor ax,ax
;        mov es,ax
;        mov ax,[anc_seg_retour]
;        mov es:[469h],ax
;        mov ax,[anc_ofs_retour]
;        mov es:[467h],ax
	retf
restore_back_real ENDP



;***************************************************** FIN 'KERNEL.ASM'
