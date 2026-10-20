property masterSP, ScrollBHType, SP, mouseOnMe, childSprites, topLimit, grabbedOffset, mySpace, regTopOffset, regPointPercent, myHeight, myTop, waitFrames, midStretch

on beginSprite me
  set SP to the spriteNum of me
  set childSprites to [1]
end

on init me, theMasterSP
  set masterSP to theMasterSP
end

on SetChildren me, theList
  set childSprites to duplicate(theList)
  set tempRect to the rect of sprite getAt(childSprites, 1)
  set limits to [getAt(tempRect, 2), getAt(tempRect, 4)]
  set topLimit to getAt(tempRect, 2)
  set mySpace to getAt(tempRect, 4) - getAt(tempRect, 2)
  set regPointPercent to 100 * getAt(the regPoint of the member of sprite SP, 2) / getAt(the rect of the member of sprite SP, 4)
end

on mouseDown me
  set mouseOnMe to 1
  if ScrollBHType = #ScrollerMid then
    set grabbedOffset to the mouseV - the locV of sprite SP
  else
    if ScrollBHType = #ScrollerBehind then
      set tempMouse to the mouseV
      set tempScroll to 0
      if tempMouse < myTop then
        set tempScroll to -1
      else
        if tempMouse > myTop + myHeight then
          set tempScroll to 1
        end if
      end if
      sendSprite(masterSP, #scroll, #Page, tempScroll)
    else
      if ScrollBHType = #ArrowUp or ScrollBHType = #ArrowDown then
        set waitFrames to 0
        exitFrame(me)
        set waitFrames to 3
      end if
    end if
  end if
end

on mouseUp me
  set mouseOnMe to 0
end

on mouseUpOutSide me
  set mouseOnMe to 0
end

on setScrollInfo me, thePercentDown, thePercentFilled
  if ScrollBHType = #ScrollerMid then
    if midStretch then
      if integerp(thePercentFilled) then
        set myHeight to mySpace * thePercentFilled / 100
        if myHeight < 20 then
          set myHeight to 20
        end if
        set the height of sprite SP to myHeight
        set tempRect to the rect of sprite SP
        set regTopOffset to myHeight * regPointPercent / 100
      end if
      set tempDown to thePercentDown * (mySpace - myHeight) / 100
      set myTop to topLimit + tempDown
      set the locV of sprite SP to myTop + regTopOffset
      setScrollEnds(me)
    else
      set tempDown to thePercentDown * mySpace / 100
      set myTop to topLimit + tempDown
      set the locV of sprite SP to myTop
    end if
  else
    if ScrollBHType = #ScrollerBehind then
      set myTop to thePercentDown
      set myHeight to thePercentFilled
    end if
  end if
end

on setScrollEnds me
  if getAt(childSprites, 2) > 0 then
    set the locV of sprite getAt(childSprites, 2) to myTop
    set the locV of sprite getAt(childSprites, 3) to myTop + myHeight
  end if
  sendSprite(getAt(childSprites, 1), #setScrollInfo, myTop, myHeight)
end

on exitFrame me
  if ScrollBHType = #ScrollerMid then
    if mouseOnMe then
      if midStretch then
        set goFor to the mouseV - grabbedOffset
        if goFor < regTopOffset + topLimit then
          set tempLocV to regTopOffset + topLimit
        else
          if goFor > regTopOffset + topLimit + mySpace - myHeight then
            set tempLocV to regTopOffset + topLimit + mySpace - myHeight
          else
            set tempLocV to goFor
          end if
        end if
        set the locV of sprite SP to tempLocV
        set myTop to tempLocV - regTopOffset
        set tempMaxDown to mySpace - myHeight
        if tempMaxDown = 0 then
          set tempMaxDown to 1
        end if
        sendSprite(masterSP, #scroll, #percent, 100 * (myTop - topLimit) / tempMaxDown)
        setScrollEnds(me)
      else
        set goFor to the mouseV - grabbedOffset
        if goFor < topLimit then
          set tempLocV to topLimit
        else
          if goFor > topLimit + mySpace then
            set tempLocV to topLimit + mySpace
          else
            set tempLocV to goFor
          end if
        end if
        set the locV of sprite SP to tempLocV
        set myTop to tempLocV
        set tempMaxDown to mySpace
        if tempMaxDown = 0 then
          set tempMaxDown to 1
        end if
        sendSprite(masterSP, #scroll, #percent, 100 * (myTop - topLimit) / tempMaxDown)
        setScrollEnds(me)
      end if
    end if
  else
    if ScrollBHType = #ArrowUp or ScrollBHType = #ArrowDown then
      if mouseOnMe then
        if waitFrames then
          set waitFrames to waitFrames - 1
        else
          if ScrollBHType = #ArrowUp then
            sendSprite(masterSP, #scroll, #Relative, -1)
          else
            sendSprite(masterSP, #scroll, #Relative, 1)
          end if
        end if
      end if
    end if
  end if
end

on getPropertyDescriptionList me
  set p_list to [#ScrollBHType: [#comment: "This sprite is:", #format: #symbol, #range: [#ArrowUp, #ArrowDown, #ScrollerUp, #ScrollerMid, #ScrollerDown, #ScrollerBehind], #default: #ArrowUp], #midStretch: [#comment: "Stretch scrollbar:", #format: #boolean, #default: 1]]
  return p_list
end
