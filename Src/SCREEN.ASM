;***************************************************************
;*                    SCREEN.ASM                               *
;*                                                             *
;*      contient les definitions des fonction pour acceder     *
;*     a l'‚cran du pc tournant sour PRO286 en mode prot‚g‚    *
;*                                                             *
;*         ATTENTION : NECESSITE UN ASSEMBLAGE EN MODE         *
;*                        386 PROTEGE                          *
;*                                                             *
;*        VALABLE POUR UN ECRAN VGA TEXTE COULEUR 80*25        *
;*                                                             *
;*             (c) Nicolas CLERC  <>  Mars 1993                *
;***************************************************************

USCR_LIGNEDEB   equ 1   ; ligne de debut ( la 1ere : ligne 0 )
USCR_NBLIGNE    equ 23  ; nombre de ligne dans l'ecran utilisateur

;*********************************************************************
;*      GET_VIDEO_SEG : retourne ds AX le selecteur sur le segment video
;*      resultat correcte qqs le mode du processeur
;*      NECESSITE QUE LA CONSTANTE "video_seg" ( selecteur video en 286p)
;*                           SOIT DEFINE ET CORRECTE
;*                       ! APPEL PAR LE NOYAU UNIQUEMENT !
;*                     NECESSITE UN NIVEAU DE PROTECTION = 0
;*
get_video_seg PROC
	smsw ax
	test ax,1
	jz video_r      ;jump car en mode reel
	mov ax,video_seg ;desc du segment video en mode protege
	jmp fin_get_vid
video_r:
	mov ax,0b80ah
fin_get_vid:
	ret
get_video_seg ENDP

;**********************************************************************
;*      KER_SCROLL : scroll d'une ligne de l'ecran principal
;*              APELLABLE UNIQUEMENT PAR LE NOYAU
;*
ASSUME DS:kernel_data_seg    
ker_scroll PROC
	call get_video_seg
	pushf           ; sauvegarde pour IF
	push ds
	push es

	cli
	mov es,ax
	mov ds,ax
	mov di,00
	mov si,0A0h
	mov cx,(USCR_NBLIGNE - 1)*80    ; NBLIGNE-1 lignes a scroller !
	cld
	rep movsw
	mov ax,kern_data
	mov ds,ax
	mov ah,byte ptr ds:[screen_coul]
	mov al,20h
	mov di,(USCR_NBLIGNE - 1)*160
	mov cx,80
	rep stosw
	
	pop es
	pop ds
	popf            ; permet la restauration du flag interrupt !!!!!
	ret
ker_scroll ENDP

;**********************************************************************
;*      SCROLL_SCR : scroll d'une ligne de l'ecran principal
;*
scroll_scr PROC
_scroll_scr equ offset scroll_scr        
	pushall
	push ds
	push es
	call ker_scroll
	pop es
	pop ds
	popall
	ret
scroll_scr ENDP

;**********************************************************************
;*      KER_CALC_OFS_ECR : calcul de l'offset sur l'ecr de la pos
;*                         du curseur
;*              SORTIE : AX = offset
;*             APPEL UNIQUEMENT A PARTIR DU KERNEL !!!!!
;*              ( pas de sauvegarde des registres )
ASSUME ds:kernel_data_seg
ker_calc_ofs_ecr PROC
	push ds
	mov ax,kern_data
	mov ds,ax
	mov bh,[screen_col]
	mov bl,[screen_line]
	xor ax,ax
	mov al,bh
	mov bx,160
	mul bx           ; offset de decal pour la ligne
	pop bx
	push ax
	xor ax,ax
	mov al,bl
	shl ax,1
	pop bx
	add ax,bx       ; ax = offset de decalage sur l'ecran
	ret
ker_calc_ofs_ecr ENDP






;**********************************************************************
;*      LOCATE : positionnement du curseur a une position donn‚e
;*          BH = collone (0->79)
;*          BL = ligne (0->22)
;*
locate PROC
_locate equ offset locate        
	pushall
	push es
	cmp bl,USCR_NBLIGNE - 1
	jbe notsup
	mov bl,USCR_NBLIGNE - 1
