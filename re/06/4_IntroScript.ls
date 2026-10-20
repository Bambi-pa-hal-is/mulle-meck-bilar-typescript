property counter, Path, SP, SPBG, nrOfSteps
global gDir, gSound

on new me
  set SP to getProp(the spriteList of gDir, #SmallCarStart)
  set SPBG to getProp(the spriteList of gDir, #PhotoBG)
  set the member of sprite SPBG to member("06b014v0")
  set endLoc to point(67, 401)
  set startLoc to point(67, 401)
  set nrOfSteps to 8
  set step to (endLoc - startLoc) / nrOfSteps
  set Path to []
  repeat with n = 1 to nrOfSteps
    add(Path, startLoc + step * n)
  end repeat
  set counter to 1
  loop(me)
  return me
end

on kill me
  deleteLoopObject(gDir, me)
  return 0
end

on loop me
  sendSprite(SP, #drawCar, VOID, getAt(Path, counter) + point(-25, 15), VOID, 0.5)
  set the loc of sprite SPBG to getAt(Path, counter)
  set counter to counter + 1
  if counter > nrOfSteps then
    kill(me)
  end if
end
