property reportObject, carOffset, dragPartFromWhere, tracking
global gDir, gMulleGlobals

on new me, theReportObject
  set tracking to 0
  set reportObject to theReportObject
  set chassisNr to the chassisSPOffset of the carCopy of gDir
  set carOffset to the loc of sprite getProp(the spriteList of gDir, #CarStart) + chassisNr
  return me
end

on grabbedPart me, thePartId
  set tracking to 1
  put "in grabbpart"
  sendAllSprites(#forcePart)
  removeJunkPart(the user of gMulleGlobals, #yard, thePartId)
  sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
  sendSprite(getProp(the spriteList of gDir, #drag), #startDrag, thePartId, "floor", 0)
end

on letGoOfPart me, thePartId, where, onDoorWhere
  if symbolp(where) then
    if getaProp(the maxParts of the junkPileHandlers of gMulleGlobals, #shopFloor) <= count(getaProp(getaProp(the user of gMulleGlobals, #junk), #shopFloor)) then
      if the carOnYard of gDir then
        sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #shopFull)
      else
        sendSprite(getaProp(the spriteList of gDir, #mulleStand), #MakeMulleSpeak, #shopFull)
      end if
      addJunkPart(the user of gMulleGlobals, #yard, thePartId, onDoorWhere)
    else
      kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #ExternalGround)
      addJunkPart(the user of gMulleGlobals, #shopFloor, thePartId)
      sendSprite(115, #C_Right)
    end if
  else
    set tmp to checkPos(me, thePartId, where)
    if tmp = 1 then
      put "kick tmppos= TRUE"
      kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #InternalGround)
    end if
    if getAt(where, 2) > getAt(getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1), 4) then
      addJunkPart(the user of gMulleGlobals, #yard, thePartId)
      put "kick 22"
      kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #InternalGround)
      set isFalling to 0
    else
      addJunkPart(the user of gMulleGlobals, #yard, thePartId, where)
    end if
  end if
  sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
  set tracking to 0
end

on checkPos me, thePartId, thePartLoc
  set partId to thePartId
  set part to getPart(the parts of gMulleGlobals, partId)
  set showMember to getJunkView(part)
  set checkRect to getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1)
  set tempLocH to getAt(thePartLoc, 1)
  if tempLocH > 640 then
    set tempLocH to 640
  end if
  set tempOffsetV to getAt(the rect of member(showMember), 4) / 2
  set floorLocV to 460 - tempOffsetV
  set tempLocV to getAt(thePartLoc, 2)
  if not inside(thePartLoc, getAt(getaProp(the rects of the junkPileHandlers of gMulleGlobals, #yard), 1)) then
    set r to 0
  else
    set r to 1
  end if
  return r
end

on freeOrBindParts me
  set freeParts to []
  set boundParts to []
  set parts to getParts(the carCopy of gDir)
  repeat with n = 2 to count(parts)
    set part to getPart(the parts of gMulleGlobals, getAt(parts, n))
    set newPoints to getNewPoints(part)
    if listp(newPoints) then
      set tempList to []
      repeat with index in newPoints
        add(tempList, getAt(index, 1))
      end repeat
      if areTheseFree(the carCopy of gDir, tempList) then
        add(freeParts, part)
      else
        add(boundParts, part)
      end if
      next repeat
    end if
    add(freeParts, part)
  end repeat
  repeat with index in freeParts
    set snapPoint to getAt(getCoveredPoints(index), 1)
    set layer to getAt(getSnapInfo(the carCopy of gDir, snapPoint, #layers), 1)
    if layer > 0 then
      sendSprite(getProp(the spriteList of gDir, #CarStart) + layer, #activate, 1)
    end if
  end repeat
  repeat with index in boundParts
    set snapPoint to getAt(getCoveredPoints(index), 1)
    set layer to getAt(getSnapInfo(the carCopy of gDir, snapPoint, #layers), 1)
    if layer > 0 then
      sendSprite(getProp(the spriteList of gDir, #CarStart) + layer, #activate, 0)
    end if
  end repeat
end

on kill me
  return 0
end
