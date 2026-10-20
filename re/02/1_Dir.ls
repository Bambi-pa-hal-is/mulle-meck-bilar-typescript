property ancestor, spriteList, cursorOverList, partsCommon, carCopy, junkHandlersCopy, partsInShop, TicksPerFrame, FrameList, goToLoad, nfOfTicks, overDoor, gLoAd

on new me
  global gMulleGlobals
  activate(me, 1)
  set ancestor to new(script("GeneralAncestor"), me)
  set partsInShop to count(getaProp(getaProp(the user of gMulleGlobals, #junk), #shopFloor))
  set spriteList to [#drag: 105, #JunkStart: 12, #DoorStart: 10, #fDialog: 114, #Mulle: 102, #Buffa: 103, #leftSign: 83, #rightSign: 82]
  set carCopy to the car of the user of gMulleGlobals
  if the loadIndicator of gMulleGlobals = 0 then
    set goToLoad to 0
  else
    set goToLoad to 1
  end if
  set overDoor to 0
  return me
end

on init me
end

on activate me, theState
  put "activAte"
  if theState then
    sendAllSprites(#activate, 1)
  else
    sendAllSprites(#activate, 0)
  end if
end

on kill me
  if objectp(partsCommon) then
    set partsCommon to kill(partsCommon)
  end if
  if objectp(ancestor) then
    set ancestor to kill(ancestor)
  end if
  if objectp(gLoAd) then
    set gLoAd to kill(gLoAd)
  end if
  return 0
end
