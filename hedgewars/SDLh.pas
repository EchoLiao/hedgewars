(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

unit SDLh;
interface

{$IFDEF LINUX}
{$DEFINE UNIX}
{$ENDIF}
{$IFDEF FREEBSD}
{$DEFINE UNIX}
{$ENDIF}

{$IFDEF UNIX}
  {$IFNDEF DARWIN}
    {$linklib c}
  {$ENDIF}
  {$linklib pthread}
{$ENDIF}

{$PACKRECORDS C}

{$IFDEF DARWIN}
	  {$PASCALMAINNAME SDL_main}
{$IFNDEF IPHONEOS}
	  {$linkframework Cocoa}
	  {$linkframework SDL}
	  {$linkframework SDL_net}
	  {$linkframework SDL_image}
	  {$linkframework SDL_ttf}
	  {$linklib SDLmain}
	  {$linklib gcc}
{$ENDIF}
{$ENDIF}

(*  SDL  *)
const {$IFDEF WIN32}
      SDLLibName = 'SDL.dll';
      {$ENDIF}
      {$IFDEF UNIX}
	{$IFDEF DARWIN}
	  SDLLibName = 'SDL';
	{$ELSE}
          SDLLibName = 'libSDL.so';
        {$ENDIF}
      {$ENDIF}
      SDL_SWSURFACE   = $00000000;
      SDL_HWSURFACE   = $00000001;
      SDL_ASYNCBLIT   = $00000004;
      SDL_ANYFORMAT   = $10000000;
      SDL_HWPALETTE   = $20000000;
      SDL_DOUBLEBUF   = $40000000;
      SDL_FULLSCREEN  = $80000000;
      SDL_NOFRAME     = $00000020;
      SDL_HWACCEL     = $00000100;
      SDL_SRCCOLORKEY = $00001000;
      SDL_RLEACCEL    = $00004000;
      SDL_SRCALPHA    = $00010000;

      SDL_NOEVENT     = 0;
      SDL_ACTIVEEVENT = 1;
      SDL_KEYDOWN     = 2;
      SDL_KEYUP       = 3;
      SDL_QUITEV      = 12;
      SDL_VIDEORESIZE = 16;

      SDL_APPINPUTFOCUS = 2;

      SDL_INIT_VIDEO  = $00000020;
      SDL_INIT_AUDIO  = $00000010;

      SDL_GL_DOUBLEBUFFER = 5;
      SDL_OPENGL          = 2;
      SDL_RESIZABLE       = $00000010;

      RMask = $FF;
      GMask = $FF00;
      BMask = $FF0000;
      AMask = $FF000000;

type PSDL_Rect = ^TSDL_Rect;
     TSDL_Rect = record
                 x, y: SmallInt;
                 w, h: Word;
                 end;

     TPoint = record
              X: LongInt;
              Y: LongInt;
              end;

     PSDL_PixelFormat = ^TSDL_PixelFormat;
     TSDL_PixelFormat = record
                        palette: Pointer;
                        BitsPerPixel : Byte;
                        BytesPerPixel: Byte;
                        Rloss : Byte;
                        Gloss : Byte;
                        Bloss : Byte;
                        Aloss : Byte;
                        Rshift: Byte;
                        Gshift: Byte;
                        Bshift: Byte;
                        Ashift: Byte;
                        RMask : Longword;
                        GMask : Longword;
                        BMask : Longword;
                        AMask : Longword;
                        colorkey: Longword;
                        alpha : Byte;
                        end;


     PSDL_Surface = ^TSDL_Surface;
     TSDL_Surface = record
                    flags : Longword;
                    format: PSDL_PixelFormat;
                    w, h  : LongInt;
                    pitch : Word;
                    pixels: Pointer;
                    offset: LongInt;
                    end;

     PSDL_Color = ^TSDL_Color;
     TSDL_Color = record
                  case byte of
                       0: (r: Byte;
                           g: Byte;
                           b: Byte;
                           unused: Byte;
                          );
                       1: (value: Longword);
                  end;

     PSDL_RWops = ^TSDL_RWops;
     TSeek = function( context: PSDL_RWops; offset: LongInt; whence: LongInt ): LongInt; cdecl;
     TRead = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; maxnum : LongInt ): LongInt;  cdecl;
     TWrite = function( context: PSDL_RWops; Ptr: Pointer; size: LongInt; num: LongInt ): LongInt; cdecl;
     TClose = function( context: PSDL_RWops ): LongInt; cdecl;

     TStdio = record
              autoclose: LongInt;
              fp: pointer;
              end;

     TMem = record
            base: PByte;
            here: PByte;
            stop: PByte;
            end;

     TUnknown = record
                data1: Pointer;
                end;

     TSDL_RWops = record
                  seek: TSeek;
                  read: TRead;
                  write: TWrite;
                  close: TClose;
                  type_: Longword;
                  case Byte of
                       0: (stdio: TStdio);
                       1: (mem: TMem);
                       2: (unknown: TUnknown);
                       end;

     TSDL_KeySym = record
                   scancode: Byte;
                   sym: Longword;
                   modifier: Longword;
                   unicode: Word;
                   end;

     TSDL_ActiveEvent = record
	                type_: byte;
                    gain: byte;
                    state: byte;
                    end;

     TSDL_KeyboardEvent = record
                          type_: Byte;
                          which: Byte;
                          state: Byte;
                          keysym: TSDL_KeySym;
                          end;

     TSDL_QuitEvent = record
                      type_: Byte;
                      end;
	TSDL_ResizeEvent = record
			type_: Byte;
			w, h: LongInt;
			end;

     PSDL_Event = ^TSDL_Event;
     TSDL_Event = record
                  case Byte of
                       SDL_NOEVENT: (type_: byte);
                       SDL_ACTIVEEVENT: (active: TSDL_ActiveEvent);
                       SDL_KEYDOWN, SDL_KEYUP: (key: TSDL_KeyboardEvent);
                       SDL_QUITEV: (quit: TSDL_QuitEvent);
                       SDL_VIDEORESIZE: (resize: TSDL_ResizeEvent);
                       end;

     PByteArray = ^TByteArray;
     TByteArray = array[0..65535] of Byte;
     PLongWordArray = ^TLongWordArray;
     TLongWordArray = array[0..16383] of LongWord;

     PSDL_Thread = Pointer;
     PSDL_mutex = Pointer;

