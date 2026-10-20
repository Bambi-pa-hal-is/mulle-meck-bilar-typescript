property myMember, rectList, dialogActive, currentCursor, cursorNumber, SP, steerSP, soundList, sndId, oldType, sndDelay, counter, hasBeenOutside, wasShowing
global gDir, gSound

on beginSprite me
  set dialogActive to 0
  set sndDelay to 10
  set counter to 0
  set myMember to "19b001v0"
  set SP to the spriteNum of me
  set steerSP to SP + 1
  set myLoc to point(320, 200)
  set the loc of sprite SP to myLoc
  set the loc of sprite steerSP to myLoc
  set rectList to [#Steering: rect(116, 114, 197, 244), #Home: rect(216, 116, 281, 249), #Diploma: rect(316, 127, 368, 264), #quit: rect(390, 125, 460, 266), #Cancel: rect(470, 255, 528, 365)]
  set soundList to [#Home: "09d006v0", #Cancel: "09d004v0", #Steering: "09d005v0", #quit: "09d003v0", #Diploma: "09d002v0"]
  set diff to myLoc - point(320, 240)
  if not (diff = point(0, 0)) then
    set diff to rect(getAt(diff, 1), getAt(diff, 2), getAt(diff, 1), getAt(diff, 2))
    repeat with n = 1 to count(rectList)
      setAt(rectList, n, getAt(rectList, n) + diff)
    end repeat
  end if
end

on startMeUp me
  set the member of sprite SP to member(myMember)
  activate(gDir, 0)
  set dialogActive to 1
  set currentCursor to #Standard
  steerMode(me, #show)
  sendSprite(115, #MEnter, "c_standard", 2)
end

on closeMeDown me
  set the member of sprite SP to member("Dummy")
  set the member of sprite steerSP to member("Dummy")
  activate(gDir, 1)
  set dialogActive to 0
  sendSprite(115, #MLeave, 2)
  sendSprite(115, #MLeave)
  stop(gSound, sndId)
end

on exitFrame me
  if dialogActive then
    if wasShowing then
      activate(gDir, 0)
      set wasShowing to 0
    end if
    if counter then
      set counter to counter - 1
      if counter = 0 then
        stop(gSound, sndId)
        set sndId to play(gSound, getProp(soundList, oldType), #EFFECT)
      end if
    end if
    set isInside to 0
    repeat with X = 1 to count(rectList)
      if inside(point(the mouseH, the mouseV), getAt(rectList, X)) then
        set isInside to 1
        sendSprite(115, #MEnter, "c_click")
        set cursorNumber to X
        set tempType to getPropAt(rectList, X)
        set currentCursor to #click
        if not (oldType = tempType) then
          set hasBeenOutside to 0
          stop(gSound, sndId)
          set counter to sndDelay
          set oldType to tempType
        else
          if finished(gSound, sndId) and counter = 0 and hasBeenOutside then
            set hasBeenOutside to 0
            set counter to sndDelay
            set oldType to tempType
          end if
        end if
        exit repeat
      end if
    end repeat
    if not isInside then
      if finished(gSound, sndId) then
        set hasBeenOutside to 1
        set oldType to 0
      end if
      set counter to 0
      sendSprite(115, #MLeave)
      set currentCursor to #Standard
    end if
  end if
end

on steerMode me, theMode
  if objectp(the carDriving of gDir) then
    set tempSteer to the keySteer of the carDriving of gDir
    if theMode = #Change then
      set tempSteer to not tempSteer
      setKeySteer(gDir, tempSteer)
    end if
    if tempSteer then
      set the member of sprite steerSP to member("Dummy")
    else
      set the member of sprite steerSP to member("09b005v0")
    end if
  end if
end

on mouseUp me
  exitFrame(me)
  if currentCursor = #click then
    play(gSound, "SndMouseClick", #OPEFFECT)
    case cursorNumber of
      1:
        steerMode(me, #Change)
      2:
        prepareToLeave(gDir, "03")
      3:
        prepareToLeave(gDir, "08")
      4:
        go(1, "12")
      5:
        functionDialogSwitch(me)
    end case
  end if
end

on functionDialogSwitch me
  if dialogActive then
    closeMeDown(me)
  else
    set wasShowing to 0
    if the mode of gDir = #Showing then
      sendSprite(getProp(the spriteList of gDir, #ShowOff), #mouseUp)
      set wasShowing to 1
    end if
    startMeUp(me)
  end if
end
