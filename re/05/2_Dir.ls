property ancestor, map, carDriving, mode, objects, maxObjects, carCopy, spriteList, mapCoordinate, nextDir, drivingHandlers, maxSPUnder, maxSPOver, keyHandlers, usedArrows, sndId, correctedCarLoc, gotKeyPoll, wasSoundOn
global gMulleGlobals, gPathGlobals, gSound

on new me
  set carCopy to the car of the user of gMulleGlobals
  set ancestor to new(script("GeneralAncestor"), me)
  set drivingHandlers to new(script("DrivingHandlers"))
  set spriteList to [#map: 1, #ObjectsUnder: 5, #ObjectsOver: 21, #car: 20, #medal: 64, #KPH: 58, #Petrol: 59, #fDialog: 110, #ShowCar: 55, #RealCar: 20, #ShowOff: 50]
  set nextDir to EMPTY
  set mode to #Preparing
  set maxObjects to 5
  set maxSPUnder to 15
  set maxSPOver to 10
  set objects to []
  set keyHandlers to new(script("KeyHandlers"))
  set the loc of sprite getProp(spriteList, #map) to point(320, 396 / 2 + 4)
  openXtra(gPathGlobals, #KeyPoll)
  set gotKeyPoll to findXtra(gPathGlobals, "KeyPoll")
  loadWorld(me)
  setProp(spriteList, #car, getProp(spriteList, #ShowCar))
  set mode to #Showing
  return me
end

on loadWorld me
  if not objectp(the world of gMulleGlobals) then
    set the world of gMulleGlobals to new(script("World"))
    set the lastWorld of the worlds of gMulleGlobals to 0
  end if
  if not isSameWorld(the worlds of gMulleGlobals) then
    set oneWorld to the activeWorld of the worlds of gMulleGlobals
    if oneWorld = 0 then
      set oneWorld to getAt(getAt(getWorldSymbols(the worlds of gMulleGlobals), 1), 2)
    end if
    set status to loadWorld(the worlds of gMulleGlobals, the world of gMulleGlobals, oneWorld)
    if symbolp(status) then
      alert("World error: " & string(status))
      exit
    end if
    calcRandomDestinations(the world of gMulleGlobals)
  end if
  if getDrivingInfo(the user of gMulleGlobals) = 0 then
    randomizeDestinations(the world of gMulleGlobals)
  end if
  calcCurrentlyAvailable(the externalParts of gMulleGlobals)
  set map to new(script("Map"))
  set status to loadMap(the maps of gMulleGlobals, map, getCurrentMapId(the world of gMulleGlobals))
  if symbolp(status) then
    alert("Map error:" & string(status))
    exit
  end if
end

on init me
  set usedArrows to 0
  set tempInfo to getDrivingInfo(the user of gMulleGlobals)
  if tempInfo = 0 then
    set tempInfo to getStartInfo(the world of gMulleGlobals)
    set startFuel to #Full
    set startKeySteer to 1
  else
    set startFuel to getaProp(tempInfo, #fuel)
    set startKeySteer to getaProp(tempInfo, #keySteer)
  end if
  changeMap(me, getaProp(tempInfo, #map), #Absolute, 0)
  setDoIdle(keyHandlers, 0)
end

on startCar me
  set the member of sprite getProp(spriteList, #ShowCar) to member("Dummy")
  if not objectp(carDriving) then
    set carDriving to new(script("CarDriving"))
  end if
  set tempInfo to getDrivingInfo(the user of gMulleGlobals)
  if tempInfo = 0 then
    set tempInfo to getStartInfo(the world of gMulleGlobals)
    set startFuel to #Full
    set startKeySteer to 1
  else
    set startFuel to getaProp(tempInfo, #fuel)
    set startKeySteer to getaProp(tempInfo, #keySteer)
  end if
  setKeySteer(me, startKeySteer)
  init(carDriving, [#StartCoordinate: getaProp(tempInfo, #coordinate), #StartDirection: getaProp(tempInfo, #direction), #startFuel: startFuel])
  changeMap(me, getaProp(tempInfo, #map), #Absolute)
  checkTerrain(carDriving)
  setDoIdle(keyHandlers, 1)
  sendSprite(getProp(spriteList, #Petrol), #init)
  set mode to #Driving
end

on startMovie me
  set the member of sprite 118 to member("Dummy")
  set the member of sprite 119 to member("Dummy")
  stopBG(gSound)
  stopAllEffects(gSound)
  sendSprite(115, #MEnter, "00b023v0", 1)
end

on teleport me, theWorld, theMap, theLoc
  set the activeWorld of the worlds of gMulleGlobals to theWorld
  loadWorld(me)
  changeMap(me, theMap, #Absolute)
  setCoordinate(carDriving, theLoc)
end

on changeMap me, thePoint, theMode, theRealInit
  if voidp(theMode) then
    set theMode to #Relational
  end if
  if voidp(thePoint) then
    set thePoint to point(0, 0)
  end if
  set temp to getNewMapId(the world of gMulleGlobals, thePoint, theMode)
  if integerp(temp) then
    if theMode = #Relational then
      set mapCoordinate to mapCoordinate + thePoint
    else
      set mapCoordinate to thePoint
    end if
    set status to loadMap(the maps of gMulleGlobals, map, temp)
    if symbolp(status) then
      alert("Map error:" & string(status))
      exit
    end if
    set the member of sprite getProp(spriteList, #map) to member(getMapImage(map))
    if voidp(theRealInit) then
      setTopology(carDriving, getTopology(map))
      set correctedCarLoc to 0
      goThroughObjects(me)
      if listp(correctedCarLoc) then
        setCoordinate(carDriving, correctedCarLoc, #AdjustTopo)
      end if
    end if
    return 1
  else
    return 0
  end if
end

on prepareToLeave me, toDir
  set the WhereFrom of gMulleGlobals to "05"
  stopEngine(the displayObject of carDriving)
  set nextDir to toDir
  if toDir = "04" or toDir = "03" then
    setDrivingInfo(the user of gMulleGlobals, 0)
    go("GoHome")
    exit
  else
    if toDir = "08" then
      set tempList to [#map: mapCoordinate, #direction: getDirection(carDriving), #coordinate: getCoordinate(carDriving), #fuel: the fuel of carDriving, #keySteer: the keySteer of carDriving]
      setDrivingInfo(the user of gMulleGlobals, tempList)
      go("08")
      exit
    else
      set tempList to [#map: mapCoordinate, #direction: getDirection(carDriving), #coordinate: getCoordinate(carDriving), #fuel: the fuel of carDriving, #keySteer: the keySteer of carDriving]
      setDrivingInfo(the user of gMulleGlobals, tempList)
      go("Leave")
    end if
  end if
end

on loop me
  if mode = #Driving then
    set carLoc to getShowCoordinate(carDriving)
    repeat with index in objects
      step(index, carLoc)
    end repeat
  end if
  loop(ancestor)
end

on loginEnd me
end

on goThroughObjects me
  repeat with index in objects
    kill(index)
  end repeat
  set objects to []
  set rDests to getRandomDestinations(the world of gMulleGlobals)
  set tempSPUnder to getProp(spriteList, #ObjectsUnder)
  set tempSPOver to getProp(spriteList, #ObjectsOver)
  repeat with n = 0 to maxSPUnder - 1
    set the member of sprite tempSPUnder + n to member("Dummy")
  end repeat
  repeat with n = 0 to maxSPOver - 1
    set the member of sprite tempSPOver + n to member("Dummy")
  end repeat
  set objectsData to getObjects(map)
  set SPCounterUnder to 0
  set SPCounterOver to 0
  set tempCarLoc to getShowCoordinate(carDriving)
  repeat with n = 1 to count(objectsData)
    set tempObj to new(script("Object"))
    set tempObjData to getAt(objectsData, n)
    set ObjectId to getAt(tempObjData, 1)
    set objectLoc to getAt(tempObjData, 2)
    if count(tempObjData) = 3 then
      set objectOptional to getAt(tempObjData, 3)
    else
      set objectOptional to [:]
    end if
    if fromList(tempObj, ObjectId) then
      set tempOK to 0
      if getType(tempObj) = #rdest then
        set tempInMap to getaProp(rDests, ObjectId)
        if tempInMap = mapCoordinate then
          set tempOK to 1
        end if
      else
        if getType(tempObj) = #Correct then
          set tempDiff to tempCarLoc - objectLoc
          set tempH to getAt(tempDiff, 1)
          set tempV to getAt(tempDiff, 2)
          set hypo to sqrt(tempH * tempH + tempV * tempV)
          if count(objectOptional) = 0 then
            set tempRadius to 80
          else
            set tempRadius to getaProp(objectOptional, #InnerRadius)
            if voidp(tempRadius) then
              set tempRadius to 80
            end if
          end if
          if hypo < tempRadius then
            set correctedCarLoc to objectLoc
          end if
        else
          set tempOK to 1
        end if
      end if
      if tempOK then
        set showIt to init(tempObj, [SPCounterOver + tempSPOver, SPCounterUnder + tempSPUnder], objectLoc, objectOptional, tempCarLoc)
        if showIt then
          set tempSPInfo to getSpritesInfo(tempObj)
          repeat with m = 1 to count(tempSPInfo)
            case getPropAt(tempSPInfo, m) of
              #over:
                set SPCounterOver to SPCounterOver + getAt(tempSPInfo, m)
              #Under:
                set SPCounterUnder to SPCounterUnder + getAt(tempSPInfo, m)
            end case
          end repeat
          add(objects, tempObj)
        end if
      end if
    end if
  end repeat
end

on setKeySteer me, YesNo
  if voidp(YesNo) then
    set YesNo to the keySteer of carDriving
  end if
  set the keySteer of carDriving to YesNo
  if YesNo then
    sendSprite(115, #setMode, #Keys)
  else
    sendSprite(115, #setMode, #mouse)
  end if
end

on keyDown me, which
  if mode = #Driving then
    if the userSteer of carDriving then
      case which of
        #left:
          steer(carDriving, -1)
        #right:
          steer(carDriving, 1)
        #up:
          set usedArrows to 0
          changeSpeed(carDriving, 1)
        #down:
          set usedArrows to 0
          changeSpeed(carDriving, -1)
        #ArrowUp:
          set usedArrows to 1
          changeSpeed(carDriving, 1)
        #ArrowDown:
          set usedArrows to 1
          changeSpeed(carDriving, -1)
      end case
    end if
  end if
end

on keyUp me, which
  if mode = #Driving then
    if the userSteer of carDriving then
      if which = #up or which = #down then
        changeSpeed(carDriving, 0)
      else
        if usedArrows then
          changeSpeed(carDriving, 0)
        end if
        steer(carDriving, 0)
      end if
    end if
  end if
end

on changecarSound me
  if objectp(carDriving) then
    changecarSound(the displayObject of carDriving)
  end if
end

on stopSound me
  sendSprite(getProp(spriteList, #medal), #stopSound)
  stopSound(carDriving)
end

on activate me, YesNo
  if YesNo then
    set mode to #Driving
    setDoIdle(keyHandlers, 1)
    if wasSoundOn then
      changecarSound(the displayObject of carDriving, 1)
    end if
  else
    stopBG(gSound)
    if not (mode = #Showing) then
      set wasSoundOn to the soundOn of the displayObject of carDriving
      set the keySteer of carDriving to the wasKeySteer of keyHandlers
      setKeySteer(me, the wasKeySteer of keyHandlers)
    end if
    set mode to #Waiting
    setDoIdle(keyHandlers, 0)
  end if
end

on OutOfFuel me, lastToEnd
  set mode to #OutOfGas
  set tempObj to new(script("OutOfFuelScript"), lastToEnd)
end

on kill me
  if objectp(keyHandlers) then
    set keyHandlers to kill(keyHandlers)
  end if
  if objectp(carDriving) then
    set carDriving to kill(carDriving)
  end if
  set drivingHandlers to kill(drivingHandlers)
  set ancestor to kill(ancestor)
  return 0
end