notsup:
	call ker_locate
	pop es
	popall
	ret
locate ENDP

;**********************************************************************
;*      KER_LOCATE : positionnement du curseur a une position donn‚e
;*          BH = collone (0->79)
;*          BL = ligne (0->23)
;*
ASSUME DS:kernel_data_seg
ker_locate PROC
	push bx

	push bx
	xor ax,ax
	mov al,bh
	mov bx,160
	mul bx           ; offset de decal pour la ligne
	pop bx
	push ax
	xor ax,ax
	mov al,bl
	shl ax,1
	pop bx
	add ax,bx       ; ax = offset de decalage sur l'ecran
	
	push ax         ; sauvegarde de l'offset de la position courante
	mov ax,kern_data
	mov ds,ax
	pop ax          ; on recupere la position
	mov [screen_ofs],ax
	mov dx,03d4h
	shr ax,1

	add  ax,160*USCR_LIGNEDEB ; pour offset de decallage du curseur
	push ax
	mov al,0eh
	out dx,ax
	pop ax
	mov ah,al
	mov al,0fh
	out dx,ax
	
	pop bx          ; on recupere les poisiton en col/ligne
	mov [screen_col],bl
	mov [screen_line],bh

	ret
ker_locate ENDP

;**********************************************************************
;*      CLEARSCREEN : efface l'ecran de texte utilisateur et
;*              place le curseur a la position 0,0
;*
;*              APPELABLE UNIQUEMENT EN MODE PROTEGE !!!!!
ASSUME ds:kernel_data_seg
clearscreen PROC 
_clearscreen equ offset clearscreen
	push ds
	pushall
	mov ax,kern_data
	mov ds,ax
	mov ah,byte ptr ds:[screen_coul]
	mov al,20h
	push ax
	call get_video_seg
	mov es,ax
	pop ax
	mov di,0
	mov cx,USCR_NBLIGNE*80  ; nombre de mot a metre a blanc.
	rep stosw
	mov bx,0000
	call ker_locate
	popall
	pop ds
	ret
clearscreen     ENDP

;**********************************************************************
;*      SETCOLOR : selection des attribut d'affichage a l'ecran
;*           Attribut a placer sur la pile avant l'appel
;*
;*              APPELABLE UNIQUEMENT EN MODE PROTEGE !!!!!

ASSUME ds:kernel_data_seg
setcolor PROC far
_setcolor equ offset setcolor
	pushall
	cli
	push ds
	mov bp,sp
	mov ax,kern_data
	mov ds,ax
	mov ax,word ptr ss:[bp+24] ; on recupere le carac
	mov [screen_coul],al
	pop ds
	popall    ; incluant popf  -> restauration de l'etat des int original
	retf 2
setcolor ENDP

;**********************************************************************
;*      PUTCHAR : affiche un caractere a la position courante du curseur
;*           Caractere placer sur la pile avant l'appel !!!!
;*
;*              APPELABLE UNIQUEMENT DU MODE PROTEGE !!!!!
ASSUME DS:kernel_data_seg
putchar PROC far 
_putchar equ offset putchar
	pushall
	cli
	push es
	push ds
	mov bp,sp       ; on cree le cadre de pile !

	mov ax,kern_data
	mov ds,ax               ; es = selecteur de donn‚e du kernel
	call get_video_seg
	mov es,ax               ; ds = selecteur video
	
	mov ax,word ptr ss:[bp+26] ; on recupere le carac
	cmp al,32               ; caractere de ctrl ?
	jnb carac_normal        ; si >= 32 -> saut a carac_normal
	cmp al,13
	jnz fin_proc            ; si <>13 on sort
	
;********* traitement de \n        
	inc [screen_line]       ; screen_line += 1
	mov [screen_col],0
	mov al,[screen_line]
	cmp al,USCR_NBLIGNE-1   ; screen_line >=NBLIGNE  ?
	jna cont_nl             ; non : on ne scrolle pas !!!!
	call scroll_scr
	mov [screen_line],USCR_NBLIGNE-1    ; screen_line = 23
	mov al,USCR_NBLIGNE-1
