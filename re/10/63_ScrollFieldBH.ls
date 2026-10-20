property myMember, AutoFind, arrowUpSP, arrowDownSP, scrollerBehindSP, scrollerUpSP, scrollerMidSP, scrollerDownSP, enterFieldSP, trashSP, draggerSP, spriteList, SP, RelativeSP, lineNr, nrOfLines, visibleLines, textList, downOnLine, waitFrames, dragOffset
global gDir

on beginSprite me
  set SP to the spriteNum of me
  set spriteList to [#ArrowUp: arrowUpSP, #ArrowDown: arrowDownSP, #ScrollerBehind: scrollerBehindSP, #ScrollerUp: scrollerUpSP, #ScrollerMid: scrollerMidSP, #ScrollerDown: scrollerDownSP, #EnterField: enterFieldSP, #trash: trashSP, #Dragger: draggerSP]
  if RelativeSP then
    repeat with n = 1 to count(spriteList)
      if getAt(spriteList, n) <> 0 then
        setAt(spriteList, n, SP + getAt(spriteList, n))
      end if
    end repeat
  end if
  set draggerSP to getProp(spriteList, #Dragger)
  set trashSP to getProp(spriteList, #trash)
  set myMember to the name of the member of sprite the spriteNum of me
  if AutoFind then
    autoFindSprites(me)
  end if
  repeat with tempSP in spriteList
    if tempSP <> 0 then
      sendSprite(tempSP, #init, SP)
    end if
  end repeat
  set the scrollTop of member(myMember) to 0
  set lineNr to 1
  set nrOfLines to the number of lines in the text of member(myMember)
  set visibleLines to the height of sprite SP / the textHeight of member myMember
  set tempScroll to getProp(spriteList, #ScrollerMid)
  if tempScroll <> 0 then
    sendSprite(tempScroll, #SetChildren, [getProp(spriteList, #ScrollerBehind), getProp(spriteList, #ScrollerUp), getProp(spriteList, #ScrollerDown)])
  end if
end

on endSprite me
  set the text of member(myMember) to " "
end

on setText me, theText
  if listp(theText) then
    set textList to duplicate(theText)
    sort(textList)
  else
    set textList to []
    sort(textList)
    repeat with n = 1 to nrOfLines
      add(textList, line n of theText)
    end repeat
  end if
  set theText to EMPTY
  repeat with aLine in textList
    set theText to theText & aLine & RETURN
  end repeat
  delete char length(theText) of theText
  set the text of member(myMember) to theText
  set nrOfLines to count(textList)
  set the scrollTop of member(myMember) to 0
  scrollByLine(member(myMember), lineNr - 1)
  set tempScroll to getProp(spriteList, #ScrollerMid)
  if tempScroll <> 0 then
    set tempNrOf to nrOfLines
    if tempNrOf = 0 then
      set tempNrOf to 1
    end if
    set percentVisible to 100 * visibleLines / tempNrOf
    if percentVisible > 100 then
      set percentVisible to 100
    end if
    set tempNrOf to nrOfLines - visibleLines
    if tempNrOf = 0 then
      set tempNrOf to 1
    end if
    set percentDown to 100 * (lineNr - 1) / tempNrOf
    sendSprite(tempScroll, #setScrollInfo, percentDown, percentVisible)
  end if
end

on autoFindSprites me
  set tempNecessary to [#ArrowUp, #ArrowDown]
  repeat with n = 1 to 120
    if the memberNum of sprite n > 0 then
      set tempObjects to the scriptInstanceList of sprite n
      repeat with bh in tempObjects
        set tempType to getaProp(bh, #ScrollBHType)
        if symbolp(tempType) then
          deleteOne(tempNecessary, tempType)
          setProp(spriteList, tempType, n)
        end if
      end repeat
    end if
  end repeat
  if count(tempNecessary) then
    alert("These scroller sprites were not found:" & string(tempNecessary))
  end if
end

on scroll me, theMode, how
  if theMode = #Relative then
    if lineNr + how > 0 and lineNr + how <= nrOfLines - visibleLines + 1 then
      set lineNr to lineNr + how
      scrollByLine(member(myMember), how)
      set tempNrOf to nrOfLines - visibleLines
      if tempNrOf = 0 then
        set tempNrOf to 1
      end if
      set tempPercent to 100 * (lineNr - 1) / tempNrOf
      sendSprite(getProp(spriteList, #ScrollerMid), #setScrollInfo, tempPercent)
    end if
  else
    if theMode = #Absolute then
      if how < 1 then
        set how to 1
      end if
      set diff to how - lineNr
      set lineNr to how
      scrollByLine(member(myMember), diff)
    else
      if theMode = #percent then
        set how to 1 + integer(how * (nrOfLines - visibleLines) / 100.0)
        set how to correctLine(me, how)
        set diff to how - lineNr
        set lineNr to how
        scrollByLine(member(myMember), diff)
      else
        if theMode = #Page then
          set how to lineNr + how * visibleLines
          set how to correctLine(me, how)
          set diff to how - lineNr
          set lineNr to how
          set tempNrOf to nrOfLines - visibleLines
          if tempNrOf = 0 then
            set tempNrOf to 1
          end if
          set tempPercent to 100 * (lineNr - 1) / tempNrOf
          sendSprite(getProp(spriteList, #ScrollerMid), #setScrollInfo, tempPercent)
          scrollByLine(member(myMember), diff)
        else
          if theMode = #Match then
            add(textList, how)
            set how to getPos(textList, how)
            deleteAt(textList, how)
            set how to how - 1
            set how to correctLine(me, how)
            set diff to how - lineNr
            set lineNr to how
            set tempNrOf to nrOfLines - visibleLines
            if tempNrOf = 0 then
              set tempNrOf to 1
            end if
            set tempPercent to 100 * (lineNr - 1) / tempNrOf
            sendSprite(getProp(spriteList, #ScrollerMid), #setScrollInfo, tempPercent)
            scrollByLine(member(myMember), diff)
          end if
        end if
      end if
    end if
  end if
end

on deleteLine me, theLine
  if stringp(theLine) then
    set tempOff to offset(theLine, the text of member(myMember))
    if tempOff then
      set theLine to the number of lines in char 1 to tempOff of the text of member(myMember)
    else
      exit
    end if
  end if
  if theLine > 0 and theLine <= nrOfLines then
    set nrOfLines to nrOfLines - 1
    if theLine <= lineNr then
      set lineNr to lineNr - 1
    else
      if lineNr = nrOfLines - visibleLines + 1 then
        set lineNr to lineNr - 1
      end if
    end if
    set lineNr to correctLine(me, lineNr)
    set tempStr to EMPTY
    set tempStr to getAt(textList, theLine)
    deleteAt(textList, theLine)
    setText(me, textList)
    resultsFromScroller(gDir, #DeletedLine, tempStr)
  end if
end

on AddLine me, theLine
  set tempOff to offset(theLine & RETURN, the text of member(myMember))
  if tempOff = 0 and count(textList) then
    set tempOff to theLine = getAt(textList, count(textList))
  end if
  if tempOff = 0 then
    if nrOfLines = 6 then
      sendSprite(getProp(the spriteList of gDir, #MulleHead), #fullAlert)
      exit
    end if
    add(textList, theLine)
    set lineNr to getPos(textList, theLine)
    set lineNr to correctLine(me, lineNr)
    setText(me, textList)
    resultsFromScroller(gDir, #NewLine, theLine)
  else
    resultsFromScroller(gDir, #ChoseLine, theLine)
  end if
end

on correctLine me, theLine
  if theLine <= 1 then
    set theLine to 1
  else
    if theLine > nrOfLines - visibleLines + 1 then
      set theLine to nrOfLines - visibleLines + 1
    end if
  end if
  if nrOfLines < visibleLines then
    set theLine to 1
  end if
  return theLine
end

on mouseDown me
  if nrOfLines = 0 then
    exit
  end if
  set tempLine to 1 + (the mouseV - the top of sprite SP) / the textHeight of member myMember
  if tempLine < 1 then
    set tempLine to 1
  else
    if tempLine > nrOfLines then
      set tempLine to nrOfLines
    end if
  end if
  set downOnLine to tempLine
  set waitFrames to 3
  if draggerSP then
    set the text of member(the memberNum of sprite draggerSP) to getAt(textList, tempLine)
    set dragOffset to point(-getAt(the rect of member(the memberNum of sprite draggerSP), 3) / 2, -25)
    sendSprite(trashSP, #startDrag)
  end if
end

on mouseUp me
  if nrOfLines = 0 then
    exit
  end if
  sendSprite(trashSP, #endDrag)
  set tempLine to 1 + (the mouseV - the top of sprite SP) / the textHeight of member myMember
  if tempLine < 1 then
    set tempLine to 1
  else
    if tempLine > nrOfLines then
      set tempLine to nrOfLines
    end if
  end if
  if the doubleClick then
    if tempLine = downOnLine then
      resultsFromScroller(gDir, #ChoseLine, getAt(textList, tempLine))
    end if
  else
    if tempLine = downOnLine then
      if getProp(spriteList, #EnterField) then
        set the text of member(the memberNum of sprite getProp(spriteList, #EnterField)) to getAt(textList, tempLine)
      end if
    end if
  end if
  if draggerSP then
    set the locH of sprite draggerSP to -4711
  end if
  set downOnLine to 0
end

on mouseUpOutSide me
  if draggerSP then
    if downOnLine then
      sendSprite(trashSP, #scrollThrowHere, SP, getAt(textList, downOnLine))
      set the locH of sprite draggerSP to -4711
    end if
  end if
  set downOnLine to 0
end

on exitFrame me
  if draggerSP then
    if downOnLine then
      if waitFrames then
        set waitFrames to waitFrames - 1
      else
        set the loc of sprite draggerSP to point(the mouseH, the mouseV) + dragOffset
      end if
    end if
  end if
end

on getPropertyDescriptionList me
  set p_list to [#AutoFind: [#comment: "Autofind necessary sprites: (might be slow)", #format: #boolean, #default: 0], #RelativeSP: [#comment: "Sprite channels are offsets:", #format: #boolean, #default: 1], #enterFieldSP: [#comment: "Use these channels (0 = unused):          Enter in field:", #format: #integer, #default: -8], #trashSP: [#comment: "Trash:", #format: #integer, #default: -7], #scrollerBehindSP: [#comment: "Behind scrollbar:", #format: #integer, #default: -6], #scrollerMidSP: [#comment: "Scrollbar stretch:", #format: #integer, #default: -5], #scrollerUpSP: [#comment: "Scrollbar top:", #format: #integer, #default: -4], #scrollerDownSP: [#comment: "Scrollbar bottom:", #format: #integer, #default: -3], #arrowUpSP: [#comment: "Arrow up:", #format: #integer, #default: -2], #arrowDownSP: [#comment: "Arrow down:", #format: #integer, #default: -1], #draggerSP: [#comment: "Drag text:", #format: #integer, #default: 1]]
  return p_list
end

on getBehaviorDescription me
  set str to "This BH is to be assigned to the scrolling field." & RETURN & "The arrows and scrollbars must be in lower (than this ch) numbered channels" & RETURN & "while drag text must be in a higher numbered channel." & RETURN & RETURN & "Results from clicking, entering new lines will be reported" & RETURN & "to a global handler:" & RETURN & "on resultsFromScroller resultType, aString" & RETURN & RETURN & "resultType = #ChoseLine (aString = chosen string)" & RETURN & "resultType = #NewLine (aString = new string)" & RETURN & "resultType = #DeletedLine (aString = deleted string)"
  return str
end
