property channels, newSnd, channelInfo, ticksPerSec

on new me
  set channels to [1: 0, 2: 0, 3: 0]
  set channelInfo to [[], [], []]
  set newSnd to 1
  if the machineType = 256 then
    set ticksPerSec to 63
  else
    set ticksPerSec to 60
  end if
  return me
end

on kill me
  nothing()
end

on finished me, sndId
  purge(me)
  if sndId <> 0 then
    if getProp(channels, 2) = sndId then
      return 0
    else
      if getProp(channels, 1) = sndId then
        return 0
      else
        if getProp(channels, 3) = sndId then
          return 0
        else
          return 1
        end if
      end if
    end if
  else
    return 1
  end if
end

on getChannel me, sndId
  purge(me)
  repeat with n = 1 to count(channels)
    if getAt(channels, n) = sndId then
      return value(getPropAt(channels, n))
    end if
  end repeat
  return 0
end

on fade me, sndId, inOut, theLength
  if sndId <> 0 then
    set tempCh to 0
    if getProp(channels, 2) = sndId then
      set tempCh to 2
    else
      if getProp(channels, 1) = sndId then
        set tempCh to 1
      else
        if getProp(channels, 3) = sndId then
          set tempCh to 3
        end if
      end if
    end if
    if tempCh then
      if inOut = #in then
        sound(#fadeIn, tempCh, theLength)
      else
        sound(#fadeOut, tempCh, theLength)
      end if
    end if
  end if
end

on stop me, sndId
  if sndId <> 0 then
    if getProp(channels, 2) = sndId then
      sound(#stop, 2)
      setProp(channels, 2, 0)
    else
      if getProp(channels, 1) = sndId then
        sound(#stop, 1)
        setProp(channels, 1, 0)
      else
        if getProp(channels, 3) = sndId then
          sound(#stop, 3)
          setProp(channels, 3, 0)
        end if
      end if
    end if
  end if
  return 0
end

on stopBG me
  if getProp(channels, 1) <> 0 then
    sound(#stop, 1)
    setProp(channels, 1, 0)
  end if
end

on stopAllEffects me
  if getProp(channels, 2) <> 0 then
    sound(#stop, 2)
    setProp(channels, 2, 0)
  end if
  if getProp(channels, 3) <> 0 then
    sound(#stop, 3)
    setProp(channels, 3, 0)
  end if
end

on play me, soundMember, what, theOption
  purge(me)
  if voidp(theOption) then
    set theOption to #member
    if the number of member soundMember = -1 or soundMember = EMPTY then
      put "Snd: ", soundMember
      set soundMember to "20d163v0"
    end if
  end if
  case what of
    #BG:
      set newSnd to newSnd + 1
      setProp(channels, 1, newSnd)
      lowLevelPlay(me, 1, theOption, soundMember)
      return newSnd
    #TRANS:
      set newSnd to newSnd + 1
      setProp(channels, 1, newSnd)
      stopAllEffects(me)
      lowLevelPlay(me, 1, theOption, soundMember)
      return newSnd
    #EFFECT:
      if getProp(channels, 3) = 0 then
        set newSnd to newSnd + 1
        setProp(channels, 3, newSnd)
        lowLevelPlay(me, 3, theOption, soundMember)
        return newSnd
      else
        set newSnd to newSnd + 1
        setProp(channels, 2, newSnd)
        lowLevelPlay(me, 2, theOption, soundMember)
        return newSnd
      end if
    #OPEFFECT:
      if getProp(channels, 2) = 0 then
        set newSnd to newSnd + 1
        setProp(channels, 2, newSnd)
        lowLevelPlay(me, 2, theOption, soundMember)
        return newSnd
      else
        if getProp(channels, 3) = 0 then
          set newSnd to newSnd + 1
          setProp(channels, 3, newSnd)
          lowLevelPlay(me, 3, theOption, soundMember)
          return newSnd
        end if
      end if
  end case
  return 0
end

on lowLevelPlay me, ch, how, theName
  if how = #file then
    sound(#playFile, ch, theName)
    if the result <> 0 then
      put "Snd", theName
      puppetSound(ch, "20d163v0")
      setAt(channelInfo, ch, [#member, the ticks, 0])
    else
      setAt(channelInfo, ch, [#file])
    end if
  else
    if how = #member then
      puppetSound(ch, theName)
      setAt(channelInfo, ch, [#member, the ticks, the loop of member(theName), 90 + the size of member(theName) * ticksPerSec / 11025])
    end if
  end if
end

on purge me
  if not soundBusy(1) then
    setProp(channels, 1, 0)
  end if
  if not soundBusy(2) then
    setProp(channels, 2, 0)
  else
    set tempInfo to getAt(channelInfo, 2)
    if count(tempInfo) then
      if getAt(tempInfo, 1) = #member then
        if the ticks - getAt(tempInfo, 2) > getAt(tempInfo, 4) and getAt(tempInfo, 3) = 0 then
          setProp(channels, 2, 0)
          sound(#stop, 2)
        end if
      end if
    end if
  end if
  if not soundBusy(3) then
    setProp(channels, 3, 0)
  else
    set tempInfo to getAt(channelInfo, 3)
    if count(tempInfo) then
      if getAt(tempInfo, 1) = #member then
        if the ticks - getAt(tempInfo, 2) > getAt(tempInfo, 4) and getAt(tempInfo, 3) = 0 then
          setProp(channels, 3, 0)
          sound(#stop, 3)
        end if
      end if
    end if
  end if
end

on CuePassed me, theChannel, theNumber, theName
  set theChannel to value(the last char in string(theChannel))
  sendAllSprites(#spritecuePassed, theChannel, theNumber, theName)
end
