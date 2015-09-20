test_puts db "***** Test de puts en mode protege *****",0

cop1    db 13,"Multitasking Protected Mode Kernel  version á-test",13
	db "Copyright Nicolas CLERC 1994",13
	db "(c) & (p) LionSoft 1994",13,13
	db 0

welcome_txt db 13,13,13,13,13
	db "        *****************************************************************",13
	db "        *                Protected Mode Operating System                *",13
	db "        *                         P.M.O.S. i486                         *",13    
	db "        *                                                               *",13
	db "        *  PMOS   Version v á0.020      Mars 1995    (c) Nicolas CLERC  *",13          
	db "        *****************************************************************",13
	db " [ESC] pour revenir au DOS",13,13,13
	db "LOGIN: ",0

bad_cpu_txt     db 13,10,"<<< PMOS i486 : MAUVAIS PROCESSEUR >>>",13,10
		db "Ce programme ne peut tourner que sur processeur de type Intel i80386sx",13,10
		db " ou superieur. Essayez sur une autre machine.",13,10,"$"

win_lance_txt   db 13,10,"<<< PMOS i486 : Window EST EN COURS D'EXECUTION >>>",13,10
		db "Windows ne supporte pas les programmes qui veulent le controle",13,10
		db "du processeur , il ne vous reste plus qu'a quitter, ",13,10
		db "et relancer PMOS i486 depuis le prompt DOS !",13,10,"$"

virtual_mode_txt db 13,10,"<<< PMOS i486 : MODE VIRTUEL ENGAGE >>>",13,10
		db "PMOS i486 ne peut pas s'executer sur une machine en mode virtuel.",13,10
		db "Retirer les gestionnaires de memoires pagine tel que EMM386,",13,10
		db "QEMM,386Max de votre CONFIG.SYS . Ne conserver que HIMEM.SYS.",13,10 

nico_lsf_txt    db "PMOS i486 : Copyright LIONSOFT 1995  , (c) Nicolas CLERC 1995",13,10,10,"$"


ok_txt          db "Ok.",13,0


fin_prot        db 13,"   Retour au mode reel .... ",13,0

text_ligne1     db "Pa.aMa.aOa.aSa.a aia4a8a6a a  N o y a u   M o d e   P r o t ‚ g ‚   ( c )   N i c o l a s   C L E R C                                                              "
