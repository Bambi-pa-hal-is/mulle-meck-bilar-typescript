property startLoc, endLoc, frameMovement, frameCount, nrOfFrames
global gMulleGlobals, gDir, gSound

on beginSprite me
  set startLoc to point(600, 230)
  set endLoc to point(-25, 300)
  set frameMovement to (startLoc - endLoc) / 12
  set frameCount to 0
  set nrOfFrames to 3
  set the loc of sprite the spriteNum of me to startLoc
end

on runMikro me
  set the member of sprite the spriteNum of me to "03a009v0"
  set the loc of sprite the spriteNum of me to startLoc
  updateStage()
  play(gSound, "MikroCar", #EFFECT)
  addLoopObject(gDir, me)
end

on loop me
  set frameCount to frameCount + 1
  if frameCount < nrOfFrames then
    set the member of sprite the spriteNum of me to the memberNum of sprite the spriteNum of me + 1
  else
    set the member of sprite the spriteNum of me to "03a009v0"
    set frameCount to 0
  end if
  updateStage()
  if getAt(the loc of sprite the spriteNum of me, 1) - getAt(endLoc, 1) > 0 then
    set newLoc to point(getAt(the loc of sprite the spriteNum of me, 1) - getAt(frameMovement, 1), getAt(the loc of sprite the spriteNum of me, 2) - getAt(frameMovement, 2))
    set the loc of sprite the spriteNum of me to newLoc
  else
    set frameCount to 0
    deleteLoopObject(gDir, me)
    go("04")
  end if
end
