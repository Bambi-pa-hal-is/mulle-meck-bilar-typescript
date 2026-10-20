on startMovie
  global gMulleGlobals, gDir
  startMovie(gDir)
end

on CuePassed channel, number, name
  global gDir
  set X to value(the last char in string(channel))
  sendSprite(getaProp(the spriteList of gDir, #Mulle), #spritecuePassed, X, number, name)
end
