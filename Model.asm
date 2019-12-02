proc Model.Update uses edx
     invoke     GetTickCount
     mov        edx, eax
     sub        edx, [Model.LastTime]
     cmp        edx, deltaTime
     jb         .EndFalse
     mov        [Model.LastTime], eax
     cmp        [Model.blIsStickGrowing], TRUE
     jne        @F
     stdcall    Model.GrowStick
@@:
     cmp        [Model.blIsStickFalling], TRUE
     jne        @F
     stdcall    Model.RotateStick
     cmp        eax, TRUE
     je         @F
     mov        [Model.blIsStickFalling], FALSE
     cmp        [Model.blProceedTurn], TRUE
     je         .dropHero
     stdcall    Model.BeginWalk
     jmp        @F
.dropHero:
     stdcall    Model.BeginDropHero
@@:
     cmp        [Model.blIsHeroWalking], TRUE
     jne        @F
     stdcall    Model.MoveHero
     cmp        eax, FALSE
     je         @F
     stdcall    Model.EndWalk
@@:
     cmp        [Model.blIsWorldMovingLeft], TRUE
     jne        @F
     stdcall    Model.MoveWorldLeft
@@:
     cmp        [Model.blIsHeroFalling], TRUE
     jne        @F
     stdcall    Model.DropHero
     cmp        eax, TRUE
     jne        @F
     stdcall    Model.EndGame
@@:

.EndTrue:
     mov        eax, TRUE
     ret
.EndFalse:
     mov        eax, FALSE
     ret
endp

proc Model.EndGame
     stdcall    SH.SetRandomBG
     stdcall    Model.Init
     ret
endp

proc Model.DropHero
     add        [Model.Hero.top], Model.Hero.DropStep
     cmp        [Model.Hero.top], winHeight
     jle         .EndFalse
.EndTrue:
     mov        eax, TRUE
     ret
.EndFalse:
     mov        eax, FALSE
     ret
endp

proc Model.BeginDropHero
     mov        [Model.blIsHeroFalling], TRUE
     ret
endp

proc Model.MoveWorldLeft
     sub        [Model.ColL.left], Model.World.Step
     sub        [Model.ColL.right], Model.World.Step
     sub        [Model.ColBuff.left], Model.World.Step
     sub        [Model.ColBuff.right], Model.World.Step
     sub        [Model.Stick.left], Model.World.Step
     sub        [Model.Stick.right], Model.World.Step
     sub        [Model.Hero.left], Model.World.Step
     sub        [Model.ColR.left], Model.World.Step
     sub        [Model.ColR.right], Model.World.Step
     mov        eax, [Model.ColR.right]
     cmp        eax, [Model.ColR.Width]
     jle        .EndMoving
     jmp        .EndProc
.EndMoving:
     mov        [Model.ColL.left], 0
     mov        eax, [Model.ColR.Width]
     mov        [Model.ColL.Width], eax
     mov        [Model.ColL.right], eax
     mov        eax, [Model.ColBuff.Pos]
     mov        [Model.ColR.left], eax
     add        eax, [Model.ColBuff.Width]
     mov        [Model.ColR.right], eax
     mov        eax, [Model.ColBuff.Width]
     mov        [Model.ColR.Width], eax
     stdcall    Model.EndGrowStick
     mov        eax, [Model.Stick.left]
     sub        eax, Model.HeroSize
     mov        [Model.Hero.left], eax
     mov        [Model.blDrawColBuff], FALSE
     mov        [Model.blIsWorldMovingLeft], FALSE
     add        [Model.Score], 1
.EndProc:
     ret
endp

proc Model.ProceedTurn uses edx
     mov        [Model.blProceedTurn], TRUE
     cmp        [Model.blIsStickOk], TRUE
     jne        .lose
