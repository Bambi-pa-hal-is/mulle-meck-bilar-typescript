property active

on beginSprite me
end

on mouseEnter me
end

on mouseLeave me
end

on keyDown me
  global gDir
  set the keyPressed of gDir to 1
  pass()
end
