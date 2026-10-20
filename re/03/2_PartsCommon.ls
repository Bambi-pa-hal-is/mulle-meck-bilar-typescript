property reportObject, carOffset, dragPartFromWhere, mulleLayer, waitin, trackRect, tracking, playedDescription, tmpId
global gDir, gMulleGlobals, gSound

on new me, theReportObject
  set waitin to 0
  set reportObject to theReportObject
  set chassisNr to the chassisSPOffset of the carCopy of gDir
  set carOffset to the loc of sprite getProp(the spriteList of gDir, #CarStart) + chassisNr
  set mulleLayer to the driverLayer of the car of the user of gMulleGlobals
  set trackRect to 0
  set tracking to 0
  set tmpId to 0
  return me
end

on grabbedPart me, thePartId, fromWhere
  sendSprite(getaProp(the spriteList of gDir, #fButton), #activateClick, 0)
  set dragPartFromWhere to fromWhere
  if fromWhere = #car then
    clearCar(the car of the user of gMulleGlobals)
    deletePart(the carCopy of gDir, thePartId)
    rebuild(the carCopy of gDir)
    set part to getPart(the parts of gMulleGlobals, thePartId)
    set tempMaster to getMaster(part)
    if tempMaster then
      set thePartId to tempMaster
    end if
    kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #car)
  else
    if fromWhere = #Floor then
      removeJunkPart(the user of gMulleGlobals, #shopFloor, thePartId)
    end if
  end if
  set snapRects to generateSnapRects(me, thePartId)
  set tmpCurrentLoc to point(the mouseH, the mouseV)
  if fromWhere = #car then
    set pixDecrease to 25
    repeat with n = 1 to count(snapRects)
      if inside(tmpCurrentLoc, getAt(snapRects, n)) then
        set oldrect to getAt(snapRects, n)
        set newrect to rect(getAt(oldrect, 1) + pixDecrease, getAt(oldrect, 2) - pixDecrease, getAt(oldrect, 3) - pixDecrease, getAt(oldrect, 4) - pixDecrease)
        setAt(snapRects, n, newrect)
      end if
    end repeat
  end if
  sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
  sendSprite(getProp(the spriteList of gDir, #drag), #startDrag, thePartId, fromWhere, snapRects)
  set trackRect to rect(the mouseH - 2, the mouseV - 2, the mouseH + 2, the mouseV + 2)
  set tracking to 1
end

on generateSnapRects me, thePartId
  set part to getPart(the parts of gMulleGlobals, thePartId)
  if voidp(part) then
    alert("no file for part " & string(thePartId))
  end if
  set tempMaster to getMaster(part)
  if tempMaster then
    set part to getPart(the parts of gMulleGlobals, tempMaster)
  end if
  set tempMorph to getMorphList(part)
  if listp(tempMorph) then
    if count(tempMorph) > 0 then
      set partList to tempMorph
    else
      set partList to [getId(part)]
    end if
  else
    set partList to [getId(part)]
  end if
  set freeList to []
  set snapOffsets to []
  repeat with partId in partList
    set Required to getRequiredPoints(getPart(the parts of gMulleGlobals, partId))
    if areTheseFree(the carCopy of gDir, Required) then
      add(freeList, partId)
      set whichSnap to getAt(Required, 1)
      add(snapOffsets, getSnapInfo(the carCopy of gDir, whichSnap, #offset))
    end if
  end repeat
  set snapRects to [:]
  set rectSize to 40
  repeat with n = 1 to count(freeList)
    set partId to getAt(freeList, n)
    set snapOffset to getAt(snapOffsets, n)
    set part to getPart(the parts of gMulleGlobals, partId)
    set tempMembers to [getUseView(part)]
    set tempBackMember to getUseView2(part)
    set tempOffset to getOffset(part)
    if voidp(getAt(tempOffset, 1)) then
      next repeat
    end if
    if stringp(tempBackMember) then
      if length(tempBackMember) > 0 then
        add(tempMembers, tempBackMember)
      end if
    end if
    set drawCheatVar to 1
    repeat with index in tempMembers
      set tempRect to the rect of member(index)
      set midPoint to point(getAt(tempRect, 3) / 2, getAt(tempRect, 4) / 2)
      set midPoint to midPoint - the regPoint of member(index)
      set midPoint to midPoint + carOffset + tempOffset + snapOffset
      set drawCheatVar to 0
      set tempSnap to rect(getAt(midPoint, 1) - rectSize, getAt(midPoint, 2) - rectSize, getAt(midPoint, 1) + rectSize, getAt(midPoint, 2) + rectSize)
      addProp(snapRects, partId, tempSnap)
    end repeat
  end repeat
  if the currentTalk of sprite(getaProp(the spriteList of gDir, #Mulle)) = #noPoints then
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #waitForProtest, 0, #Cut)
  end if
  if snapRects = [:] then
    if waitin = 0 then
      set waitin to 1
      sendSprite(getaProp(the spriteList of gDir, #Mulle), #waitForProtest, 1)
    end if
  end if
  return snapRects
end

on drawcheat me, thePoint
  set tmpstart to getProp(the spriteList of gDir, #cheatStart)
  if thePoint <> 0 then
    repeat while the name of member(the member of sprite tmpstart) <> "Dummy"
      set tmpstart to tmpstart + 1
    end repeat
    set the member of sprite tmpstart to "helpDot"
    set the loc of sprite tmpstart to thePoint
  else
    repeat while the name of member(the member of sprite tmpstart) <> "Dummy"
      set the member of sprite tmpstart to "Dummy"
      set the loc of sprite tmpstart to point(-100, -100)
      set tmpstart to tmpstart + 1
    end repeat
  end if
end

on showUseView me, partId, YesNo
  put "in showUseView with: ", partId
  set part to getPart(the parts of gMulleGlobals, partId)
  set whichSnap to getAt(getRequiredPoints(part), 1)
  set layers to getSnapInfo(the carCopy of gDir, whichSnap, #layers)
  set snapOffset to getSnapInfo(the carCopy of gDir, whichSnap, #offset)
  if YesNo then
    set memberList to [getUseView(part), getUseView2(part)]
    set offset to getOffset(part)
  else
    set partId to 0
    set memberList to ["Dummy", "Dummy"]
    set offset to point(0, 0)
  end if
  repeat with n = 1 to count(layers)
    set layer to getAt(layers, n)
    if layer >= -1 and length(getAt(memberList, n)) > 0 then
      if layer > mulleLayer - 1 then
        set layer to layer + 2
      end if
      set tempSP to getProp(the spriteList of gDir, #CarStart) + layer
      set the member of sprite tempSP to member(getAt(memberList, n))
      set the loc of sprite tempSP to carOffset + offset + snapOffset
      sendSprite(tempSP, #setPart, partId)
    end if
  end repeat
end

on letGoOfPart me, thePartId, where
  set playedDescription to 0
  if dragPartFromWhere = #Floor then
    if tracking and inside(point(the mouseH, the mouseV), trackRect) then
      if the currentTalk of sprite(getaProp(the spriteList of gDir, #Mulle)) <> #noPoints and thePartId <> tmpId then
        set tmpId to thePartId
        set snd to getDescription(getPart(the parts of gMulleGlobals, thePartId))
        sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #Describe, snd)
      end if
      set playedDescription to 1
    end if
  end if
  set tracking to 0
  sendSprite(getaProp(the spriteList of gDir, #fButton), #activateClick, 1)
  if waitin = 1 then
    set waitin to 0
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #waitForProtest, 0, #noCut)
  end if
  set shallCheckFree to 1
  set isFalling to 0
  if where = #car then
    clearCar(the car of the user of gMulleGlobals)
    addPart(the carCopy of gDir, thePartId)
  else
    if symbolp(where) then
      kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #ExternalGround)
      sendSprite(115, #c_click)
      addJunkPart(the user of gMulleGlobals, 0, thePartId, 0)
    else
      if dragPartFromWhere = #Floor then
        set shallCheckFree to 0
      end if
      set temp to correctPosition(the junkPileHandlers of gMulleGlobals, thePartId, where)
      set isFalling to getAt(temp, 2)
      if isFalling = 0 then
        kickPartSound(the SharedSound of gMulleGlobals, 0, thePartId, #InternalGround)
      end if
      addJunkPart(the user of gMulleGlobals, #shopFloor, thePartId, getAt(temp, 1))
    end if
  end if
  sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk, isFalling, where)
  sendSprite(getaProp(the spriteList of gDir, #Mulle), #checkEquipment, #none)
  if shallCheckFree then
    freeOrBindParts(me)
  end if
  drawcheat(me, 0)
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
    set snapPoint to getAt(getRequiredPoints(index), 1)
    repeat with n = 1 to 2
      set layer to getAt(getSnapInfo(the carCopy of gDir, snapPoint, #layers), n)
      if layer > mulleLayer - 1 then
        set layer to layer + 2
      end if
      if layer > -1 then
        sendSprite(getProp(the spriteList of gDir, #CarStart) + layer, #activate, 1)
      end if
    end repeat
  end repeat
  repeat with index in boundParts
    set snapPoint to getAt(getRequiredPoints(index), 1)
    repeat with n = 1 to 2
      set layer to getAt(getSnapInfo(the carCopy of gDir, snapPoint, #layers), n)
      if layer > mulleLayer - 1 then
        set layer to layer + 2
      end if
      if layer > -1 then
        sendSprite(getProp(the spriteList of gDir, #CarStart) + layer, #activate, 0)
      end if
    end repeat
  end repeat
end

on kill me
  return 0
end
