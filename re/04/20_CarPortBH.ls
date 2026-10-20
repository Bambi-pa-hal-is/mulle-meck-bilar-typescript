property mediaName, goToType, trackRect, doortracking, screenObject, activeClick, alwaysOpen, locked
global gDir, gSound, gMulleGlobals

on beginSprite me
  set doortracking to 0
  set trackRect to the rect of sprite the currentSpriteNum
  set screenObject to new(script("screenObject"), me, trackRect, 0)
  addScreenObject(gDir, screenObject)
  set activeClick to 1
  set alwaysOpen to 0
  set locked to 0
  if the carOnYard of gDir then
    set alwaysOpen to 1
    set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum + 1
  end if
end

on activateClick me, theState
  set activeClick to theState
end

on mouseEnter me
  if not locked then
    if activeClick then
      if not doortracking and not alwaysOpen then
        set doortracking to 1
        play(gSound, "02e016v0", #OPEFFECT)
        set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum + 1
        if the tracking of the partsCommon of gDir then
          sendSprite(115, #c_MoveRight)
        else
          sendSprite(115, #C_Right)
        end if
      end if
    end if
  end if
end

on prepareFrame me
  if not locked then
    if doortracking and not alwaysOpen then
      if not inside(point(the mouseH, the mouseV), trackRect) then
        set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum - 1
        play(gSound, "02e015v0", #OPEFFECT)
        sendSprite(115, #C_Standard)
        set doortracking to 0
      end if
    end if
  end if
end

on report me, theObject, what
  if not locked then
    if activeClick then
      if alwaysOpen then
        if what = #over then
          set doortracking to 1
          if the mouseDown then
            sendSprite(115, #c_MoveRight)
          else
            sendSprite(115, #C_Right)
          end if
        else
          if what = #NotOver then
            set doortracking to 0
            sendSprite(115, #C_Standard)
          end if
        end if
      end if
      set tempCheck to 0
      set the toYardThroughDoor of the user of gMulleGlobals to 0
      if what = #clicked then
        if the carOnYard of gDir then
          set activeClick to 0
          set the WhereFrom of gMulleGlobals to "04_car"
          set the toYardThroughDoor of the user of gMulleGlobals to 0
          if goToType = #marker then
            go(string(mediaName))
          else
            go(1, mediaName)
          end if
        else
          set the WhereFrom of gMulleGlobals to "04_nocar"
          go("NoCar")
        end if
      end if
    end if
  end if
end

on getPropertyDescriptionList
  set p_list to [#mediaName: [#comment: "the name of the destination marker:", #format: #string, #default: EMPTY], #goToType: [#comment: "Destination is:", #format: #symbol, #range: [#movie, #marker], #default: #marker]]
  return p_list
end
