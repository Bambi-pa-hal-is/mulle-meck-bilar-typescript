property shopFloorRect, nrOfPiles, rects, maxParts, figgeBeenHere
global gMulleGlobals, gDir

on new me
  set nrOfPiles to 6
  set maxParts to [#Pile1: 50, #Pile2: 50, #Pile3: 50, #Pile4: 50, #Pile5: 50, #Pile6: 50, #shopFloor: 15, #yard: 20]
  set rects to [#Pile1: [rect(193, 260, 637, 400), rect(291, 193, 637, 263), rect(361, 153, 636, 194)], #Pile2: [rect(210, 252, 654, 380), rect(256, 174, 651, 262), rect(365, 120, 667, 188)], #Pile3: [rect(150, 281, 639, 380), rect(127, 162, 643, 291), rect(183, 100, 639, 164)], #Pile4: [rect(0, 324, 425, 404), rect(3, 174, 425, 325), rect(3, 90, 425, 182)], #Pile5: [rect(6, 268, 450, 412), rect(5, 180, 411, 275), rect(0, 100, 303, 189)], #Pile6: [rect(0, 275, 400, 390), rect(1, 201, 368, 283), rect(4, 135, 270, 203)], #shopFloor: [rect(20, 400, 600, 460)], #yard: [rect(290, 400, 580, 445)], #PileDoors: [rect(8, 106, 56, 323), rect(44, 84, 115, 224), rect(111, 41, 151, 103), rect(463, 47, 503, 107), rect(512, 69, 592, 208), rect(572, 94, 637, 312)]]
  set shopFloorRect to rect(10, 400, 600, 460)
  set yardRect to rect(290, 400, 580, 445)
  set figgeBeenHere to 0
  return me
end

on kill me
  return 0
end

on setPileRects me
end

on getRandomPile me
  global gMulleGlobals
  set tempList to []
  repeat with n = 1 to nrOfPiles
    add(tempList, n)
  end repeat
  set rndList to []
  repeat with n = 1 to nrOfPiles
    set tempRnd to random(count(tempList))
    add(rndList, getAt(tempList, tempRnd))
    deleteAt(tempList, tempRnd)
  end repeat
  repeat with n = 1 to nrOfPiles
    set tempSymbol to symbol("Pile" & string(getAt(rndList, n)))
    if not checkFull(me, tempSymbol) then
      return tempSymbol
      exit repeat
    end if
  end repeat
  return 0
end

on checkFull me, whichJunk
  global gMulleGlobals
  set tempMax to getaProp(maxParts, whichJunk)
  if count(getJunk(the user of gMulleGlobals, whichJunk)) < tempMax then
    set r to 0
  else
    set r to 1
  end if
  return r
end

on setPartPosition me, whichJunk, partId
  global gMulleGlobals
  set partHeight to getHeight(getPart(the parts of gMulleGlobals, partId))
  set partWidth to getWidth(getPart(the parts of gMulleGlobals, partId))
  if symbolp(whichJunk) then
    set tempRects to getaProp(rects, whichJunk)
  else
    if integerp(whichJunk) then
      set tempRects to getaProp(rects, symbol("Pile" & string(whichJunk)))
    end if
  end if
  set bottomline to 0
  repeat with n = 1 to count(tempRects)
    if getAt(getAt(tempRects, n), 4) > bottomline then
      set bottomline to getAt(getAt(tempRects, n), 4)
    end if
  end repeat
  if whichJunk = #shopFloor or whichJunk = #yard then
    set rndRect to getAt(tempRects, random(count(tempRects)))
    set rndH to random(getAt(rndRect, 3) - getAt(rndRect, 1))
    set rndV to random(getAt(rndRect, 4) - getAt(rndRect, 2))
    set tempOffset to point(getAt(rndRect, 1), getAt(rndRect, 2))
    set newPartLoc to point(rndH, rndV) + tempOffset
  else
    set newPartLoc to point(0, 999)
    set overDoor to 0
    repeat while overDoor = 0
      set rndRect to getAt(tempRects, random(count(tempRects)))
      set rndH to random(getAt(rndRect, 3) - getAt(rndRect, 1))
      set rndV to random(getAt(rndRect, 4) - getAt(rndRect, 2))
      set tempOffset to point(getAt(rndRect, 1), getAt(rndRect, 2))
      set newPartLoc to point(rndH, rndV) + tempOffset
      if getAt(newPartLoc, 2) + partHeight >= bottomline then
        set rndV to rndV - (getAt(newPartLoc, 2) + partHeight - bottomline)
        set newPartLoc to point(rndH, rndV) + tempOffset
      end if
      set rectToCome to rect(getAt(newPartLoc, 1) - partWidth, getAt(newPartLoc, 2) - partHeight, getAt(newPartLoc, 1) + partWidth, getAt(newPartLoc, 2) + partHeight)
      set testRect to intersect(rectToCome, getAt(getaProp(rects, #PileDoors), integer(the last char in string(whichJunk))))
      if testRect = rect(0, 0, 0, 0) then
        set overDoor to 1
        next repeat
      end if
      set newPartLoc to point(0, 999)
    end repeat
  end if
  return newPartLoc
end

on checkPoint me, thePoint, theid, thePile
  set partHeight to getHeight(getPart(the parts of gMulleGlobals, theid))
  set partWidth to getWidth(getPart(the parts of gMulleGlobals, theid))
  set tempRects to getaProp(rects, symbol("Pile" & string(thePile)))
  set bottomline to 0
  repeat with n = 1 to count(tempRects)
    if getAt(getAt(tempRects, n), 4) > bottomline then
      set bottomline to getAt(getAt(tempRects, n), 4)
    end if
  end repeat
  set rectToCome to rect(getAt(thePoint, 1) - partWidth, getAt(thePoint, 2) - partHeight, getAt(thePoint, 1) + partWidth, getAt(thePoint, 2) + partHeight)
  put "botton ", bottomline
  set diff to 0
  if getAt(rectToCome, 4) > bottomline then
    set diff to getAt(rectToCome, 4) - bottomline
    set rectToCome to rect(getAt(rectToCome, 1), getAt(rectToCome, 2) - diff, getAt(rectToCome, 3), getAt(rectToCome, 4) - diff)
  end if
  set testRect to intersect(rectToCome, getAt(getaProp(rects, #PileDoors), thePile))
  if testRect = rect(0, 0, 0, 0) and getAt(rectToCome, 4) <= bottomline then
    if diff = 0 then
      set returnValue to #true
    else
      set returnValue to point(getAt(thePoint, 1), getAt(thePoint, 2) - diff)
    end if
  else
    set returnValue to #false
  end if
  return returnValue
end

on correctPosition me, thePartId, thePartLoc
  set isFalling to 0
  set partId to thePartId
  set part to getPart(the parts of gMulleGlobals, partId)
  set showMember to getJunkView(part)
  set tempRect to getAt(getProp(rects, #shopFloor), 1)
  set tempLocH to getAt(thePartLoc, 1)
  if tempLocH < getAt(tempRect, 1) then
    set tempLocH to getAt(tempRect, 1)
  else
    if tempLocH > getAt(tempRect, 3) then
      set tempLocH to getAt(tempRect, 3)
    end if
  end if
  set tempOffsetV to getAt(the rect of member(showMember), 4) / 2
  set floorLocV to getAt(tempRect, 4)
  put "floorLocV ", floorLocV
  set tempLocV to getAt(thePartLoc, 2)
  if tempLocV < floorLocV then
    set isFalling to 1
    set tempNewLocV to floorLocV
  else
    set rndDiff to 35 + random(10)
    set tempNewLocV to floorLocV + (tempOffsetV - rndDiff)
  end if
  return [point(tempLocH, tempNewLocV), isFalling]
end
