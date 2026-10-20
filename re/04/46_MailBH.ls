property trackRect, doortracking, screenObject, activeClick, locked, missionIsOn
global gDir, gSound, gMulleGlobals

on beginSprite me
  set doortracking to 0
  set trackRect to the rect of sprite the currentSpriteNum
  set screenObject to new(script("screenObject"), me, trackRect, 0)
  addScreenObject(gDir, screenObject)
  set activeClick to 1
  set locked to 0
  set missionIsOn to 0
end

on activateClick me, theState
  set activeClick to theState
end

on mouseEnter me
  if not locked then
    if missionIsOn = 0 then
      if activeClick then
        if not doortracking then
          set doortracking to 1
          play(gSound, "04e009v0", #EFFECT)
          set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum + 1
          sendSprite(115, #c_click)
        end if
      end if
    end if
  end if
end

on prepareFrame me
  if not locked then
    if missionIsOn = 0 then
      if doortracking then
        if not inside(point(the mouseH, the mouseV), trackRect) then
          set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum - 1
          play(gSound, "04e010v0", #EFFECT)
          sendSprite(115, #C_Standard)
          set doortracking to 0
        end if
      end if
    end if
  end if
end

on showMail me
  set the member of sprite the spriteNum of me to "02b005v0"
  set missionIsOn to 1
end

on mouseUp me
  if activeClick then
    if not locked then
      if missionIsOn = 1 then
        sendAllSprites(#activateClick, 0)
        if the carOnYard of gDir = 0 then
          sendSprite(getaProp(the spriteList of gDir, #mulleStand), #MakeMulleSpeak, #Mail)
        else
          sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #Mail)
        end if
        set missionIsOn to 0
      end if
    end if
  end if
end

on report me, theObject, what
  if activeClick then
    if not locked then
      if what = #clicked then
        if missionIsOn = 0 then
          if the carOnYard of gDir = 0 then
            if the mode of sprite(getaProp(the spriteList of gDir, #mulleStand)) = #Wait then
              sendSprite(getaProp(the spriteList of gDir, #mulleStand), #MakeMulleSpeak, #noMail)
            end if
          else
            if the mode of sprite(getaProp(the spriteList of gDir, #mulleInCar)) = #Wait then
              sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #noMail)
            end if
          end if
        end if
      end if
    end if
  end if
end
