on exitFrame
  global gSound, transitionSound
  if finished(gSound, transitionSound) then
    go(1, "04")
  else
    go(the frame)
  end if
end
