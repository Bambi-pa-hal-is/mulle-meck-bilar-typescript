property spriteList, nrOfSteps, nowAt, stepV, carSP, startV, spriteStartV, carStartV, carStartH, medalsStartV, medalsSP
global gMulleGlobals

on beginSprite me
  init(me)
end

on init me
  set spriteList to [#title: 55, #Signature: 56, #CarName: 59, #userName: 57, #to: 58, #LeftR: 60, #RightR: 61]
  set spriteStartV to [#CarName: 0, #userName: 0, #to: 0]
  repeat with n = 1 to count(spriteStartV)
    set tempProp to getPropAt(spriteStartV, n)
    setProp(spriteStartV, tempProp, 240 - the locV of sprite getProp(spriteList, tempProp))
  end repeat
  set carSP to 4
  set carStartV to 240 - the locV of sprite 4 + 7
  set carStartH to the locH of sprite 4 + 7
  set nrOfSteps to 3
  set nowAt to 1
  set totHeight to 812 - 300
  set stepV to totHeight / nrOfSteps
  set startV to 240 + nowAt * stepV
  set tempMembers to ["00n004v0", "00n005v0", "00n006v0", "00n007v0", "00n010v0", "00n009v0"]
  set tempText to ["08t001v0", "08t002v0", "08t003v0", "08t004v0", "08t005v0", "08t006v0"]
  set medalsSP to 63
  set medalsStartV to 200 - the locV of sprite medalsSP
  set tempStartH to 70
  set tempWidth to 90
  repeat with n = 1 to 6
    if getMedal(the car of the user of gMulleGlobals, n) then
      set the member of sprite medalsSP + n - 1 to member(getAt(tempMembers, n))
      set the member of sprite medalsSP + n - 1 + 6 to member(getAt(tempText, n))
      set the locH of sprite medalsSP + n - 1 to tempStartH + tempWidth * (n - 1)
      set the locH of sprite medalsSP + n - 1 + 6 to the locH of sprite medalsSP + n - 1 - 43
      next repeat
    end if
    set the member of sprite medalsSP + n - 1 to member("Dummy")
    set the member of sprite medalsSP + n - 1 + 6 to member("Dummy")
  end repeat
  show(me)
  updateStage()
end

on ScrollToMid me
  set nowAt to 2
  show(me)
end

on scroll me, theDirection
  if theDirection = -1 and nowAt > 1 then
    set nowAt to nowAt + theDirection
    show(me)
  else
    if theDirection = 1 and nowAt < nrOfSteps then
      set nowAt to nowAt + theDirection
      show(me)
    end if
  end if
end

on show me
  set tempV to startV - (nowAt - 1) * stepV
  repeat with n = 1 to count(spriteList)
    set tempOffset to getaProp(spriteStartV, getPropAt(spriteList, n))
    if voidp(tempOffset) then
      set tempOffset to 0
    end if
    set the locV of sprite getAt(spriteList, n) to tempV - tempOffset
  end repeat
  repeat with n = 1 to 6
    set the locV of sprite medalsSP + n - 1 to tempV - medalsStartV
    set the locV of sprite medalsSP + n - 1 + 6 to tempV - medalsStartV + 40
  end repeat
  sendSprite(carSP, #drawCar, VOID, point(carStartH, tempV - carStartV))
end
