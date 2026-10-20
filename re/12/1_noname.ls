on mouseUp
  global gAlreadyDone
  if voidp(gAlreadyDone) then
    if the doubleClick then
      go("Eldmatch")
    else
      go(the frame + 1)
    end if
  end if
end
