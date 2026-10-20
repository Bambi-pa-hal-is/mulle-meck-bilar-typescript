property whichPile, tracking, trackRect, partSprite, partId, myPile, maxTop, minLeft, maxRight, bottomline, puttingBack, topLayer, dragSprite, myRects, tempNewPos, nrOfMoveSteps, moveCount, xDiff, yDiff, loopcount, releaseOk, tmpId
global gMulleGlobals, junk, gDir, gSound

on beginSprite me
  set puttingBack to EMPTY
  set tempNewPos to 0
  set nrOfMoveSteps to 10
  set loopcount to 0
  set releaseOk to 0
  set tmpId to 0
  set tmp to symbol("pile" & whichPile)
  set myRects to getaProp(the rects of the junkPileHandlers of gMulleGlobals, tmp)
  set maxTop to 999
  set minLeft to 999
  set maxRight to 0
  set bottomline to 0
  repeat with X = 1 to 3
    if getAt(getAt(myRects, X), 1) < minLeft then
      set minLeft to getAt(getAt(myRects, X), 1)
    end if
    if getAt(getAt(myRects, X), 3) > maxRight then
      set maxRight to getAt(getAt(myRects, X), 3)
    end if
    if getAt(getAt(myRects, X), 4) > bottomline then
      set bottomline to getAt(getAt(myRects, X), 4)
    end if
    if getAt(getAt(myRects, X), 2) < maxTop then
      set maxTop to getAt(getAt(myRects, X), 2)
    end if
  end repeat
  distributeParts(me)
  checkNrofParts(me)
end

