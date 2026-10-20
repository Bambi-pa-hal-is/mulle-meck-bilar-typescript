property type, mode, animObject, activeClick, currentSound, exitLoopAction
global gDir, gSound, gMulleGlobals

on beginSprite me
  set type to #Figge
  set mode to #Still
  set tempList to the scriptInstanceList of sprite the spriteNum of me
  repeat with index in tempList
    if the type of index = #SpriteAnim then
      set animObject to index
    end if
  end repeat
  setAnimNormal(animObject)
  set the visible of sprite the currentSpriteNum to 0
  set activeClick to 1
  set exitLoopAction to 0
end

on activateClick me, theState
  set activeClick to theState
end

on loop me
  if finished(gSound, currentSound) = 0 then
    nothing()
  else
    case exitLoopAction of
      1:
        set currentSound to play(gSound, "03d043v0", #EFFECT)
        set exitLoopAction to 2
      2:
        finishFigge(me)
        set exitLoopAction to 3
        deleteLoopObject(gDir, me)
      4:
        set mode to #Talk
        sendSprite(the spriteNum of me, #setAnimAction, mode)
        deleteLoopObject(gDir, me)
    end case
  end if
end

on doFigge me
  if activeClick then
    activate(gDir, 0)
    set currentSound to play(gSound, "03e009v0", #EFFECT)
    addLoopObject(gDir, me)
    set exitLoopAction to 1
  end if
end

on finishFigge me
  if mode = #Still then
    play(gSound, "02e016v0", #EFFECT)
    set the member of sprite getaProp(the spriteList of gDir, #DoorStart) to the memberNum of sprite getaProp(the spriteList of gDir, #DoorStart) + 1
    leaveStuff()
    set tempMode to 0
    set tempMode to #ComeIn
    set mode to tempMode
    set the visible of sprite the spriteNum of me to 1
    put "sendin come in"
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  end if
end

on Interupt me
  if exitLoopAction = 3 then
    set the makeHimLeave of sprite(getaProp(the spriteList of gDir, #Mulle)) to 0
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #Stopped, #Talk)
  end if
  set exitLoopAction to 4
  stopAllEffects(gSound)
end

on FiggeLeave me
  set mode to #Talk
  makeAnimSpeech(animObject, "03d046v0")
  addLoopObject(gDir, me)
  sendSprite(the spriteNum of me, #setAnimAction, mode)
  set exitLoopAction to 4
end

on leaveStuff me
  calcCurrentlyAvailable(the externalParts of gMulleGlobals)
  set tmpList to getCurrentlyAvailable(the externalParts of gMulleGlobals, #JunkMan)
  if count(tmpList) <= 3 then
    set tmpNewParts to tmpList
    repeat with n = 1 to count(tmpList)
      addJunkPart(the user of gMulleGlobals, #yard, getAt(tmpNewParts, n))
    end repeat
  else
    repeat with n = 1 to 3
      addJunkPart(the user of gMulleGlobals, #yard, getAt(tmpList, n))
    end repeat
  end if
  set the loc of sprite getaProp(the spriteList of gDir, #FiggeInterup) to point(0, 0)
end

on Stopped me
  case mode of
    #ComeIn:
      makeAnimSpeech(animObject, "03d044v0")
      set tempMode to #Talk
    #Talk:
      if exitLoopAction = 3 then
        set currentSound to sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #greetFigge)
        addLoopObject(gDir, me)
        set tempMode to #Freeze
      else
        setAnimNormal(animObject)
        set tempMode to #GoOut
        set exitLoopAction to 0
      end if
    #Freeze:
      set tempMode to #Freeze
    #GoOut:
      set tempMode to #Still
      set the visible of sprite the currentSpriteNum to 0
      play(gSound, "02e015v0", #EFFECT)
      set the member of sprite getaProp(the spriteList of gDir, #DoorStart) to the memberNum of sprite getaProp(the spriteList of gDir, #DoorStart) - 1
      play(gSound, "03e010v0", #EFFECT)
      set the loc of sprite getaProp(the spriteList of gDir, #FiggeInterup) to point(700, 500)
      activate(gDir, 1)
    #Still:
      set tempMode to #Still
  end case
  set mode to tempMode
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
