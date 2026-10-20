on mouseUp me
  global gDir, gMulleGlobals, gSound
  play(gSound, "SndMouseClick", #EFFECT)
  if the returnTo of gDir = "02" then
    go("j" & string(the myLastPile of the user of gMulleGlobals), "02")
  else
    go(1, the returnTo of gDir)
  end if
end
