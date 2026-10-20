global gDir

on enterFrame
  if checkBeenHereBefore(gDir) = 1 then
    go("startGame")
  end if
end
