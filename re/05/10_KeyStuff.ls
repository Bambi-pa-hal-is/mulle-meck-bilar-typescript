on keyDown
  global gDir
  systemKeys()
  if objectp(gDir) then
    if the mode of gDir = #Driving then
      case the keyCode of
        123:
          setKeySteer(gDir, 1)
          keyDown(gDir, #left)
        124:
          setKeySteer(gDir, 1)
          keyDown(gDir, #right)
        125:
          if not the gotKeyPoll of gDir then
            setKeySteer(gDir, 1)
            keyDown(gDir, #ArrowDown)
          end if
        126:
          if not the gotKeyPoll of gDir then
            setKeySteer(gDir, 1)
            keyDown(gDir, #ArrowUp)
          end if
        otherwise:
          if the key = "s" then
            changecarSound(gDir)
          end if
      end case
    else
      if the mode of gDir = #Showing then
        sendSprite(getProp(the spriteList of gDir, #ShowOff), #fakeMouse)
      end if
    end if
  end if
end

on idle
  global gDir
  idle(the keyHandlers of gDir)
end

on keyUp
  global gDir
  if objectp(gDir) then
    keyUp(gDir)
  end if
end
