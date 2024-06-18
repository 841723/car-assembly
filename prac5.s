		AREA datos,DATA
; gestion VIC
VICIntEnable   		EQU 0xFFFFF010      ; @ para habilitar iterrupciones de UN periferico en VIC
VICIntEnClr  		EQU 0xFFFFF014      ; @ para deshabilitar iterrupciones de UN periferico en VIC
VICVectAddr0   		EQU 0xFFFFF100      ; @ del periferico 1 en el vector de interrupcion
VICVectAddr			EQU 0xFFFFF030      ; @ del periferico que le llega a la CPU

; gestion indices de prioridades IRQ
timer_indice		EQU 4				; indice en el vector VI donde debe estar @RSI_timer
teclado_indice 		EQU 7				; indice en el vector VI donde debe estar @RSI_teclado

; gestion direcciones
timer_os			DCD 0
teclado_os			DCD 0
	
; gestion RSI
RDAT				EQU 0xE0010000		; ASCII de la tecla pulsada
T0_IR				EQU 0xE0004000 		
T0_TC				EQU 0xE0004008
	
; gestion stats jugador 'H'
					ALIGN 4
pos_H				DCD 0x40007FF1		; @ de posicion de H
dirx_H				DCB 0 				; direccion mov. caracter ‘H’ (-1 izda.,0 stop,1 der.) 
diry_H 				DCB 0				; direccion mov. caracter ‘H’ (-1 arriba,0 stop,1 abajo)
activo_H			DCB 0				; =1 activo H, =0 no activo H


; gestion stats jugador 'A'
					ALIGN 4
pos_A				DCD 0x40007FEC		; @ de posicion de A
dirx_A				DCB 0 				; direccion mov. caracter ‘A’ (-1 izda.,0 stop,1 der.) 
diry_A 				DCB 0 				; direccion mov. caracter ‘A’ (-1 arriba,0 stop,1 abajo)
activo_A			DCB 0				; =1 activo A, =0 no activo A
				
; gestion stats juego
vel_max				DCB 1
vel_min				DCB 128
vel					DCB 16
					ALIGN 4
reloj 				DCD 0
; gestion cronometro
minutos				DCB 0
segundos_unidades 	DCB 0
segundos_decenas 	DCB 0
decimas				DCB 0
centesimas			DCB 0
					ALIGN 4


; gestion finalizacion del programa
fin 				EQU 0 				;indicador fin de programa (si vale 1) 

; gestion pantalla y carretera
pantalla_arriba		EQU 0x40007E00
pantalla_abajo		EQU 0x40007FFF
carretera_arriba 	EQU 0x40007E20
carretera_abajo		EQU 0x40007FFF
direccion_sig		DCB 0  				; =0 por calcular, =1 izquierda, =2 derecha, =3 recto
n_rest				DCB 0
columna_izq_sup		DCB 7
ancho				DCB 15
giros				EQU 3

	
; gestion caracteres ASCII
espacio				EQU 32
sostenido			EQU 35
H					EQU 72
A					EQU 65 
arroba				EQU 64
izq					EQU 60
der					EQU 62
obstaculo			EQU 56
	
; gestion menu
pulsa				DCB ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','P','U','L','S','A',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
jugadores			DCB ' ',' ',' ','1',' ','J','U','G','A','D','O','R',':',' ',' ',' ',' ',' ','2',' ','J','U','G','A','D','O','R','E','S',':',' ',' '
numeros				DCB ' ',' ',' ',' ',' ',' ',' ',' ','1',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ','2',' ',' ',' ',' ',' ',' ',' ',' '
inicia_juego		DCB 0
final				DCB ' ',' ',' ',' ',' ',' ',' ','P','A','R','T','I','D','A',' ',' ',' ','P','E','R','D','I','D','A',' ',' ',' ',' ',' ',' ',' ',' '

