property partId, isFalling, floorLocV, SP, showMember, velV, velH, activeClick, loopcount, trackRect
global gDir, gMulleGlobals, gSound

on beginSprite me
  set SP to the spriteNum of me
  set isFalling to 0
  set velV to 0
  set velH to 0
  set activeClick to 1
  set loopcount to 0
end

on activateClick me, theState
  set activeClick to theState
end

on setPart me, thePartId, thePartLoc, theIsFalling, fallingFrom
  set isFalling to theIsFalling
  if thePartId = 0 then
    set the member of sprite SP to member("Dummy")
  else
    if isFalling then
      set the loc of sprite SP to fallingFrom
      set velV to 0
      set floorLocV to getAt(thePartLoc, 2)
    else
      set the loc of sprite SP to thePartLoc
    end if
    set velH to 30
    set partId to thePartId
    set part to getPart(the parts of gMulleGlobals, partId)
    set showMember to getJunkView(part)
    set the member of sprite SP to member(showMember)
  end if
end

on mouseDown me
  if activeClick then
    grabbedPart(the partsCommon of gDir, partId, #Floor)
  end if
end

on loop me
  set loopcount to loopcount + 1
  if loopcount = 2 then
    if the mouseDown = 0 then
    else
      grabbedPart(the partsCommon of gDir, partId, #Floor)
    end if
    set loopcount to 0
    deleteLoopObject(gDir, me)
  end if
end

on exitFrame me
  if isFalling then
    if the locV of sprite SP = floorLocV then
      set Hmax to getAt(getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #shopFloor), 1), 3)
      if the locH of sprite SP > Hmax then
        set the locH of sprite SP to Hmax
      end if
      set velV to 0
      set isFalling to 0
      if the playedDescription of the partsCommon of gDir = 0 then
        kickPartSound(the SharedSound of gMulleGlobals, SP, partId, #InternalGround)
      end if
      setJunkPartProp(the user of gMulleGlobals, #shopFloor, partId, point(getAt(the loc of sprite SP, 1), floorLocV))
    else
      if velV < 60 then
        set velV to velV + 8
      end if
      if velV + the locV of sprite SP < floorLocV then
        set the locV of sprite SP to velV + the locV of sprite SP
      else
        set the locV of sprite SP to floorLocV
      end if
    end if
  end if
end
