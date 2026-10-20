on exitFrame
  global gDir
  if the testing of gDir then
    go("start")
  else
    go(1, "05")
  end if
end
