__VERSION__ = "0.0.1.0"
import ctypes
import sys
from typing import Any, Dict, Optional, Tuple, Union

if sys.platform.startswith("win"):
   leerImagenesLib_Name ="LeerImagenes.dll"
elif sys.platform.startswith("linux"):
   leerImagenesLib_Name = "LeerImagenesLib.o"
   
try:
   leerImagenesLib = ctypes.cdll.LoadLibrary(leerImagenesLib_Name)
except:
   try:
      leerImagenesLib = ctypes.cdll.LoadLibrary('./'+leerImagenesLib_Name)
   except:
      try:
         leerImagenesLib = ctypes.cdll.LoadLibrary("./bin/"+leerImagenesLib_Name)
      except:
         try:
            leerImagenesLib = ctypes.cdll.LoadLibrary("./lib/"+leerImagenesLib_Name)
         except:
            print( "No se encuentra la libreria \"" + leerImagenesLib_Name +"\"" );
            exit();

DWORD = ctypes.c_uint;
BYTE = ctypes.c_ubyte

IMGMODE_PNG  = 0
IMGMODE_JPEG = 1
IMGMODE_BMP  = 2

ENCODING = "ansi"

class TPixel(ctypes.Structure):
   _fields_ = [
      ("_red", BYTE),
      ("_green", BYTE),
      ("_blue", BYTE),
      ("_alpha", BYTE),
   ]
   @property
   def red(self)->int: return int(self._red)
   @red.setter
   def red(self, newValue:int):
      if newValue < 0: newValue = 0
      if newValue > 255: newValue = 255
      self._red = newValue
   
   @property
   def green(self)->int: return int(self._green)
   @green.setter
   def green(self, newValue:int):
      if newValue < 0: newValue = 0
      if newValue > 255: newValue = 255
      self._green = newValue
   
   @property
   def blue(self)->int: return int(self._blue)
   @blue.setter
   def blue(self, newValue:int):
      if newValue < 0: newValue = 0
      if newValue > 255: newValue = 255
      self._blue = newValue
   
   @property
   def alpha(self)->int: return int(self._alpha)
   @alpha.setter
   def alpha(self, newValue:int):
      if newValue < 0: newValue = 0
      if newValue > 255: newValue = 255
      self._alpha = newValue

   @property
   def crud(self)->tuple: return ( self.red, self.green, self.blue, self.alpha )

PTPixel = ctypes.POINTER(TPixel)

class PCHAR(ctypes.c_char_p):
   def stream(self, len:int)->bytes:
      return ctypes.string_at( self, len )
      
class TImage(ctypes.Structure):
   _fields_ = [
      ("_width", DWORD),
      ("_height", DWORD),
      ("_data", PTPixel),
   ]
   @property
   def width(self)->int: return self._width
   @width.setter
   def width(self, newWidth): return
   
   @property
   def height(self)->int: return self._height
   @height.setter
   def height(self, newheight): return

   @property
   def data(self)->PTPixel: return self._data

   def getPixel(self, x:int,y:int)->TPixel:
      i = y * self.width + x
      return self.data[i]

   def setPixel(self, x:int, y:int, pixel:TPixel):
      px = pixel
      if isinstance(pixel, tuple):
         px = _listToPixel(pixel)
      if isinstance(pixel, list):
         px = _listToPixel(pixel)
      i = y * self.width + x
      self.data[i] = px

   def stream(self, len=None):
      if len == None: len = self.width * self.height * 4
      return ctypes.string_at( self.data, len )
   
PTImage = ctypes.POINTER(TImage)

def _listToPixel(l)->TPixel:
   px = TPixel()
   if len(l) == 3:
      px.red   = l[0]
      px.green = l[1]
      px.blue  = l[2]
      px.alpha = 255
   elif len(l) == 4:
      px.red   = l[0]
      px.green = l[1]
      px.blue  = l[2]
      px.alpha = l[3]
   else:
      px.red   = l[0]
      px.green = l[0]
      px.blue  = l[0]
      px.alpha = l[0]
   return px

