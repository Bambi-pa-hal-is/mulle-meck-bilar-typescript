on exitFrame
  go(the frame)
end

on idle
  global gJustPressedKey, gMsgFromSP
  if gJustPressedKey then
    sendSprite(gMsgFromSP, #GotIt)
    set gJustPressedKey to 0
  end if
end

on CuePassed me, whichChannel, cuePointNumber, cuePointName
  set whichChannel to value(the last char in string(whichChannel))
  sendAllSprites(#spritecuePassed, whichChannel, cuePointNumber, cuePointName)
end
