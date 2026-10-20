property ancestor, spriteList, cursorOverList, partsCommon, carCopy, mouseOverCar, mouseOverMulle, mouseButtonActive, EnterShopEvent, StopSpeak
global gMulleGlobals, gDir, gSound

on new me
  put "A new ancestor"
  set ancestor to new(script("GeneralAncestor"), me)
  set spriteList to [#CarStart: 10, #drag: 100, #JunkStart: 46, #DoorStart: 3, #garage: 4, #DoorToYard: 5, #fDialog: 114, #cheatStart: 102, #fButton: 101, #Mulle: 6, #Buffa: 7, #Figge: 8, #TeleSmall: 2, #TeleBig: 109, #Mikro: 13, #HighLight: 9, #FiggeInterup: 120]
  set carCopy to the car of the user of gMulleGlobals
  set the loc of sprite getProp(spriteList, #fDialog) to point(320, 240)
  set the loc of sprite getProp(spriteList, #HighLight) to point(320, 240)
  set the mouseUpScript to "virtualMouseUp"
  set the mouseDownScript to "virtualMouseDown"
  set the keyDownScript to "systemkeys"
  set mouseOverCar to []
  set mouseOverMulle to []
  set EnterShopEvent to 0
  set mouseButtonActive to 1
  set StopSpeak to 0
  set mouseButtonActive to 1
  return me
end

on activate me, theState
  put "in activate"
  if theState then
    sendAllSprites(#activateClick, 1)
    set mouseButtonActive to 1
    sendSprite(getProp(spriteList, #CarStart), #drawCar)
  else
    sendAllSprites(#activateClick, 0)
    set mouseButtonActive to 0
  end if
end

on init me
  set partsCommon to new(script("PartsCommon"), me)
end

on startMovie me
  stopAllEffects(gSound)
  stopBG(gSound)
  set the loc of sprite getaProp(spriteList, #FiggeInterup) to point(700, 500)
  sendSprite(getProp(spriteList, #JunkStart), #drawJunk)
  sendSprite(getProp(spriteList, #CarStart), #drawCar)
  sendSprite(getaProp(spriteList, #Mulle), #checkEquipment, #none)
  checkMissions(the missions of gMulleGlobals)
  if objectp(the currentMission of the missions of gMulleGlobals) = 1 then
    if the missionIsComing of the user of gMulleGlobals = 1 then
      if not (the nrOfBuiltCars of the user of gMulleGlobals mod 3 = 0 and the figgeIsComing of the user of gMulleGlobals = 1) then
        if getType(the currentMission of the missions of gMulleGlobals) = #Telephone then
          set EnterShopEvent to 1
          set StopSpeak to 1
          performMission(the missions of gMulleGlobals)
        end if
      end if
    end if
  end if
  if EnterShopEvent = 0 then
    checkFigge()
  end if
  if StopSpeak = 0 then
    if the justStarted of gMulleGlobals and the parts of the car of the user of gMulleGlobals = [1, 82, 133, 152] then
      sendSprite(getaProp(spriteList, #Mulle), #MakeMulleSpeak, #yourTurn)
      set the justStarted of gMulleGlobals to 0
    else
      if random(6) = 1 then
        sendSprite(getaProp(spriteList, #Mulle), #MakeMulleSpeak, #InspireYou)
      end if
    end if
  end if
  set the loc of sprite 115 to point(-20, -20)
  if the CustomCursorActive of gMulleGlobals then
    cursor(200)
  else
    sendSprite(115, #C_Standard)
  end if
  preloadMember("02e015v0")
  preloadMember("02e016v0")
  preloadMember("open1")
  preloadMember("open2")
  preloadMember("open3")
end

on checkFigge
  set NotMetHim to getUserProp(the user of gMulleGlobals, #Visited92)
  if not (NotMetHim = #NoProp) then
    calcCurrentlyAvailable(the externalParts of gMulleGlobals)
    if count(getCurrentlyAvailable(the externalParts of gMulleGlobals, #JunkMan)) > 0 then
      if the nrOfBuiltCars of the user of gMulleGlobals mod 3 = 0 and the figgeIsComing of the user of gMulleGlobals = 1 then
        set StopSpeak to 1
        sendSprite(getaProp(spriteList, #Figge), #doFigge)
        set the figgeIsComing of the user of gMulleGlobals to 0
        set the figgeBeenHere of the junkPileHandlers of gMulleGlobals to 1
      end if
    end if
  end if
end

on kill me
  if objectp(partsCommon) then
    set partsCommon to kill(partsCommon)
  end if
  if objectp(ancestor) then
    set ancestor to kill(ancestor)
  end if
  return 0
end