on checkNrofParts me
  set check to symbol("Pile" & whichPile)
  set check to symbol("Pile" & whichPile)
  if getaProp(the maxParts of the junkPileHandlers of gMulleGlobals, check) <= count(getaProp(getaProp(the user of gMulleGlobals, #junk), check)) + 20 then
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #addToSounList, #Reject)
  else
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #addToSounList, #Think)
  end if
end

on distributeParts me
  global gMulleGlobals
  set myPile to getJunk(the user of gMulleGlobals, symbol("Pile" & string(whichPile)))
  set startChannel to getaProp(the spriteList of gDir, #JunkStart) - 1
  set channel to getaProp(the spriteList of gDir, #JunkStart)
  repeat with n = 1 to count(myPile)
    sendSprite(channel, #setPart, [getPropAt(myPile, n), getAt(myPile, n)])
    set channel to channel + 1
  end repeat
  set topLayer to count(myPile) + startChannel
  set the member of sprite channel to "Dummy"
end

on forcePartInPlace me
  set loopcount to 0
  set puttingBack to EMPTY
  set the loc of sprite topLayer to tempNewPos
  if voidp(getaProp(myPile, partId)) then
    alert("No ID for part " & partId)
  else
    removeJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId)
    addJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId, tempNewPos)
  end if
end

on exitFrame me
  set cFrame to the frame
  set mFrame to marker(0) + 9
  if cFrame = mFrame then
    go("Pile" & string(whichPile))
  end if
  if puttingBack <> EMPTY then
    if puttingBack = "center" then
      if loopcount < nrOfMoveSteps then
        set the loc of sprite topLayer to point(getAt(the loc of sprite topLayer, 1) + xDiff / nrOfMoveSteps, getAt(the loc of sprite topLayer, 2) + yDiff / nrOfMoveSteps)
        set loopcount to loopcount + 1
      else
        set loopcount to 0
        set puttingBack to EMPTY
        kickPartSound(the SharedSound of gMulleGlobals, partSprite, partId, #InternalGround)
        if voidp(getaProp(myPile, partId)) then
          alert("No ID for part " & partId)
        else
          removeJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId)
          set newPoint to the loc of sprite topLayer
          put "exitAddjunk"
          addJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId, newPoint)
        end if
      end if
    end if
  end if
end

on GoLeft me
  if puttingBack = "center" then
    forcePartInPlace(me)
  end if
  set the member of sprite getaProp(the spriteList of gDir, #Buffa) to "Dummy"
  if whichPile > 1 then
    set the myLastPile of the user of gMulleGlobals to whichPile - 1
    if the goToLoad of gDir then
      set the WhereFrom of gMulleGlobals to "02"
      go("left", "unload")
    else
      set doorToPreload to "open" & whichPile - 1
      preloadMember(doorToPreload)
      go("Pile" & string(whichPile - 1))
      sendSprite(getaProp(the spriteList of gDir, #Buffa), #changePile, -1)
    end if
  else
    set the myLastPile of the user of gMulleGlobals to 6
    if the goToLoad of gDir then
      set the WhereFrom of gMulleGlobals to "02"
      go("left", "unload")
    else
      set doorToPreload to "open6"
      preloadMember(doorToPreload)
      go("Pile6")
      sendSprite(getaProp(the spriteList of gDir, #Buffa), #changePile, -1)
    end if
  end if
end

on GoRight me
  if puttingBack = "center" then
    forcePartInPlace(me)
  end if
  set the member of sprite getaProp(the spriteList of gDir, #Buffa) to "Dummy"
  if whichPile < 6 then
    set the myLastPile of the user of gMulleGlobals to whichPile + 1
    if the goToLoad of gDir then
      set the WhereFrom of gMulleGlobals to "02"
      go("right", "unload")
    else
      set doorToPreload to "open" & whichPile + 1
      preloadMember(doorToPreload)
      go("Pile" & string(whichPile + 1))
      sendSprite(getaProp(the spriteList of gDir, #Buffa), #changePile, 1)
    end if
  else
    set the myLastPile of the user of gMulleGlobals to 1
    if the goToLoad of gDir then
      set the WhereFrom of gMulleGlobals to "02"
      go("right", "unload")
    else
      set doorToPreload to "open1"
      preloadMember(doorToPreload)
      go("Pile1")
      sendSprite(getaProp(the spriteList of gDir, #Buffa), #changePile, 1)
    end if
  end if
end

on grabPart me, grabbedPartId, grabbedPartSprite
  if puttingBack = "center" then
    forcePartInPlace(me)
  end if
  set releaseOk to 1
  set partSprite to grabbedPartSprite
  set dragSprite to grabbedPartSprite
  set partId to grabbedPartId
  sendSprite(getaProp(the spriteList of gDir, #drag), #setPart, the member of sprite grabbedPartSprite)
  set the loc of sprite getaProp(the spriteList of gDir, #drag) to the loc of sprite grabbedPartSprite
  set trackRect to rect(the mouseH - 2, the mouseV - 2, the mouseH + 2, the mouseV + 2)
  set tracking to 1
end

on releasePart me
  if releaseOk = 1 then
    if the currentAction of sprite(getaProp(the spriteList of gDir, #Mulle)) = #none then
      set playedDescription to 0
    else
      set playedDescription to 1
    end if
    if tracking and inside(point(the mouseH, the mouseV), trackRect) and partId <> tmpId then
      set tmpId to partId
      set playedDescription to 1
      sendSprite(partSprite, #PlayDescription)
    end if
    set tracking to 0
    set the member of sprite partSprite to the member of sprite getaProp(the spriteList of gDir, #drag)
    set the member of sprite getaProp(the spriteList of gDir, #drag) to member("dummy")
    if inside(point(the mouseH, the mouseV), the rect of sprite getaProp(the spriteList of gDir, #rightSign)) then
      if whichPile = 6 then
        set toPile to 1
      else
        set toPile to whichPile + 1
      end if
      sendSprite(partSprite, #moveToDifferentPile, whichPile, toPile)
      sendSprite(115, #C_Right)
      distributeParts(me)
    else
      if inside(point(the mouseH, the mouseV), the rect of sprite getaProp(the spriteList of gDir, #leftSign)) then
        if whichPile = 1 then
          set toPile to 6
        else
          set toPile to whichPile - 1
        end if
        sendSprite(partSprite, #moveToDifferentPile, whichPile, toPile)
        sendSprite(115, #c_Left)
        distributeParts(me)
      else
        if inside(point(the mouseH, the mouseV), getAt(myRects, 1)) or inside(point(the mouseH, the mouseV), getAt(myRects, 2)) or inside(point(the mouseH, the mouseV), getAt(myRects, 3)) then
          set tmp to checkPoint(the junkPileHandlers of gMulleGlobals, point(the mouseH, the mouseV), partId, whichPile)
          if tmp = #true then
            if playedDescription = 0 then
              kickPartSound(the SharedSound of gMulleGlobals, partSprite, partId, #InternalGround)
            end if
            putOnTop(me, partSprite)
          else
            if tmp = #false then
              flowBack(me)
            else
              set loopcount to 0
              set tempNewPos to tmp
              set xDiff to getAt(tempNewPos, 1) - the mouseH
              set yDiff to getAt(tempNewPos, 2) - the mouseV
              set puttingBack to "center"
              putOnTop(me, partSprite)
            end if
          end if
        else
          if inside(point(the mouseH, the mouseV), the trackRect of sprite(getaProp(the spriteList of gDir, #DoorStart))) then
            sendSprite(partSprite, #moveToShop, whichPile)
            kickPartSound(the SharedSound of gMulleGlobals, the currentSpriteNum, partId, #ExternalGround)
            sendSprite(115, #c_click)
            distributeParts(me)
          else
            flowBack(me)
          end if
        end if
      end if
    end if
    set releaseOk to 0
  end if
end

on flowBack me
  set tempJunkSymbol to symbol("pile" & whichPile)
  set tempNewPos to setPartPosition(the junkPileHandlers of gMulleGlobals, tempJunkSymbol, partId)
  set xDiff to getAt(tempNewPos, 1) - the mouseH
  set yDiff to getAt(tempNewPos, 2) - the mouseV
  set loopcount to 0
  set puttingBack to "center"
  putOnTop(me, partSprite)
end

on prepareFrame me
  if tracking then
    if not inside(point(the mouseH, the mouseV), trackRect) then
      sendSprite(getaProp(the spriteList of gDir, #drag), #drag)
      set the member of sprite partSprite to member("dummy")
    end if
  end if
end

on putOnTop me, theSprite, extraInfo
  if voidp(getaProp(myPile, partId)) then
  else
    removeJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId)
  end if
  if voidp(extraInfo) then
    if inside(point(the mouseH, the mouseV), trackRect) then
      set newPoint to the loc of sprite theSprite
    else
      set newPoint to point(the mouseH, the mouseV)
    end if
  else
    set newPoint to extraInfo
  end if
  addJunkPart(the user of gMulleGlobals, symbol("pile" & whichPile), partId, newPoint)
  distributeParts(me)
end

on getPropertyDescriptionList me
  return [#whichPile: [#comment: "Which pile (1-6):", #format: #integer, #default: 1, #range: [#min: 1, #max: 6]]]
end
