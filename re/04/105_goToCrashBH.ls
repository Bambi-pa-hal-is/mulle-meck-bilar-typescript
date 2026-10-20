property snd
global gSound

on setSnd me, theSndId
  set snd to theSndId
end

on exitFrame me
  if finished(gSound, snd) then
    go(the frame + 1)
  end if
end
