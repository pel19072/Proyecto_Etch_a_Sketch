
;*******************************************************************************
;                                                                              *
;    Filename:		    Code -> code.asm				       *
;    Date:                  06/10/2020                                         *
;    File Version:          v.1                                                *
;    Author:                Ricardo Pellecer Orellana                          *
;    Company:               UVG                                                *
;    Description:           Proyecto Sketch                                    *
;                                                                              *
;*******************************************************************************

#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE

 
GPR_VAR			UDATA
    W_TEMP		RES	    1	; PARA GUARDAR INFO MIENTRAS SE EJECUTA LA INTERRUPCIÓN
    STATUS_TEMP		RES	    1
    FLAG		RES	    1	; PARA CAMBIAR DE DISPLAY
    COMUNICACIONX	RES	    1	; CONEXION ENTRE TX Y RX
    COMUNICACIONY	RES	    1	; CONEXION ENTRE TX Y RX
    DISPLAY_HX		RES	    1	; VARIABLE PARA REALIZAR DELAY_1MS
    DISPLAY_LX		RES	    1	; VARIABLE PARA REALIZAR DELAY_1MS
    DISPLAY_HY		RES	    1	; VARIABLE PARA REALIZAR DELAY_1MS
    DISPLAY_LY		RES	    1	; VARIABLE PARA REALIZAR DELAY_1MS
    VAR_ADCX		RES	    1
    VAR_ADCY		RES	    1
    ROTACION		RES	    1
    FLAG_ADC		RES	    1
    FLAG_RC		RES	    1
		

;*******************************************************************************
; RESET VECTOR
;*******************************************************************************

RES_VECT    CODE    0x0000		; processor reset vector
    GOTO    START			; go to beginning of program

;*******************************************************************************
; ISR VECTOR
;*******************************************************************************

ISR_VECTOR  CODE    0x0004

PUSH:			    ; PUSHEA LOS DATOS DE STATUS Y W A UNA VARIABLE TEMPORAL EN CASO SE VEAN AFECTADOS EN LA INTERRUPCIÓN 
    BCF	    INTCON, GIE	    ; DESACTIVA INTERRUPCIONES PARA EVITAR INTERRUPCIONES MIENTRAS SE ESTÁ EN EL ISR
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

ISR:
    BTFSC   PIR1, ADIF	    ; CÓDIGO PARA SABER DE PARTE DE QUÉ TIMER SE REALIZÓ LA INTERRUPCIÓN
    CALL    BANDERA_ADC
    BTFSC   INTCON, T0IF
    CALL    BANDERA_TIMER0
    BTFSC   PIR1, TMR2IF
    CALL    BANDERA_TIMER2    
    BTFSC   PIR1, RCIF
    CALL    BANDERA_RX
        
POP:			    ; POPEA LOS DATOS DE UNA VARIABLE TEMPORAL A STATUS Y W PARA RECUPERAR CUALQUIER DATO PERDIDO EN LA INTERRUPCIÓN
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
RETFIE			    ; INCLUYE LA REACTIVACION DEL GIE

BANDERA_TIMER0:
    MOVLW   .248	    ; DELAY PARA 2ms --> 248 / DELAY PARA 10ms --> 216
    MOVWF   TMR0  
    CALL    DISPLAY
    CALL    NIB_SEPX
    CALL    NIB_SEPY
    BCF	    INTCON, T0IF      
RETURN 
    
BANDERA_TIMER2:    
    BTFSC   PIR1, TXIF
    CALL    BANDERA_TX
    BCF	    PIR1, TMR2IF
RETURN    
    
BANDERA_ADC:
    BTFSC   FLAG_ADC, 0
    GOTO    ADCY
    ADCX:
	MOVFW   ADRESH	    ; MANDA LA CODIFICACION DIGITAL DE MI SEÑAL ANALOGICA AL PUERTO B
	MOVWF   VAR_ADCX
	CALL	CONFIGURACION_ADCY
	BCF	PIR1, ADIF
	BSF	ADCON0, 1
	BSF	FLAG_ADC, 0
    RETURN   
    ADCY:				; FUNGIONA CON EL DISPLAY DERECHO
	MOVFW   ADRESH	    ; MANDA LA CODIFICACION DIGITAL DE MI SEÑAL ANALOGICA AL PUERTO B
	MOVWF   VAR_ADCY
	CALL	CONFIGURACION_ADCX
	BCF	PIR1, ADIF
	BSF	ADCON0, 1
	BCF	FLAG_ADC, 0
    RETURN  
    
    
BANDERA_TX:
    MOVFW   ROTACION
    SUBLW   .3
    BTFSC   STATUS, Z
    GOTO    ENTER
    MOVFW   ROTACION
    SUBLW   .2
    BTFSC   STATUS, Z
    GOTO    COORY
    MOVFW   ROTACION
    SUBLW   .1
    BTFSC   STATUS, Z
    GOTO    COMA
    COORX:
	MOVFW   VAR_ADCX
	MOVWF   TXREG
	INCF	ROTACION
    RETURN  
    
    COMA:
	MOVLW   .44
	MOVWF   TXREG
	INCF	ROTACION
    RETURN
    
    COORY:
	MOVLW   VAR_ADCY
	MOVWF   TXREG
	INCF	ROTACION
    RETURN
    
    ENTER:
	MOVLW   .10
	MOVWF   TXREG
	CLRF	ROTACION
    RETURN
    
