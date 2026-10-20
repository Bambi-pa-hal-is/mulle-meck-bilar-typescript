property justStarted, active, partId, snapRects, showingUseView, myMember, dragObject, dragging
global gDir, gMulleGlobals, gSound

on beginSprite me
  set active to 0
  set showingUseView to 0
  set dragObject to new(script("SafeDragScript"), me)
  activate(dragObject, 0)
end

on startDrag me, thePartId, fromWhere, theSnapRects
  set dragging to 1
  set snapRects to theSnapRects
  set partId to thePartId
  set part to getPart(the parts of gMulleGlobals, partId)
  set myMember to getJunkView(part)
  set the member of sprite the spriteNum of me to member(myMember)
  set justStarted to 1
  set active to 1
  set showingUseView to 0
  activate(dragObject, 1)
end

on exitFrame me
  if active then
    set tempMouseLoc to point(the mouseH, the mouseV)
    set the loc of sprite the spriteNum of me to tempMouseLoc
    checkSnapRects(me, tempMouseLoc)
  end if
end

on checkSnapRects me, theLoc
  set tempInside to 0
  repeat with n = 1 to count(snapRects)
    if inside(theLoc, getAt(snapRects, n)) then
      set tempInside to 1
      set tempId to getPropAt(snapRects, n)
      if not (showingUseView = tempId) and not justStarted then
        if showingUseView then
          showUseView(the partsCommon of gDir, showingUseView, 0)
        end if
        set showingUseView to tempId
        kickPartSound(the SharedSound of gMulleGlobals, 0, partId, #car)
        showUseView(the partsCommon of gDir, showingUseView, 1)
        set the member of sprite the spriteNum of me to member("Dummy")
      end if
      exit repeat
    end if
  end repeat
  if not tempInside then
    if justStarted then
      set justStarted to 0
    end if
    if showingUseView then
      showUseView(the partsCommon of gDir, showingUseView, 0)
      kickPartSound(the SharedSound of gMulleGlobals, 0, partId, #car)
      set showingUseView to 0
      set the member of sprite the spriteNum of me to member(myMember)
    end if
  end if
end

on mouseUp me
  set dragging to 0
  if the currentSound of sprite(getaProp(the spriteList of gDir, #Mulle)) = "nothing" then
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #removeLoop)
  end if
end

on report me, theObject, what
  if what = #clicked then
    if the mouseH > 630 then
      set mouseH to 630
    else
      if the mouseH < 10 then
        set mouseH to 10
      else
        set mouseH to the mouseH
      end if
    end if
    activate(dragObject, 0)
    set active to 0
    set the member of sprite the spriteNum of me to member("Dummy")
    set overDoor to 0
    set tempSP to getProp(the spriteList of gDir, #DoorStart) - 1
    repeat with n = 1 to 3
      set tempObj to getAt(the scriptInstanceList of sprite n + tempSP, 1)
      if the doortracking of tempObj = 1 then
        if the mediaName of tempObj = "02" then
          set overDoor to #ToJunkPile
          exit repeat
        end if
      end if
    end repeat
    if showingUseView then
      letGoOfPart(the partsCommon of gDir, showingUseView, #car)
    else
      if symbolp(overDoor) and count(the mouseOverCar of gDir) = 0 then
        set tmpPile to symbol("pile" & the myLastPile of the user of gMulleGlobals)
        if checkFull(the junkPileHandlers of gMulleGlobals, tmpPile) then
          letGoOfPart(the partsCommon of gDir, partId, point(mouseH, the mouseV))
          sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #fullPile)
        else
          letGoOfPart(the partsCommon of gDir, partId, overDoor)
        end if
      else
        letGoOfPart(the partsCommon of gDir, partId, point(mouseH, the mouseV))
      end if
    end if
  end if
end
