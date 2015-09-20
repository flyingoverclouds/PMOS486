;*************************************************************************
;**     P R O 4 8 6   :   mini noyau multitache en assembleur 486       **
;**                       mode prot‚g‚                                  **
;*************************************************************************
;**  (c) LIONSOFT 1995  :  r‚alis‚ par Nicolas CLERC                    **
;*************************************************************************
;------------------------------------
;-- PRO486.ASM : fichier Principal --
;------------------------------------
.486p


codeseg         equ 08h          ; entree 1 DS GDT
dataseg         equ 10h          ;        2
stackseg        equ 18h          ;        3
extrseg         equ 20h          ;        4
ecranseg        equ 28h          ;        5
idtseg          equ 30h          ;        6
gdtseg          equ 38h          ;        7
kern_screen     equ 40h          ;        8
kern_data       equ 48h          ;        9
prot_code       equ 50h          ;        10
ligne1          equ 58h          ;        11     ligne du haut d'ecran
segretour       equ 

video_seg equ ecranseg

include kernel.def
;*****************************************************************
;* pile reelle                                                   *
;*****************************************************************
stack segment use16 'STACK'
    db 200
stack ends

;*****************************************************************
;* segment de donnee du mode protege : !! LEVEL 0  !!            *
;*****************************************************************
kernel_data_seg SEGMENT use16 'DATA'
include kernel_p.var      ; variable noyau mode protege
include french.key        ; donn‚e pour le clavier AT francais 102 touches
kernel_data_seg ENDS


;*****************************************************************
;* pile protege pour le niveau de protection 0 : SYSTEME         *
;*****************************************************************
stack0_prot SEGMENT use16 'STACK' para
		even
		dw 100h dup (0)
debut_pile      label word 
stack0_prot ENDS

;*****************************************************************
;* extras segment                                                *
;*****************************************************************

extras segment use16 'DATA'
	db 0
extras ends

;******************************************************************
;* segment de donne globale ( reel et protege )                   *
;******************************************************************

data    SEGMENT use16 'DATA'

anccs   dw 0
ancoff  dw 0
video   db 0
ppile   dw 0
spile   dw 0
tous    df 0

fin_prog        db 0

assume ds:code


include kernel.var
__gdt_tab__ equ gdt     ; pour les proc systemes !
__idt_tab__ equ idt     ; pour les proc systemes d'interruption !

align 16        ; on aligne sur le paragraphe : plus rapide sur i80486

idt     desc_int_s 256 dup (<>)
intend  equ $

gdt     desc_seg_s 256 dup (<>)
segend  equ $

;*** Inclusion des zones de test
include txt486.asm
;***

data    ends

;************** Macro pour l'affichage du OK !!
aff_ok  MACRO
	push 2
	callf codeseg,_setcolor
	mov si,offset ok_txt
	callf codeseg,_tty_puts
	push 7
	callf codeseg,_setcolor
ENDM



;******************************************************************
;* SEGMENT DE CODE POUR LE KERNEL : LEVEL 0                       *
;******************************************************************
code_prot SEGMENT use16 'CODE'

ASSUME CS:code_prot

code_prot ENDS

;******************************************************************
;* segment de code ( reel et protege )                            *
;******************************************************************
code    segment use16 'CODE'
assume cs:code,ds:data

include cpuid.asm          ; detection du type de CPU
include kernel.asm         ; mode protege
include screen.asm         ; mode protege
include init_int.asm       ; mode reel
include decirq.asm         ; mode reel

assume cs:code

commut proc near

	mov ax,data
	mov ds,ax
	pushall
	
	;--------- verification si Windows tourne sur la machine
	mov ax,1600h
	int 2fh         ; on appelle le Multiplex pour savoir si Win est la!
	cmp al,80
	je detect_win_ok
	cmp al,0
	je detect_win_ok

	mov dx,offset win_lance_txt
	mov ah,09h
	int 21h
	mov dx,offset nico_lsf_txt
	mov ah,09h
	int 21h
	jmp fin_mpos386
	;--------- debut de la verification du type processeur
detect_win_ok:
	call get_cpuid
	call get_fpuid


	;--------- Verification du mot d'etat du CPU 
detect_cpu_ok:        
	mov eax,cr0
	test ax,1       ; deja mode protege  ?
	jz real_mode_ok ; non -> on continue
	mov dx,offset virtual_mode_txt
	mov ah,09h
	int 21h
	jmp fin_mpos386
	
