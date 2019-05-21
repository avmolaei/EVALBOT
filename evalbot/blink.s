	;; TG 09/2012 - Evalbot (Cortex M3 de Texas Instrument)
	;; fait clignoter les leds connectées au port GPIO_F
   	
		AREA    |.text|, CODE, READONLY
 

SYSCTL_PERIPH		EQU		0x400FE108	;SYSCTL_RCGC2_R : pour enable clock (p291 datasheet de lm3s9b92.pdf)
GPIO_PORTF_BASE		EQU		0x40025000  ; voir chap.8 "GPIO": page 416 de lm3s9B92.pdf
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction  (p417 de lm3s9B92.pdf)
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 de lm3s9B92.pdf)
GPIO_O_DEN   		EQU 	0x0000051C  ; GPIO Digital Enable	(p437 de lm3s9B92.pdf)
										; Pour être "propre" il faudrait aussi s'assurer que les
										;autres registres de configuration sont a 0 (ce qui est le
										;cas a l'init.)


PORT4				EQU		0x10	;led sur port 4
PORT5				EQU		0x20  	;led sur port 5


DUREE   			EQU     0x002FFFFF	

	  	ENTRY
		EXPORT	__main
__main
		ldr r6, = SYSCTL_PERIPH
        mov r0, #0x00000020  ;;Enable clock sur GPIOF où sont branchés les leds
        str r0, [r6]
		
		nop	   ; tres tres important....(beaucoup temps perdu, cf petite note p413!)
		nop	   ; "There must be  a delay of 3 system clocks before any GPIO reg. access
		nop	   ; pas necessaire en simu  ou en debbug step by step...@#@! :-(
	
        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR   ;2 Pins du portF en sortie
        ldr r0, = PORT4 + PORT5	
        str r0, [r6]
		
        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;;Enable Digital Function (p316 )
        ldr r0, = PORT4 + PORT5		
        str r0, [r6]
 
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = PORT4 + PORT5			
        str r0, [r6]

        mov r2, #0x000       ;pour eteindre tout
     
		;Allume les 2 leds
		mov r3, #(PORT4 + PORT5)     ;Allume portF broche 4et 5 : 00110000
        ldr r6, = GPIO_PORTF_BASE+ ((PORT4+PORT5)<<2) ; @data Register = @base + (mask<<2)

		;Pour allumer seulement la led broche 4 sans toucher au reste (led 5)
		;mov r3, #PORT4       ;Allume portF broche 4 : 00010000
		;ldr r6, = GPIO_PORTF_BASE+ (PORT4<<2) ; @data Register = @base + (mask<<2)

		;on peut aussi allumer la led 4 comme ca => ca eteint la led 5 si allumée
		;mov r3, #PORT5 	     ;Allume portF broche 4et 5 : 00110000
        ;ldr r6, = GPIO_PORTF_BASE+ ((PORT4+PORT5)<<2) ; @data Register = @base + (mask<<2)
loop
        str r2, [r6]    ;Eteint tout car r2 = 0x00      
        ldr r1, = DUREE ;pour la duree de la boucle d'attente1 (wait1)

wait1	subs r1, #1
        bne wait1

        str r3, [r6]  ;Allume en fonction du contenu de r3
        ldr r1, = DUREE	;pour la duree de la boucle d'attente2 (wait2)

wait2   subs r1, #1
        bne wait2

        b loop                 
        END 