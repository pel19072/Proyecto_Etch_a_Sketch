'''
Ricardo Pellecer Orellana --> Carne 19072
Proyecto Etch a Sketch
26/Octubre/2020
'''

from Interfaz_Final import *
from PyQt5 import QtWidgets
from PyQt5.QtGui import QPainter, QPen, QPixmap, QColor
import threading
import serial
import time
import sys
import TXRX as tx

x = 0 #Coordenada en X
y = 0 #Coordenada en Y

#Esta clase crea la ventana de la interfaz con sus caracteristicas
class SKETCH (QtWidgets.QMainWindow, Ui_MainWindow):
    #Es el constructor - Da las caracteristicas a las ventanas y botones
    def __init__ (self):
        super().__init__()
        self.setupUi(self)
        self.mapa = QPixmap(900, 900) #Le da un tamaño a mi canvas para dibujar
        self.mapa.fill(QColor('#ffffff')) #Pone el canvas en color blanco
        self.label.setPixmap(self.mapa)
        self.painter = QPainter(self.label.pixmap())
        pen = QPen() #Crea el lapiz para dibujar
        pen.setWidth(3)
        pen.setColor(QColor('#a6c2f9')) #Hace que dibuje en un color distinto a negro
        self.painter.setRenderHint(QPainter.Antialiasing)
        self.painter.setPen(pen)
        coorde = threading.Thread(daemon=True,target=lectura_y_escritura) #Trabajar con threads permite abrir la ventana y actualizarla paralelo a la lectura de datos seriales
        coorde.start() #Inicia la lectura de datos
        self.pushButton.clicked.connect(self.presionado) #Crea el boton para limpiar la pantalla y le asigna su funcion de borrar todo

    def presionado(self):
        self.painter.eraseRect(0,0,1000,1000) #Esta instruccion borra todo lo creado en el canvas

    def paint (self,dx,dy): #En los parametros utiliza los diferenciales creados en una funcion posterior
        global x,y #Menciona que se usaran las variables x, y declaradas al inicio
        try:
            self.painter.drawLine(x, y, x+dx, y+dy) #Dibuja una linea entre los puntos anteriores y sus diferenciales
            self.update() #Actualiza el canvas -Esto es posible gracias al uso de los threads para trabajar en paralelo-
            #Estas dos lineas actualizan los puntos anteriores a los actuales
            x += dx
            y += dy

            #Estas instrucciones permiten que el dibujo funcione como el movimiento de un pacman
            #Es decir, evita que se salga del canvas y reinicie cuando llegue a un borde
            if x >= 900:
                x = 0
            elif x<0:
                x = 900
            if y >= 900:
                y = 0
            elif y<0:
                y = 900
        except:
            pass
def lectura_y_escritura():
    global ventanamain #Esta variable es la que llama al dibujo del canvas para poder mappear los nuevos diferenciales en los puntos actuales
    #Inicializo mi puerto para comenzar la lectura y escritura serial
    ser = serial.Serial(port='COM4',baudrate=9600, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS, timeout=0)
    #Se crea un loop infinito -este tampoco da error, nuevamente gracias al uso de los threads-
    while (1) :
        try :
            coor1 = tx.escritura(ser).split(',') #Toma mis valores de mi funcion de escritura del PIC en la PC de mi documento TXRX y separa por comas las coordenadas
            potx = int(coor1[0]) #Guarda el dato leido por el eje X del potenciometro
            poty = int(coor1[1]) #Guarda el dato leido por el eje Y del potenciometro
            #Estas lineas inicializan los diferenciales
            dx = 0
            dy = 0
            '''
            El primer if indica que cuando el joystick se mueve a la derecha o hacia arriba el desplazamiento sea positivo
            El segundo if indica que cuando el joystick se mueve a la izquierda o hacia abajo el desplazamiento sea negativo
            Estas lineas indican que mientras el joystick este en el centro no haya desplazamiento
            '''
            if potx >=50:
                dx = potx-50
            elif potx <=30:
                dx = -1*(30-potx)
            else:
                dx = 0

            if poty >=50:
                dy = poty-50
            elif poty <=30:
                dy = -1*(30-poty)
            else:
                dy = 0
            #Esta linea manda mappeado los datos al PIC
            tx.lectura(ser, str(99*x//900), str(99*y//900))
            #Esta linea indica que el siguiente punto a dibujar debe basarse en los nuevos diferenciales
            ventanamain.paint(dx,dy)
            #Esta linea es solamente de monitoreo para ver que todo se este mandando bien
            print ("(",99*x//900,",",99*y//900,")")
        except:
            pass

#Estas lineas ejecutan la aplicacion
aplication = QtWidgets.QApplication([])
ventanamain=SKETCH()
ventanamain.show()
aplication.exec_()