BANDERA_RX:    
    BTFSC   FLAG_RC, 0
    GOTO    RCY
    RCX:
	MOVFW   RCREG			; RECIBO LA SEÑAL DEL TX A TRAVÉS DEL RX Y LA MANDO A MI VARIABLE CONECTORA
	MOVWF   COMUNICACIONX
	BSF	FLAG_RC, 0
    RETURN   
    RCY:				; FUNGIONA CON EL DISPLAY DERECHO
	MOVFW   RCREG			; RECIBO LA SEÑAL DEL TX A TRAVÉS DEL RX Y LA MANDO A MI VARIABLE CONECTORA
	MOVWF   COMUNICACIONY
	BCF	FLAG_RC, 0
    RETURN
RETURN    
    
;*******************************************************************************
; TABLA DE DISPLAYS
;*******************************************************************************

TABLA:
    ANDLW   b'00001111' ; MASK
    ADDWF   PCL, F
    RETLW   b'10001000' ; 0
    RETLW   b'11101011'	; 1
    RETLW   b'01001100'	; 2
    RETLW   b'01001001'	; 3
    RETLW   b'00101011'	; 4
    RETLW   b'00011001'	; 5
    RETLW   b'00011000'	; 6
    RETLW   b'11001011'	; 7
    RETLW   b'00001000' ; 8
    RETLW   b'00001011' ; 9
    RETLW   b'00001010' ; A
    RETLW   b'00111000' ; b
    RETLW   b'10011100' ; C
    RETLW   b'01101000' ; d
    RETLW   b'00011100' ; E
    RETLW   b'00011110' ; F  
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG   CODE     0x0100                 ; let linker place main program

START
SETUP:
    CALL    CONFIGURACION_BASE		    ; EXPLICACIONES EN LA SECCIÓN DE CONFIGURACIONES
    CALL    CONFIGURACION_TIMER0
    CALL    CONFIGURACION_TIMER2
    CALL    CONFIGURACION_INTERRUPCION
    CALL    CONFIGURACION_ADC
    CALL    CONFIGURACION_TX_9600
    CALL    CONFIGURACION_RX
    
;*******************************************************************************
; MAIN LOOP
;*******************************************************************************    

LOOP:
    GOTO    LOOP
    
;*******************************************************************************
; RUTINA DE DISPLAY
;*******************************************************************************        
DISPLAY:
    BCF	    PORTA, 1
    BCF	    PORTA, 2
    BCF	    PORTA, 3
    BCF	    PORTA, 4
    BTFSC   FLAG, 0
    GOTO    CY
    CX:
	BTFSC   FLAG, 1
	GOTO    OP1X
	OP0X:
	    MOVFW   DISPLAY_HY		; LLEVA EL VALOR DEL PUERTO INCREMENTADO POR LOS BOTONES PARA SER TRANSFORMADO CON LA TABLA AL VALOR DEL DISLPLAY
	    CALL    TABLA		; TABLA CON LOS VALORES DEL DISPLAY
	    MOVWF   PORTD		; PUERTO CONECTADO AL DISPLAY
	    BSF	    PORTA, 1
	    BSF	    FLAG, 1
	RETURN   
	OP1X:				; FUNGIONA CON EL DISPLAY DERECHO
	    MOVFW   DISPLAY_LY
	    CALL    TABLA	
	    MOVWF   PORTD
	    BSF	    PORTA, 2
	    BSF	    FLAG, 0	
	    BCF	    FLAG, 1	
	RETURN  
    CY:
	BTFSC   FLAG, 1
	GOTO    OP1Y
	OP0Y:
	    MOVFW   DISPLAY_HX		; LLEVA EL VALOR DEL PUERTO INCREMENTADO POR LOS BOTONES PARA SER TRANSFORMADO CON LA TABLA AL VALOR DEL DISLPLAY
	    CALL    TABLA		; TABLA CON LOS VALORES DEL DISPLAY
	    MOVWF   PORTD		; PUERTO CONECTADO AL DISPLAY
	    BSF	    PORTA, 3
	    BSF	    FLAG, 1
	RETURN   
	OP1Y:				; FUNGIONA CON EL DISPLAY DERECHO
	    MOVFW   DISPLAY_LX
	    CALL    TABLA	
	    MOVWF   PORTD
	    BSF	    PORTA, 4
	    BCF	    FLAG, 0	
	    BCF	    FLAG, 1	
	RETURN  

;*******************************************************************************
; RUTINA DE SEPARACIÓN DE NIBBLES
;*******************************************************************************        
    
