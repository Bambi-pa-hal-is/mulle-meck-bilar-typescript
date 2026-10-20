on startMovie me
  global gMulleGlobals, gSound, gDir
  stopAllEffects(gSound)
  stopBG(gSound)
  if the loadIndicator of gMulleGlobals = 0 then
    play(gSound, "02e010v0", #BG)
  end if
  set the keyDownScript to "systemkeys"
  set the loc of sprite 115 to point(-20, -20)
  if the CustomCursorActive of gMulleGlobals then
    cursor(200)
  else
    sendSprite(115, #C_Standard)
  end if
  activate(gDir, 1)
  set gLoAd to new(script("Load"), me)
  addLoopObject(gDir, gLoAd)
  preloadMember("02e015v0")
  preloadMember("02e016v0")
end

on CuePassed channel, number, name
  global gDir
  set X to value(the last char in string(channel))
  sendSprite(getaProp(the spriteList of gDir, #Mulle), #spritecuePassed, X, number, name)
end
