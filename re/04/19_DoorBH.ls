property mediaName, goToType, trackRect, doortracking, screenObject, activeClick, locked
global gDir, gSound, gMulleGlobals

on beginSprite me
  set doortracking to 0
  set trackRect to the rect of sprite the spriteNum of me
  set screenObject to new(script("screenObject"), me, trackRect, 0)
  addScreenObject(gDir, screenObject)
  set activeClick to 1
  set locked to 0
  if the carOnYard of gDir then
    set locked to 1
  end if
end

on activateClick me, theState
  set activeClick to theState
end

on mouseEnter me
  if not locked then
    if activeClick then
      if not doortracking then
        set doortracking to 1
        play(gSound, "02e016v0", #EFFECT)
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
    if doortracking then
      if not inside(point(the mouseH, the mouseV), trackRect) then
        set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum - 1
        play(gSound, "02e015v0", #EFFECT)
        sendSprite(115, #C_Standard)
        set doortracking to 0
      end if
    end if
  end if
end

on report me, theObject, what
  if not locked then
    set tempCheck to 0
    if what = #clicked then
      set tempCheck to 0
      if the carOnYard of gDir then
        if mediaName = "05" then
          set startCheck to sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #getProperty, #OkToRun)
          if startCheck then
            set crashCheck to sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #getProperty, #CrashState)
            if crashCheck = 0 then
              if goToType = #marker then
              else
              end if
            else
              if count(crashCheck) = 2 then
                set tempCheck to 1
                set tmpmarker to getAt(crashCheck, random(count(crashCheck)))
              else
                if count(crashCheck) = 1 then
                  set tempCheck to 1
                  set tmpmarker to getAt(crashCheck, 1)
                end if
              end if
            end if
          end if
        else
          if tempCheck = 0 then
            set the toYardThroughDoor of the user of gMulleGlobals to 1
            if goToType = #marker then
              go(string(mediaName))
            else
              go(1, mediaName)
            end if
          end if
        end if
      else
        set the toYardThroughDoor of the user of gMulleGlobals to 1
        set the WhereFrom of gMulleGlobals to "04"
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
