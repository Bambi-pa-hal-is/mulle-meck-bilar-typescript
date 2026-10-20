property isInside, masterSP, withName, myMember, SP, dragging
global gSound, gDir

on beginSprite me
  set SP to the spriteNum of me
  set myMember to the memberNum of sprite SP
  set dragging to 0
  set ScrollBHType to #trash
end

on init me, theMasterSP
  set masterSP to theMasterSP
end

on scrollThrowHere me, theSpriteNum, theStr
  set dragging to 0
  if theSpriteNum = masterSP then
    if isInside then
      play(gSound, "11e002v0", #OPEFFECT)
      sendSprite(masterSP, #deleteLine, theStr)
      set the member of sprite SP to member(myMember + 1)
    end if
  end if
end

on mouseEnter me
  if dragging then
    play(gSound, "11e001v0", #OPEFFECT)
    sendSprite(getProp(the spriteList of gDir, #MulleHead), #WarnOfThrowing)
    set the member of sprite SP to member(myMember + 1)
  end if
  set isInside to 1
end

on mouseLeave me
  set the member of sprite SP to member(myMember)
  set isInside to 0
end

on startDrag me
  set dragging to 1
end

on endDrag me
  set dragging to 0
end

on mouseUp me
end

on mouseUpOutSide me
end
