from Interfaz_Final import *
from PyQt5 import QtWidgets
from PyQt5.QtGui import QPainter, QPen, QPixmap, QColor
import threading
import serial
import time
import sys
import math
import TXRX as tx
x=0
y=0
class SKETCH (QtWidgets.QMainWindow, Ui_MainWindow):
    def __init__ (self):
        super().__init__()
        self.setupUi(self)
        self.mapa = QPixmap(900, 900)
        self.mapa.fill(QColor('#f9b5a6'))
        self.label.setPixmap(self.mapa)
        self.painter = QPainter(self.label.pixmap())
        pen = QPen()
        pen.setWidth(3)
        pen.setColor(QColor('#a6c2f9'))
        self.painter.setRenderHint(QPainter.Antialiasing)
        self.painter.setPen(pen)
        coorde = threading.Thread(daemon=True,target=hilo_cordenadas)
        coorde.start()
        self.pushButton.clicked.connect(self.presionado)

    def presionado(self):
        self.painter.eraseRect(0,0,1000,1000)

    def paint (self,dx,dy):
        global x,y
        try:
            self.painter.drawLine(x, y, x+dx, y+dy)
            self.update()
            x += dx
            if x >= 900:
                x = 0
            elif x<0:
                x = 900
            y += dy
            if y >= 900:
                y = 0
            elif y<0:
                y = 900
        except:
            pass
def hilo_cordenadas():
    global ventanamain
    ser = serial.Serial(port='COM4',baudrate=9600, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS, timeout=0)
    while (1) :
        try :
            coor1 = tx.escritura(ser)
            cor_x = int(coor1[0])
            cor_y = int(coor1[2])
            dx = 0
            dy = 0

            if cor_x >=50:
                dx = cor_x-50
            elif cor_x <=30:
                dx = -1*(30-cor_x)
            else:
                dx = 0

            if cor_y >=50:
                dy = cor_y-50
            elif cor_y <=30:
                dy = -1*(30-cor_y)
            else:
                dy = 0

            tx.lectura(ser, str(99*x//900), str(99*y//900))
            ventanamain.paint(dx,dy)
            print ("(",99*x//900,",",99*y//900,")")
            print(dx,dy)
        except:
            pass

aplication = QtWidgets.QApplication([])
ventanamain=SKETCH()
ventanamain.show()
aplication.exec_()
