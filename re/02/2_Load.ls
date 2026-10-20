property TicksPerFrame, FrameList, nfOfTicks

on new me
  global gMulleGlobals, gDir
  set FrameList to [0, 0, 0, 0, 0]
  set TicksPerFrame to the ticks
  set nfOfTicks to 30
  return me
end

on loop me
  global gMulleGlobals, gDir
  if not the goToLoad of gDir then
    set Ticksvalue to the ticks - TicksPerFrame
    add(FrameList, Ticksvalue)
    deleteAt(FrameList, 1)
    set TicksPerFrame to the ticks
    set check to 1
    repeat with n = 1 to count(FrameList)
      if getAt(FrameList, n) < nfOfTicks then
        set check to 0
      end if
    end repeat
    set the goToLoad of gDir to check
    if the goToLoad of gDir then
      set the loadIndicator of gMulleGlobals to 1
      stopBG(gSound)
    end if
  else
    deleteLoopObject(gDir, me)
  end if
end
