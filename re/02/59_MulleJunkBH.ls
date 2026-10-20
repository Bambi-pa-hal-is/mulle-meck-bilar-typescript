property type, mode, animObject, randomSounds, sortSounds, activeClick, ThoughtSounds, currentAnimChart, currentAction, theSnd
global gDir

on beginSprite me
  set type to #Mulle
  set mode to #Wait
  set currentAnimChart to #MulleJunk
  set currentAction to #none
  set ThoughtSounds to ["02d001v0", "02d002v0", "02d003v0", "02d004v0", "02d005v0"]
  set sortSounds to ["02d006v0", "02d007v0", "02d008v0"]
  set randomSounds to ThoughtSounds
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  repeat with index in tempList
    if the type of index = #SpriteAnim then
      set animObject to index
    end if
  end repeat
  set activeClick to 1
  sendSprite(the currentSpriteNum, #setAnimChart, "MulleJunk")
  set theSnd to EMPTY
end

on activate me, theState
  put "the state :", theState
  set activeClick to theState
end

on exitFrame me
  if the goToLoad of gDir = 0 then
    if activeClick then
      if mode = #Wait then
        if getAnimWaitState(animObject) = #Still then
          if random(250) = 1 then
            move(me)
          end if
        end if
      end if
    end if
  end if
end

on addToSounList me, what
  if what = #Reject then
    set randomSounds to sortSounds
  else
    set randomSounds to ThoughtSounds
  end if
end

on describepart me, theDescription
  playAnimSound(animObject, EMPTY)
  set mode to #Talk
  set currentAction to #Describe
  if random(2) = 1 then
    set currentAnimChart to #TalkToMeJunk
    sendSprite(the spriteNum of me, #setAnimChart, "TalkToMeJunk")
  end if
  makeAnimSpeech(animObject, theDescription)
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end

on MakeMulleSpeak me, theAction
  set currentAction to theAction
  playAnimSound(animObject, EMPTY)
  set mode to #Talk
  if theAction = #shopFull then
    set n to random(3)
    case n of
      1:
        set theSnd to "02d009v0"
      2:
        set theSnd to "02d010v0"
      3:
        set theSnd to "02d011v0"
    end case
  else
    if theAction = #pileFull then
      set n to random(3)
      case n of
        1:
          set theSnd to "02d013v0"
        2:
          set theSnd to "02d014v0"
        3:
          set theSnd to "02d015v0"
      end case
    end if
  end if
  if random(2) = 1 then
    set currentAnimChart to #TalkToMeJunk
    sendSprite(the spriteNum of me, #setAnimChart, "TalkToMeJunk")
  end if
  makeAnimSpeech(animObject, theSnd)
  sendSprite(the spriteNum of me, #setAnimAction, #Talk)
end

on move me
  set tempMode to 0
  set tempMode to #Talk
  set theSnd to getAt(randomSounds, random(count(randomSounds)))
  if random(2) = 1 then
    set currentAnimChart to #TalkToMeJunk
    sendSprite(the spriteNum of me, #setAnimChart, "TalkToMeJunk")
  end if
  makeAnimSpeech(animObject, theSnd)
  set mode to tempMode
  if mode <> 0 then
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  end if
end

on Stopped me
  case mode of
    #Talk:
      if currentAnimChart = #TalkToMeJunk then
        sendSprite(the currentSpriteNum, #setAnimChart, "MulleJunk")
      end if
      if theSnd <> EMPTY then
        unloadMember(theSnd)
      end if
      set the tmpId of sprite(120) to 0
      setAnimNormal(animObject)
      set tempMode to #Wait
      set currentAction to #none
    otherwise:
      set tempMode to #Wait
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
