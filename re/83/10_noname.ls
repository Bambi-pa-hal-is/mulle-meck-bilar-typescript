on startMovie
  global gDir
  startMovie(gDir)
end

on mouseUp
  go("Leave")
end

on CuePassed theChannel, theNumber, theName
  global gSound
  CuePassed(gSound, theChannel, theNumber, theName)
end
