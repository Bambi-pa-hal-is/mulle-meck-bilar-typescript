on exitFrame
  global gDir
  if the medal of gDir then
    go(#next)
  else
    if the testing of gDir then
      go("start")
    else
      go("Leave")
    end if
  end if
end