.win:
     mov        eax, [Model.Stick.bottom]
     sub        eax, [Model.Stick.top]
     mov        edx, [Model.ColL.right]
     mov        [Model.Stick.left], edx
     add        edx, eax
     mov        [Model.Stick.right], edx
     mov        [Model.Stick.top], Model.Top - Model.StickWidth
     mov        [Model.blIsStickRotated], FALSE

     mov        [Model.blIsWorldMovingLeft], TRUE
     mov        [Model.blDrawColBuff], TRUE
     stdcall    Model.Random, Model.MinColWidth, Model.MaxColWidth
     mov        [Model.ColBuff.Width], eax
     mov        eax, winWidth
     sub        eax, [Model.ColBuff.Width]
     mov        edx, [Model.ColR.Width]
     stdcall    Model.Random, edx, eax
     mov        [Model.ColBuff.Pos], eax
     add        eax, [Model.ColR.left]
     mov        [Model.ColBuff.left], eax
     add        eax, [Model.ColBuff.Width]
     mov        [Model.ColBuff.right], eax
     mov        [Model.blProceedTurn], FALSE
     jmp        .EndProc
.lose:
     mov        [Model.Stick.AngleBegin], 90
     mov        [Model.Stick.AngleEnd], 180
     mov        [Model.blIsStickFalling], TRUE
.EndProc:
     ret
endp

proc Model.EndWalk
     mov        [Model.Hero.CurrState], LEGS_STRAIGHT
     mov        [Model.blIsHeroWalking], FALSE
     stdcall    Model.ProceedTurn
     ret
endp

proc Model.MoveHero uses edx
     invoke     GetTickCount
     mov        edx, eax
     sub        eax, [Model.LastLegsChange]
     cmp        eax, Model.DeltaLegs
     jb         .endLegs
     mov        [Model.LastLegsChange], edx
     cmp        [Model.Hero.CurrState], LEGS_OUT
     je         .legsOut
     cmp        [Model.Hero.CurrState], LEGS_IN
     je         .legsIn
.legsStraight:
     cmp        [Model.Hero.PrevState], LEGS_OUT
     jne        @F
     mov        [Model.Hero.CurrState], LEGS_IN
     jmp        .endLegs
@@:
     mov        [Model.Hero.CurrState], LEGS_OUT
     jmp        .endLegs
.legsIn:
     mov        [Model.Hero.CurrState], LEGS_STRAIGHT
     mov        [Model.Hero.PrevState], LEGS_IN
     jmp        .endLegs
.legsOut:
     mov        [Model.Hero.CurrState], LEGS_STRAIGHT
     mov        [Model.Hero.PrevState], LEGS_OUT
.endLegs:
     mov        eax, [Model.Hero.left]
     cmp        eax, [Model.Stick.End]
     jl         @F
     mov        [Model.Hero.top], Model.Top - Model.HeroSize
@@:
     add        eax, Model.Hero.Step
     cmp        eax, [Model.Hero.Dest]
     jg         .endMove
     mov        [Model.Hero.left], eax
     jmp        .EndFalse
.endMove:
     cmp        [Model.blIsStickOk], TRUE
     jne        @F
     mov        [Model.Hero.top], Model.Top - Model.HeroSize
@@:
     mov        edx, [Model.Hero.Dest]
     mov        [Model.Hero.left], edx
.EndTrue:
     mov        eax, TRUE
     jmp        .EndProc
.EndFalse:
     mov        eax, FALSE
.EndProc:
     ret
endp

proc Model.BeginWalk uses edx

     invoke     GetTickCount
     mov        [Model.LastLegsChange], eax
     sub        [Model.Hero.top], Model.Hero.Step * 2
     mov        [Model.Hero.CurrState], LEGS_OUT
     mov        [Model.blIsHeroWalking], TRUE

     mov        edx, [Model.Stick.bottom]
     sub        edx, [Model.Stick.top]
     add        edx, [Model.ColL.right]
     mov        [Model.Stick.End], edx

     cmp        edx, [Model.ColR.left]
     jng        .lose
     cmp        edx, [Model.ColR.right]
     jng        .win
.lose:
     mov        [Model.blIsStickOk], FALSE
     sub        edx, Model.HeroSize
     mov        [Model.Hero.Dest], edx
     jmp        .EndProc
.win:
     mov        eax, [Model.ColR.right]
     sub        eax, Model.HeroSize + Model.StickWidth
     mov        [Model.Hero.Dest], eax
     mov        [Model.blIsStickOk], TRUE
     jmp        .EndProc
