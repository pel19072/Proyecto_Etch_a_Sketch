'''
Ricardo Pellecer Orellana --> Carne 19072
Proyecto Etch a Sketch
26/Octubre/2020
'''
import serial
import time
import sys
import math

#COMUNICACION SERIAL DE PIC CON LA CUMPU

# escritura
def escritura(puerto):
    final = []
    final1 = ''
    n = ''
    #borrar el buffer para iniciar en cero
    puerto.flushInput()
    puerto.flushOutput()
    try:
        #puerto.flushInput()
        while n != 10:
            n = ord(puerto.read())
        for i in range(4):
            #esperar un tiempo para recibir datos
            #puerto.flushInput()
            #time.sleep(.1)
            #puerto.read()
            #leer dato serial
            recibido = puerto.read()
            final.append(recibido)
        numero1 = str(math.floor(5*(int(ord(final[0])))/13))
        numero2 = str(math.floor(5*(int(ord(final[2])))/13))
        final1 = numero1 + ',' + numero2
        return final1
    except:
        pass
    # RECUERDEN CONECTAR EL RX del pic AL TX de la compu

def lectura(puerto, x, y):
    puerto.flushOutput()
    try:
        puerto.write(bytes.fromhex(x))
    except:
        x = '0' + x
        puerto.write(bytes.fromhex(x))
    try:
        puerto.write(bytes.fromhex(y))
    except:
        y = '0' + y
        puerto.write(bytes.fromhex(y))
    return


# Configurar el puerto serial. Elejir el puerto en el que aparece en su computadora y la velocidad
#ser= serial.Serial(port='COM4',baudrate=9600, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS, timeout=0)

#x = chr(int(escritura(ser).split(',')[0]))
#y = chr(int(escritura(ser).split(',')[1]))

#lectura(ser, x, y)

#print(x, chr(x))
#print(y, chr(y))
