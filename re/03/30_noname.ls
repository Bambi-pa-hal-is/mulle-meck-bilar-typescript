on exitFrame
  global gSound, transitionSound
  case random(2) of
    1:
      set transitionSound to play(gSound, "03d009v0", #EFFECT)
    2:
      set transitionSound to play(gSound, "03d010v0", #EFFECT)
  end case
end