function  SDL_Init(flags: Longword): LongInt; cdecl; external SDLLibName;
procedure SDL_Quit; cdecl; external SDLLibName;
function  SDL_VideoDriverName(var namebuf; maxlen: LongInt): PChar; cdecl; external SDLLibName;
procedure SDL_EnableUNICODE(enable: LongInt); cdecl; external SDLLibName;

procedure SDL_Delay(msec: Longword); cdecl; external SDLLibName;
function  SDL_GetTicks: Longword; cdecl; external SDLLibName;

function  SDL_MustLock(Surface: PSDL_Surface): Boolean;
function  SDL_LockSurface(Surface: PSDL_Surface): LongInt; cdecl; external SDLLibName;
procedure SDL_UnlockSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;

function  SDL_GetError: PChar; cdecl; external SDLLibName;

function  SDL_SetVideoMode(width, height, bpp: LongInt; flags: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurface(flags: Longword; Width, Height, Depth: LongInt; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurfaceFrom(pixels: Pointer; width, height, depth, pitch: LongInt; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
procedure SDL_FreeSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;
function  SDL_SetColorKey(surface: PSDL_Surface; flag, key: Longword): LongInt; cdecl; external SDLLibName;
function  SDL_SetAlpha(surface: PSDL_Surface; flag, key: Longword): LongInt; cdecl; external SDLLibName;

function  SDL_UpperBlit(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): LongInt; cdecl; external SDLLibName;
function  SDL_FillRect(dst: PSDL_Surface; dstrect: PSDL_Rect; color: Longword): LongInt; cdecl; external SDLLibName;
procedure SDL_UpdateRect(Screen: PSDL_Surface; x, y: LongInt; w, h: Longword); cdecl; external SDLLibName;
function  SDL_Flip(Screen: PSDL_Surface): LongInt; cdecl; external SDLLibName;

procedure SDL_GetRGB(pixel: Longword; fmt: PSDL_PixelFormat; r, g, b: PByte); cdecl; external SDLLibName;
function  SDL_MapRGB(format: PSDL_PixelFormat; r, g, b: Byte): Longword; cdecl; external SDLLibName;

function  SDL_DisplayFormat(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_DisplayFormatAlpha(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_RWFromFile(filename, mode: PChar): PSDL_RWops; cdecl; external SDLLibName;
function  SDL_SaveBMP_RW(surface: PSDL_Surface; dst: PSDL_RWops; freedst: LongInt): LongInt; cdecl; external SDLLibName;

{$IFDEF SDL13}
function  SDL_GetKeyboardState(numkeys: PLongInt): PByteArray; cdecl; external SDLLibName;
function  SDL_GetMouseState(index: LongInt; x, y: PInteger): Byte; cdecl; external SDLLibName;
{$ELSE}
function  SDL_GetKeyState(numkeys: PLongInt): PByteArray; cdecl; external SDLLibName;
function  SDL_GetMouseState(x, y: PInteger): Byte; cdecl; external SDLLibName;
{$ENDIF}
function  SDL_GetKeyName(key: Longword): PChar; cdecl; external SDLLibName;
procedure SDL_WarpMouse(x, y: Word); cdecl; external SDLLibName;

function  SDL_PollEvent(event: PSDL_Event): LongInt; cdecl; external SDLLibName;

function  SDL_ShowCursor(toggle: LongInt): LongInt; cdecl; external SDLLibName;

procedure SDL_WM_SetCaption(title: PChar; icon: PChar); cdecl; external SDLLibName;

function  SDL_CreateMutex: PSDL_mutex; cdecl; external SDLLibName;
procedure SDL_DestroyMutex(mutex: PSDL_mutex); cdecl; external SDLLibName;
function  SDL_LockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName name 'SDL_mutexP';
function  SDL_UnlockMutex(mutex: PSDL_mutex): LongInt; cdecl; external SDLLibName name 'SDL_mutexV';

function  SDL_GL_SetAttribute(attr: byte; value: LongInt): LongInt; cdecl; external SDLLibName;
procedure SDL_GL_SwapBuffers(); cdecl; external SDLLibName;

(*  TTF  *)

const {$IFDEF WIN32}
      SDL_TTFLibName = 'SDL_ttf.dll';
      {$ENDIF}
      {$IFDEF UNIX}
	{$IFDEF DARWIN}
	  SDL_TTFLibName = 'SDL_ttf';
	{$ELSE}
          SDL_TTFLibName = 'libSDL_ttf.so';
        {$ENDIF}
      {$ENDIF}
      TTF_STYLE_NORMAL = 0;
      TTF_STYLE_BOLD   = 1;
      TTF_STYLE_ITALIC = 2;

type PTTF_Font = ^TTTF_font;
     TTTF_Font = record
                 end;

function TTF_Init: LongInt; cdecl; external SDL_TTFLibName;
procedure TTF_Quit; cdecl; external SDL_TTFLibName;


function TTF_SizeUTF8(font: PTTF_Font; const text: PChar; var w, h: LongInt): LongInt; cdecl; external SDL_TTFLibName;
(* TSDL_Color -> Longword conversion is workaround over freepascal bug.
   See http://www.freepascal.org/mantis/view.php?id=7613 for details *)
function TTF_RenderUTF8_Solid(font: PTTF_Font; const text: PChar; fg: Longword): PSDL_Surface; cdecl; external SDL_TTFLibName;
function TTF_RenderUTF8_Blended(font: PTTF_Font; const text: PChar; fg: Longword): PSDL_Surface; cdecl; external SDL_TTFLibName;
function TTF_RenderUTF8_Shaded(font: PTTF_Font; const text: PChar; fg, bg: Longword): PSDL_Surface; cdecl; external SDL_TTFLibName;

function TTF_OpenFont(const filename: PChar; size: LongInt): PTTF_Font; cdecl; external SDL_TTFLibName;
procedure TTF_SetFontStyle(font: PTTF_Font; style: LongInt); cdecl; external SDL_TTFLibName;


(*  SDL_image  *)

const {$IFDEF WIN32}
      SDL_ImageLibName = 'SDL_image.dll';
      {$ENDIF}
      {$IFDEF UNIX}
	{$IFDEF DARWIN}
	  SDL_ImageLibName = 'SDL_image';
	{$ELSE}
           SDL_ImageLibName = 'libSDL_image.so';
	{$ENDIF}
      {$ENDIF}

function IMG_Load(const _file: PChar): PSDL_Surface; cdecl; external SDL_ImageLibName;

(*  SDL_net  *)

const {$IFDEF WIN32}
      SDL_NetLibName = 'SDL_net.dll';
      {$ENDIF}
      {$IFDEF UNIX}
	{$IFDEF DARWIN}
	  SDL_NetLibName = 'SDL_net';
	{$ELSE}
          SDL_NetLibName = 'libSDL_net.so';
	{$ENDIF}
      {$ENDIF}

type TIPAddress = record
                  host: Longword;
                  port: Word;
                  end;

     PTCPSocket = ^TTCPSocket;
     TTCPSocket = record
                  ready: LongInt;
                  channel: LongInt;
                  remoteAddress: TIPaddress;
                  localAddress: TIPaddress;
                  sflag: LongInt;
                  end;
     PSDLNet_SocketSet = ^TSDLNet_SocketSet;
     TSDLNet_SocketSet = record
                         numsockets,
                         maxsockets: LongInt;
                         sockets: PTCPSocket;
                         end;

function SDLNet_Init: LongInt; cdecl; external SDL_NetLibName;
procedure SDLNet_Quit; cdecl; external SDL_NetLibName;

function SDLNet_AllocSocketSet(maxsockets: LongInt): PSDLNet_SocketSet; cdecl; external SDL_NetLibName;
function SDLNet_ResolveHost(var address: TIPaddress; host: PCHar; port: Word): LongInt; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Accept(server: PTCPsocket): PTCPSocket; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Open(var ip: TIPaddress): PTCPSocket; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Send(sock: PTCPsocket; data: Pointer; len: LongInt): LongInt; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Recv(sock: PTCPsocket; data: Pointer; len: LongInt): LongInt; cdecl; external SDL_NetLibName;
procedure SDLNet_TCP_Close(sock: PTCPsocket); cdecl; external SDL_NetLibName;
procedure SDLNet_FreeSocketSet(_set: PSDLNet_SocketSet); cdecl; external SDL_NetLibName;
function SDLNet_AddSocket(_set: PSDLNet_SocketSet; sock: PTCPSocket): LongInt; cdecl; external SDL_NetLibName;
function SDLNet_CheckSockets(_set: PSDLNet_SocketSet; timeout: LongInt): LongInt; cdecl; external SDL_NetLibName;

procedure SDLNet_Write16(value: Word; buf: pointer);
procedure SDLNet_Write32(value: LongWord; buf: pointer);
function SDLNet_Read16(buf: pointer): Word;
function SDLNet_Read32(buf: pointer): LongWord;

implementation

function SDL_MustLock(Surface: PSDL_Surface): Boolean;
begin
SDL_MustLock:= ( surface^.offset <> 0 )
       or(( surface^.flags and (SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_RLEACCEL)) <> 0)
end;

procedure SDLNet_Write16(value: Word; buf: pointer);
begin
  PByteArray(buf)^[1]:= value;
  PByteArray(buf)^[0]:= value shr 8
end;

procedure SDLNet_Write32(value: LongWord; buf: pointer);
begin
  PByteArray(buf)^[3]:= value;
  PByteArray(buf)^[2]:= value shr  8;
  PByteArray(buf)^[1]:= value shr 16;
  PByteArray(buf)^[0]:= value shr 24
end;

function SDLNet_Read16(buf: pointer): Word;
begin
  SDLNet_Read16:= PByteArray(buf)^[1] or
                 (PByteArray(buf)^[0] shl 8)
end;

function SDLNet_Read32(buf: pointer): LongWord;
begin
  SDLNet_Read32:=  PByteArray(buf)^[3] or
                  (PByteArray(buf)^[2] shl  8) or
                  (PByteArray(buf)^[1] shl 16) or
                  (PByteArray(buf)^[0] shl 24)
end;

end.