.EndProc:
     ret
endp

proc Model.GrowStick
     mov        eax, [Model.Stick.top]
     sub        eax, deltaHeight
     cmp        eax, [Model.Stick.MaxTop]
     jl         .Exceeds
     mov        [Model.Stick.top], eax
     jmp        .EndProc
.Exceeds:
     mov        eax, [Model.Stick.MaxTop]
     mov        [Model.Stick.top], eax
     stdcall    Model.BeginFallingStick
.EndProc:
     ret
endp

proc Model.RotateStick     
     add        [Model.Stick.RotAngle], Model.Stick.Step
     mov        eax, [Model.Stick.AngleEnd]
     cmp        [Model.Stick.RotAngle], eax
     ja         .EndFalse
                                              ; =>
     fild       [Model.Stick.RotAngle]        ; => [RotAngle]
     fldpi                                    ; => [RotAngle] [Pi]
     fmulp                                    ; => [RotAngle * Pi]
     fild       [Model.180]                   ; => [RotAngle * Pi] [180]
     fdivp                                    ; => [RotAngle * Pi / 180]
     fsincos                                  ; => [sin(RotAngle)] [cos(RotAngle)]
     fild       [Model.Stick.right]           ; => [sin(RotAngle)] [cos(RotAngle)] [x0]
     fild       [Model.Stick.right]           ; => [sin(RotAngle)] [cos(RotAngle)] [x0] [x0]
     fmul       st0, st2                      ; => [sin(RotAngle)] [cos(RotAngle)] [x0] [x0 * cos(RotAngle)]
     fsubp                                    ; => [sin(RotAngle)] [cos(RotAngle)] [x0 - x0 * cos(RotAngle)]
     fild       [Model.Stick.bottom]          ; => [sin(RotAngle)] [cos(RotAngle)] [x0 - x0 * cos(RotAngle)] [y0]
     fmul       st0, st3                      ; => [sin(RotAngle)] [cos(RotAngle)] [x0 - x0 * cos(RotAngle)] [y0 * sin(RotAngle)]
     faddp                                    ; => [sin(RotAngle)] [cos(RotAngle)] [x0 - x0 * cos(RotAngle) + y0 * sin(RotAngle)]
     fstp       [Model.XFORM.eDx]             ; => [sin(RotAngle)] [cos(RotAngle)]
     fild       [Model.Stick.bottom]          ; => [sin(RotAngle)] [cos(RotAngle)] [y0]
     fild       [Model.Stick.bottom]          ; => [sin(RotAngle)] [cos(RotAngle)] [y0] [y0]
     fmul       st0, st2                      ; => [sin(RotAngle)] [cos(RotAngle)] [y0] [y0 * cos(RotAngle)]
     fsubp                                    ; => [sin(RotAngle)] [cos(RotAngle)] [y0 - y0 * cos(RotAngle)]
     fild       [Model.Stick.right]           ; => [sin(RotAngle)] [cos(RotAngle)] [y0 - y0 * cos(RotAngle)] [x0]
     fmul       st0, st3                      ; => [sin(RotAngle)] [cos(RotAngle)] [y0 - y0 * cos(RotAngle)] [x0 * sin(RotAngle)]
     fsubp                                    ; => [sin(RotAngle)] [cos(RotAngle)] [y0 - y0 * cos(RotAngle) - x0 * sin(RotAngle)]
     fstp       [Model.XFORM.eDy]             ; => [sin(RotAngle)] [cos(RotAngle)]

     fst        [Model.XFORM.eM11]            ; => [sin(RotAngle)] [cos(RotAngle)]
     fstp       [Model.XFORM.eM22]            ; => [sin(RotAngle)]
     fst        [Model.XFORM.eM12]            ; => [sin(RotAngle)]
     fchs                                     ; => [-sin(RotAngle)]
     fstp       [Model.XFORM.eM21]            ; =>
.EndTrue:
     mov        eax, TRUE
     ret
.EndFalse:
     mov        eax, FALSE
     ret
endp

