        format PE GUI 4.0
        entry WinMain
        include 'win32w.inc'

nil             = 0
deltaTime       = 15

clrBlack        = $00000000
clrWhite        = $00FFFFFF

winWidth        = 437
winHeight       = 629

bgCount         = 12


section '.code' code readable writeable

proc WinMain uses esi
     locals
        Msg     MSG
     endl

     xor        ebx, ebx

     invoke     GetModuleHandle, nil
     mov        esi, eax
     mov        [SH.WindowClassEx.hInstance], esi
     invoke     LoadCursor, 0, IDC_ARROW
     mov        [SH.WindowClassEx.hCursor], eax
     invoke     LoadIconW, esi, SH.IconName
     mov        [SH.WindowClassEx.hIcon], eax
     invoke     RegisterClassEx, SH.WindowClassEx

     and        eax, $0000FFFF
     invoke     CreateWindowEx, 0, eax, SH.Title, (WS_OVERLAPPEDWINDOW or WS_VISIBLE) and not (WS_MAXIMIZEBOX or WS_THICKFRAME),\
                                400, 350, winWidth, winHeight,\
                                0, 0, [SH.WindowClassEx.hInstance],  nil
     mov        [SH.hWnd], eax

     lea        edi, [Msg]
.MsgLoop:
     invoke     PeekMessage, edi, 0, 0, 0, PM_NOREMOVE
     test       eax, eax
     jz         .Idle
     invoke     GetMessage, edi, 0, 0, 0
     test       eax, eax
     jz         .EndMsgLoop
     invoke     DispatchMessage, edi
     jmp        .MsgLoop
.Idle:
     stdcall    Model.Update
     cmp        eax, TRUE
     jne        .MsgLoop
     invoke     InvalidateRect, [SH.hWnd], SH.ClientRect, FALSE
     jmp        .MsgLoop
.EndMsgLoop:
     invoke     ExitProcess, 0
endp

proc SH.SetRandomBG uses ebx
     locals
        hbmTMP  dd      ?
     endl

     stdcall    Model.Random, ebx, bgCount - 1
     mov        ebx, eax
     add        [SH.BGDefName], bx

     invoke     GetModuleHandle, nil
     invoke     LoadBitmapW, eax, SH.BGDefName
     mov        [hbmTMP], eax
     invoke     SelectObject, [SH.hdcBG], eax
     invoke     DeleteObject, eax
     mov        eax, [hbmTMP]
     mov        [SH.hbmBack], eax

     sub        [SH.BGDefName], bx
     ret
endp

include 'Model.c'

proc SH.LoadHeroBM uses esi
     invoke     GetModuleHandle, nil
     mov        esi, eax
     invoke     LoadBitmapW, esi, SH.bmHeroName
     mov        [SH.hbmHero], eax
     invoke     SelectObject, [SH.hdcHero], eax
     mov        [SH.Hero.bmCurr], LEGS_STRAIGHT
     invoke     LoadBitmapW, esi, SH.bmHeroLegsInName
     mov        [SH.hbmHeroLegsIn], eax
     invoke     LoadBitmapW, esi, SH.bmHeroLegsOutName
     mov        [SH.hbmHeroLegsOut], eax
     ret
endp

proc SH.OnCreate uses esi ebx,\
     hWnd

     xor        ebx, ebx ; CreateWindowEx changes ebx value :\

     stdcall    Model.Random.Init
     invoke     GetClientRect, [hWnd], SH.ClientRect
     invoke     GetDC, ebx
     mov        esi, eax

     invoke     CreateCompatibleDC, esi
     mov        [SH.hdcHero], eax

     invoke     CreateCompatibleDC, esi
     mov        [SH.hdcBG], eax
     stdcall    SH.SetRandomBG
     invoke     CreateCompatibleDC, esi
     mov        [SH.hdcBack], eax
     invoke     CreateCompatibleBitmap, esi, [SH.ClientRect.right], [SH.ClientRect.bottom]
     mov        [SH.hbmBack], eax
     invoke     SelectObject, [SH.hdcBack], eax
     invoke     DeleteObject, eax
     invoke     CreateSolidBrush, clrBlack
     invoke     SelectObject, [SH.hdcBack], eax
     invoke     DeleteObject, eax
     invoke     CreateFontW, -54, 0, 0, 0, 0, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH + FF_DONTCARE, SH.fontName
     invoke     SelectObject, [SH.hdcBack], eax
     invoke     DeleteObject, eax
     invoke     SetBkMode, [SH.hdcBack], TRANSPARENT
     invoke     ReleaseDC, ebx, esi
     stdcall    SH.LoadHeroBM
     stdcall    Model.Init
     ret
