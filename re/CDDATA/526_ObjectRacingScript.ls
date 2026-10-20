property child, counter, insideInner, hiScores, saveName, fieldName, racing, delayCounter, fps, mustEnterFrom, nrOfTimesPassed, enteredFrom, thisTime, nrOfLetters
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  set insideInner to 0
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set nrOfLetters to 6
  set racing to 0
  set delayCounter to 0
  set fps to the frameTempo
  set nrOfTimesPassed to 0
  set mustEnterFrom to getaProp(the optionalData of child, #EnterDir)
  if voidp(mustEnterFrom) then
    set mustEnterFrom to 1
  end if
  set saveName to "CustomRacingDB"
  set fieldName to "CustomRacingField"
  if the number of member saveName = -1 then
    newMember(#field, saveName, "data")
    set hiScores to [186: "MIA M", 232: "FIGGE F"]
    set the text of member(saveName) to string(hiScores)
    if the machineType = 256 then
      set tempFont to "Arial"
      set tempSize to 20
    else
      set tempFont to "Helvetica"
      set tempSize to 24
    end if
    repeat with n = 1 to 2
      newMember(#field, fieldName & string(n), "data")
      set the boxType of member(fieldName & string(n)) to #fixed
      set the textFont of member (fieldName & string(n)) to tempFont
      set the textSize of member (fieldName & string(n)) to tempSize
      set the text of member(fieldName & string(n)) to " "
      set the textFont of member (fieldName & string(n)) to tempFont
      set the textSize of member (fieldName & string(n)) to tempSize
      set the rect of member(fieldName & string(n)) to rect(0, 0, 158, 20)
      set the foreColor of member (fieldName & string(n)) to 149
    end repeat
  else
    set hiScores to value(the text of member(saveName))
  end if
  sort(hiScores)
  set tempSP to the SPUnder of child
  set the member of sprite tempSP to member(getAt(getProp(getFrameList(child), #Board), 1))
  set tempLoc to getaProp(the optionalData of child, #Board)
  if voidp(tempLoc) then
    set tempLoc to point(0, 0)
  end if
  set the loc of sprite tempSP to tempLoc
  set the member of sprite tempSP + 1 to member(getAt(getProp(getFrameList(child), #Goal), 1))
  set the loc of sprite tempSP + 1 to the myLoc of child
  showTime(me)
  repeat with n = 1 to 2
    set the member of sprite tempSP + n + 1 to member(fieldName & string(n))
    set the loc of sprite tempSP + n + 1 to getaProp(the optionalData of child, #Board) + point(-75, -25) + point(0, 30) * (n - 1)
  end repeat
end

on step me, carLoc
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #Inner)
  if temp = #EnterInnerRadius then
    EnterInnerRadius(me, carLoc)
  else
    if temp = #ExitInnerRadius then
      ExitInnerRadius(me, carLoc)
    end if
  end if
  if racing then
    set counter to counter + 1
    set the text of member(fieldName & "1") to string(counter / fps) & ":" & string(10 * (counter mod fps) / fps) & "0"
  else
    if delayCounter then
      set delayCounter to delayCounter - 1
      if delayCounter mod 6 = 5 then
        set the text of member(fieldName & "1") to thisTime
      else
        if delayCounter mod 6 = 0 then
          set the text of member(fieldName & "1") to " "
        end if
      end if
      if delayCounter = 0 then
        showTime(me)
      end if
    end if
  end if
end

on showTime me
  repeat with n = 1 to 2
    set tempTime to string(getPropAt(hiScores, n) / 10) & ":" & string(getPropAt(hiScores, n) mod 10) & "0"
    set the text of member(fieldName & string(n)) to tempTime && char 1 to nrOfLetters of getAt(hiScores, n)
  end repeat
end

on enterOuterRadius me
end

on ExitOuterRadius me
end

on EnterInnerRadius me, carLoc
  set tempEnterAngl to calcDirection(the drivingHandlers of gDir, carLoc, the myLoc of child)
  set tempDiff to abs(mustEnterFrom - tempEnterAngl)
  if tempDiff > 8 then
    set tempDiff to 16 - tempDiff
  end if
  if tempDiff <= 3 then
    set enteredFrom to 1
    if racing then
      if nrOfTimesPassed = 1 then
        play(gSound, getAt(the sounds of child, 2), #EFFECT)
        addCompletedMission(the user of gMulleGlobals, getAt(getSetWhenDone(child, #missions), 1))
        set racing to 0
        set delayCounter to 24
        set tempTime to 10 * counter / fps
        set tempName to upperCase(gPathGlobals, getUserId(the user of gMulleGlobals))
        set thisTime to string(tempTime / 10) & ":" & string(tempTime mod 10) & "0" && char 1 to nrOfLetters of tempName
        setCacheProp(the car of the user of gMulleGlobals, #racing, tempTime)
        if tempTime < 150 then
          set medalId to getAt(getSetWhenDone(child, #medals), 1)
          if not getMedal(the car of the user of gMulleGlobals, medalId) then
            sendSprite(getProp(the spriteList of gDir, #medal), #Blink, medalId)
            addMedal(the car of the user of gMulleGlobals, medalId)
          end if
        end if
        if getPropAt(hiScores, count(hiScores)) >= tempTime then
          deleteAt(hiScores, count(hiScores))
          addProp(hiScores, tempTime, char 1 to nrOfLetters of tempName)
          set the text of member(saveName) to string(hiScores)
        end if
      end if
    else
      play(gSound, getAt(the sounds of child, 1), #EFFECT)
      set nrOfTimesPassed to 0
      set racing to 1
      set counter to 0
      repeat with n = 1 to 2
        set the text of member(fieldName & string(n)) to " "
      end repeat
    end if
  else
    set enteredFrom to -1
  end if
end

on ExitInnerRadius me, carLoc
  if racing then
    set tempEnterAngl to calcDirection(the drivingHandlers of gDir, carLoc, the myLoc of child)
    set tempDiff to abs(mustEnterFrom - tempEnterAngl)
    if tempDiff > 8 then
      set tempDiff to 16 - tempDiff
    end if
    if tempDiff <= 3 then
      if enteredFrom = -1 then
        set nrOfTimesPassed to nrOfTimesPassed - 1
      end if
    else
      if enteredFrom = 1 then
        set nrOfTimesPassed to nrOfTimesPassed + 1
      end if
    end if
  end if
end
