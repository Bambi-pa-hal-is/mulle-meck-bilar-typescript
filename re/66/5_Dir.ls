property testing, partToGive, spriteList, stack1, stack2, stack3, can1, can2, can3, can4, can5, can6, dragLoc, pCan, canHeights, dragging, pCursors, pLeftKran, pCenterKran, pRightKran, pKranSprNum, pKranLocList, pItem, pPartsList, pGotPart
global gMulleGlobals

on new me
  set pPartsList to []
  set pGotPart to 0
  return me
end

on init me
  set testing to 0
  if objectp(the world of gMulleGlobals) then
    set objId to getEnteredObject(the world of gMulleGlobals)
  else
    set objId to 0
  end if
  if objId then
    set tempObj to new(script("Object"))
    fromList(tempObj, objId)
    set pPartsList to value(the text of member("PluginGameDB"))
    set partNum to count(pPartsList)
    repeat with X = 1 to partNum
      set part to getAt(pPartsList, random(count(pPartsList)))
      if findPart(the user of gMulleGlobals, part) = 0 then
        set partToGive to part
        set pGotPart to 1
        exit repeat
        next repeat
      end if
      deleteAt(pPartsList, getPos(pPartsList, part))
      set partToGive to 666
      set pGotPart to 0
    end repeat
    set tempObj to 0
  else
    set partToGive to 666
  end if
end

on checkBeenHereBefore me
  set pPartsList to value(the text of member("PluginGameDB"))
  set partNum to count(pPartsList)
  set BeenHereFlag to 0
  repeat with X = 1 to partNum
    set part to getAt(pPartsList, X)
    if not findPart(the user of gMulleGlobals, part) = 0 then
      set BeenHereFlag to 1
      exit repeat
    end if
  end repeat
  return BeenHereFlag
end

on getPartToGive me
  return partToGive
end

on loop me
end

on startMovie me
  sendSprite(115, #C_Standard)
end

on leave me
  if pGotPart then
    addJunkPart(the user of gMulleGlobals, #yard, partToGive)
  end if
end

on kill me
  return 0
end

on startGame me
  go("Game")
  set pLeftKran to "Kran1"
  set pCenterKran to "Kran2"
  set pRightKran to "Kran3"
  set pKranSprNum to 68
  set pKranLocList to ["point(125,152)", "point(320,155)", "point(486,154)"]
  set can1 to 61
  set can2 to 62
  set can3 to 63
  set can4 to 64
  set can5 to 65
  set can6 to 66
  set dragging to 0
  set canHeights to [1, 62, 48, 31, 35, 30]
  set the visible of sprite can1 to 1
  set stack1 to new(script("Parent CanStack"), 133, 407)
  set stack2 to new(script("Parent CanStack"), 325, 407)
  set stack3 to new(script("Parent CanStack"), 500, 407)
  push(stack1, can1, me)
  push(stack1, can2, me)
  push(stack1, can3, me)
  push(stack1, can4, me)
  push(stack1, can5, me)
  push(stack1, can6, me)
end

on GoLeft me
  if pItem = 1 then
    if the member of sprite pKranSprNum = member(pCenterKran) then
      set the member of sprite pKranSprNum to member(pLeftKran)
      set the loc of sprite pCan to value(getAt(pKranLocList, 1)) + getAt(canHeights, pCan - can1 + 1) / 2
    else
      if the member of sprite pKranSprNum = member(pRightKran) then
        set the member of sprite pKranSprNum to member(pCenterKran)
        set the loc of sprite pCan to value(getAt(pKranLocList, 2)) + getAt(canHeights, pCan - can1 + 1) / 2
      end if
    end if
  else
    if the member of sprite pKranSprNum = member(pCenterKran) then
      set the member of sprite pKranSprNum to member(pLeftKran)
    else
      if the member of sprite pKranSprNum = member(pRightKran) then
        set the member of sprite pKranSprNum to member(pCenterKran)
      end if
    end if
  end if
end

on GoRight me
  if pItem = 1 then
    if the member of sprite pKranSprNum = member(pLeftKran) then
      set the member of sprite pKranSprNum to member(pCenterKran)
      set the loc of sprite pCan to value(getAt(pKranLocList, 2)) + getAt(canHeights, pCan - can1 + 1) / 2
    else
      if the member of sprite pKranSprNum = member(pCenterKran) then
        set the member of sprite pKranSprNum to member(pRightKran)
        set the loc of sprite pCan to value(getAt(pKranLocList, 3)) + getAt(canHeights, pCan - can1 + 1) / 2
      end if
    end if
  else
    if the member of sprite pKranSprNum = member(pLeftKran) then
      set the member of sprite pKranSprNum to member(pCenterKran)
    else
      if the member of sprite pKranSprNum = member(pCenterKran) then
        set the member of sprite pKranSprNum to member(pRightKran)
      end if
    end if
  end if
end

on GoDown me
  if pItem then
    sendSprite(pCan, #dropItem)
    set pItem to 0
    set pCan to 0
  else
    puppetSound("P36ef008")
  end if
end

on GoUp me
  if pItem = 0 then
    if the member of sprite pKranSprNum = member(pLeftKran) then
      set pCan to getLast(the stack of stack1)
      set myStack to 1
    else
      if the member of sprite pKranSprNum = member(pCenterKran) then
        set pCan to getLast(the stack of stack2)
        set myStack to 2
      else
        set pCan to getLast(the stack of stack3)
        set myStack to 3
      end if
    end if
    if pCan <> 0 then
      sendSprite(pCan, #getItem)
      if the frameLabel = "Game" then
        set the loc of sprite pCan to value(getAt(pKranLocList, myStack)) + getAt(canHeights, pCan - can1 + 1) / 2
        set pItem to 1
      end if
    end if
  else
    puppetSound("P36ef008")
  end if
end
