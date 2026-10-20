property type, mode, animObject, randomSounds, leadSounds, CarEquipment, activeClick, FrozenAction, intoMail, currentAnimChart, theSnd
global gDir, gMulleGlobals

on beginSprite me
  set type to #Mulle
  set mode to #Wait
  set currentAnimChart to #Mulle
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  set animObject to getAt(tempList, 1)
  setAnimNormal(animObject)
  set activeClick to 1
  set FrozenAction to EMPTY
  set intoMail to 0
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
    playAnimSound(animObject, EMPTY)
    set tempMode to #Talk
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
      if random(2) = 1 then
      else
        set currentAnimChart to #TalkToMe
        sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
      end if
    else
      if theAction = #FiggeRemark then
        set theSnd to "04d021v0"
        set currentAnimChart to #TalkToMe
        sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
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
          set currentAnimChart to #TalkToMe
          sendSprite(the spriteNum of me, #setAnimChart, "TalkToMe")
        else
          if theAction = #noMail then
            set theSnd to "04d001v0"
            set currentAnimChart to #TalkToMe
            sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
          else
            if theAction = #Mail then
              set intoMail to 1
              set theSnd to "04d020v0"
              set currentAnimChart to #TalkToMe
              sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
            end if
          end if
        end if
      end if
    end if
    set mode to tempMode
    makeAnimSpeech(animObject, theSnd)
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  end if
end

on Stopped me
  put "mode ", mode
  case mode of
    #Talk:
      if intoMail then
        set intoMail to 0
        performMission(the missions of gMulleGlobals)
      end if
      if currentAnimChart = #TalkToMe then
        sendSprite(the currentSpriteNum, #setAnimChart, "Mulle")
      end if
      setAnimNormal(animObject)
      set tempMode to #Wait
    otherwise:
      set tempMode to #Wait
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
