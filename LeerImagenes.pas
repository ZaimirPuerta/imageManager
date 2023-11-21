{$MODE OBJFPC}
{$MACRO ON}{$H+}
{$COperators ON}
{%RunFlags MESSAGES+}
library LeerImagenes;

{$modeswitch ADVANCEDRECORDS}
{$modeswitch class}
{$calling cdecl}

uses sysutils, classes, math,
   FPimage, FPCanvas, FPImgCanv,
   FPReadPNG, FPReadJPEG, FPReadBMP,
   FPWritePNG, FPWriteJPEG, FPWriteBMP
;
{$DEFINE RETURN := RESULT :=}


type TPixel = packed record
      public
         case Longint of
            0: (red, green, blue, alpha: byte);
   end;
   PTPixel = ^TPixel;

   TImage = packed record
      public
         //size   : DWORD;
         width  : DWORD;
         height : DWORD;
         data   : PTPixel;
   end;
   PTImage = ^TImage;

// LECTORES Y GUARDADORES DE IMAGENES
var
  READER_PNG  : TFPReaderPNG;
  READER_JPEG : TFPReaderJPEG;
  READER_BMP  : TFPReaderBMP;
  WRITER_PNG  : TFPWriterPNG;
  WRITER_JPEG : TFPWriterJPEG;
  WRITER_BMP  : TFPWriterBMP;


function init(): boolean;
begin
   try
      READER_PNG  := TFPReaderPNG.create();
      READER_JPEG := TFPReaderJPEG.create();
      READER_BMP  := TFPReaderBMP.create();
      WRITER_PNG  := TFPWriterPNG.create();
      WRITER_JPEG := TFPWriterJPEG.create();
      WRITER_BMP  := TFPWriterBMP.create();

      WRITER_PNG.UseAlpha:= True;

      RETURN True;
   except
      RETURN False;
   end;
end;

function done(): boolean;
begin
   try
      READER_PNG.destroy();
      READER_JPEG.destroy();
      READER_BMP.destroy();
      WRITER_PNG.destroy();
      WRITER_JPEG.destroy();
      WRITER_BMP.destroy();
      RETURN True;
   except
      RETURN False;
   end;
end;

function optenerElReader(data:PCHAR): TFPCustomImageReader;
var header:String;
begin
   header := data[0] + data[1] + data[2] + data[3];

   if header[1..3] = 'BM6' then begin
      RETURN READER_BMP;
   end else
   if header[2..4] = 'PNG' then begin
      RETURN READER_PNG;
   end else BEGIN
      RETURN READER_JPEG;
   end;
end;

function TImageToTFPCustomImage(image : TImage): TFPCustomImage;
var x,y,i : DWORD;
    color : TFPColor;
    pixel : TPixel;
begin
   result := TFPMemoryImage.create(image.width, image.height);
   for y := 0 to image.height-1 do begin
      for x := 0 to image.width-1 do begin
          i := y * image.width + x;
          pixel := image.data[i];
          color.red   := pixel.red   << 8;
          color.green := pixel.green << 8;
          color.blue  := pixel.blue  << 8;
          color.alpha := pixel.alpha << 8;
          result.Colors[x,y] := color;
      end;
   end;
end;

function TFPCustomImageToTImage(image : TFPCustomImage): TImage;
var x,y,i : DWORD;
    color : TFPColor;
    pixel : TPixel;
begin
   result.width  := image.Width;
   result.height := image.height;
   result.data   := AllocMem(image.width * image.height * 4);
   for y := 0 to image.height-1 do begin
      for x := 0 to image.width-1 do begin
          i := y * image.width + x;
          color := image.Colors[x,y];
          pixel.red   := color.red   >> 8;
          pixel.green := color.green >> 8;
          pixel.blue  := color.blue  >> 8;
          pixel.alpha := color.alpha >> 8;
          result.data[i] := pixel;
      end;
   end;
end;

function loadImage(data:PCHAR; size:DWORD): TImage;
var image : TFPCustomImage;
    reader : TFPCustomImageReader;
    stream : TStream;
begin
   stream := TMemoryStream.create();
   //stream := TStringStream.Create('');
   stream.WriteBuffer(data[0], size);
   stream.Seek(0, 0);

   reader := optenerElReader(data);
   image := TFPMemoryImage.create(1,1);
   image.LoadFromStream(stream, reader);

   result := TFPCustomImageToTImage(image);

   image.destroy();
   stream.Destroy();
end;

function readFileToBytes(fname:String; var f : PCHAR): DWORD;
var _file : file;
    size:DWORD;
begin
   if not FileExists(fname) then exit(0);
   assign(_file, fname);
   reset(_file, 1);
   size := FileSize(_file);
   f := AllocMem(size);
   BlockRead(_file, f[0], size, result);
   close(_file);
