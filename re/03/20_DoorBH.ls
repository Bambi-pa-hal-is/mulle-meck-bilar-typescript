property mediaName, goToType, trackRect, doortracking, screenObject, activeClick, overPart
global gDir, gMulleGlobals, gSound

on beginSprite me
  set doortracking to 0
  set trackRect to the rect of sprite the spriteNum of me
  set screenObject to new(script("screenObject"), me, trackRect, 0)
  addScreenObject(gDir, screenObject)
  set activeClick to 1
  set overPart to 0
end

on activateClick me, theState
  set activeClick to theState
end

on mouseEnter me
  if activeClick then
    if count(the mouseOverCar of gDir) = 0 then
      if not doortracking then
        set doortracking to 1
        sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 0)
        play(gSound, "02e016v0", #OPEFFECT)
        set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum + 1
        if mediaName = "04" then
          if the mouseOverMulle of gDir = [] then
            if not the mouseDown then
              sendSprite(115, #c_Left)
            end if
          end if
        else
          if the tracking of the partsCommon of gDir then
            sendSprite(115, #c_MoveIn)
          else
            sendSprite(115, #c_click)
          end if
        end if
      end if
    end if
  end if
end

on prepareFrame me
  if doortracking then
    if not inside(point(the mouseH, the mouseV), trackRect) then
      sendSprite(getaProp(the spriteList of gDir, #Figge), #activateClick, 1)
      play(gSound, "02e015v0", #OPEFFECT)
      set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum - 1
      if the active of sprite(getaProp(the spriteList of gDir, #drag)) = 1 then
        sendSprite(115, #c_grab)
      else
        if overPart = 0 then
          sendSprite(115, #C_Standard)
        end if
      end if
      set doortracking to 0
    end if
  end if
end

on resizeRect me, small
  if small = 1 then
    set trackRect to rect(70, 25, 45, 100)
  else
    set trackRect to the rect of sprite the currentSpriteNum
  end if
end

on CheckMouse me
  if inside(point(the mouseH, the mouseV), trackRect) then
    return 1
  else
    return 0
  end if
end

on report me, theObject, what
  if what = #clicked then
    if count(the mouseOverCar of gDir) = 0 then
      if inside(point(the mouseH, the mouseV), trackRect) then
        updateProperties(the car of the user of gMulleGlobals)
        set the toYardThroughDoor of the user of gMulleGlobals to 1
        set the WhereFrom of gMulleGlobals to "03"
        if goToType = #marker then
          go(string(mediaName))
        else
          go(1, mediaName)
        end if
      end if
    end if
  end if
end

on getPropertyDescriptionList
  set p_list to [#mediaName: [#comment: "the name of the destination marker:", #format: #string, #default: EMPTY], #goToType: [#comment: "Destination is:", #format: #symbol, #range: [#movie, #marker], #default: #marker]]
  return p_list
end
