property partId, active, screenObject, activeClick
global gDir, gMulleGlobals

on beginSprite me
  set active to 0
  set partId to 0
end

on isMouseOverMe me
  if inside(point(the mouseH, the mouseV), the rect of sprite the spriteNum of me) then
    return 1
  else
    return 0
  end if
end

on activateClick me, theState
  set active to theState
end

on setPart me, thePartId
  set partId to thePartId
  if partId = 0 then
    activate(me, 0)
  else
    if not active then
      activate(me, 1)
    end if
  end if
end

on activate me, YesNo
  if not (active = YesNo) then
    set active to YesNo
  end if
end

on mouseDown me
  put "mouseDown"
  if active then
    grabbedPart(the partsCommon of gDir, partId, #car)
    showUseView(the partsCommon of gDir, partId, 0)
  end if
end