cont_nl:
	xor ah,ah               ; ah=0 -> ax=al=screen_line
	mov bx,160
	mul bx                  ; ax = ax * bx = ax*160 = nouvel offset
	mov [screen_ofs],ax 
	jmp putchar_fin2        ; pour mise en place du curseur et economie
;*********** traitement carac >= 32
carac_normal:
	mov ah,[screen_coul] ; ah = attribut du caracteres !!!
	mov si,[screen_ofs]  ; si = ofs courant du curseur
	mov es:[si],ax ; affichage du caractere
	inc [screen_ofs]
	inc [screen_ofs]    ; on incremente l'offset pr le carac suivant

	inc [screen_col]    ;on incremente la colonne
	cmp [screen_col],79 ; col > 79 ?
	jna putchar_fin         ; non -> on finis
	mov [screen_col],0  ; oui -> col=0 
	inc [screen_line]    ; & line = line + 1
	cmp [screen_line],USCR_NBLIGNE-1 ; line > 23 ( apres la derniere ligne ?) ?
	jna putchar_fin         ; non - > on fini !
	dec [screen_line]    ; line = line - 1
	call scroll_scr         ; oui -> on scroll une ligne
	sub [screen_ofs],160 ; offset de position = -1ligne !
putchar_fin:
	mov ax,[screen_ofs] ; ax = offset sur ecran
putchar_fin2:        
	add ax,160*USCR_LIGNEDEB
	shr ax,1                ; ax = offset pour CRT VGA !
	
	push ax
	mov dx,03d4h
	mov al,0eh
	out dx,ax
	pop ax
	mov ah,al
	mov al,0fh
	out dx,ax

fin_proc:        
	pop ds
	pop es
	popall    ; incluant popf  -> restauration de l'etat des int original
	retf 2
putchar ENDP





;**********************************************************************
;*      KER_PRINTF : affichage d'une chaine de caracde type asciiZ
;*              DS:SI   = adr du texte ( terminer par 0 )
;*              AH      = Attribut d'affichage
;*              BH      = ligne  (0->23)
;*              BL      = colonne (0->79)
;*
;*            !  APPELABLE UNIQUEMENT EN INTERNE PAR LE NOYAU !
;*
ker_printf  PROC
	push ax
	push bx
	xor ax,ax
	mov al,bh
	mov bx,160
	mul bx           ; offset de decal pour la ligne
	pop bx
	push ax
	xor ax,ax
	mov al,bl
	shl ax,1
	pop bx
	add ax,bx       ; ax = offset de decalage sur l'ecran
	mov di,ax
	
	
	call get_video_seg
	mov es,ax       ; ES:DI adr sur l'ecran
	pop ax
	cld
boucle_printf:
	lodsb
	stosw
	cmp byte ptr ds:[si],0
	jnz boucle_printf

	ret
ker_printf  ENDP


;**********************************************************************
;*      PUTS : affichage d'une chaine de caractere de type asciiZ
;*              DS:SI   = adr du texte ( terminer par 0 )
;*              AH      = Attribut d'affichage
;*              BH      = ligne  (0->23)
;*              BL      = colonne (0->79)
;*
;*      Necessite la presence des macro 'pushall' et 'popall'.
;*      Appel bas-niveau … i_printf
;*
puts    PROC far
_puts equ offset puts        
	pushall
	push ds
	call ker_printf
	pop ds
	popall
	retf
puts    ENDP
	
;***********************************************************************
;*      TTY_PUTS : affichage d'une chaine de carac en tty a la pos courante
;*                 Utilise Putchar !!!
;*         DS:SI = pointeur sur chaine asciiZ
;*
;*                  APPELABLE UNIQUEMENT DU MODE PROTEGE !!!!!!!
tty_puts PROC far
_tty_puts equ offset tty_puts        
	pushall
	push es

ttyp_b1: 
	mov al,byte ptr ds:[si]
	push ax         ; on empile le caractere a afficher
	callf codeseg,_putchar
	inc si
	cmp byte ptr ds:[si],0
	jnz ttyp_b1

	pop es
	popall
	retf
tty_puts ENDP


;***************************************************** FIN 'SCREEN.ASM'