end;

function writeBytesToFile(fname:String; data : PCHAR; pos:DWORD; len:DWORD): DWORD;
var _file : file;
begin
   assign(_file, fname);
   rewrite(_file, 1);
   BlockWrite(_file, data[pos], len, result);
   close(_file);
end;

function loadImageFromFile(fname:PCHAR; size:DWORD): TImage;
var i : DWORD;
    s : String;
    f : PCHAR;
begin
   s := '';
   for i := 0 to size-1 do s += fname[i];
   i := readFileToBytes(s, f);
   RETURN loadImage(f, i);
end;

function saveImage(data : TImage; mode:byte; var output:PCHAR): DWORD;
var image : TFPCustomImage;
    writer : TFPCustomImageWriter;
    stream : TStream;
    buff : array of char;
    i : DWORD;
begin
   image := TImageToTFPCustomImage(data);

   if mode = 0 then
      writer := WRITER_PNG
   else if mode = 1 then
      writer := WRITER_JPEG
   else if mode = 2 then
      writer := WRITER_BMP
   else
     writer := WRITER_PNG
   ;

   stream := TStringStream.Create('');
   image.SaveToStream(stream, writer);

   stream.Seek(0,0);

   setLength(buff, stream.size);

   stream.Read(buff[0], stream.size);

   output := AllocMem(stream.Size);
   for i := 0 to stream.size-1 do begin
      output[i] := buff[i];
   end;
   result := stream.size;
   setLength(buff, 0);

   stream.destroy();
   image.destroy();
end;

function saveImageToFile(data : TImage; mode:byte; fname:PCHAR; size:DWORD): DWORD;
var output : PCHAR;
    len : DWORD;
    i : DWORD;
    s : String;
begin
   s := '';
   for i := 0 to size-1 do s += fname[i];
   len := saveImage(data, mode, output);
   RETURN writeBytesToFile(s, output, 0, len);
end;

function scaleImage(imagen:PTImage; width,height: DWORD): boolean;
var FImage : TFPCustomImage;
    scaledImage : TFPCustomImage;
    canvas : TFPCustomCanvas;
    xx,yy : DWORD;
    //color1, color2 : TFPColor;
begin
   try
      FImage := TImageToTFPCustomImage(imagen^);
      scaledImage := TFPMemoryImage.create(width,height);

      canvas := TFPImageCanvas.Create(scaledImage);
      with Canvas as TFPImageCanvas do begin
        StretchDraw(0,0,width,height, FImage);
      end;

      // ESTO HACE QUE SE PUEDAN MANTENER LOS COLORES ALPHA
      for yy := 0 to height-1 do begin
         for xx := 0 to width-1 do begin
            scaledImage.Colors[xx, yy] := scaledImage.Colors[xx,yy];
         end;
      end;

      imagen^ := TFPCustomImageToTImage(scaledImage);
      canvas.destroy();
      FImage.destroy();
      scaledImage.destroy();
      RETURN True;
   except
      RETURN False;
   end;
end;

function getPixel(imagen:TImage; x,y:DWORD): TPixel;
begin
   return imagen.data[ y * imagen.width + x ];
end;

procedure setPixel(imagen:PTImage; x,y:DWORD; pixel:TPixel);
begin
   imagen^.data[ y * imagen^.width + x ] := pixel;
end;

procedure drawImage(dest:PTImage; x,y,_width,_height:DWORD; image:TImage);
var img1, img2 : TFPCustomImage;
    xx, yy : DWORD;
    color1, color2 : TFPColor;
begin
   img1 := TImageToTFPCustomImage(dest^);
   img2 := TImageToTFPCustomImage(image);

   scaleImage(@image, _width, _height);
   for yy := 0 to _height-1 do begin
      for xx := 0 to _width-1 do begin
         color1 := img1.Colors[xx+x,yy+y];
         color2 := img2.Colors[xx,yy];
         img1.Colors[xx+x, yy+y] := AlphaBlend(color1, color2);
      end;
   end;

   dest^ := TFPCustomImageToTImage(img1);

   img2.destroy();
   img1.destroy();
end;

function pixelToColor(pixel : TPixel):TFPColor;
begin
   result.red   := pixel.red   << 8;
   result.green := pixel.green << 8;
   result.blue  := pixel.blue  << 8;
   result.alpha := pixel.alpha << 8;
end;

procedure drawLine(dest:PTImage; x1,y1, x2,y2 : DWORD; pixel:TPixel; size:DWORD);
var img1, img2 : TFPCustomImage;
    width,height : DWORD;
    Canvas : TFPCustomCanvas;
    sepx,sepy : DWORD;
    color1,color2 : TFPColor;
    x,y : DWORD;
