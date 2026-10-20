on exitFrame
  go(the frame)
end

on CuePassed me, whichChannel, cuePointNumber, cuePointName
  set whichChannel to value(the last char in string(whichChannel))
  if whichChannel = 1 and cuePointName = "Mulle" then
    go(the frame + 1)
  end if
end
