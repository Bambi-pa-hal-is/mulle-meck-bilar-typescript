property myCastmember, myCast, rectList, dialogActive, currentCursor, cursoRect, cursorNumber, currentSound, loopcount, soundToKick
global gDir, gMulleGlobals, gSound

on prepareSprite me
  functionDialogOff(me)
end

on startMeUp me
  put member(myCastmember, myCast)
  set the member of sprite the currentSpriteNum to member(myCastmember, myCast)
  activate(gDir, 0)
  set dialogActive to 1
  put "starting up"
  set currentCursor to "normal"
  set currentSound to EMPTY
  set loopcount to 0
  set rectList to [rect(161, 129, 247, 263), rect(279, 136, 340, 263), rect(371, 135, 443, 263), rect(465, 204, 521, 310)]
end

on closeMeDown me
  set the member of sprite the currentSpriteNum to member("Dummy")
  activate(gDir, 1)
  set dialogActive to 0
end

on exitFrame me
  if dialogActive then
    if currentCursor = "normal" then
      repeat with X = 1 to count(rectList)
        if inside(point(the mouseH, the mouseV), getAt(rectList, X)) then
          sendSprite(115, #c_click)
          set cursoRect to getAt(rectList, X)
          set cursorNumber to X
          set currentCursor to "click"
          addLoopObject(gDir, me)
          case X of
            1:
              set soundToKick to "09d001v0"
            2:
              set soundToKick to "09d002v0"
            3:
              set soundToKick to "09d003v0"
            4:
              set soundToKick to "09d004v0"
          end case
        end if
      end repeat
    else
      if not inside(point(the mouseH, the mouseV), cursoRect) then
        sendSprite(115, #C_Standard)
        set currentCursor to "normal"
        if soundToKick <> EMPTY then
          stop(gSound, currentSound)
          deleteLoopObject(gDir, me)
          set soundToKick to EMPTY
        end if
      end if
    end if
  end if
end

on loop me
  set loopcount to loopcount + 1
  if loopcount = 10 then
    set currentSound to play(gSound, soundToKick, #EFFECT)
    deleteLoopObject(gDir, me)
    set loopcount to 0
  end if
end

on mouseUp me
  if currentCursor = "click" then
    if soundToKick <> EMPTY then
      stop(gSound, currentSound)
      deleteLoopObject(gDir, me)
      set soundToKick to EMPTY
    end if
    play(gSound, "SndMouseClick", #EFFECT)
    case cursorNumber of
      "1":
        set thisMovie to chars(the movie, 1, 2)
        trash(the car of the user of gMulleGlobals)
        if thisMovie = "03" then
          repeat with n = getProp(the spriteList of gDir, #CarStart) to getProp(the spriteList of gDir, #CarStart) + 35
            if n <> getProp(the spriteList of gDir, #CarStart) + 7 then
              set the member of sprite n to "dummy"
            end if
          end repeat
          updateStage()
        end if
        if the nrOfBuiltCars of the user of gMulleGlobals = 0 then
          set list to [82, 133, 152]
        else
          if the nrOfBuiltCars of the user of gMulleGlobals = 1 then
            set list to [82, 152]
          else
            if the nrOfBuiltCars of the user of gMulleGlobals = 2 then
              set list to [82]
            else
              set list to []
            end if
          end if
        end if
        repeat with n = 1 to count(list)
          addPart(the car of the user of gMulleGlobals, getAt(list, n))
        end repeat
        if thisMovie = "03" then
          repeat with n = getProp(the spriteList of gDir, #JunkStart) to getProp(the spriteList of gDir, #JunkStart) + 35
            set the member of sprite n to "dummy"
          end repeat
        end if
        repeat with n = 1 to count(list)
          put "sendin id ", getAt(list, n)
          put "from login"
          removeJunkPart(the user of gMulleGlobals, VOID, getAt(list, n))
        end repeat
        if thisMovie = "03" then
          sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
          sendSprite(getProp(the spriteList of gDir, #CarStart), #drawCar)
          updateStage()
          if count(list) = 3 then
            sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #AfterTrash3)
          else
            if count(list) = 2 then
              sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #AfterTrash2)
            else
              if count(list) = 1 then
                sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #AfterTrash1)
              else
                if count(list) = 0 then
                  sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #afterTrash0)
                end if
              end if
            end if
          end if
          put "cursorNumber ", cursorNumber
          put "in dialog"
          functionDialogSwitch(me)
        else
          set the WhereFrom of gMulleGlobals to char 1 to 2 of the movie
          functionDialogSwitch(me)
          updateStage()
          go(1, "03")
        end if
      "2":
        set the WhereFrom of gMulleGlobals to char 1 to 2 of the movie
        go("08")
      "3":
        go("12")
      "4":
        functionDialogSwitch(me)
    end case
  end if
end

on functionDialogSwitch me
  if the member of sprite the currentSpriteNum = member(myCastmember, myCast) then
    put "startcall"
    set cursorNumber to "0"
    closeMeDown(me)
  else
    startMeUp(me)
  end if
end

on functionDialogOff me
  set the visible of sprite the currentSpriteNum to 0
end

on getPropertyDescriptionList
  set p_list to [#myCastmember: [#comment: "Which castmember:", #format: #string, #default: EMPTY], #myCast: [#comment: "of which cast:", #format: #string, #default: EMPTY]]
  return p_list
end