endp

proc SH.PaintBack
     invoke     BitBlt, [SH.hdcBack], ebx, ebx, [SH.ClientRect.right], [SH.ClientRect.bottom], [SH.hdcBG], ebx, ebx, SRCCOPY
     invoke     Rectangle, [SH.hdcBack], [Model.ColL.left], [Model.ColL.top], [Model.ColL.right], [Model.ColL.bottom]
     invoke     Rectangle, [SH.hdcBack], [Model.ColR.left], [Model.ColR.top], [Model.ColR.right], [Model.ColR.bottom]
     cmp        [Model.blDrawColBuff], TRUE
     jne        .skipColBuff
     invoke     Rectangle, [SH.hdcBack], [Model.ColBuff.left], [Model.ColBuff.top], [Model.ColBuff.right], [Model.ColBuff.bottom]
.skipColBuff:
     cmp        [Model.blDrawStick], TRUE
     jne        .endStick
     cmp        [Model.blIsStickRotated], TRUE
     jne        .skipRotating
     invoke     SaveDC, [SH.hdcBack]
     invoke     SetGraphicsMode, [SH.hdcBack], 2
     invoke     SetWorldTransform, [SH.hdcBack], Model.XFORM
     invoke     Rectangle, [SH.hdcBack], [Model.Stick.left], [Model.Stick.top], [Model.Stick.right], [Model.Stick.bottom]
     invoke     RestoreDC, [SH.hdcBack], 1
     jmp        .endStick
.skipRotating:
     invoke     Rectangle, [SH.hdcBack], [Model.Stick.left], [Model.Stick.top], [Model.Stick.right], [Model.Stick.bottom]
.endStick:
     cmp        [Model.blDrawHero], TRUE
     jne        .endHero
     cmp        [Model.Hero.CurrState], LEGS_STRAIGHT
     je         .LEGS_STRAIGHT
     cmp        [Model.Hero.CurrState], LEGS_IN
     je         .LEGS_IN
     cmp        [Model.Hero.CurrState], LEGS_OUT
     je         .LEGS_OUT
.LEGS_STRAIGHT:
     invoke     SelectObject, [SH.hdcHero], [SH.hbmHero]
     jmp        .drawHero
.LEGS_IN:
     invoke     SelectObject, [SH.hdcHero], [SH.hbmHeroLegsIn]
     jmp        .drawHero
.LEGS_OUT:
     invoke     SelectObject, [SH.hdcHero], [SH.hbmHeroLegsOut]
     jmp        .drawHero
.drawHero:
     invoke     TransparentBlt, [SH.hdcBack], [Model.Hero.left], [Model.Hero.top], Model.HeroSize, Model.HeroSize, [SH.hdcHero], ebx, ebx, Model.HeroSize, Model.HeroSize, Model.clHeroBack
.endHero:
     cinvoke    wsprintf, SH.strScoreFormated, SH.strScore, [Model.Score]
     invoke     DrawText, [SH.hdcBack], SH.strScoreFormated, -1, SH.StaticRect, DT_CENTER
     ret
endp

