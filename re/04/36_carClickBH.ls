property activeClick, SP, engineSnd, crashSnd, okToLeave
global gDir, gMulleGlobals, gSound

on beginSprite me
  set activeClick to 1
  set engineSnd to 0
  set crashSnd to 0
  set SP to 0
  set okToLeave to 0
end

on activateClick me, theState
  set activeClick to theState
end

on loop me
  if finished(gSound, engineSnd) then
    deleteLoopObject(gDir, me)
    set crashSnd to play(gSound, "04e002v0", #EFFECT)
    GoOut(me)
  end if
end

on mouseEnter me
  if activeClick then
    if the carOnYard of gDir then
      sendSprite(115, #c_click)
    end if
  end if
end

on mouseLeave me
  if activeClick then
    if the carOnYard of gDir then
      sendSprite(115, #C_Standard)
    end if
  end if
end

on mouseUp me
  if activeClick then
    if the carOnYard of gDir then
      set the WhereFrom of gMulleGlobals to "04"
      set SP to getaProp(the spriteList of gDir, #mulleInCar)
      if the OkToRun of sprite(SP) then
        if the crashSounds of sprite(SP) = [] then
          put "Its ok, no crash"
          if nrOfWorlds(the worlds of gMulleGlobals) > 1 then
            checkNrofBuiltCars(me)
            activate(gDir, 0)
            set the rect of window("test") to rect(the stageLeft + 109, the stageTop + 90, the stageLeft + 531, the stageTop + 390)
            cursor(-1)
            cursor(200)
            set the titleVisible of window("test") to 0
            set the fileName of window("test") to "18"
            set the visible of window("test") to 1
          else
            set okToLeave to 1
            checkNrofBuiltCars(me)
            kickEngine(me)
          end if
        else
          kickEngine(me)
        end if
        sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #setAnimAction, #Still)
      else
        sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #Refuse)
      end if
    end if
  end if
end

on checkNrofBuiltCars me
  if the enterParts of the carCopy of gDir <> the parts of the carCopy of gDir then
    set the nrOfBuiltCars of the user of gMulleGlobals to the nrOfBuiltCars of the user of gMulleGlobals + 1
    set the figgeIsComing of the user of gMulleGlobals to 1
    set the missionIsComing of the user of gMulleGlobals to 1
  end if
  set the enterParts of the carCopy of gDir to duplicate(the parts of the carCopy of gDir)
end

on kickEngine me
  activate(gDir, 0)
  case getaProp(the carProperties of the car of the user of gMulleGlobals, #EngineType) of
    1:
      set engineSnd to play(gSound, "05e074v0", #EFFECT)
    2:
      set engineSnd to play(gSound, "05e067v0", #EFFECT)
    3:
      set engineSnd to play(gSound, "05e025v0", #EFFECT)
    4:
      set engineSnd to play(gSound, "05e004v0", #EFFECT)
    5:
      set engineSnd to play(gSound, "05e011v0", #EFFECT)
    6:
      set engineSnd to play(gSound, "05e053v0", #EFFECT)
    7:
      set engineSnd to play(gSound, "05e018v0", #EFFECT)
    8:
      set engineSnd to play(gSound, "05e060v0", #EFFECT)
    9:
      set engineSnd to play(gSound, "05e032v0", #EFFECT)
  end case
  if okToLeave = 1 then
    set okToLeave to 0
    set the gCurrentSound of gDir to engineSnd
    go("05")
  else
    addLoopObject(gDir, me)
  end if
end

on GoOut me
  put "SP ", SP
  put "crashsounds ", the crashSounds of sprite(SP)
  if count(the crashSounds of sprite(SP)) = 2 then
    if random(2) = 1 then
      go("fence")
    else
      go("offroad")
    end if
  else
    if count(the crashSounds of sprite(SP)) = 1 then
      if getAt(the crashSounds of sprite(SP), 1) = "04d005v0" then
        go("offroad")
      else
        if getAt(the crashSounds of sprite(SP), 1) = "04d006v0" then
          go("fence")
        end if
      end if
    end if
  end if
end
