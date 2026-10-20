property downOn

on mouseUp me
  global gMainScroller, gSound
  if downOn then
    play(gSound, "SndMouseClick", #OPEFFECT)
    set downOn to 0
    set tempStr to cleanString(the text of member("EnterField"))
    sendSprite(gMainScroller, #AddLine, tempStr)
  end if
end

on mouseUpOutSide me
  set downOn to 0
end

on mouseDown me
  cursor(200)
  set downOn to 1
end
