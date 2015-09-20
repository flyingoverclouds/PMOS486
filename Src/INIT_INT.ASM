;***************************************************************
;*                   INIT_INT.ASM                              *
;*                                                             *
;*  contient les definitions des proc‚dures d'initisalisation  *
;*           des interruptions pour PC sous PRO286             *
;*                                                             *
;*         ATTENTION : NECESSITE UN ASSEMBLAGE EN MODE         *
;*                        386 PROTEGE                          *
;*                                                             *
;*             (c) Nicolas CLERC  <>  Mars 1993                *
;***************************************************************



EOI             equ 20h
KEYB_PORT       equ 60h
VALID_IRQ       equ 252
;********************************************* TEXTE POUR LES EXCEPTION
texcp0   db "D i v i s i o n   p a r   0   :   r e t o u r   p r o g ",0
texcp1   db "P a s   a   p a s   :   r e t o u r   p r o g ",0
texcp2   db "N M I   ! ! ! ! ",0
texcp3   db "B r e a k   P o i n t ",0
texcp4   db "O v e r f l o w   A U L   e n   s i g n ‚ ",0
texcp5   db "B O U N D   d ‚ b o r d e m e n t ",0
texcp6   db "B a d   o p e r a t i o n   c o d e   - - >   H A L T   ! ! ! ",0
texcp7   db "N o   8 0 2 8 7   p r e s e n t   ! ",0
texcp8   db "D o u b l e   f a u t e   p r o t e c t i o n   - - >   H A L T ",0
texcp9   db "8 0 2 8 7   R W   o p   o u t   o f   s e g m e n t ",0
texcp10  db "T S S   i n v a l i d e ",0
texcp11  db "V i r t u a l   m e m o r y   :   s e g m e n t   n o t   i n   m e m o r y ",0
texcp12  db "S t a c k   o v e r f l o w   - - >   H A L T ",0
texcp13  db "G e n e r a l   p r o t e c t i o n   d e f a u l t ",0
texcp14  db "8 0 3 8 6   :   P a g i n a t i o n   e r r o r ",0
texcp15  db "N o   i t e m ",0
texcp16  db "8 0 x 8 7   e r r o r ",0

;********************************************************** PROCEDURE 

key_int PROC
        pushall
        push ds
        push es

        in al,KEYB_PORT
        cmp al,127
        ja fin_int9
        cmp al,1
        jne non_esc       ; si touche diff de [esc]
        push ax
        mov ax,dataseg
        mov ds,ax
        mov byte ptr ds:[fin_prog],255
        pop ax
non_esc:
        push ax
        mov ax,kern_screen
        mov es,ax             ; es = selecteur ecran kernel
        mov di,4
        mov ax,kern_data      
        mov ds,ax             ; ds = selecteur donn‚e du kernel
        mov bx,OFFSET key_map
        pop ax                ; ax = scan code 
        xlat                  ; ax = key_map[ax]  
        push ax
        callf codeseg,_putchar
fin_int9:        
        mov ax,EOI
        out 20h,al
        
        pop es
        pop ds
        popall 
        iret
key_int ENDP


horl_int PROC
        pushall
        push ds
        
        mov ax,kern_screen
        mov ds,ax
        mov si,0
        xor byte ptr ds:[si],'c'
        inc si
        inc si
        xor byte ptr ds:[si],'l'
        inc si
        inc si
        xor byte ptr ds:[si],'k'
        mov ax,EOI
        out 20h,al
        
        pop ds
        popall 
        iret
horl_int ENDP


excp8  PROC
        pushall
        cli
        push ds
        mov di,0
        mov ax,kern_screen
        mov es,ax
        mov ax,codeseg
        mov ds,ax
        mov si,offset texcp8
        cld
boucle_excp8:
        lodsb
        stosw
        cmp byte ptr ds:[si],0
        jnz boucle_excp8

        cli
        hlt
        pop ds
        popall  ;--> restauration du flag IF
        inc sp
        inc sp
        iret
excp8  ENDP





init_interrupt PROC
        pushall
        cli
        mov di,codeseg       ; idt pour clavier
        mov si,offset key_int
        mov al,int_gate or pres_in_mem or levelp_0 or gate_desc
        mov bx,21h
        call init_idt

        mov si,offset horl_int
        mov bx,20h
        call init_idt

        mov si,offset excp8
        mov bx,8
;        call init_idt
        popall          ; popf inclus -> restauration du flag if
        ret
init_interrupt ENDP


;***************************************************** FIN 'INIT_INT.ASM'

