property mediaName, goToType, trackRect, doortracking, screenObject, activeClick, currentSound
global gDir, gMulleGlobals, gSound

on beginSprite me
  set doortracking to 0
  set trackRect to the rect of sprite the currentSpriteNum
  set screenObject to new(script("screenObject"), me, trackRect, 0)
  addScreenObject(gDir, screenObject)
  set activeClick to 1
  set currentSound to EMPTY
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
        if not the mouseDown then
          sendSprite(115, #c_Left)
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
      if not the mouseDown then
        sendSprite(115, #C_Standard)
      end if
      set doortracking to 0
    end if
  end if
end

on report me, theObject, what
  if activeClick then
    set Test to 0
    if what = #clicked then
      if sendSprite(getaProp(the spriteList of gDir, #Mulle), #checkEquipment, #wheels) then
        sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #noWheels)
        set Test to 1
      else
        if sendSprite(getaProp(the spriteList of gDir, #Mulle), #checkEquipment, #Seat) then
          sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #noSeat)
          set Test to 1
        end if
      end if
      if Test = 0 then
        set activeClick to 0
        updateProperties(the car of the user of gMulleGlobals)
        set the toYardThroughDoor of the user of gMulleGlobals to 0
        set the WhereFrom of gMulleGlobals to "03"
        stopAllEffects(gSound)
        go("garage")
      end if
    end if
  end if
end

on checkMyRect me
  if inside(point(the mouseH, the mouseV), trackRect) then
    go(string(mediaName))
  end if
end

on getPropertyDescriptionList
  set p_list to [#mediaName: [#comment: "the name of the destination marker:", #format: #string, #default: EMPTY], #goToType: [#comment: "Destination is:", #format: #symbol, #range: [#movie, #marker], #default: #marker]]
  return p_list
end