;
;						LA MAYORIA DE LAS SUBRUTINAS REALIZADAS SIN PASAR PARAMETROS NI RESULTADOS
;						
;					Despues de tutoria con carlos, esta fue la conclusion, dejarlas sin parametros ya que 
;					dentro de ellas se usan multitud de variables del area de datos. Por lo tanto no podrian
;					catalogarse como SBR, pero son extensiones de codigo con encapsulacion de registros. Se
;					utilizan para una mejor legibilidad, "humanizar" del codigo, y asi comprender el significado
;					de un conjunto de instrucciones. Aparte esto no afecta al correcto funcionamiento del 
;					programa.
;					


		AREA codigo,CODE
		
		EXPORT inicio					; forma de enlazar con el startup.s
		IMPORT srand					; para poder invocar SBR srand
		IMPORT rand						; para poder invocar SBR rand
			
inicio		

		; inicio las RSI con el VIC
		LDR r0, =VICVectAddr0
		LDR r1, =teclado_os					
		LDR r2, =teclado_indice				
		ldr r3, [r0,r2,LSL #2]				
		str r3, [r1]						
		LDR r3, =RSI_teclado				
		str r3, [r0,r2,LSL #2]
		ldr r1, =timer_os					
		ldr r2, =timer_indice				
		ldr r3, [r0,r2,LSL #2]				
		str r3, [r1]						
		LDR r3, =RSI_timer			
		str r3, [r0,r2,LSL #2]
		LDR r0, =VICIntEnable				
		mov r1, #2_10010000
		str r1, [r0]						
		
		; comienzo del programa como tal
		bl borra_pantalla	
		ldr r0, =carretera_arriba
		add r0, r0, #128
		ldr r1, =pulsa
		mov r2, #0
		; bucle para escribir primera linea en pantalla
buc_pulsa
		ldrb r3, [r1, r2]
		strb r3, [r0, r2]
		add r2, r2, #1
		cmp r2, #32
		bne buc_pulsa	
		add r0, r0, #64
		ldr r1, =jugadores
		mov r2, #0
		; bucle para escribir segunda linea en pantalla
buc_jugador
		ldrb r3, [r1, r2]
		strb r3, [r0, r2]
		add r2, r2, #1
		cmp r2, #32
		bne buc_jugador	
		add r0, r0, #32
		ldr r1, =numeros
		mov r2, #0
		; bucle para escribir tercera linea en pantalla
buc_numeros
		ldrb r3, [r1, r2]
		strb r3, [r0, r2]
		add r2, r2, #1
		cmp r2, #32
		bne buc_numeros
buc_menu
		ldr r0, =inicia_juego
		ldrb r0, [r0]
		cmp r0, #1
		bne buc_menu
		; espera hasta seleccionar un modo de juego
		; pone en la semilla el tiempo hasta el momento actual
		bl borra_pantalla
		ldr r0, =T0_TC
		ldr r0, [r0]
		PUSH{r0}
		bl srand
		add sp, sp, #4
		ldr r0, =activo_A
		ldrb r0, [r0]
		cmp r0, #0
		beq un_jugador
		; configura la carretera y jugadores dependiendo de los jugadores que actuaran
dos_jugadores		
		mov r0, #A
		ldr r1, =0x40007FEC
		ldr r2, =pos_A
		str r1, [r2]
		strb r0, [r1]
		mov r0, #H
		ldr r1, =0x40007FF1
		ldr r2, =pos_H
		str r1, [r2]
		strb r0, [r1]
		b inicio_while
un_jugador
		mov r0, #H
		ldr r1, =0x40007FEC
		ldr r2, =pos_H
		str r1, [r2]
		strb r0, [r1]
		ldr r0, =ancho
		mov r1, #8
		strb r1, [r0]
		ldr r0, =columna_izq_sup
		strb r1, [r0]
inicio_while		
		bl comenzar_pantalla	
		
while
		; bucle "infinito" hasta que fin sea 1 o esten desactivados AMBOS coches, gestion de movimientos de jugadores y carretera
		ldr r0, =activo_A
		ldrb r0, [r0]
		ldr r1, =activo_H
		ldrb r1, [r1]
		add r2, r0, r1, LSL #1
		cmp r1, #1
		bleq mover_H
		cmp r0, #1
		bleq mover_A
		bl actualizar_pantalla
		cmp r2, #0
		beq fin_while
		ldr r0, =fin
		cmp r0, #1
		bne while		
fin_while		
		; desactivacion de RSI mediante VIC
		ldr r0, =VICIntEnClr				
		mov r1, #2_10010000					
		str r1, [r0]		
		bl pantalla_final			
bfin 
		; bucle final
		b bfin
	
	
			; SUBRUTINAS SBR
; 	como he comentado antes no son SBR como tal, ya que no se utilizan parametros pasados por pila, sino que se cogen directamente del area de datos
; 	pese a esto, las llamaremos SBR.

; SBR pantalla_final
pantalla_final
		PUSH {lr}
		PUSH {r0-r3}
		bl borra_pantalla
		ldr r0, =carretera_arriba
		add r0, r0, #128
		ldr r1, =final
		mov r2, #0
		; bucle para escribir linea en pantalla en la posicion correcta
buc_final
		ldrb r3, [r1, r2]
		strb r3, [r0, r2]
		add r2, r2, #1
		cmp r2, #32
		bne buc_final
		ldr r0, =0x40007EEC
		PUSH {r0}
		bl muestra_tiempo
		add sp, sp, #4
		POP {r0-r3}
		POP {pc}
		
;SBR comenzar_pantalla			
comenzar_pantalla
		PUSH {lr}
		PUSH {r0-r5}
		ldr r0, =carretera_arriba
		ldr r1, =carretera_abajo
		mov r2, #sostenido
		ldr r3, =columna_izq_sup
		ldrb r3, [r3]
		ldr r4, =ancho
		ldrb r4, [r4]
		rsb r5, r4, #32
		add r0, r0, r3
		; r5 es la cantidad de bits que hay que avanzar para llegar del extremo derecho de la carretera hasta el izquierdo, 
		; "atravesando" el borde de la pantalla
buc_comienzo_pantalla
		; se colocan #, limites de carrtera dependiendo del ancho de la misma
		strb r2, [r0], r4
		strb r2, [r0], r5
		cmp r0, r1
		blt buc_comienzo_pantalla	
		POP {r0-r5}
		POP {pc}

; SBR bajar_carretera
bajar_carretera
		PUSH{lr}
		PUSH{r0-r10}
		
		; borrar ultima fila
		ldr r0, =carretera_abajo
		mov r1, #32
		mov r2, #sostenido
		mov r3, #espacio
buc1_borrar_ultima_fila
		ldrb r4, [r0, -r1]
		cmp r4, r2 
		strbeq r3, [r0, -r1]
		add r1, r1, #-1
		cmp r1, #0
		bne buc1_borrar_ultima_fila
		
		; bajar demas filas
		sub r0, r0, #32
		mov r1, #480
buc2_bajar_carretera
		mov r6, #0
		ldrb r4, [r0]
		cmp r4, r2
		bne no_desactivar
		
		ldrb r4, [r0,#32]
		cmp r4, #A
		ldreq r5, =activo_A
		strbeq r6, [r5]
		cmp r4, #H
		ldreq r5, =activo_H
		strbeq r6, [r5]
no_desactivar		
		ldrb r4, [r0]
		cmp r4, r2 
		; guardo las nuevas posiciones de la carretera
		mov r3, #espacio
		strbeq r3, [r0]
		strbeq r2, [r0, #32]
		add r1, r1, #-1
		add r0, r0, #-1
		cmp r1, #0
		bne buc2_bajar_carretera
fin_buc1_borrar_ultima_fila
		POP{r0-r10}
		POP{pc}
		
		
; SBR actualizar_pantalla 
actualizar_pantalla
		PUSH{lr}
		PUSH{r0-r4}
		
		; sincronizacion con el reloj, VELOCIDAD, si tiempo no es el suficiente, no se ejecuta
		ldr r0, =reloj						 
		ldr r1, [r0]							; guardas en r1, el reloj
		ldr r2, =vel
		ldrb r2, [r2]							; guardas en r2, la velocidad de H
		cmp r1, r2
		blt	fin_actualizar_pantalla
		mov r2, #0
		str r2, [r0]							; ponemos a 0 el tiempo
		bl bajar_carretera

		; ver si hay alguna direccion definida previamenre
		ldr r1, =direccion_sig
		ldrb r0, [r1]							
		cmp r0, #0								; si direccion_sig = 0: ALEATORIO
		beq aleatorio
	
		ldr r3, =n_rest
		ldrb r4, [r3]							
		sub r4, r4, #1							
		cmp r4, #0								; si (n_rest-1) == 0 ====> direccion_sig = 0, n_rest == 4
		strbeq r4, [r1]							
		addeq r4, r4, #giros						
		strb r4, [r3]

		; como SI que hay direccion definida previamente se evalua cual es
		; =1 IZQUIERDA, =2 DERECHA, =3 RECTO
		cmp r0, #1
		beq mover_izquierda_c
		cmp r0, #2
		beq mover_derecha_c
		cmp r0, #3
		beq mover_recto_c
		
		; sacar nueva direccion
aleatorio
		ldr r3, =n_rest
		mov r4, #giros
		strb r4, [r3]
		
		sub sp, sp, #4
		bl rand
		POP {r0}
		
		movs r0, r0, LSR #12
		bcc mover_lados
		ldr r0, =direccion_sig
		mov r1, #3
		strb r1, [r0]
		
mover_recto_c
		; avanzar recto la carretera
		ldr r0, =carretera_arriba
		mov r1, #sostenido
		ldr r2, =columna_izq_sup
		ldrb r2, [r2]
		ldr r3, =ancho
		ldrb r3, [r3]
		strb r1, [r0, r2]
		add r2, r2, r3
		strb r1, [r0, r2]
		b fin_actualizar_pantalla
				
mover_lados
		mov r1, #1
		and r0, #2_1
		cmp r0, #0
		
		ldr r0, =direccion_sig
		strbeq r1, [r0]
		
		beq mover_izquierda_c
		mov r1, #2
		strb r1, [r0]
		
mover_derecha_c
		; comprueba que no se vaya a chocar con la pared derecha; si lo va hacer, avanza recto
		ldr r1, =columna_izq_sup
		ldrb r1, [r1]
		cmp r1, #16
		beq mover_recto_c
		
		ldr r0, =carretera_arriba
		mov r1, #sostenido
		ldr r4, =columna_izq_sup
		ldrb r2, [r4]
		ldr r3, =ancho
		ldrb r3, [r3]
		add r2, r2, #1
		strb r2, [r4]
		strb r1, [r0, r2]
		add r2, r2, r3
		strb r1, [r0, r2]
		b fin_actualizar_pantalla
		
mover_izquierda_c
		; comprueba que no se vaya a chocar con la pared izquierda; si lo va hacer, avanza recto
		ldr r1, =columna_izq_sup
		ldrb r1, [r1]
		cmp r1, #0
		beq mover_recto_c
		
		ldr r0, =carretera_arriba
		mov r1, #sostenido
		ldr r4, =columna_izq_sup
		ldrb r2, [r4]
		ldr r3, =ancho
		ldrb r3, [r3]
		add r2, r2, #-1
		strb r2, [r4]
		strb r1, [r0, r2]
		add r2, r2, r3
		strb r1, [r0, r2]
		b fin_actualizar_pantalla
				
fin_actualizar_pantalla
		POP{r0-r4}
		POP {pc}
		
; SBR borra_pantalla
borra_pantalla
		PUSH{lr}								
		PUSH{r0-r2}								
		mov r0, #0								
		mov r1, #32								
		ldr r2, =pantalla_arriba				
		; bucle que pone en blanco toda la pantalla
buc_borra
		cmp r0, #512
		beq fin_buc_borra						
		strb r1, [r2], #1						
		add r0,r0,#1
		bal buc_borra
fin_buc_borra	
		POP{r0-r2}
		POP{pc}


; SBR muestra_tiempo
;	esta si es SBR como tal ya que si se guarda un parametro en la pila, pero tambien se usan del area de datos
;	el parametro es la posicion donde va a escribirse el cronometro, ya que en la pantalla final es diferente a durante el juego
muestra_tiempo
		PUSH{lr, r11}
		mov fp, sp
		PUSH{r0-r6}

		ldr r0, =decimas						
		ldrb r0, [r0]							
		ldr r1, =segundos_unidades				
		ldrb r1, [r1]							
		ldr r2, =segundos_decenas				
		ldrb r2, [r2]								
		ldr r3, =minutos						
		ldrb r3, [r3]							
		ldr r4, [fp, #8]
		mov r5, #58								
		mov r6, #48								
		strb r6, [r4], #1						
		add r3, r3, r6							
		strb r3, [r4], #1						
		strb r5, [r4], #1						
		add r2, r2, r6							
		strb r2, [r4], #1					
		add r1, r1, r6							
		strb r1, [r4], #1					
		strb r5, [r4], #1						
		add r0, r0, r6							
		strb r0, [r4], #1						

		POP{r0-r6}
		POP{pc, r11}
	
; SBR desactivar_HA
desactivar_HA
		; desactivara tanto el coche A como el H y parara la ejecucion del juego
		PUSH {lr}
		PUSH {r0-r2}
		
		ldr r0, =activo_H
		ldr r1, =activo_A
		mov r2, #0
		strb r2, [r0]
		strb r2, [r1]
		
		POP {r0-r2}
		POP {pc}


; SBR mover_H
mover_H
		PUSH{lr}
		PUSH{r0-r10}
				
mover_H_izquierda
		; compruebo que dirx_H = -1
		ldr r0, =dirx_H
		ldrsb r0,[r0]							
		cmp r0, #-1								; si es =-1, mover izquierda
		bne mover_H_derecha
		
		; compruebo que no vaya a superar ningun borde 
		ldr r1, =pos_H
		ldr r2, [r1]
		ldrb r2, [r2, #-1]
		mov r3, #A
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_H
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_H
		strbne r1, [r2]
		ldrne r2, =pos_H
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_H
		
		; borrar anterior coche
		ldr r3, =pos_H
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]
		
		; moverse
		mov r1, #H
		strb r1, [r2, #-1]!
		str r2, [r3]
		
		; poner dirx a 0
		ldr r0, =dirx_H
		mov r1, #0
		strb r1, [r0]
		b fin_mover_H
		
mover_H_derecha
		; compruebo que dirx = 1
		cmp r0, #1								; si es =1, mover derecha
		bne mover_H_arriba
		ldr r1, =pos_H
		ldr r2, [r1]
		ldrb r2, [r2, #1]
		mov r3, #A
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_H
		
		; compruebo que no vaya a superar ningun borde 
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_H
		strbne r1, [r2]
		ldrne r2, =pos_H
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_H

		; borrar anterior coche
		ldr r3, =pos_H
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #H
		strb r1, [r2, #1]!
		str r2, [r3]		
		; poner dirx a 0
		ldr r0, =dirx_H
		mov r1, #0
		strb r1, [r0]
		b fin_mover_H
mover_H_arriba
		; compruebo que diry_H = 1
		ldr r0, =diry_H
		ldrsb r0,[r0]							
		cmp r0, #1								; si es =1, mover arriba
		bne mover_H_abajo
		
		; compruebo que no me vaya a comer ningun borde 
		ldr r1, =pos_H
		ldr r2, [r1]
		sub r3, r2, #32
		ldr r1, =carretera_arriba
		cmp r3, r1
		blt fin_mover_H
		
		ldrb r2, [r2, #-32]
		mov r3, #A
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_H
		
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_H
		strbne r1, [r2]
		ldrne r2, =pos_H
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_H

		
		; borrar anterior
		ldr r3, =pos_H
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #H
		strb r1, [r2, #-32]!
		str r2, [r3]		
		; poner diry a 0
		ldr r0, =diry_H
		mov r1, #0
		strb r1, [r0]
		b fin_mover_H
mover_H_abajo
		; compruebo que diry_H = -1				
		cmp r0, #-1					; si es =1, mover abajo				
		bne fin_mover_H	
		
		; compruebo que no me vaya a comer ningun borde 
		ldr r1, =pos_H
		ldr r2, [r1]
		
		add r3, r2, #32
		ldr r1, =carretera_abajo
		cmp r3, r1
		bgt fin_mover_H
		
		ldrb r2, [r2, #32]
		mov r3, #A 
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_H
		
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_H
		strbne r1, [r2]
		ldrne r2, =pos_H
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_H
						
		; borrar anterior
		ldr r3, =pos_H
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #H
		strb r1, [r2, #32]!
		str r2, [r3]		
		; poner diry a 0
		ldr r0, =diry_H
		mov r1, #0
		strb r1, [r0]
		b fin_mover_H

fin_mover_H	
		POP{r0-r10}
		POP{pc}
		
		
; mover_A
mover_A
		PUSH{lr}
		PUSH{r0-r10}
		
mover_A_izquierda	
		; compruebo que dirx_A = -1
		ldr r0, =dirx_A
		ldrsb r0,[r0]							
		cmp r0, #-1								
		bne mover_A_derecha
		; compruebo que no me vaya a comer ningun borde 
		ldr r1, =pos_A
		ldr r2, [r1]
		ldrb r2, [r2, #-1]
		mov r3, #H
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_A
		
wh		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_A
		strbne r1, [r2]
		ldrne r2, =pos_A
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_A
		; borrar anterior
		ldr r3, =pos_A
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #A
		strb r1, [r2, #-1]!
		str r2, [r3]		
		; poner dirx a 0
		ldr r0, =dirx_A
		mov r1, #0
		strb r1, [r0]
		b fin_mover_A
		
mover_A_derecha
		; compruebo que dirx_A = 1
		cmp r0, #1								
		bne mover_A_arriba
		ldr r1, =pos_A
		ldr r2, [r1]
		ldrb r2, [r2, #1]
		mov r3, #H
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_A
		
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_A
		strbne r1, [r2]
		ldrne r2, =pos_A
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_A
		; borrar anterior
		ldr r3, =pos_A
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #A
		strb r1, [r2, #1]!
		str r2, [r3]		
		; poner dirx a 0
		ldr r0, =dirx_A
		mov r1, #0
		strb r1, [r0]
		b fin_mover_A
mover_A_arriba
		; compruebo que diry_A = 1
		ldr r0, =diry_A
		ldrsb r0,[r0]							
		cmp r0, #1								
		bne mover_A_abajo
		; compruebo que no me vaya a comer ningun borde lateral
		ldr r1, =pos_A
		ldr r2, [r1]
		
		sub r3, r2, #32
		ldr r1, =carretera_arriba
		cmp r3, r1
		blt fin_mover_A
		
		ldrb r2, [r2, #-32]
		mov r3, #H
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_A
		
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_A
		strbne r1, [r2]
		ldrne r2, =pos_A
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_A	
		
		; borrar anterior
		ldr r3, =pos_A
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #A
		strb r1, [r2, #-32]!
		str r2, [r3]		
		; poner diry a 0
		ldr r0, =diry_A
		mov r1, #0
		strb r1, [r0]
		b fin_mover_A
mover_A_abajo
		; compruebo que diry_A = -1						
		cmp r0, #-1								
		bne fin_mover_A
		; compruebo que no me vaya a comer ningun borde lateral
		ldr r1, =pos_A
		ldr r2, [r1]
		
		add r3, r2, #32
		ldr r1, =carretera_abajo
		cmp r3, r1
		bgt fin_mover_A
		
		ldrb r2, [r2, #32]
		mov r3, #H
		cmp r3, r2
		bleq desactivar_HA
		beq fin_mover_A
		
		mov r0, #espacio
		mov r1, #0
		cmp r2,r0
		ldrne r2, =activo_A
		strbne r1, [r2]
		ldrne r2, =pos_A
		ldrne r2, [r2]
		strbne r0, [r2]
		bne fin_mover_A
		
		; borrar anterior
		ldr r3, =pos_A
		ldr r2, [r3]
		mov r1, #espacio
		strb r1, [r2]		
		; moverse
		mov r1, #A
		strb r1, [r2, #32]!
		str r2, [r3]		
		; poner diry a 0
		ldr r0, =diry_A
		mov r1, #0
		strb r1, [r0]
		b fin_mover_A
		
fin_mover_A	
		POP{r0-r10}
		POP{pc}
		
		
		
			;INTERRUPCIONES RSI
; RSI_timer
RSI_timer
		sub lr, lr, #4							
		PUSH {lr}								
		mrs r14, spsr							
		PUSH {r14}								
		msr cpsr_c,#2_01010010
		PUSH {r0-r1}
		
		ldr r0, =T0_IR
		mov r1, #1
		str r1, [r0]
		
		ldr r0, =reloj
		ldr r1, [r0]
		add r1, r1, #1
		str r1, [r0]	
		
		ldr r0, =activo_A
		ldrb r0, [r0]
		ldr r1, =activo_H
		ldrb r1, [r1]
		add r1, r0, r1, LSL #1
		cmp r1, #0
		beq fin_RSI_timer_2
		
		ldr r1, =centesimas						; Guardamos en r1 @centesimas
		ldrb r0, [r1]							; Guardamos en r0 el valor de centesimas
		add r0, r0, #1							; Sumamos una centesima al tiempo actual
		strb r0, [r1]
		cmp r0, #10								; Se han llegado a 10 centesimas -> decimas debe aumentar
		bne fin_RSI_timer						
		mov r0, #0								; Se ponen centesimas a 0
		strb r0, [r1]
		
		ldr r1, =decimas						; Guardamos en r1 @decimas
		ldrb r0, [r1]							; Guardamos en r0 el valor de decimas
		add r0, r0, #1							; Sumamos una centesima al tiempo actual
		strb r0, [r1]
		cmp r0, #10								; Se han llegado a 100 decimas -> segundos debe aumentar
		bne fin_RSI_timer						; 
		mov r0, #0								; Se ponen decimas a 0
		strb r0, [r1]
		
		ldr r1, =segundos_unidades				; Guardamos en r1 @segundos_unidades
		ldrb r0, [r1]							; Guardamos en r2 el valor de segundos_unidades
		add r0, r0, #1							; Aumentamos en 1 ya que se ha llegado a 100 decimas
		strb r0, [r1]
		cmp r0, #10								; Se han llegado a 10 segundos_unidades -> segundos_decenas debe aumentar
		bne fin_RSI_timer
		mov r0, #0
		strb r0, [r1]
		
		ldr r1, =segundos_decenas				; Guardamos en r1 @segundos_decenas
		ldrb r0, [r1]							; Guardamos en r0 el valor de segundos_decenas
		add r0, r0, #1							; Aumentamos en 1 ya que se ha llegado a 10 unidades de segundo
		strb r0, [r1]
		cmp r0, #6								; Se han llegado a 60 segundos -> minutos debe aumentar
		bne fin_RSI_timer
		mov r0, #0
		strb r0, [r1]
		
		ldr r1, =minutos						; Guardamos en r1 @minutos
		ldrb r0, [r1]							; Guardamos en r0 el valor de minutos
		add r0, r0, #1							; Sumamos un minuto al tiempo actual
		strb r0, [r1]
		
fin_RSI_timer
		ldr r0, =pantalla_arriba
		PUSH {r0}
		bl muestra_tiempo
		add sp, sp, #4
fin_RSI_timer_2
		POP {r0-r1}
		msr cpsr_c,#2_11010010
		POP {r14}								
		msr spsr_fsxc, r14						
		LDR r14, =VICVectAddr					
		str r14, [r14]							
		POP {pc}^



; RSI_teclado
RSI_teclado
		sub lr, lr, #4							
		PUSH {lr}								
		mrs r14, spsr							
		PUSH {r14}								
		msr cpsr_c,#2_01010010
		PUSH {r0-r3}							

		LDR r1, =RDAT							
		ldrb r0, [r1]							
		ldr r1, =pantalla_abajo
		
sel_un_jugador
		cmp r0, #49
		bne sel_dos_jugadores
		
		ldr r0, =inicia_juego
		ldrb r1, [r0]
		mov r2, #1
		cmp r1, #0
		strbeq r2, [r0]
		bne fin_RSI_teclado_H
		
		ldr r0, =activo_H
		mov r1, #1
		strb r1, [r0]
		bal fin_RSI_teclado_H
		
sel_dos_jugadores
		cmp r0, #50
		bne aumentar_vel
		
		ldr r0, =inicia_juego
		ldrb r1, [r0]
		mov r2, #1
		cmp r1, #0
		strbeq r2, [r0]
		bne fin_RSI_teclado_H
		
		ldr r0, =activo_H
		mov r1, #1
		strb r1, [r0]
		ldr r0, =activo_A
		mov r1, #1
		strb r1, [r0]
		bal fin_RSI_teclado_H
		
aumentar_vel
		cmp r0, #43								; miras si la tecla pulsada es ASCII(43)='+'
		bne reducir_vel						    ; si no es, salta a la siguiente comprobacion
		ldr r0, =vel
		ldrb r1, [r0]
		cmp r1, #1
		beq fin_RSI_teclado
		mov r1, r1, LSR #1
		strb r1, [r0]	
		bal fin_RSI_teclado_H


reducir_vel
		cmp r0, #45								; miras si la tecla pulsada es ASCII(45)='-'
		bne mover_izquierda_H					; si no es, salta a la siguiente comprobacion
		ldr r0, =vel
		ldrb r1, [r0]
		cmp r1, #128
		beq fin_RSI_teclado
		mov r1, r1, LSL #1
		strb r1, [r0]	
		bal fin_RSI_teclado_H

		
				
mover_izquierda_H
		and r0, #2_11011111						; pasa el valor de la tecla a minuscula
		cmp r0, #74								; miras si la tecla pulsada es ASCII(74)='j'
		bne mover_derecha_H						; si no es, salta a la siguiente comprobacion
		ldr r0, =dirx_H
		ldrb r1, [r0]
		mov r1, #-1
		strb r1, [r0]
		ldr r0, =diry_H
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]
		bal fin_RSI_teclado_H



mover_derecha_H
		cmp r0, #76								; miras si la tecla pulsada es ASCII(76)='l'
		bne mover_arriba_H						; si no es, salta a la siguiente comprobacion
		ldr r0, =dirx_H
		ldrb r1, [r0]
		mov r1, #1
		strb r1, [r0]
		ldr r0, =diry_H
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_H

		
		
mover_arriba_H
		cmp r0, #73								; miras si la tecla pulsada es ASCII(73)='i'
		bne mover_abajo_H						; si no es, salta a la siguiente comprobacion
		ldr r0, =diry_H
		ldrb r1, [r0]
		mov r1, #1
		strb r1, [r0]
		ldr r0, =dirx_H
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_H

	
	
mover_abajo_H
		cmp r0, #75								; miras si la tecla pulsada es ASCII(75)='k'
		bne acabar_q							; si no es, salta a la siguiente comprobacion	
		ldr r0, =diry_H
		ldrb r1, [r0]
		mov r1, #-1
		strb r1, [r0]
		ldr r0, =dirx_H
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_H

		
	
acabar_q
		cmp r0, #81								; miras si la tecla pulsada es ASCII(81)='q'
		bne fin_RSI_teclado_H					; si no es, salta a la siguiente comprobacion
		ldr r0, =fin
		mov r1, #1
		str r1, [r0]
		bal fin_RSI_teclado_H

fin_RSI_teclado_H

; detectar teclas de A
mover_izquierda_A
		
		cmp r0, #65								; miras si la tecla pulsada es ASCII(74)='j'
		bne mover_derecha_A						; si no es, salta a la siguiente comprobacion
		ldr r0, =dirx_A
		ldrb r1, [r0]
		mov r1, #-1
		strb r1, [r0]
		ldr r0, =diry_A
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]
		bal fin_RSI_teclado_A



mover_derecha_A
		cmp r0, #68								; miras si la tecla pulsada es ASCII(76)='l'
		bne mover_arriba_A						; si no es, salta a la siguiente comprobacion
		ldr r0, =dirx_A
		ldrb r1, [r0]
		mov r1, #1
		strb r1, [r0]
		ldr r0, =diry_A
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_A

		
		
mover_arriba_A
		cmp r0, #87								; miras si la tecla pulsada es ASCII(73)='i'
		bne mover_abajo_A						; si no es, salta a la siguiente comprobacion
		ldr r0, =diry_A
		ldrb r1, [r0]
		mov r1, #1
		strb r1, [r0]
		ldr r0, =dirx_A
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_A

	
	
mover_abajo_A
		cmp r0, #83								; miras si la tecla pulsada es ASCII(75)='k'
		bne fin_RSI_teclado_A					; si no es, salta a la siguiente comprobacion	
		ldr r0, =diry_A
		ldrb r1, [r0]
		mov r1, #-1
		strb r1, [r0]
		ldr r0, =dirx_A
		ldrb r1, [r0]
		mov r1, #0
		strb r1, [r0]		
		bal fin_RSI_teclado_A

	
fin_RSI_teclado_A
fin_RSI_teclado
		POP {r0-r3}								
		msr cpsr_c,#2_11010010
		POP {r14}								
		msr spsr_fsxc, r14						
		LDR r14, =VICVectAddr					
		str r14, [r14]							
		POP {pc}^
		
		END