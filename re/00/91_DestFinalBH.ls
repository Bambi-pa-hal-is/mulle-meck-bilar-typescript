property sndId

on exitFrame
  global gSound, gMulleGlobals
  if voidp(sndId) then
    set tempList to ["05e074v0", "05e067v0", "05e025v0", "05e004v0", "05e011v0", "05e053v0", "05e018v0", "05e060v0", "05e032v0"]
    set tempEngine to getProperty(the car of the user of gMulleGlobals, #EngineType)
    if tempEngine < 1 or tempEngine > count(tempList) then
      set tempEngine to 4
    end if
    set sound to getAt(tempList, tempEngine)
    set sndId to play(gSound, sound, #EFFECT)
  else
    if finished(gSound, sndId) then
      go(1, "05")
    end if
  end if
  go(1, "05")
end
