		AREA    |.text|, CODE, READONLY
;Clock
SYSCTL_PERIPH_GPIOF EQU		0x400FE108
	
;Données
GPIO_PORTD_BASE		EQU		0x40024000	;SYSCTL_RCGC2_R : pour enable clock (p291 datasheet de lm3s9b92.pdf)

;Direction
GPIO_O_DIR   		EQU 	0x400

;Sortie 2mA 
GPIO_O_DR2R   		EQU 	0x500  

;Fonction Digital
GPIO_O_DEN   		EQU 	0x51C  

;Pullup
GPIO_PUR			EQU		0x510
	  	ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


; Port select

PORT67				EQU		0x03 ; SW 1 et 2 - Lignes 6 et 7 Port D
PORT6				EQU		0x01 ; SW 1  - Lignes 6 Port D
PORT7				EQU		0x02 ; SW 2  - Lignes 7 Port D
	
		
		
__main
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CONFIGURATION DE LA CLOCK;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;clock sur GPIO F où sont branchés les leds et GPIO D sur ;lequel sont branchés les SW : 0x38 == 000101000)
; Enable the Port F and D,  peripheral clock by setting the ;corresponding bits,(p291 datasheet de lm3s9B96.pdf), ;GPIO::FEDCBA)
			ldr r6, = SYSCTL_PERIPH_GPIOF  		
        	mov r0, #0x30			
			str r0, [r6]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DELAI;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;"There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
;tres tres important....;; pas necessaire en simu ou en debbug ;step by step...
			nop	   									
			nop	   
			nop	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CONFIGURATION PORTD PIN6;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Configuration du Port D - Enable Digital Function - Port D			
			ldr r7, = GPIO_PORTD_BASE+GPIO_O_DEN	
        	ldr r0, = PORT67
        	str r0, [r7]			

; Activer le registre des switchs, Port D			
			ldr r7, = GPIO_PORTD_BASE+GPIO_PUR	
        	ldr r0, = PORT67
        	str r0, [r7]

			BL	MOTEUR_INIT	   		 		
loop			
			BL	MOTEUR_DROIT_ON
			BL	MOTEUR_GAUCHE_ON

			BL	MOTEUR_DROIT_AVANT	   
			BL	MOTEUR_GAUCHE_AVANT
			

;Traitement qui allume/éteint la LED1 en fonction de l'état  ;du SW1, la LED1 est initialement allumée, et s'éteint si SW1 ;est activé = appuyé
;si switch 1 est actif (=0), on éteint la LED1
			ldr r7,= GPIO_PORTD_BASE + (PORT67<<2)
			ldr r4, [r7]				
	
			
;Test des états des bumper
; Test de l'état de b2			
			cmp	r4,#0x02								
			beq rotleft
; Test l'état de b1			
			cmp r4,#0x01			
			beq rotright
			b	loop
			
			
			
				
rotright	
			BL	MOTEUR_DROIT_ON
			BL	MOTEUR_GAUCHE_ON
			BL	MOTEUR_GAUCHE_AVANTW
			BL	MOTEUR_DROIT_ARRIERE   

; Lire dans R4 l'etat des SW	
			ldr r7,= GPIO_PORTD_BASE + (PORT67<<2)
			ldr r4, [r7]			
			
;Test de l'état de SW1
			cmp r4,#0x40
			beq rotleft
			BL	WAIT
			b	loop; Rotation à gauche de l'Evalbot		
rotleft	
			BL	MOTEUR_DROIT_ON
			BL	MOTEUR_GAUCHE_ON
			BL	MOTEUR_DROIT_AVANT
			BL	MOTEUR_GAUCHE_ARRIERE   
		
			ldr r7,= GPIO_PORTD_BASE + (PORT67<<2)

; Lire dans R4 l'etat des SW
			ldr r4, [r7]			
		
;Test de l'état de SW2
			
			cmp r4,#0x80	
			beq rotright
			BL WAIT
			b loop		
			
			
			
WAIT	ldr r1, =0xAFFFFF
wait1	subs r1, #1
        bne wait1
		BX LR
		

			
			END 

 