global gDir

on exitFrame
  loop(gDir)
  if symbolp(the doNextFrame of gDir) then
    case the doNextFrame of gDir of
      #jump:
        cursor(200)
        set the doNextFrame of gDir to 0
        go("Leave")
      #activateScreen:
        cursor(200)
        set the doNextFrame of gDir to 0
        activateScreen(gDir, 1)
        go(the frame)
    end case
  else
    go(the frame)
  end if
end

on idle
  if the keyPressed of gDir and the myMIAW of gDir = 0 then
    set the keyPressed of gDir to 0
    checkText(gDir)
  end if
end
