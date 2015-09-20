;***************************************************************
;*                    DECIRQ.ASM                               *
;*                                                             *
;*         contient les definitions des proc‚dures pour        *
;*       initialis‚ le processeur d'interruption 8259A-1       *
;*                                                             *
;*         ATTENTION : NECESSITE UN ASSEMBLAGE EN MODE         *
;*                        386 PROTEGE                          *
;*                                                             *
;*             (c) Nicolas CLERC  <>  Mars 1993                *
;***************************************************************

;***********************************************************************
;*      INIT_IRQ : d‚place les interreuption mat‚riel
;*                 sur les ints 20h … 2Fh

init_irq PROC
	pushall
	cli
	mov     al,11h                ; s‚quence d'initialisation
	out     20h,al                ; pour le  8259A-1
	out     0A0h,al               ; et pour le  8259A-2
	mov     al,20h                ; d‚but des int mat‚rielle 1  (0x20)
	out     21h,al                ; ( IRQ0 -> IRQ7 )
	mov     al,28h                ; debut des int mat‚rielle 2 (0x28)
	out     0A1h,al               ; ( IRQ8 -> IRQ15 )
	mov     al,04h                ; 8259-1 en maitre 
	out     21h,al
	mov     al,02h                ; 8259-2 en esclave 
	out     0A1h,al
	mov     al,01h                ; mode 8086 pour les 2
	out     21h,al
	popall
	ret
init_irq ENDP


;***********************************************************************
;*      RESTORE_IRQ : restore les interruption mat‚riel a 
;*                    leur place originelle

restore_irq PROC
	pushall
	cli
	mov al,0FFh                   ; plus d'IRQs !
	out 21h,al
	mov     al,11h                ; s‚quence d'initialisation
	out     20h,al                ; pour le  8259A-1
	out     0A0h,al               ; et pour le  8259A-2
	mov     al,08h                ; d‚but des int mat‚rielle 1  (08h)
	out     21h,al                ; ( IRQ0 -> IRQ7 )
	mov     al,70h                ; debut des int mat‚rielle 2 (70h)
	out     0A1h,al               ; ( IRQ8 -> IRQ15 )
	mov     al,04h                ; 8259-1 en maitre 
	out     21h,al
	mov     al,02h                ; 8259-2 en esclave 
	out     0A1h,al
	mov     al,01h                ; mode 8086 pour les 2
	out     21h,al
	out     0A1h,al
	popall
	ret
restore_irq ENDP


;***************************************************** FIN 'DECIRQ.ASM'

