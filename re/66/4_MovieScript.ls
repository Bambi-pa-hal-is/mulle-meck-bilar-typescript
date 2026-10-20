global gDir, gTangent, gSound

on startMovie
  global gDir
  startMovie(gDir)
  set the keyDownScript to "getKeyCode"
end

on CuePassed theChannel, theNumber, theName
  CuePassed(gSound, theChannel, theNumber, theName)
end

on getKeyCode
  if the frameLabel = "Game" then
    set gTangent to the keyCode
    case gTangent of
      123:
        GoLeft(gDir)
      124:
        GoRight(gDir)
      125:
        GoDown(gDir)
      126:
        GoUp(gDir)
    end case
  end if
end
