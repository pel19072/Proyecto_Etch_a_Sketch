
import serial
import time
import sys
import math

#COMUNICACION SERIAL DE PIC CON LA CUMPU

# escritura
def escritura(puerto):
    final = []
    n = ''
    #borrar el buffer para iniciar en cero
    puerto.flushInput()
    puerto.flushOutput()
    try:
        while n != 10:
            n = ord(puerto.read())
        for i in range(4):
            #leer dato serial
            recibido = puerto.read()
            final.append(recibido)
        final[0] = str(math.floor(5*(int(ord(final[0])))/13))
        final[2] = str(math.floor(5*(int(ord(final[2])))/13))
        return final
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