begin
   {$DEFINE DRAWLINE_MODE := 0}
   img1 := TImageToTFPCustomImage(dest^);
   {$IF DRAWLINE_MODE = 0}
   width  := max(x1,x2) - min(x1,x2)+1;
   height := max(y1,y2) - min(y1,y2)+1;
   sepx := min(x1,x2);
   sepy := min(y1,y2);
   {$ENDIF}

   {$IF DRAWLINE_MODE = 1}
   img2 := TFPMemoryImage.create(img1.width, img1.height);
   canvas := TFPImageCanvas.Create(img2);
   with Canvas as TFPImageCanvas do begin
      //Brush.FPColor := colTransparent;
      pen.FPColor := colWHITE;
      pen.Style:=psSolid;
      Pen.Width:= size;
      pen.EndCap:=pecRound;
      pen.Pattern := %11001100;
      //pen.JoinStyle:=pjsBevel;
      Line(x1, y1, x2, y2);
   end;

   for y := 0 to img1.height-1 do begin
      for x := 0 to img1.width-1 do begin
         color2 := img2.Colors[x,y];
         if not (color2 = colWhite) then continue;
         if pixel.alpha <= 1 then continue;
         color1 := img1.Colors[ x, y ];
         img1.Colors[ x, y ] := AlphaBlend( color1, pixelToColor(pixel) );
      end;
   end;
   {$ENDIF}

   {$IF DRAWLINE_MODE = 0}
   img2 := TFPMemoryImage.create(width, height);
   canvas := TFPImageCanvas.Create(img2);
   with Canvas as TFPImageCanvas do begin
      Brush.FPColor := colTransparent;
      pen.FPColor := colWHITE;
      Pen.Width:= size;
      Line(x1-sepx, y1-sepy, x2-sepx, y2-sepy);
   end;

   for y := 0 to height-1 do begin
      for x := 0 to width-1 do begin
         color2 := img2.Colors[x,y];
         if not (color2 = colWhite) then continue;
         if pixel.alpha <= 1 then continue;
         color1 := img1.Colors[ x+sepx, y+sepy ];
         img1.Colors[ x+sepx, y+sepy ] := AlphaBlend( color1, pixelToColor(pixel) );
      end;
   end;
   {$ENDIF}
   dest^ := TFPCustomImageToTImage(img1);

   img1.destroy();
   Canvas.destroy();
end;

procedure drawRectangle(dest:PTImage; x1,y1, x2,y2 : DWORD; pixel:TPixel; size:DWORD; solid:boolean);
var img1 : TFPCustomImage;
    width,height : DWORD;
    sepx,sepy : DWORD;
    color1 : TFPColor;
    x,y : DWORD;
    _tam : DWORD;
begin
   if not solid then begin
      x := min(x1, x2);
      x2 := max(x1,x2);
      x1 := x;
      x := min(y1, y2);
      y2 := max(y1, y2);
      y1 := x;

      if size <= 1 then _tam := 0
      else _tam := size-1;

      drawLine(dest, x1,y1,x2+_tam,y1-_tam, pixel, size*2+1);

      drawLine(dest, x2,y1,x2+_tam,y2+_tam, pixel, size*2+1);

      drawLine(dest, x2,y2,x1,y2+_tam, pixel, size*2+1);

      drawLine(dest, x1,y2+_tam,x1-_tam,y1-_tam, pixel, size*2+1);

      //drawLine(dest, x2,y1,x2,y2, pixel, size);
      //drawLine(dest, x2,y2,x1,y2, pixel, size);
      //drawLine(dest, x1,y2,x1,y1, pixel, size);
      exit();
   end;


   img1 := TImageToTFPCustomImage(dest^);
   width  := max(x1,x2) - min(x1,x2);
   height := max(y1,y2) - min(y1,y2);

   sepx := min(x1,x2);
   sepy := min(y1,y2);

   for y := 0 to height-1 do begin
      for x := 0 to width-1 do begin
         if pixel.alpha <= 1 then continue;
         color1 := img1.Colors[ x+sepx, y+sepy ];
         img1.Colors[ x+sepx, y+sepy ] := AlphaBlend( color1, pixelToColor(pixel) );
      end;
   end;

   dest^ := TFPCustomImageToTImage(img1);

   img1.destroy();
end;

function createImage(width,height:DWORD): TImage;
begin
   result.width := width;
   result.height:= height;
   result.data  := AllocMem(width*height*4);
end;

EXPORTS
 init
,done
,loadImage
,loadImageFromFile
,saveImage
,saveImageToFile
,scaleImage
,getPixel
,setPixel
,drawImage
,drawLine
,drawRectangle
,createImage
;

begin
end.
