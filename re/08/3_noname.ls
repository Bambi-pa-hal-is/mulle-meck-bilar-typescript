on startMovie
  global gDir, gMulleGlobals
  set the returnTo of gDir to the WhereFrom of gMulleGlobals
  set the WhereFrom of gMulleGlobals to "08"
  startMovie(gDir)
end

on CuePassed theChannel, cueNr, cueName
  set tempCh to string(theChannel)
  set tempCh to value(char length(tempCh) of tempCh)
  sendAllSprites(#spritecuePassed, tempCh, cueNr, cueName)
end