proc Model.BeginGrowStick
     cmp        [Model.blCanGrowStick], TRUE
     jne        .EndProc
     invoke     GetTickCount
     mov        [Model.LastTime], eax
     mov        [Model.blDrawStick], TRUE
     mov        [Model.Stick.top], Model.Top - Model.MinStickHeight
     mov        [Model.blCanGrowStick], FALSE
     mov        [Model.blIsStickGrowing], TRUE
     mov        [Model.blIsStickRotated], FALSE
     mov        eax, winWidth
     sub        eax, [Model.ColL.right]
     neg        eax
     add        eax, Model.Top + Model.MinColWidth / 2
     mov        [Model.Stick.MaxTop], eax
.EndProc:
     ret
endp

proc Model.EndGrowStick
     mov        eax, [Model.ColL.right]
     mov        [Model.Stick.right], eax
     sub        eax, Model.StickWidth
     mov        [Model.Stick.left], eax
     mov        [Model.blIsStickRotated], FALSE
     mov        [Model.blDrawStick], FALSE
     mov        [Model.blCanGrowStick], TRUE
     ret
endp

proc Model.BeginFallingStick
     mov        eax, [Model.Stick.AngleBegin]
     mov        [Model.Stick.RotAngle], eax
     mov        [Model.blIsStickRotated], TRUE
     mov        [Model.blIsStickGrowing], FALSE
     mov        [Model.blIsStickFalling], TRUE
     ret
endp

proc Model.Random.Init uses ecx edx
     invoke     GetTickCount
     xor        edx, edx
     mov        ecx, Model.Random.M
     div        ecx
     mov        [Model.Random.N], edx
     ret
endp

proc Model.Random uses ecx edx,\
     min, max

     mov        eax, Model.Random.A
     mov        ecx, [Model.Random.N]
     mul        ecx
     add        eax, Model.Random.C
     adc        edx, 0
     mov        ecx, 65536
     div        ecx              ; eax = next / 65536
     mov        edx, eax
     shr        edx, 16
     mov        cx, Model.Random.M
     div        cx
     mov        eax, [max]
     sub        eax, [min]
     inc        eax
     mov        ecx, eax
     movzx      eax, dx          ; ax = Random value
     mov        [Model.Random.N], eax
     xor        edx, edx
     div        cx
     movzx      eax, dx
     add        eax, [min]
     ret
endp

proc Model.Init uses edx
     mov        [Model.Score], 0
     stdcall    Model.Random, Model.MinColWidth, Model.MaxColWidth
     mov        [Model.ColL.right], eax
     mov        [Model.ColL.Width], eax
     mov        [Model.Stick.right], eax
     mov        [Model.Stick.left], eax
     sub        [Model.Stick.left], Model.StickWidth
     stdcall    Model.Random, Model.MinColWidth, Model.MaxColWidth
     mov        [Model.ColR.Width], eax
     mov        eax, winWidth
     sub        eax, [Model.ColR.Width]
     mov        edx, [Model.ColL.right]
     add        edx, [Model.ColR.Width]
     stdcall    Model.Random, edx, eax
     mov        [Model.ColR.left], eax
     add        eax, [Model.ColR.Width]
     mov        [Model.ColR.right], eax
     mov        eax, [Model.ColL.right]
     sub        eax, Model.HeroSize + Model.StickWidth
     mov        [Model.Hero.left], eax
     mov        [Model.Stick.AngleBegin], 0
     mov        [Model.Stick.AngleEnd], 90
     mov        [Model.Hero.top], Model.Top - Model.HeroSize
     stdcall    Model.SetFlags
     ret
endp

proc Model.SetFlags
     mov        [Model.blDrawStick], FALSE
     mov        [Model.blCanGrowStick], TRUE
     mov        [Model.blIsStickGrowing], FALSE
     mov        [Model.blIsStickFalling], FALSE
     mov        [Model.blIsStickRotated], FALSE
     mov        [Model.blDrawHero], TRUE
     mov        [Model.blIsHeroWalking], FALSE
     mov        [Model.blProceedTurn], FALSE
     mov        [Model.blIsWorldMovingLeft], FALSE
     mov        [Model.blDrawColBuff], FALSE
     mov        [Model.blIsHeroFalling], FALSE
     ret
endp
