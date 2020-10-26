
import serial
import time
import sys

#COMUNICACION SERIAL DE PIC CON LA CUMPU

# Configurar el puerto serial. Elejir el puerto en el que aparece en su computadora y la velocidad
ser= serial.Serial(port='COM4',baudrate=9600, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS, timeout=0)

# loop infinito
ser.flushInput()
ser.flushOutput()
contador = 0
for j in range(30):
    try:
        n = ''
        while n != 10:
            n = ord(ser.read())
        for i in range(4):
            #borrar el buffer para iniciar en cero
            ser.flushInput()
            #ser.flushOutput()
            #esperar un tiempo para recibir datos
            time.sleep(.3)
            ser.readline()
            #leer dato serial
            recibido1=ser.readline() #readline lee hasta encontrar el enter ASCII "A"h
            #convertir a número de 8 bits e imprimir el dato recibido
            #numero = ord(recibido1)
            print(recibido1)
            # RECUERDEN CONECTAR EL RX del pic AL TX de la compu
    except:
        print('nellll')
    try:
        for i in range(1):
            #escribir dato serial
            ser.flushOutput()
            time.sleep(.3)
            if (contador == 1):
                ser.write(bytes.fromhex('05'))#00001010
                contador = 0
            if (contador == 0):
                ser.write(bytes.fromhex('A2'))#00001010
                contador = 1
            #ser.write(bytes.fromhex('BF'))#00001010
            #print(bytes.fromhex('05'))
    except:
        print('nellll 2')

