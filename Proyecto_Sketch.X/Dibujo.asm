
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
    X			RES	    1	; CONEXION ENTRE TX Y RX
    Y			RES	    1	; CONEXION ENTRE TX Y RX
    XH			RES	    1	; CONEXION ENTRE TX Y RX
    YH			RES	    1	; CONEXION ENTRE TX Y RX
    XL			RES	    1	; CONEXION ENTRE TX Y RX
    YL			RES	    1	; CONEXION ENTRE TX Y RX
    DISPLAY_HX		RES	    1	; VARIABLE PARA COLCAR MI DECENA DE LA COORDENADA EN X
    DISPLAY_LX		RES	    1	; VARIABLE PARA COLCAR MI UNIDAD DE LA COORDENADA EN X
    DISPLAY_HY		RES	    1	; VARIABLE PARA COLCAR MI DECENA DE LA COORDENADA EN Y
    DISPLAY_LY		RES	    1	; VARIABLE PARA COLCAR MI UNIDAD DE LA COORDENADA EN Y
    RXB0		RES	    1	; 
    RXB1		RES	    1	; 
    RXB2		RES	    1	; 
    RXB3		RES	    1	; 
    RXB4		RES	    1	; 
    RXB5		RES	    1	; 
    CUENTARX		RES	    1	; 
    CONT1		RES	    1	; 
		

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
    BTFSC   INTCON, T0IF
    CALL    BANDERA_TIMER0   
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
    CALL    DISPLAY	    ; EN ESTE TIMER SE MUXEAN LOS DISPLAYS 
    BCF	    INTCON, T0IF      
RETURN 
     
BANDERA_RX:    
    INCF    CUENTARX,1		    
    MOVFW   RXB4		    
    MOVWF   RXB5
    
    MOVFW   RXB3		    
    MOVWF   RXB4
    
    MOVFW   RXB2		    
    MOVWF   RXB3	
    
    MOVFW   RXB1		    
    MOVWF   RXB2
    
    MOVFW   RXB0		    
    MOVWF   RXB1
        
    MOVFW   RCREG		    
    MOVWF   RXB0		       
    
    XORLW   .10			    
    BTFSC   STATUS,Z		    
    GOTO    VERIFICACION
    RETURN
    
    VERIFICACION:  
	MOVLW   .6			    
	SUBWF   CUENTARX,W
	BTFSS   STATUS,Z
	GOTO    ERRONEO

	MOVLW	.44		
	SUBWF	RXB3,W
	BTFSS	STATUS,Z
	GOTO	ERRONEO


	MOVLW   .48		    
	SUBWF   RXB1,W
	MOVWF   DISPLAY_HX

	MOVLW   .48		   
	SUBWF   RXB2,W
	MOVWF   DISPLAY_LX

	MOVLW   .48		   
	SUBWF   RXB4,W
	MOVWF   DISPLAY_HY

	MOVLW   .48		
	SUBWF   RXB5,W
	MOVWF   DISPLAY_LY    
	CLRF	CUENTARX
	RETURN

    ERRONEO:
	CLRF    CUENTARX		;Clear al conteo para recibir nuevo mensaje
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
; TABLA DE CONVERSIONES
;*******************************************************************************
; SE USARA ESTA TABLA PARA REALIZAR LAS CONVERSIONES A ASCII 
; Y ENVIAR LOS DATOS EN EL FORMATO DESEADO   
CONVERSIONES:       
    ANDLW   b'00001111'	
    ADDWF   PCL, F
    RETLW   .48		;0 
    RETLW   .49		;1 
    RETLW   .50		;2 
    RETLW   .51		;3 
    RETLW   .52		;4 
    RETLW   .53		;5 
    RETLW   .54		;6 
    RETLW   .55		;7 
    RETLW   .56		;8
    RETLW   .57		;9 
    RETLW   .65		;A   
    RETLW   .66		;B   
    RETLW   .67		;C  
    RETLW   .68		;D   
    RETLW   .69		;E  
    RETLW   .70		;F 
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG   CODE     0x0100                 ; let linker place main program

START
SETUP:
    CALL    CONFIGURACION_BASE		    ; EXPLICACIONES EN LA SECCIÓN DE CONFIGURACIONES
    CALL    CONFIGURACION_TIMER0
    CALL    CONFIGURACION_INTERRUPCION
    CALL    CONFIGURACION_ADC
    CALL    CONFIGURACION_TX_9600
    CALL    CONFIGURACION_RX
    CALL    LIMPIA_VARIABLES
    
;*******************************************************************************
; MAIN LOOP
;*******************************************************************************    

LOOP:
    CALL    CONVERSION_ADC
    CALL    NIB_SEPX
    CALL    NIB_SEPY
    CALL    RUTINA_TX
    GOTO    LOOP			
    
;*******************************************************************************
; RUTINA DE DISPLAY
;*******************************************************************************        
DISPLAY: ; MUXEO DE LOS DISPLAYS
    BCF	    PORTA, 1			; EN ESTOS BITS DEL PUERTO A ESTÁN LOS TRANSISTORES
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
; RUTINA DE CONVERSION ADC
;*******************************************************************************        
 
