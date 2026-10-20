on startMovie
  global gDir, gMulleGlobals
  startMovie(gDir)
end

on CuePassed theChannel, cueNr, cueName
  set tempCh to string(theChannel)
  set tempCh to value(char length(tempCh) of tempCh)
  sendAllSprites(#spritecuePassed, tempCh, cueNr, cueName)
end

on mouseUp
  global gDir
  if objectp(gDir) then
    if the mode of gDir = #Showing then
      sendSprite(getProp(the spriteList of gDir, #ShowOff), #fakeMouse)
    end if
  end if
end
