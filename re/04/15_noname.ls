on exitFrame
  global gDir
  loop(gDir)
  if the returnFromWindow of gDir then
    if the goWorld of gDir then
      go("05")
    end if
    activate(gDir, 1)
    set the returnFromWindow of gDir to 0
  end if
  go(the frame)
end