def init()->bool:
   return bool(leerImagenesLib.init())

def done()->bool:
   return bool(leerImagenesLib.done())

def loadImage(data:bytes)->TImage:
   if isinstance(data, str): data = bytes(data, ENCODING)
   func = leerImagenesLib.loadImage
   func.restype = TImage
   return func(PCHAR(data), DWORD(len(data)))

def loadImageFromFile(fname:bytes)->TImage:
   if isinstance(fname, str): fname = bytes(fname, ENCODING)
   func = leerImagenesLib.loadImageFromFile
   func.restype = TImage
   return func(PCHAR(fname), DWORD(len(fname)))

def saveImage(data:TImage, mode:int, output:PCHAR)->DWORD:
   func = leerImagenesLib.saveImage
   func.restype = DWORD
   return func(data, BYTE(mode),  ctypes.byref(output))

def saveImageToFile(data:TImage, mode:int, fname:bytes)->DWORD:
   if isinstance(fname, str): fname = bytes(fname, ENCODING)
   func = leerImagenesLib.saveImageToFile
   func.restype = DWORD
   return func(data, BYTE(mode), PCHAR(fname), DWORD(len(fname)))

def scaleImage(imagen:TImage, width:int, height:int)->bool:
   func = leerImagenesLib.scaleImage
   func.restype = ctypes.c_bool
   return bool( func( ctypes.byref(imagen), DWORD(width), DWORD(height) ) )

def getPixel(imagen:TImage, x:int, y:int)->TPixel:
   func = leerImagenesLib.getPixel
   func.restype = TPixel
   return func( imagen, DWORD(x), DWORD(y) )

def setPixel(imagen:TImage, x:int, y:int, pixel:TPixel):
   px = pixel
   if isinstance(pixel, tuple):
      px = _listToPixel(pixel)
   if isinstance(pixel, list):
      px = _listToPixel(pixel)
   func = leerImagenesLib.setPixel
   func( ctypes.byref(imagen), DWORD(x), DWORD(y), px )

def drawImage(dest:TImage, x:int, y:int, width:int, height:int, image:TImage):
   if width == None: width = image.width
   if height == None: height = image.height
   func = leerImagenesLib.drawImage
   func( ctypes.byref(dest), DWORD(x), DWORD(y), DWORD(width), DWORD(height), image )

def drawLine(dest:TImage, x1:int, y1:int, x2:int, y2:int, pixel:TPixel, size:int=1):
   px = pixel
   if isinstance(pixel, tuple):
      px = _listToPixel(pixel)
   if isinstance(pixel, list):
      px = _listToPixel(pixel)
   func = leerImagenesLib.drawLine
   func( ctypes.byref(dest), DWORD(x1), DWORD(y1), DWORD(x2), DWORD(y2), px , DWORD(size))

def drawRectangle(dest:TImage, x1:int, y1:int, x2:int, y2:int, pixel:TPixel, size:int=1, solid:bool=True):
   px = pixel
   if isinstance(pixel, tuple):
      px = _listToPixel(pixel)
   if isinstance(pixel, list):
      px = _listToPixel(pixel)
   func = leerImagenesLib.drawRectangle
   func( ctypes.byref(dest), DWORD(x1), DWORD(y1), DWORD(x2), DWORD(y2), px , DWORD(size), ctypes.c_bool(solid))

def createImage(width:int, height:int)->TImage:
   func = leerImagenesLib.createImage
   func.restype = TImage
   return func( DWORD(width), DWORD(height) )

