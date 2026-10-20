property child, insideInner, toMap, toLoc, toWorld, isVertical, DownRight, border
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set optional to getOptionalData(child)
  set tempXtra to 25
  set toLoc to getaProp(optional, #toLoc)
  set toMap to getaProp(optional, #toMap)
  set toWorld to getaProp(optional, #toWorld)
  set whichBorder to getaProp(optional, #whichBorder)
  if whichBorder = 3 then
    set isVertical to 0
    set DownRight to 0
    set border to 4 + tempXtra
  else
    if whichBorder = 1 then
      set isVertical to 0
      set DownRight to 1
      set border to 636 - tempXtra
    else
      if whichBorder = 4 then
        set isVertical to 1
        set DownRight to 0
        set border to 4 + tempXtra
      else
        if whichBorder = 2 then
          set isVertical to 1
          set DownRight to 1
          set border to 400 - tempXtra
        end if
      end if
    end if
  end if
end

on step me, carLoc
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #Inner)
  if insideInner then
    set temp to getAt(carLoc, isVertical + 1)
    if DownRight = 0 then
      if temp < border then
        teleport(gDir, toWorld, toMap, toLoc)
      end if
    else
      if temp > border then
        teleport(gDir, toWorld, toMap, toLoc)
      end if
    end if
  end if
end
