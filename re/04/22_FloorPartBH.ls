property partId, isFalling, floorLocV, SP, showMember, velV, activeClick, velH, loopcount, puttingBack, nrOfMoveSteps, xDiff, yDiff
global gDir, gMulleGlobals, gSound

on beginSprite me
  set SP to the spriteNum of me
  set isFalling to 0
  set velV to 0
  set velH to 0
  set activeClick to 1
  set nrOfMoveSteps to 14
end

on activateClick me, theState
  set activeClick to theState
end

on setPart me, thePartId, thePartLoc
  set isFalling to 0
  if thePartId = 0 then
    set the member of sprite SP to member("Dummy")
  else
    set partId to thePartId
    set part to getPart(the parts of gMulleGlobals, partId)
    set showMember to getJunkView(part)
    set the member of sprite SP to member(showMember)
    set tempLocH to getAt(thePartLoc, 1)
    if tempLocH < 290 then
      set velH to 20
    else
      if tempLocH > 640 then
        set tempLocH to 640
      end if
    end if
    set tempOffsetV to getAt(the rect of member(showMember), 4) / 2
    set floorLocV to 460 - tempOffsetV
    set tempLocV to getAt(thePartLoc, 2)
    set rect to getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1)
    if tempLocV < getAt(rect, 2) or tempLocH < 290 then
      put "isfalling1 + id", thePartId
      set isFalling to 1
      set velV to 0
      set tempNewLocV to floorLocV
      set the loc of sprite SP to point(tempLocH, tempLocV)
    else
      if tempLocV > floorLocV + 2 * tempOffsetV then
        set tempNewLocV to floorLocV + 2 * tempOffsetV
        set the loc of sprite SP to point(tempLocH, tempNewLocV)
      else
        set tempNewLocV to tempLocV
        set the loc of sprite SP to point(tempLocH, tempNewLocV)
      end if
    end if
    setJunkPartProp(the user of gMulleGlobals, #yard, partId, point(tempLocH, tempNewLocV))
  end if
end

on mouseDown me
  if activeClick then
    grabbedPart(the partsCommon of gDir, partId, #Floor)
  end if
end

on exitFrame me
  if isFalling then
    if the locV of sprite SP >= getAt(getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1), 2) then
      set Hmax to getAt(getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1), 3)
      if the locH of sprite SP < 290 then
        set the locH of sprite SP to velH + the locH of sprite SP
      else
        if the locH of sprite SP > Hmax then
          set the locH of sprite SP to Hmax
        else
          set velV to 0
          set newPoint to the loc of sprite SP
          set isFalling to 0
          kickPartSound(the SharedSound of gMulleGlobals, SP, partId, #InternalGround)
          setJunkPartProp(the user of gMulleGlobals, #yard, partId, newPoint)
        end if
      end if
    else
      if velV < 30 then
        set velV to velV + 8
      end if
      set the locV of sprite SP to velV + the locV of sprite SP
      if the locH of sprite SP < 290 then
        set the locH of sprite SP to velH + the locH of sprite SP
      end if
    end if
  end if
end

on forcePart me
  if isFalling then
    set tempNewPos to setPartPosition(the junkPileHandlers of gMulleGlobals, #yard, partId)
    put "kick in force"
    kickPartSound(the SharedSound of gMulleGlobals, SP, partId, #InternalGround)
    set the loc of sprite the spriteNum of me to tempNewPos
    setJunkPartProp(the user of gMulleGlobals, #yard, partId, tempNewPos)
  end if
end