try:
   import tkinter
   class Imagen(tkinter.PhotoImage):
      def __init__(self, name: Optional[str]=None, cnf: Dict[str, Any]={}, master: tkinter.Misc=None, *, data: Union[str, bytes]=None, format: str=None, file: str=None, gamma: float=None, height: int=None, palette: Union[int, str]=None, width: int=None) -> None:
         qwArguments = {}
         if name    != None: qwArguments["name"]    = name
         if cnf     != None: qwArguments["cnf"]     = cnf
         if master  != None: qwArguments["master"]  = master
         if format  != None: qwArguments["format"]  = format
         if gamma   != None: qwArguments["gamma"]   = gamma
         if height  != None: qwArguments["height"]  = height
         if palette != None: qwArguments["palette"] = palette
         if width   != None: qwArguments["width"]   = width
         ##** LEER TODOS LOS PIXELES PARA CREAR UN CANVAS INTERNO CON LA LIBRERIA "LeerImagenes"
         # CREAR UN CANVAS
         self._dataImage = None

         if file != None:
            self._dataImage = loadImageFromFile(file)
         elif data != None:
            self._dataImage = loadImage(data)
         else:
            self._dataImage = createImage(width, height)

         if width  == None: width = self._dataImage.width
         if height == None: height = self._dataImage.height

         out = PCHAR()
         len = saveImage(self._dataImage, 0, out)
         self._originalImageData = out.stream(len)
         del out

         if (self._dataImage.width != width) or (self._dataImage.height != height):
            scaleImage(self._dataImage, width, height)

         out = PCHAR()
         len = saveImage(self._dataImage, 0, out)
         qwArguments["data"] = out.stream(len)
         del out

         super(Imagen, self).__init__(**qwArguments)
     
      def _update(self):
         out = PCHAR()
         len = saveImage(self._dataImage, 0, out)
         self.configure( data=out.stream(len) )
         del out

      def reset(self):
         del self._dataImage
         self._dataImage = loadImage(self._originalImageData)
         self._update()

      def scale(self, w,h):
         scaleImage(self._dataImage, w,h)
         self._update()

      def get(self, x: int, y: int) -> Tuple[int, int, int, int]:
         return self._dataImage.getPixel(x,y).crud

      def put(self, data: Union[str, tuple], to: Optional[Tuple[int, int]]) -> None:
         if isinstance(data, str):
            d = data.split("#")[1]
            if len(d) == 3:
               r = d[0].upper() * 2
               g = d[1].upper() * 2
               b = d[2].upper() * 2
               a = "FF"
            elif len(d) == 4:
               r = d[0].upper() * 2
               g = d[1].upper() * 2
               b = d[2].upper() * 2
               a = d[3].upper() * 2
            elif len(d) == 6:
               r = d[0:2].upper()
               g = d[2:4].upper()
               b = d[4:6].upper()
               a = "FF"
            elif len(d) == 8:
               r = d[0:2].upper()
               g = d[2:4].upper()
               b = d[4:6].upper()
               a = d[6:8].upper()
            else:
               r=g=b=a = "00"
            r = int(r, base=16)
            g = int(g, base=16)
            b = int(b, base=16)
            a = int(a, base=16)
         else:
            r,g,b,a = data

         self._dataImage.setPixel( to[0], to[1], (r,g,b,a) )
         self._update()

      def change(self, newImage, modo=0, width:int=None, height:int=None):
         del self._dataImage
         if modo == 1:
            self._dataImage = loadImage(newImage)
         else:
            self._dataImage = loadImageFromFile(newImage)
         if width  == None: width  = self._dataImage.width
         if height == None: height = self._dataImage.height
         
         scaleImage(self._dataImage, width, height)
         self._update()


except:
   print("> Alert < : The module tkinter don't installed and the class \"Imagen\" don't created")
   pass

def main():
   init()

   imagen = createImage(128,128)
   
   drawRectangle(imagen, 0,0,128,128, (200, 50, 50), 1, True)
   drawRectangle(imagen, 32,32,64,64, (200, 200, 50), 1, True)
   drawRectangle(imagen, 64,64,96,96, (50, 200, 200), 1, False)
   drawLine(imagen, 32,32, 96,96, (255,255,255), 1)
   saveImageToFile(imagen, 0, "salida.png")

   done()
   return

if __name__ == "__main__":
   main();