property counter, myMember, medalList, soundList, sndCounter, sndId, medalId, blinkSpeed
global gSound, gDir

on beginSprite me
  set medalList to ["00n004v0", "00n005v0", "00n006v0", "00n007v0", "00n010v0", "00n009v0"]
  set soundList to ["05d008v0", "05d009v0", "05d007v0", EMPTY, "05d006v0", "05d010v0"]
  set counter to 0
end

on Blink me, theMedalId
  set medalId to theMedalId
  set sndId to play(gSound, "00e021v0", #OPEFFECT)
  set sndCounter to 1
  set counter to 1
  set myMember to getAt(medalList, medalId)
  set blinkSpeed to 5
end

on FinishedSound me
  if not counter then
    return 1
  end if
  return sndCounter = 2 and finished(gSound, sndId)
end

on stopSound me
  stop(gSound, sndId)
end

on exitFrame me
  if counter then
    if finished(gSound, sndId) then
      if sndCounter = 1 then
        set tempSnd to getAt(soundList, medalId)
        if length(tempSnd) then
          set sndId to play(gSound, tempSnd, #OPEFFECT)
          set sndCounter to 2
        else
          stop(me)
          exit
        end if
      else
        stop(me)
        exit
      end if
    end if
    set counter to counter + 1
    if (counter + 3 * blinkSpeed / 2) mod (blinkSpeed * 2) = 0 then
      set the member of sprite the spriteNum of me to member(myMember)
    else
      if counter mod (blinkSpeed * 2) = 0 then
        set the member of sprite the spriteNum of me to member("Dummy")
      end if
    end if
  end if
end

on stop me
  set the member of sprite the spriteNum of me to member("Dummy")
  set counter to 0
end
