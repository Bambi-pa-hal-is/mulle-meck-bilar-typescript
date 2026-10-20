on startMovie
  global gDir
  startMovie(gDir)
end

on mouseUp
  global gDir
  if not (the myMarker of gDir = "JustDoIt") then
    go("Leave")
  end if
end

on CuePassed theChannel, theNumber, theName
  global gSound
  CuePassed(gSound, theChannel, theNumber, theName)
end
