property type, mode, animObject, startSounds, crashSounds, NoBreaks, NoStearing, OkToRun, activeClick, FrozenAction, intoMail, currentAnimChart
global gDir, gMulleGlobals

on beginSprite me
  set type to #Mulle
  set mode to #Wait
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  set NoBreaks to 0
  set NoStearing to 0
  set OkToRun to 0
  set activeClick to 1
  repeat with index in tempList
    if the type of index = #SpriteAnim then
      set animObject to index
    end if
  end repeat
  set FrozenAction to EMPTY
  set intoMail to 0
  set currentAnimChart to "MulleCar"
end

on activate me, theState
  set activeClick to theState
end

on describepart me, theDescription
  nejj()
  set mode to #Talk
  makeAnimSpeech(animObject, theDescription)
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end

on randomMove me, maxRnd
  set tempMode to 0
  case random(maxRnd) of
    1:
      set tempMode to #Talk
      makeAnimSpeech(animObject, getAt(startSounds, random(count(startSounds))))
  end case
  if symbolp(tempMode) then
    set mode to tempMode
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  end if
end

on getProperty me, theProp
  if theProp = #OkToRun then
    return OkToRun
  else
    if theProp = #CrashState then
      if NoBreaks = 1 and NoStearing = 1 then
        return ["noBrakes", "NoStearing"]
      else
        if NoBreaks = 1 then
          return ["noBrakes"]
        else
          if NoStearing = 1 then
            return ["NoStearing"]
          else
            return 0
          end if
        end if
      end if
    end if
  end if
end

on setMulleSpeak me
  set crashSounds to []
  set startSounds to []
  if getaProp(the carProperties of the carCopy of gDir, #Steering) = 0 then
    add(crashSounds, "04d005v0")
    set NoStearing to 1
  end if
  if getaProp(the carProperties of the carCopy of gDir, #break) = 0 then
    add(crashSounds, "04d006v0")
    set NoBreaks to 1
  end if
  if getaProp(the carProperties of the carCopy of gDir, #Pedals) = 0 then
    if getaProp(the carProperties of the carCopy of gDir, #acceleration) = 0 then
      add(startSounds, "04d004v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #EngineType) = 0 then
      add(startSounds, "04d022v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #ElectricVolume) = 0 then
      add(startSounds, "04d003v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #FuelVolume) = 0 then
      if getaProp(the carProperties of the carCopy of gDir, #EngineType) <> 3 then
        add(startSounds, "04d002v0")
      end if
    end if
  else
    set startSounds to []
  end if
  if startSounds = [] then
    add(startSounds, "04d008v0")
    add(startSounds, "04d009v0")
    add(startSounds, "04d010v0")
    set OkToRun to 1
  end if
  if crashSounds = [] and startSounds = [] then
    add(startSounds, "04d007v0")
  end if
end

on loop me
  if the frame = 2 then
    deleteLoopObject(gDir, me)
    MakeMulleSpeak(me, FrozenAction)
  end if
end

on MakeMulleSpeak me, theAction
  if the frame = 1 then
    set FrozenAction to theAction
    addLoopObject(gDir, me)
  else
    if not (theAction = #Refuse and mode = #Talk) then
      playAnimSound(animObject, EMPTY)
    end if
    if theAction = #shopFull then
      set n to random(3)
      case n of
        1:
          set theSnd to "04d016v0"
        2:
          set theSnd to "04d017v0"
        3:
          set theSnd to "04d018v0"
      end case
    else
      if theAction = #Refuse then
        if mode <> #Talk then
          set theSnd to getAt(startSounds, random(count(startSounds)))
        end if
      else
        if theAction = #Package then
          set n to random(3)
          case n of
            1:
              set theSnd to "04d013v0"
            2:
              set theSnd to "04d014v0"
            3:
              set theSnd to "04d015v0"
          end case
        else
          if theAction = #FiggeRemark then
            set theSnd to "04d021v0"
          else
            if theAction = #noMail then
              set theSnd to "04d001v0"
            else
              if theAction = #Mail then
                set intoMail to 1
                set theSnd to "04d020v0"
              end if
            end if
          end if
        end if
      end if
    end if
    set currentAnimChart to #TalkToMe
    sendSprite(the currentSpriteNum, #setAnimChart, "MulleCarTalk")
    if not (theAction = #Refuse and mode = #Talk) then
      set mode to #Talk
      makeAnimSpeech(animObject, theSnd)
      sendSprite(the spriteNum of me, #setAnimAction, #Talk)
    end if
    set the gCurrentSound of gDir to theSnd
  end if
end

on Stopped me
  case mode of
    #Talk:
      if intoMail then
        set intoMail to 0
        performMission(the missions of gMulleGlobals)
      end if
      if currentAnimChart = #TalkToMe then
        sendSprite(the currentSpriteNum, #setAnimChart, "MulleCar")
      end if
      setAnimNormal(animObject)
      set tempMode to #Wait
      set the gCurrentSound of gDir to EMPTY
    otherwise:
      set tempMode to #Wait
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
