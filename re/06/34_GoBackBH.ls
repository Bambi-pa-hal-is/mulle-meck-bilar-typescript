property active
global gDir, gSound

on beginSprite me
  set active to 1
end

on activate me, YesNo
  set active to YesNo
end

on mouseUp me
  if active then
    play(gSound, "SndMouseClick", #OPEFFECT)
    if the mode of gDir = #save then
      saveIfNecessary(gDir)
    end if
    go("Leave")
  end if
end
