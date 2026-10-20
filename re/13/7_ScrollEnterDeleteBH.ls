property ScrollBHType, myMember, masterSP, maxWidth

on beginSprite me
  set ScrollBHType to #EnterField
  set myMember to the memberNum of sprite the spriteNum of me
  set maxWidth to getAt(the rect of member(myMember), 3)
  set the text of member(myMember) to " "
end

on init me, theMasterSP
  set masterSP to theMasterSP
end

on keyDown me
  global gJustPressedKey, gMsgFromSP
  if the key = RETURN then
    set tempStr to cleanString(the text of member(myMember))
    set tempPos to offset(RETURN, tempStr)
    if tempPos then
      delete char tempPos of tempStr
    end if
    sendSprite(masterSP, #scroll, #Match, tempStr)
    sendSprite(masterSP, #AddLine, tempStr)
  else
    set gJustPressedKey to 1
    set gMsgFromSP to the spriteNum of me
    pass()
  end if
end

on GotIt me
  systemKeys()
  set tempLength to length(the text of member(myMember))
  set tempWidth to getAt(charPosToLoc(member(myMember), tempLength), 1)
  if tempWidth > maxWidth - 20 then
    delete char tempLength of field myMember
    set tempLength to tempLength - 1
  end if
  repeat while 1
    if the lineCount of member(myMember) > 1 then
      delete char tempLength of field myMember
      set tempLength to tempLength - 1
      next repeat
    end if
    exit repeat
  end repeat
  set tempStr to cleanString(the text of member(myMember))
  if length(tempStr) then
    sendSprite(masterSP, #scroll, #Match, tempStr)
  end if
end

on getBehaviorDescription me
  set str to "If you want the scrollfield to adjust to" & RETURN & "written text, you must add this in a global script (copy it):" & RETURN & RETURN & "on idle" & RETURN & "  global gJustPressedKey, gMsgFromSP" & RETURN & "  if (gJustPressedKey) then" & RETURN & "    sendSprite (gMsgFromSP, #GotIt)" & RETURN & "    set gJustPressedKey = FALSE" & RETURN & "  end if" & RETURN & "end"
  return str
end
