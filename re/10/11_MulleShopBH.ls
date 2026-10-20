property type, mode, animObject, randomSounds, leadSounds, CarEquipment, activeClick, aboutToOpen, FrozenAction, makeHimLeave, startSounds, okSounds, greatSounds, currentSound, loopcount, currentTalk, currentAnimChart
global gDir, gMulleGlobals, gSound

on beginSprite me
  set type to #Mulle
  set mode to #Wait
  set currentAnimChart to #Verkstad
  set currentTalk to #Silence
  set startSounds to ["03d027v0"]
  set okSounds to ["03d034v0", "03d035v0", "03d036v0"]
  set greatSounds to ["03d037v0", "03d038v0"]
  set currentSound to "start"
  set randomSounds to startSounds
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  repeat with index in tempList
    if the type of index = #SpriteAnim then
      set animObject to index
    end if
  end repeat
  set activeClick to 1
  set aboutToOpen to 0
  set makeHimLeave to 0
  set FrozenAction to EMPTY
end

on activateClick me, theState
  set activeClick to theState
end

on exitFrame me
  if currentTalk = #Silence then
    if activeClick then
      if mode = #Wait then
        if getAnimWaitState(animObject) = #Still then
          if random(135) = 1 then
            randomMove(me, 3)
          end if
        end if
      end if
    end if
  end if
end

on removeLoop me
  deleteLoopObject(gDir, me)
end

