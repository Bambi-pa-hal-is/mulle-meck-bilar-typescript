on startMovie
  global gDir
  startMovie(gDir)
end

on stopMovieX
  global gDir
  set gDir to kill(gDir)
end

on killall
  global gPathGlobals, gMulleGlobals
  if objectp(gPathGlobals) then
    set the fileName of castLib("tempPlug") to the CDPath of gPathGlobals & "tempPlug.cst"
    set gPathGlobals to kill(gPathGlobals)
  end if
  if objectp(gMulleGlobals) then
    set gMulleGlobals to kill(gMulleGlobals)
  end if
end

on keyDown
  systemKeys()
end