real_mode_ok:        

	call init_back_real

	mov di,cs               ; segment de code du programme
	mov word ptr cs:[seg_code_retour],di

	mov di,code           ; segment de code du programme
	xor si,si
	mov al,pres_in_mem or R_seg or levelp_0 or code_desc
	mov bx,1
	mov dx,0ffffh
	call init_gdt


	mov di,data           ; segment de donnee du programme
	xor si,si
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,2
	mov dx,0ffffh
	call init_gdt

	mov di,stack0_prot     ; segment de pile pour le mode protege level 0
	mov si,offset debut_pile
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,3
	mov dx,0ffffh
	call init_gdt

	mov di,extras         ; segment extras
	xor si,si
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,4
	mov dx,0ffffh
	call init_gdt
	
	mov di,0b800h        ; memoire video couleur
	mov si,USCR_LIGNEDEB*160
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,5
	mov dx,USCR_NBLIGNE*160          ; les NBLIGNE lignes de l'ecran user
	call init_gdt

	mov di,data         ; alias de l'idt
	mov si,offset idt
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,6
	mov dx,0ffffh
	call init_gdt
	
	mov di,DATA         ;alias de la gdt
	mov si,offset gdt
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,7
	mov dx,0ffffh
	call init_gdt

	mov di,0b800h        ; ligne d'etat du kernel
	mov si,3840
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,8
	mov dx,160
	call init_gdt
	
	mov di,kernel_data_seg   ; alias de l'idt
	xor si,si
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,9
	mov dx,0ffffh
	call init_gdt

	mov di,code_prot
	xor si,si
	mov al,pres_in_mem or R_seg or levelp_0 or code_desc
	mov bx,10
	mov dx,0ffffh
	call init_gdt
	
	mov di,0b800h        ; ligne d'etat du kernel
	mov si,0
	mov al,pres_in_mem or RW_seg or levelp_0 or data_desc
	mov bx,11
	mov dx,160
	call init_gdt



	mov ax,255
	out 21h,ax

	call init_interrupt
	call init_irq   ; nouvelles adresses des irq ! int bloqu‚es !!!

	mov ax,stackseg ;mise en place pile pr mode protege
	mov ss,ax
	mov sp,offset debut_pile

	mov si,offset gdt + 7 * size desc_seg_s ; chargement des tables
	lgdt fword ptr ds:[si]                  ; alias gdt = entree 7

	mov si,offset oldidt
	sidt fword ptr ds:[si]
	mov si,offset gdt + 6 * size desc_int_s ;alias idt = entree 6
	lidt fword ptr ds:[si]

	mov eax,cr0
	or ax,1
	mov cr0,eax
ofs_prot_ent equ offset prefet

	jmpfd codeseg,ofs_prot_ent

prefet:
	cli
	mov al,VALID_IRQ ;suppression des interruptions inutilisees .
	out 21h,al
	sti

	mov ax,dataseg
	mov ds,ax

	mov ax,ligne1
	mov es,ax
	xor di,di
	mov si,offset text_ligne1
	mov cx,80
	cld
	rep movsw


	push 4
	callf codeseg,_setcolor

	callf codeseg,_clearscreen

	mov si,offset welcome_txt
	callf codeseg,_tty_puts
	
	push 2
	callf codeseg,_setcolor

	call some              ; appel intrasegment de la procedure de test
	
	mov si,offset fin_prot
	callf codeseg,_tty_puts


	mov al,255      ; inhibition de toutes les IRQs
	out 21h,al

	cli
	mov ax,dataseg
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	mov ss,ax


	mov eax,cr0
	and al,not 1
	mov cr0,eax

ofs_finpro equ offset ok
	db 0eah         ; code op pour un jump inter segment : 
	dw offset ok    ; offset de retour
seg_code_retour:
	dw 0            ; segment de retour

ok:     mov ax,data
	mov ds,ax
	mov si,offset oldidt
	lidt fword ptr ds:[si]
	
	mov ax,0a000h
	mov ds,ax
	mov byte ptr ds:[1024],255
	mov byte ptr ds:[1025],255

	mov ax,data            ; ... et pan nous revoila en mode reel !
	mov ds,ax

	call restore_irq
	call restore_back_real
	sti

	mov al,0        ; restauration de toutes les interruptions
	out 21h,al
	out 0a1h,al


fin_mpos386:
	popall
	mov ax,4c00h
	int 21h
commut endp

;*************************************************************************
;******* PROCEDURE de test

some proc near
	mov ax,ecranseg
	mov es,ax
deb_bouc:
	mov cx,2
boucl2:
	push cx
	mov si,OFFSET test_puts
	mov bh,cl
	mov bl,0
	callf codeseg,_puts
	pop cx
	inc ah
	loop boucl2

	cmp byte ptr ds:[fin_prog],0ffh
	jne deb_bouc

	push 7
	callf codeseg,_setcolor
	mov si,offset cop1
	callf codeseg,_tty_puts
	
	ret
some    endp

code    ends

end commut



;***************************************************** FIN 'PRO486.ASM'
