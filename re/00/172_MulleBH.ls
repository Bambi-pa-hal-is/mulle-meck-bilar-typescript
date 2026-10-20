property type, mode, animObject

on beginSprite me
  set type to #Mulle
  set mode to #Wait
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  repeat with index in tempList
    if the type of index = #SpriteAnim then
      set animObject to index
    end if
  end repeat
end

on exitFrame me
  if mode = #Wait then
    if getAnimWaitState(animObject) = #Still then
      if random(50) = 1 then
        randomMove(me, 5)
      end if
    end if
  end if
end

on describepart me, theDescription
  set mode to #Talk
  makeAnimSpeech(animObject, theDescription)
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end

on randomMove me, maxRnd
  set tempMode to 0
  case random(maxRnd) of
    1, 2, 3:
      set tempMode to #LookUnderCar
    4, 5:
      set tempMode to #Talk
      makeAnimSpeech(animObject, "MulleLjudTest")
    6:
      set tempMode to #ScratchHead
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end

on Stopped me
  case mode of
    #Talk:
      setAnimNormal(animObject)
      set tempMode to #Wait
    otherwise:
      set tempMode to #Wait
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