NIB_SEPX:
    MOVFW   COMUNICACIONX	; COLOCO MI VARIABLE CONECTORA DE COMUNICACION SERIAL EN MIS NIBBLES HIGH Y LOW PARA COLOCARLOS EN EL DISPLAY
    MOVWF   DISPLAY_LX
    SWAPF   COMUNICACIONX, W
    MOVWF   DISPLAY_HX
RETURN   
NIB_SEPY:
    MOVFW   COMUNICACIONY	; COLOCO MI VARIABLE CONECTORA DE COMUNICACION SERIAL EN MIS NIBBLES HIGH Y LOW PARA COLOCARLOS EN EL DISPLAY
    MOVWF   DISPLAY_LY
    SWAPF   COMUNICACIONY, W
    MOVWF   DISPLAY_HY
RETURN
    
;*******************************************************************************
; CONFIGURACIONES
;*******************************************************************************    
     
CONFIGURACION_BASE:
    BANKSEL PORTA
    CLRF    PORTA		; LIMPIA LOS PUERTOS PARA EVITAR QUE TENGAN CUALQUIER VALOR INICIAL DISTINTO DE 0
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE

    BANKSEL ANSEL
    CLRF    ANSEL
    BSF	    ANSEL, 0		; POT EN X
    BSF	    ANSEL, 5		; POT EN Y
    CLRF    ANSELH		; BORRA EL CONTROL DE ENTRADAS ANALÓGICAS	

    BANKSEL TRISA
    MOVLW   b'00100001'		; POT Y TRANSISTORES
    MOVWF   TRISA
		
    CLRF    TRISB		
    CLRF    TRISC		; PARA RX Y TX
    CLRF    TRISD		; PARA DISPLAY
    
    CLRF    TRISE
    
    BANKSEL PORTA
    CLRF    FLAG
    CLRF    FLAG_ADC
    CLRF    FLAG_RC
    CLRF    ROTACION
    CLRF    COMUNICACIONX
    CLRF    COMUNICACIONY
    CLRF    VAR_ADCX  
    CLRF    VAR_ADCY  
    CLRF    DISPLAY_LY
    CLRF    DISPLAY_LX
    CLRF    DISPLAY_HY
    CLRF    DISPLAY_HX
RETURN
    
CONFIGURACION_TIMER0:
    BANKSEL TRISA
    CLRWDT			; CONFIGURACIÓN PARA EL FUNCIONAMIENTO DEL TIMER0
    MOVLW   b'11010111'	
    MOVWF   OPTION_REG 
    BANKSEL PORTA
RETURN
    
CONFIGURACION_TIMER2:
    BANKSEL PORTA
    MOVLW   b'11111111'	
    MOVWF   T2CON    
RETURN
    
CONFIGURACION_INTERRUPCION:
    BANKSEL TRISA
    BSF	    PIE1, TMR2IE
    BSF	    PIE1, ADIE		; HABILITA INTERRUPCION DEL TIMER1
    BSF	    PIE1, RCIE		; HABILITA INTERRUPCION DE RECEPCION SERIAL CON RX
    BSF	    INTCON, PEIE
    BSF	    INTCON, T0IE
    MOVLW   .20
    MOVWF   PR2
    
    BANKSEL PORTA
    BSF	    INTCON, GIE		; HABILITA LAS INTERRUPCIONES
    BCF	    INTCON, T0IF	; PARA ASEGURARSE DE QUE NO TENGA OVERFLOW AL INICIO
RETURN

CONFIGURACION_ADC:    
    BANKSEL ADCON1 
    CLRF    ADCON1		;VDD Y VSS COMO REFERENCIA / JUSTIFICADO A LA IZQUIERDA
    
    BANKSEL ADCON0 
    BSF	    ADCON0, 0
    BSF	    ADCON0, 1  
    BCF	    ADCON0, 2
    BCF	    ADCON0, 3
    BCF	    ADCON0, 5
    BCF	    ADCON0, 6
    BSF	    ADCON0, 7   
RETURN

CONFIGURACION_ADCX:
    BANKSEL ADCON0 
    BCF	    ADCON0, 4
RETURN
    
CONFIGURACION_ADCY:    
    BANKSEL ADCON0 
    BSF	    ADCON0, 4
RETURN
    
CONFIGURACION_TX_9600:
    BANKSEL TRISA
    BCF	    TXSTA, TX9    
    BCF	    TXSTA, SYNC	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    BSF	    TXSTA, BRGH	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz

    BANKSEL ANSEL
    BCF	    BAUDCTL, BRG16  ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    
    BANKSEL TRISA
    MOVLW   .25
    MOVWF   SPBRG	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    CLRF    SPBRGH	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    BSF	    TXSTA, TXEN    
    BANKSEL PORTA
RETURN
    
CONFIGURACION_RX:
    BANKSEL PORTA
    BSF	    RCSTA, SPEN
    BCF	    RCSTA, RX9
    BSF	    RCSTA, CREN
RETURN
    
    
;*******************************************************************************

    
    END