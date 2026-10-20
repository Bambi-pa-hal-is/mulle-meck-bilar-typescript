global gPathGlobals, gMulleGlobals

on systemKeys
  global gPathGlobals
  if the keyCode = 122 then
    if the machineType = 256 then
      open(the helpFile of gPathGlobals, "Winhelp.exe")
    else
      open(the helpFile of gPathGlobals, "Skriv text")
    end if
  else
    if the machineType = 256 then
      if the optionDown and the keyCode = 53 then
        stopMovie()
        killall()
        quit()
      else
        if the controlDown and the key = "m" then
          sendSprite(116, #checkmemory)
        end if
      end if
    else
      if the commandDown and the key = "q" then
        stopMovie()
        killall()
        quit()
      else
        if the keyCode = 114 then
          open(the helpFile of gPathGlobals, "Skriv text")
        else
          if the controlDown and the key = "m" then
            sendSprite(116, #checkmemory)
          end if
        end if
      end if
    end if
  end if
end
