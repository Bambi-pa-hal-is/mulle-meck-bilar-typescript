property spriteList, returnTo
global gSound, gMulleGlobals, gPathGlobals

on new me
  set spriteList to [#CarStart: 4, #ToBeCaptured: 82, #Scroller: 110]
  set returnTo to EMPTY
  set the text of member("UserName") to getUserId(the user of gMulleGlobals)
  set tempCarName to getName(the car of the user of gMulleGlobals)
  if length(tempCarName) = 0 then
    set tempCarName to " "
  end if
  set the text of member("SavedCarName") to tempCarName
  return me
end

on init me
end

on startMovie me
  stopBG(gSound)
  stopAllEffects(gSound)
  sendSprite(115, #C_Standard)
  set the member of sprite 119 to member("Dummy")
  set the member of sprite 120 to member("Dummy")
end

on kill me
  set the text of member("SavedCarName") to " "
  set the text of member("UserName") to " "
  closeXtra(gPathGlobals, #PrintOMatic)
  return 0
end
