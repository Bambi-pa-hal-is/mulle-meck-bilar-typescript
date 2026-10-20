property screenObjects, screenPriority, addScreenList, deleteScreenList, screenOver, screenDownOn, screenClicked, clicked, visibleList, loopObjects, deleteLoopList, addLoopList, type, gameFrames, noActionSince, ongoingAction, screenPrioObject, interfaceSprites, child, ending, mouseButtonActive, cursorOverList

on new me, theChild
  set child to theChild
  set type to #GameMaster
  set screenObjects to []
  set screenPriority to []
  set addScreenList to []
  set deleteScreenList to []
  set visibleList to []
  set loopObjects to []
  set deleteLoopList to []
  set addLoopList to []
  set noActionSince to 0
  set ongoingAction to []
  set ending to 0
  set interfaceSprites to []
  repeat with index in interfaceSprites
    puppetSprite(index, 1)
  end repeat
  set screenOver to 0
  set screenDownOn to 0
  set screenClicked to 0
  set screenPrioObject to 0
  set clicked to 0
  set gameFrames to 0
  set mouseButtonActive to 1
  set cursorOverList to [:]
  sort(cursorOverList)
  set the mouseUpScript to "virtualMouseUp"
  set the mouseDownScript to "virtualMouseDown"
  return me
end

on activateMouseButton me, YesNo
  set mouseButtonActive to YesNo
  if YesNo then
  end if
end

on loop me
  global gMemoryControl
  set screenOver to 0
  set tempMouse to 1
  set mouseLoc to point(the mouseH, the mouseV)
  if mouseButtonActive then
    if objectp(screenPrioObject) then
      if checkBetween(screenPrioObject, mouseLoc, tempMouse) then
        set screenOver to 1
        set tempMouse to 0
      end if
    end if
    repeat with index in screenObjects
      if ending then
        exit repeat
      end if
      if checkBetween(index, mouseLoc, tempMouse) then
        set screenOver to 1
        set tempMouse to 0
      end if
    end repeat
  end if
  if not screenOver then
  end if
  updateLoopObjects(me)
  doTheLoops(me)
  updateScreenObjects(me)
  set clicked to 0
  repeat with n = 1 to count(visibleList) / 2
    set the visible of sprite getAt(visibleList, n * 2 - 1) to getAt(visibleList, n * 2)
  end repeat
  set visibleList to []
  set gameFrames to gameFrames + 1
end

on mouseClick me
end

on cursorChange me, thePrio, what
  set tempPos to getaProp(cursorOverList, thePrio)
  if not voidp(tempPos) then
    deleteProp(cursorOverList, thePrio)
  end if
  if what = #none then
  else
    addProp(cursorOverList, thePrio, what)
  end if
end

on displayCursor me
  if count(cursorOverList) > 0 then
    set tempCursor to getAt(cursorOverList, count(cursorOverList))
    case tempCursor of
      #OpenHand:
        cursor(2)
      #ClosedHand:
        cursor(3)
    end case
  else
    cursor(-1)
  end if
end

on actionEnd me, what
  set noActionSince to gameFrames
  set tempPos to getPos(ongoingAction, what)
  if tempPos then
    deleteAt(ongoingAction, tempPos)
  end if
end

on actionStart me, what
  add(ongoingAction, what)
end

on changeVisible me, theSpriteNr, isVisible
  add(visibleList, theSpriteNr)
  add(visibleList, isVisible)
end

on screenPriority me, theObject, trueFalse
  if trueFalse then
    set screenPrioObject to theObject
  else
    set screenPrioObject to 0
  end if
end

on deleteScreenObject me, theObject
  add(deleteScreenList, theObject)
  set the active of theObject to 0
end

on deactivateAllScreenObjects me
  repeat with index in screenObjects
    deleteScreenObject(me, index)
  end repeat
  set ending to 1
  cursor(0)
end

on addScreenObject me, theObject, thePriority
  if voidp(thePriority) then
    add(addScreenList, theObject)
    add(addScreenList, 100)
  else
    add(addScreenList, theObject)
    add(addScreenList, thePriority)
  end if
end

on updateScreenObjects me
  if not ending then
    repeat with index in deleteScreenList
      set tempPos to getPos(screenObjects, index)
      if tempPos then
        deleteAt(screenObjects, tempPos)
        deleteAt(screenPriority, tempPos)
      end if
    end repeat
    set deleteScreenList to []
    repeat with n = 1 to count(addScreenList) / 2
      set tempFind to getAt(addScreenList, n * 2)
      if tempFind <> 0 then
        set tempLeft to 1
        set tempRight to count(screenObjects)
        if tempRight = 0 then
          add(screenObjects, getAt(addScreenList, n * 2 - 1))
          add(screenPriority, tempFind)
        else
          if tempFind >= getAt(screenPriority, tempRight) then
            add(screenObjects, getAt(addScreenList, n * 2 - 1))
            add(screenPriority, tempFind)
          else
            if tempFind <= getAt(screenPriority, tempLeft) then
              addAt(screenObjects, 1, getAt(addScreenList, n * 2 - 1))
              addAt(screenPriority, 1, tempFind)
            else
              repeat while 1
                set tempMid to (tempLeft + tempRight) / 2
                set tempValMid to getAt(screenPriority, tempMid)
                if tempValMid = tempFind then
                  exit repeat
                else
                  if tempValMid > tempFind then
                    set tempRight to tempMid
                  else
                    if tempValMid < tempFind then
                      set tempLeft to tempMid
                    end if
                  end if
                end if
                if tempRight = tempLeft + 1 then
                  set tempMid to tempRight
                  exit repeat
                end if
              end repeat
              addAt(screenObjects, tempMid, getAt(addScreenList, n * 2 - 1))
              addAt(screenPriority, tempMid, tempFind)
            end if
          end if
        end if
        next repeat
      end if
      add(screenObjects, getAt(addScreenList, n * 2 - 1))
      add(screenPriority, 100)
    end repeat
  end if
  set addScreenList to []
end

on deleteLoopObject me, theObject
  add(deleteLoopList, theObject)
end

on addLoopObject me, theObject
  add(addLoopList, theObject)
end

on updateLoopObjects me
  repeat with index in deleteLoopList
    set tempPos to getPos(loopObjects, index)
    if tempPos then
      deleteAt(loopObjects, tempPos)
    end if
  end repeat
  set deleteLoopList to []
  repeat with index in addLoopList
    add(loopObjects, index)
  end repeat
  set addLoopList to []
end

on doTheLoops me
  if count(loopObjects) then
    repeat with index in loopObjects
      loop(index)
    end repeat
  end if
end

on kill me
  repeat with index in screenObjects
    deleteScreenObject(me, index)
  end repeat
  repeat with index in loopObjects
    deleteLoopObject(me, index)
  end repeat
  set addScreenList to []
  set deleteScreenList to []
  set screenObjects to []
  set addLoopList to []
  set deleteLoopList to []
  set loopObjects to []
  set ending to 1
end