CONVERSION_ADC:
    BANKSEL ADCON0
    MOVLW   b'10000011'			
    MOVWF   ADCON0  
    CALL    DELAY
   
    BSF	    ADCON0,GO
    BTFSC   ADCON0,GO 
    GOTO    $-1
    
    BANKSEL ADRESH
    MOVFW   ADRESH
    MOVWF   Y			
    
    BANKSEL ADCON0
    MOVLW   b'10010011'			
    MOVWF   ADCON0
    CALL    DELAY
    BSF	    ADCON0,GO
    BTFSC   ADCON0,GO 
    GOTO    $-1
    
    BANKSEL ADRESH
    MOVFW   ADRESH
    MOVWF   X			
    RETURN	
	
;*******************************************************************************
; RUTINA DE SEPARACIÓN DE NIBBLES
;*******************************************************************************        
    
NIB_SEPX:
    MOVFW   X	; COLOCO MI VARIABLE CONECTORA DE COMUNICACION SERIAL EN MIS NIBBLES HIGH Y LOW PARA COLOCARLOS EN EL DISPLAY
    MOVWF   XL
    SWAPF   X, W
    MOVWF   XH
RETURN   
NIB_SEPY:
    MOVFW   Y		; COLOCO MI VARIABLE CONECTORA DE COMUNICACION SERIAL EN MIS NIBBLES HIGH Y LOW PARA COLOCARLOS EN EL DISPLAY
    MOVWF   YL
    SWAPF   Y, W
    MOVWF   YH
RETURN

;*******************************************************************************
; RUTINA ENVIO
;*******************************************************************************        
     
RUTINA_TX:    
    MOVFW  XH			
    CALL   CONVERSIONES		
    MOVWF  TXREG
    CALL   DELAY_BIG
    
    MOVFW  XL			
    CALL   CONVERSIONES		
    MOVWF  TXREG
    CALL   DELAY_BIG
    
    MOVLW  .44			
    MOVWF  TXREG
    CALL   DELAY_BIG
    
    MOVFW  YH			
    CALL   CONVERSIONES		
    MOVWF  TXREG
    CALL   DELAY_BIG
    
    MOVFW  YL			
    CALL   CONVERSIONES		
    MOVWF  TXREG
    CALL   DELAY_BIG
    
    MOVLW  .10			 
    MOVWF  TXREG
    CALL   DELAY_BIG
    RETURN  
    
;*******************************************************************************
; RUTINA DE DELAYS
;*******************************************************************************            
    
DELAY:
    MOVLW   .23			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
RETURN    
  
DELAY_BIG:
    MOVLW   .255			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
    MOVLW   .255			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
    MOVLW   .255			  
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
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
    CLRF    ANSELH		; BORRA EL CONTROL DE ENTRADAS ANALÓGICAS DEL PUERTO B	

    BANKSEL TRISA
    MOVLW   b'00100001'		; POT Y TRANSISTORES
    MOVWF   TRISA
		
    CLRF    TRISB		; SIN USAR	
    CLRF    TRISC		; PARA RX Y TX
    CLRF    TRISD		; PARA DISPLAY
    
    CLRF    TRISE
    BANKSEL PORTA
RETURN
    
CONFIGURACION_TIMER0:
    BANKSEL TRISA
    CLRWDT			; CONFIGURACIÓN PARA EL FUNCIONAMIENTO DEL TIMER0
    MOVLW   b'11010111'	
    MOVWF   OPTION_REG 
    BANKSEL PORTA
RETURN
   
CONFIGURACION_INTERRUPCION:
    BANKSEL TRISA
    BSF	    PIE1, RCIE		; HABILITA INTERRUPCION DE RECEPCION SERIAL CON RX
    BSF	    INTCON, PEIE	; INTERRUPCIONES PERIFÉRICAS -TIMER 2 Y ADC-
    BSF	    INTCON, T0IE	; HABILITA INTERRUPCION DEL TIMER0
    
    BANKSEL PORTA
    BSF	    INTCON, GIE		; HABILITA LAS INTERRUPCIONES
    BCF	    INTCON, T0IF	; PARA ASEGURARSE DE QUE NO TENGA OVERFLOW AL INICIO
RETURN

CONFIGURACION_ADC:    
    BANKSEL ADCON1 
    CLRF    ADCON1		; VDD Y VSS COMO REFERENCIA / JUSTIFICADO A LA IZQUIERDA
    
    BANKSEL ADCON0		; CONFIGURACIÓN PARA USAR EL FOSC/32 Y LOS CANALES ANALÓGICOS 0 Y 4
    BSF	    ADCON0, 0		; HABILITA
    BSF	    ADCON0, 1		; DA EL PRIMER GO
    BCF	    ADCON0, 2		; AL NO CONFIGURAR EL BIT 4, SE DA LA POSIBILIDAD A USAR EL CANAL 0 O EL 4
    BCF	    ADCON0, 3
    BCF	    ADCON0, 5
    BCF	    ADCON0, 6
    BSF	    ADCON0, 7   
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

LIMPIA_VARIABLES:
    BANKSEL PORTA
    CLRF    CUENTARX
    CLRF    ADRESH
    CLRF    X
    CLRF    Y
    CLRF    CONT1
RETURN
;*******************************************************************************
 
    END