on waitForProtest me, YesNo, extraInfo
  if YesNo = 1 then
    set currentSound to "nothing"
    set activeClick to 0
    deleteLoopObject(gDir, me)
    addLoopObject(gDir, me)
    set loopcount to 0
  else
    set activeClick to 1
    deleteLoopObject(gDir, me)
    set loopcount to 0
    if extraInfo = #Cut then
      if mode = #Talk then
        set the waitin of the partsCommon of gDir to 0
        sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 1)
        sendSprite(the spriteNum of me, #setAnimAction, #Wait)
        stopAllEffects(gSound)
      end if
    end if
  end if
end

on loop me
  if currentSound = "nothing" then
    if loopcount = 14 then
      set activeClick to 1
      deleteLoopObject(gDir, me)
      set loopcount to 0
      if mode = #Talk or mode = #Wait then
        MakeMulleSpeak(me, #noPoints)
      end if
    else
      set loopcount to loopcount + 1
    end if
  else
    if currentSound = "start" then
      if the frame = 2 then
        deleteLoopObject(gDir, me)
        MakeMulleSpeak(me, FrozenAction)
      end if
    else
      if finished(gSound, currentSound) and mode = #Wait then
        if mode <> #Work and mode <> #GoTable and mode <> #GoBack then
          set mode to #Wait
          sendSprite(the spriteNum of me, #setAnimAction, mode)
        end if
        deleteLoopObject(gDir, me)
      end if
    end if
  end if
end

on MakeMulleSpeak me, theAction, extraInfo
  set currentTalk to theAction
  put "in make mulle speak ", theAction
  if the frame = 1 then
    set FrozenAction to theAction
    addLoopObject(gDir, me)
  else
    if finished(gSound, currentSound) then
      playAnimSound(animObject, EMPTY)
      if theAction = #noWheels then
        set theSnd to "03d011v0"
      else
        if theAction = #noSeat then
          set theSnd to "03d039v0"
        else
          if theAction = #yourTurn then
            set theSnd to "03d028v0"
          else
            if theAction = #fullPile then
              set theSnd to "03d033v0"
            else
              if theAction = #greetFigge then
                set makeHimLeave to 1
                set theSnd to "03d045v0"
              else
                if theAction = #noPoints then
                  case random(3) of
                    1:
                      set theSnd to "03d040v0"
                    2:
                      set theSnd to "03d041v0"
                    3:
                      set theSnd to "03d042v0"
                  end case
                else
                  if theAction = #InspireYou then
                    case random(5) of
                      1:
                        set theSnd to "03d052v0"
                      2:
                        set theSnd to "03d053v0"
                      3:
                        set theSnd to "03d054v0"
                      4:
                        set theSnd to "03d055v0"
                      5:
                        set theSnd to "03d056v0"
                    end case
                  else
                    if theAction = #Describe then
                      put "ExtraInfo", extraInfo
                      set theSnd to extraInfo
                    else
                      if theAction = #afterTrash0 then
                        set theSnd to "03d031v0"
                      else
                        if theAction = #AfterTrash1 then
                          set theSnd to "03d030v0"
                        else
                          if theAction = #AfterTrash2 then
                            set theSnd to "03d029v0"
                          else
                            if theAction = #AfterTrash3 then
                              set theSnd to "03d028v0"
                            end if
                          end if
                        end if
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
      if mode = #Wait or mode = #Talk then
        makeAnimSpeech(animObject, theSnd)
        if theAction = #noPoints then
          set tempMode to #Talk
          set currentAnimChart to #TalkToMe
          sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
        else
          if theAction = #greetFigge then
            set tempMode to #Talk
          else
            if random(2) = 1 then
              set tempMode to #Talk
            else
              set tempMode to #Talk
              set currentAnimChart to #TalkToMe
              sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
            end if
          end if
        end if
        set mode to tempMode
        sendSprite(the spriteNum of me, #setAnimAction, mode)
        set currentSound to 0
      else
        if mode <> #LookUnderCar then
          deleteLoopObject(gDir, me)
          set currentSound to play(gSound, theSnd, #EFFECT)
          addLoopObject(gDir, me)
        end if
      end if
    end if
  end if
end

on randomMove me, maxRnd
  if mode = #Wait then
    set tempMode to 0
    case random(maxRnd) of
      1:
        if randomSounds <> [] then
          sendSprite(the currentSpriteNum, #setAnimFirstFrame, "00a001v0")
          sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 0)
          if random(2) = 1 then
            set tempMode to #Talk
          else
            set tempMode to #Talk
            set currentAnimChart to #TalkToMe
            sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
          end if
          set theSnd to getAt(randomSounds, random(count(randomSounds)))
          makeAnimSpeech(animObject, theSnd)
          set mode to tempMode
        end if
      2:
        sendSprite(the currentSpriteNum, #setAnimFirstFrame, "00a001v0")
        set tempMode to #LookUnderCar
        set mode to tempMode
      3:
        sendSprite(the currentSpriteNum, #setAnimFirstFrame, "03a003v0")
        set tempMode to #GoTable
        set mode to tempMode
    end case
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  end if
end

on checkEquipment me, Specific
  if Specific <> 0 then
    if Specific = #wheels then
      if areTheseFree(the carCopy of gDir, [#a1]) = 1 or areTheseFree(the carCopy of gDir, [#a13]) = 1 then
        return 1
      else
        return 0
      end if
    else
      if Specific = #Seat then
        if getaProp(the carProperties of the carCopy of gDir, #Comfort) = 0 then
          return 1
        else
          return 0
        end if
      end if
    end if
  else
    updateProperties(the car of the user of gMulleGlobals)
    set leadSounds to []
    if count(the parts of the carCopy of gDir) >= 12 then
      set randomSounds to greatSounds
    else
      if count(the parts of the carCopy of gDir) >= 8 then
        set randomSounds to okSounds
      else
        set randomSounds to startSounds
      end if
    end if
    if areTheseFree(the carCopy of gDir, [#a1]) = 0 and areTheseFree(the carCopy of gDir, [#a13]) = 0 then
      add(leadSounds, "03d005v0")
      add(leadSounds, "03d006v0")
      add(leadSounds, "03d007v0")
    else
      if areTheseFree(the carCopy of gDir, [#a1]) = 1 or areTheseFree(the carCopy of gDir, [#a13]) = 1 then
        add(leadSounds, "03d011v0")
        add(leadSounds, "03d012v0")
      end if
    end if
    if getaProp(the carProperties of the carCopy of gDir, #break) = 0 then
      add(leadSounds, "03d018v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #FuelConsumption) = 0 then
      add(leadSounds, "03d013v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #ElectricVolume) = 0 then
      add(leadSounds, "03d014v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #FuelVolume) = 0 then
      add(leadSounds, "03d015v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #acceleration) = 0 then
      add(leadSounds, "03d016v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #Steering) = 0 then
      add(leadSounds, "03d017v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #Horn) = 0 then
      add(leadSounds, "03d019v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #ExhaustPipe) = 0 then
      add(leadSounds, "03d020v0")
    end if
    if getaProp(the carProperties of the carCopy of gDir, #Lamps) = 0 then
      add(leadSounds, "03d021v0")
    end if
  end if
end

on mouseUp me
  if activeClick then
    if mode = #Wait then
      sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 0)
      put "Settin mode in mouseup"
      if random(2) = 1 then
        set tempMode to #Talk
      else
        set tempMode to #Talk
        set currentAnimChart to #TalkToMe
        sendSprite(the currentSpriteNum, #setAnimChart, "TalkToMe")
      end if
      set mode to tempMode
      set theSnd to getAt(leadSounds, random(count(leadSounds)))
      makeAnimSpeech(animObject, theSnd)
      sendSprite(the spriteNum of me, #setAnimAction, mode)
    end if
  end if
end

on mouseEnter me
  sendSprite(getaProp(the spriteList of gDir, #DoorToYard), #resizeRect, 1)
end

on mouseLeave
  sendSprite(getaProp(the spriteList of gDir, #DoorToYard), #resizeRect, 0)
end

on Stopped me
  case mode of
    #OpenDoor:
      play(gSound, "02e016v0", #EFFECT)
      set the member of sprite getaProp(the spriteList of gDir, #garage) to the memberNum of sprite getaProp(the spriteList of gDir, #garage) + 1
      set the member of sprite getaProp(the spriteList of gDir, #Mulle) to the memberNum of sprite getaProp(the spriteList of gDir, #Mulle) + 1
      sendSprite(getaProp(the spriteList of gDir, #Mikro), #runMikro)
      updateStage()
      updateProperties(the car of the user of gMulleGlobals)
      set tempMode to #Still
      sendSprite(the currentSpriteNum, #setAnimFirstFrame, "freeze")
      set the toYardThroughDoor of the user of gMulleGlobals to 0
    #GoTable:
      set tempMode to #Work
    #Work:
      if random(8) = 1 then
        set tempMode to #GoBack
      else
        set tempMode to #Work
      end if
    #Talk:
      if makeHimLeave then
        sendSprite(getaProp(the spriteList of gDir, #Figge), #FiggeLeave)
        set makeHimLeave to 0
      end if
      if currentAnimChart = #TalkToMe then
        sendSprite(the currentSpriteNum, #setAnimChart, "Verkstad")
      end if
      setAnimNormal(animObject)
      set tempMode to #Wait
      set currentTalk to #Silence
      set the waitin of the partsCommon of gDir to 0
    #LookUnderCar:
      set tempMode to #Wait
    otherwise:
      set tempMode to #Wait
      sendSprite(the currentSpriteNum, #setAnimFirstFrame, "00a001v0")
  end case
  sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 1)
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
