property type, object, movement, frameListMember, firstFrame, FrameList, counter, listLen, soundMember, sndId, myChannel, waitForWhat, customMovement, allFrameLists, syncTalk, repeatIt, active, waitState, doWhat, movePathName, movePath, toLoc, nrOfSteps, allPathLists, actionActive, pathActive, actionCounter, pathCounter, pathRelative, myLoc, soundList, autoSound, opSndId
global gSound

on beginSprite me
  set type to #SpriteAnim
  if voidp(active) then
    set active to 1
    init(me)
  else
    if active then
      init(me)
    end if
  end if
end

on endSprite me
  if sndId then
    stop(gSound, sndId)
  end if
end

on activate me, YesNo
  set active to YesNo
end

on init me
  if not (object = #Custom) then
    set frameListMember to string(object)
  end if
  set myLoc to the loc of sprite the spriteNum of me
  if movement = #Custom then
    if char 1 of customMovement = "#" then
      delete char 1 of customMovement
    end if
    set movement to symbol(customMovement)
  end if
  setAnimFirstFrame(me, firstFrame)
  set waitState to #move
  setAnimChart(me, frameListMember)
  if length(toLoc) > 0 then
    set toLocStr to toLoc
    set toLoc to value(toLoc)
    if not listp(toLoc) then
      set tempOff to offset(",", toLocStr)
      if tempOff then
        set tempX to value(char 1 to tempOff - 1 of toLocStr)
        set tempY to value(char tempOff + 1 to length(toLocStr) of toLocStr)
        set toLoc to point(tempX, tempY)
      end if
    else
      set toLoc to point(getAt(toLoc, 1), getAt(toLoc, 2))
    end if
  end if
  setAnimPath(me, movePathName, toLoc, nrOfSteps)
  playAnimSound(me, soundMember)
  exitFrame(me)
end

on setAnimChart me, theName
  set tempChart to value(the text of member(theName & "AnimChart"))
  set allFrameLists to getaProp(tempChart, #Actions)
  set allPathLists to getaProp(tempChart, #Paths)
  setAnimAction(me, movement)
  set the member of sprite the spriteNum of me to member(firstFrame + getAt(FrameList, 1) - 1)
end

on setAnimFirstFrame me, theMember
  if firstFrame = EMPTY then
    set firstFrame to the number of member the member of sprite the spriteNum of me
  else
    set firstFrame to the number of member theMember
  end if
end

on playAnimSound me, theSnd
  if length(theSnd) > 0 then
    stop(gSound, sndId)
    set sndId to play(gSound, theSnd, #EFFECT)
    set myChannel to getChannel(gSound, sndId)
  else
    stop(gSound, sndId)
    set sndId to 0
    set myChannel to 0
  end if
end

on makeAnimSpeech me, theSnd
  set repeatIt to 1
  set syncTalk to 1
  playAnimSound(me, theSnd)
  set waitForWhat to #sound
end

on setAnimNormal me
  set repeatIt to 0
  set syncTalk to 0
  set waitForWhat to #Anim
  set doWhat to #SendSpriteMe
end

on getAnimAction me
  return movement
end

on getAnimWaitState me
  return waitState
end

on setAnimAction me, theMove
  if theMove = #Still then
    playAnimSound(me, EMPTY)
  end if
  set movement to theMove
  if theMove = #Wait then
    set options to getaProp(allFrameLists, #Wait)
    if waitState = #move then
      set tempFrameList to [getAt(options, 1)]
      set waitState to #Still
    else
      set theMove to getAt(options, random(count(options) - 1) + 1)
      set tempFrameList to getaProp(allFrameLists, theMove)
      set waitState to #move
    end if
  else
    set tempFrameList to getaProp(allFrameLists, theMove)
  end if
  set FrameList to []
  set soundList to []
  repeat with n = 1 to count(tempFrameList)
    set index to getAt(tempFrameList, n)
    if listp(index) then
      case getAt(index, 1) of
        #RndHold:
          set holdFrame to getAt(index, 2)
          set minVal to getAt(index, 3)
          set maxVal to getAt(index, 4)
          set tempRnd to minVal + random(maxVal - minVal)
          repeat with X = 1 to tempRnd
            add(FrameList, holdFrame)
            add(soundList, 0)
          end repeat
        #RndFrame:
          set rndList to getAt(index, 2)
          add(FrameList, getAt(rndList, random(count(rndList))))
          add(soundList, 0)
        #sound:
          set rndList to getAt(index, 2)
          set tempSnd to getAt(rndList, random(count(rndList)))
          if stringp(tempSnd) then
            add(soundList, tempSnd)
          else
            add(soundList, 0)
          end if
      end case
      next repeat
    end if
    add(FrameList, index)
    add(soundList, 0)
  end repeat
  if waitForWhat = #Anim and not (doWhat = #SendSpriteMe) and not (movement = #Wait) then
    add(FrameList, 1)
    add(soundList, 0)
  end if
  set listLen to count(FrameList)
  set actionCounter to 0
  set actionActive to 1
end

on setAnimPath me, movePathName, toLoc, nrOfSteps
  set pathActive to 0
  set pathCounter to 0
  if length(movePathName) then
    set movePath to getaProp(allPathLists, symbol(movePathName))
    set nrOfSteps to count(movePath)
    if pathRelative then
      repeat with n = 1 to count(movePath)
        setAt(movePath, n, getAt(movePath, n) + myLoc)
      end repeat
    end if
    set pathActive to 1
  else
    if listp(toLoc) then
      set movePath to []
      if pathRelative then
        set diff to toLoc
      else
        set diff to toLoc - myLoc
      end if
      set nrOfSteps to value(nrOfSteps)
      if nrOfSteps = 0 then
        set nrOfSteps to 1
      end if
      set step to diff / nrOfSteps
      repeat with n = 1 to nrOfSteps
        add(movePath, myLoc + step * n)
      end repeat
      set pathActive to 1
    end if
  end if
end

on spritecuePassed me, theChannel, cueNr, cueName
  if syncTalk then
    if myChannel = theChannel then
      if not finished(gSound, sndId) then
        if cueName = "Talk" then
          setAnimAction(me, #Talk)
        else
          if cueName = "Silence" then
            set waitState to #move
            setAnimAction(me, #Wait)
          end if
        end if
      end if
    end if
  end if
end

on exitFrame me
  if active then
    if pathActive then
      set pathCounter to pathCounter + 1
      set myLoc to getAt(movePath, pathCounter)
      if pathCounter >= nrOfSteps then
        set pathActive to 0
        if waitForWhat = #Path then
          doTheWhat(me)
          exit
        end if
      end if
    end if
    set the loc of sprite the spriteNum of me to myLoc
    if actionActive then
      set actionCounter to actionCounter + 1
      if autoSound then
        set tempSound to getAt(soundList, actionCounter)
        if stringp(tempSound) then
          stop(gSound, opSndId)
          set opSndId to play(gSound, tempSound, #OPEFFECT)
        end if
      end if
      set tempFrame to getAt(FrameList, actionCounter)
      set the member of sprite the spriteNum of me to member(firstFrame + tempFrame - 1)
      if actionCounter >= listLen then
        if repeatIt or movement = #Wait then
          setAnimAction(me, movement)
        else
          if movement = #Still then
            set actionCounter to 0
          else
            set actionActive to 0
            if waitForWhat = #Anim then
              doTheWhat(me)
            end if
          end if
        end if
      end if
    end if
    if sndId and waitForWhat = #sound then
      if finished(gSound, sndId) then
        doTheWhat(me)
      end if
    end if
  end if
end

on setAnimLoc me, theLoc, isRelational
  if isRelational then
    set myLoc to myLoc + theLoc
  else
    set tempPos to getPos(theLoc, -4711)
    if tempPos then
      setAt(theLoc, tempPos, getAt(myLoc, tempPos))
    end if
    set myLoc to theLoc
  end if
end

on doTheWhat me
  case doWhat of
    #GoNextFrame:
      go(the frame + 1)
    #GoNextMarker:
      go(#next)
    #SendSpriteMe:
      sendSprite(the spriteNum of me, #Stopped)
  end case
end

on getPropertyDescriptionList me
  set p_list to [#object: [#comment: "Predefined object:", #format: #symbol, #range: [#Standard, #Mulle, #Buffa, #Custom], #default: #Standard], #frameListMember: [#comment: "If #Custom, define frameChart member:", #format: #string, #default: EMPTY], #movement: [#comment: "Object's action:", #format: #symbol, #range: [#Still, #Talk, #Wait, #TalkWait, #Scratch, #Custom], #default: #Still], #customMovement: [#comment: "If #Custom, define action:", #format: #string, #default: EMPTY], #firstFrame: [#comment: "and first frame (if not defined, use shown member):", #format: #string, #default: EMPTY], #repeatIt: [#comment: "Repeat action:", #format: #boolean, #default: 0], #soundMember: [#comment: "Sound (member name):", #format: #string, #default: EMPTY], #syncTalk: [#comment: "Sync sound and talk:", #format: #boolean, #default: 0], #autoSound: [#comment: "Play auto sounds:", #format: #boolean, #default: 1], #waitForWhat: [#comment: "Wait for:", #format: #symbol, #range: [#none, #sound, #Anim, #Path], #default: #none], #doWhat: [#comment: "then", #format: #symbol, #range: [#GoNextFrame, #GoNextMarker, #SendSpriteMe], #default: #GoNextFrame], #movePathName: [#comment: "Move along path:", #format: #string, #default: EMPTY], #toLoc: [#comment: "Or to loc (point(x,y)):", #format: #string, #default: EMPTY], #nrOfSteps: [#comment: "Nr of steps:", #format: #integer, #default: 0], #pathRelative: [#comment: "Relative path:", #format: #boolean, #default: 1], #active: [#comment: "Active:", #format: #boolean, #default: 1]]
  return p_list
end
