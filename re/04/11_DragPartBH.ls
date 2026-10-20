property justStarted, active, partId, snapRects, showingUseView, myMember, dragObject, dragging
global gDir, gMulleGlobals

on beginSprite me
  set active to 0
  set showingUseView to 0
  set dragObject to new(script("SafeDragScript"), me)
  activate(dragObject, 0)
  set dragging to 0
end

on startDrag me, thePartId
  set dragging to 1
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
  end if
end

on mouseUp me
  set dragging to 0
end

on report me, theObject, what
  if what = #clicked then
    activate(dragObject, 0)
    set active to 0
    set the member of sprite the spriteNum of me to member("Dummy")
    set overDoor to 0
    set tempSP to getProp(the spriteList of gDir, #DoorStart) - 1
    repeat with n = 1 to 2
      set tempObj to getAt(the scriptInstanceList of sprite n + tempSP, 1)
      if the doortracking of tempObj = 1 then
        if the mediaName of tempObj = "03" or the mediaName of tempObj = "garage" then
          set overDoor to #ToShopFloor
          exit repeat
        end if
      end if
    end repeat
    if showingUseView then
      letGoOfPart(the partsCommon of gDir, showingUseView, #car)
    else
      if symbolp(overDoor) then
        letGoOfPart(the partsCommon of gDir, partId, overDoor, point(the mouseH, the mouseV))
      else
        letGoOfPart(the partsCommon of gDir, partId, point(the mouseH, the mouseV))
      end if
    end if
  end if
end
