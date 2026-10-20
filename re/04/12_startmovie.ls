on startMovie me
  global gDir, gMulleGlobals, gSound
  stopAllEffects(gSound)
  stopBG(gSound)
  if the loadIndicator of gMulleGlobals = 0 then
    play(gSound, "02e010v0", #BG)
  end if
  set the keyDownScript to "systemkeys"
  if the carOnYard of gDir then
    sendSprite(getProp(the spriteList of gDir, #mulleInCar), #activate, 1)
    sendSprite(getProp(the spriteList of gDir, #mulleInCar), #init, 1)
    sendSprite(getProp(the spriteList of gDir, #mulleStand), #activate, 0)
    sendSprite(getProp(the spriteList of gDir, #Buffa), #activate, 0)
    sendSprite(getProp(the spriteList of gDir, #CarStart), #drawCar)
  else
    sendSprite(getProp(the spriteList of gDir, #mulleStand), #activate, 1)
    sendSprite(getProp(the spriteList of gDir, #mulleStand), #init, 1)
    sendSprite(getProp(the spriteList of gDir, #Buffa), #activate, 1)
    sendSprite(getProp(the spriteList of gDir, #Buffa), #init, 1)
    sendSprite(getProp(the spriteList of gDir, #mulleInCar), #activate, 0)
  end if
  sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
  sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #setMulleSpeak)
  checKPostal()
  if the gifts of the user of gMulleGlobals <> [] then
    if the carOnYard of gDir then
      sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #Package)
    else
      sendSprite(getaProp(the spriteList of gDir, #mulleStand), #MakeMulleSpeak, #Package)
    end if
    set the member of sprite getaProp(the spriteList of gDir, #giftSprite) to the number of member "04b004v0"
    set the loc of sprite getaProp(the spriteList of gDir, #giftSprite) to point(180, 410)
  else
    if the figgeBeenHere of the junkPileHandlers of gMulleGlobals then
      if the carOnYard of gDir then
        sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #MakeMulleSpeak, #FiggeRemark)
      else
        sendSprite(getaProp(the spriteList of gDir, #mulleStand), #MakeMulleSpeak, #FiggeRemark)
      end if
      set the figgeBeenHere of the junkPileHandlers of gMulleGlobals to 0
    end if
  end if
  checkMissions(the missions of gMulleGlobals)
  if objectp(the currentMission of the missions of gMulleGlobals) = 1 then
    if the missionIsComing of the user of gMulleGlobals = 1 then
      if getType(the currentMission of the missions of gMulleGlobals) = #Mail then
        sendSprite(getaProp(the spriteList of gDir, #mailBox), #showMail, 1)
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
end

on checKPostal me
  global gMulleGlobals
  calcCurrentlyAvailable(the externalParts of gMulleGlobals, #Postal)
  set newGiftList to getCurrentlyAvailable(the externalParts of gMulleGlobals, #Postal)
  repeat with n = 1 to count(newGiftList)
    add(the gifts of the user of gMulleGlobals, list(getAt(newGiftList, n)))
  end repeat
end

on CuePassed channel, number, name
  global gDir
  set X to value(the last char in string(channel))
  if the carOnYard of gDir then
    sendSprite(getaProp(the spriteList of gDir, #mulleInCar), #spritecuePassed, X, number, name)
  else
    sendSprite(getaProp(the spriteList of gDir, #mulleStand), #spritecuePassed, X, number, name)
  end if
  if name = "toNextFrame" then
    go(the frame + 1)
  end if
end
