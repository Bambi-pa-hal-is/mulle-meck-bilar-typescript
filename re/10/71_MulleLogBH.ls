property animObject, bodyAnimObject, mode, SP, whichFrame, soundList, lastSound

on beginSprite me
  global gDir
  set soundList to ["11d002v0", "11d003v0", "11d004v0", "11d005v0", "11d006v0"]
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  set animObject to getAt(tempList, 1)
  set tempList to the scriptInstanceList of sprite getProp(the spriteList of gDir, #MulleBody)
  set bodyAnimObject to getAt(tempList, 1)
  set mode to #Still
  setAnimNormal(animObject)
  setAnimNormal(bodyAnimObject)
  set SP to the spriteNum of me
end

on exitFrame me
  if whichFrame = #Wait then
    if mode = #Still then
      if random(50) = 1 then
        randomMove(me, 8)
      end if
    end if
  end if
end

on randomMove me, maxRnd
  set tempRnd to random(maxRnd)
  case tempRnd of
    1:
      set mode to #Kli
      setAnimAction(bodyAnimObject, mode)
      activate(animObject, 0)
      set the member of sprite SP to member("Dummy")
    2, 3, 4:
      set mode to #Blink
      setAnimAction(animObject, mode)
    5, 6, 7, 8:
      set mode to #Talk
      repeat while 1
        set tempSound to random(count(soundList))
        if tempSound <> lastSound then
          exit repeat
        end if
      end repeat
      set lastSound to tempSound
      makeAnimSpeech(animObject, getAt(soundList, lastSound))
      setAnimAction(animObject, mode)
  end case
end

on BeginFrame me, theLabel
  set whichFrame to theLabel
  case whichFrame of
    #Still:
      set mode to #VeryStill
    #Talk:
      set mode to #Talk
      makeAnimSpeech(animObject, "11d001v0")
      setAnimAction(animObject, mode)
    #Wait:
      set mode to #Still
  end case
end

on WarnOfThrowing me
  if not (whichFrame = #Talk) then
    go("Wait")
  end if
  set mode to #Talk
  setAnimAction(bodyAnimObject, #Still)
  activate(animObject, 1)
  makeAnimSpeech(animObject, "11d007v0")
  setAnimAction(animObject, mode)
end

on fullAlert me
  if not (whichFrame = #Talk) then
    go("Wait")
  end if
  set mode to #Talk
  setAnimAction(bodyAnimObject, #Still)
  activate(animObject, 1)
  makeAnimSpeech(animObject, "11d008v0")
  setAnimAction(animObject, mode)
end

on Stopped me
  if not (mode = #TalkPek) then
    case mode of
      #Kli:
        setAnimNormal(animObject)
        activate(animObject, 1)
      #Pek:
        setAnimNormal(animObject)
        activate(animObject, 1)
      #Talk:
        setAnimNormal(animObject)
        if whichFrame = #Talk then
          go("Wait")
        end if
    end case
    set mode to #Still
    setAnimAction(animObject, mode)
  else
    set mode to #Talk
  end if
end

on spritecuePassed me, theChannel, theNr, theName
  if theName = "Point" then
    if theChannel = the myChannel of animObject then
      set mode to #TalkPek
      setAnimAction(bodyAnimObject, #Pek)
    end if
  end if
end
