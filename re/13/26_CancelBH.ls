property downOn

on mouseUp
  global gDir, gSound
  if downOn then
    play(gSound, "SndMouseClick", #OPEFFECT)
    set downOn to 0
    dialogueResult(gDir, #Cancel)
  end if
end

on mouseUpOutSide me
  set downOn to 0
end

on mouseDown me
  cursor(200)
  set downOn to 1
end