proc SH.OnPaint uses edi,\
     hWnd
     xor ebx, ebx
     stdcall    SH.PaintBack

     lea        edi, [PS]
     invoke     BeginPaint, [hWnd], edi
     invoke     BitBlt, eax, ebx, ebx, [SH.ClientRect.right], [SH.ClientRect.bottom], [SH.hdcBack], ebx, ebx, SRCCOPY
     invoke     EndPaint, [hWnd], edi
.EndProc:
     ret
endp

proc SH.WindowProc uses ebx esi edi,\
     hWnd, uMsg, wParam, lParam

     cmp        [uMsg], WM_CREATE
     je         .WMCreate
     cmp        [uMsg], WM_DESTROY
     je         .WMDestroy
     cmp        [uMsg], WM_KEYDOWN
     je         .WMKeyDown
     cmp        [uMsg], WM_KEYUP
     je         .WMKeyUp
     cmp        [uMsg], WM_PAINT
     je         .WMPaint
.Default:
     invoke     DefWindowProc, [hWnd], [uMsg], [wParam], [lParam]
     jmp        .EndProc
.WMCreate:
     stdcall    SH.OnCreate, [hWnd]
     jmp        .Default
.WMPaint:
     stdcall    SH.OnPaint, [hWnd]
     jmp        .RetZero
.WMDestroy:
     invoke     PostQuitMessage, 0
     jmp        .Default
.WMKeyDown:
     cmp        [wParam], VK_SPACE
     jne        @F
     test       [lParam], 1 shl 30
     jnz        @F
     stdcall    Model.BeginGrowStick
@@:
     jmp        .RetZero
.WMKeyUp:
     cmp        [wParam], VK_SPACE
     jne        @F
     cmp        [Model.blIsStickGrowing], TRUE
     jne        @F
     stdcall    Model.BeginFallingStick
@@:
     jmp        .RetZero
.RetZero:
     xor         eax, eax
.EndProc:
     ret
endp

section '.data' data readable writeable

include 'Model.d'

SH.WindowClassEx                WNDCLASSEX      sizeof.WNDCLASSEX, 0, SH.WindowProc, 0, 4, 0, 0, 0, COLOR_BTNFACE + 1, nil, SH.ClassName, 0
SH.ClassName                    du              'TStickHero', 0
SH.Title                        du              'Stick Hero', 0
SH.BGDefName                    du              'A', 0
SH.IconName                     du              'SH', 0
SH.bmHeroName                   du              'HERO', 0
SH.bmHeroLegsInName             du              'HEROLEGSIN', 0
SH.bmHeroLegsOutName            du              'HEROLEGSOUT', 0
SH.hdcBack                      dd              ?
SH.hdcBG                        dd              ?
SH.hdcHero                      dd              ?
SH.hbmBack                      dd              ?
SH.hbmBG                        dd              ?
SH.hbmHero                      dd              ?
SH.hbmHeroLegsIn                dd              ?
SH.hbmHeroLegsOut               dd              ?
SH.hbmHeroIn                    dd              ?
SH.hbmHeroOut                   dd              ?
SH.ClientRect                   RECT
SH.hWnd                         dd              ?
SH.Hero.bmCurr                  dd              ?

SH.StaticRect                   RECT            winWidth / 2 - SH.StaticWidth / 2, SH.StaticTop, winWidth / 2 + SH.StaticWidth / 2, SH.StaticTop + SH.StaticHeight
SH.StaticWidth                  = 100
SH.StaticHeight                 = 60
SH.StaticTop                    = 50

SH.fontName                     du              'Arial', 0

SH.strScore                     du              '%d', 0
SH.strScoreFormated             rb              $ - SH.strScore + 10
zr db 0

PS                              PAINTSTRUCT

section '.idata' data import readable writeable

library kernel32, 'kernel32.dll',\
        gdi32,    'gdi32.dll',\
        user32,   'user32.dll',\
        msimg32,  'msimg32.dll'

import  msimg32,\
TransparentBlt, 'TransparentBlt'

include 'api\kernel32.inc'
include 'api\gdi32.inc'
include 'api\user32.inc'

section '.rsrc' data resource from 'SHnew.res' readable