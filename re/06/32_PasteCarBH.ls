property active
global gMulleGlobals, gDir

on beginSprite me
  set active to 1
end

on activate me, YesNo
  set active to YesNo
end

on mouseUp me
  if active then
    if the slotOccupied of gDir then
      replaceAsk(gDir)
    else
      prepareEnterName(gDir)
    end if
  end if
end
