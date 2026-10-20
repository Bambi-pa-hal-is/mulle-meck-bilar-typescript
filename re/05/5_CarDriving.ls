property speed, direction, fuel, coordinate, nrOfDirections, directionList, decimalPrec, Steering, acceleration, lastMouseH, lastMouseV, waitForTurn, quickCarProps, maxAcc, stopTimer, internalDirection, userSteer, Topology, lastCoordinate, wheels, reachForSpeed, reachForDirection, keySteer, forwardBackward, altitude, inclination, frameCount, shouldCheckGround, mouseForward, thisHit, inTerrain, directionLock, sndId, displayObject, cursorDirection, previousData, rememberThis, criteria, hornSound, gotElectricEngine
global gMulleGlobals, gDir, gSound

on new me
  set speed to 0
  set direction to 0
  set fuel to 0
  set coordinate to point(0, 0)
  set lastCoordinate to point(0, 0)
  set userSteer to 1
  set internalDirection to 0
  set waitForTurn to 0
  set Steering to 0
  set lastMouseLoc to point(0, 0)
  set nrOfDirections to 16
  set decimalPrec to 100
  set stopTimer to 0
  set Topology to EMPTY
  set directionList to []
  set reachForSpeed to 0
  set reachForDirection to 0
  set keySteer to 1
  set forwardBackward to 0
  set altitude to 0
  set inclination to 0
  set frameCount to 0
  set shouldCheckGround to 1
  set mouseForward to 1
  set cursorDirection to 1
  set previousData to []
  repeat with n = 1 to 10
    set temp to []
    add(temp, point(0, 0))
    add(temp, 1)
    add(temp, 0)
    add(previousData, duplicate(temp))
  end repeat
  set thisHit to 0
  set directionLock to 0
  set inTerrain to 0
  set pi to PI
  repeat with n = 1 to nrOfDirections
    set tempAngle to PI * 2 * n / float(nrOfDirections)
    set xPart to integer(decimalPrec * sin(tempAngle))
    set yPart to -integer(decimalPrec * cos(tempAngle))
    add(directionList, point(xPart, yPart))
  end repeat
  set quickCarProps to duplicate(the carProperties of the carCopy of gDir)
  if getaProp(quickCarProps, #Strength) = 0 then
    makeCar(#Good)
  end if
  set tempSounds to ["05e050v0", "05e049v0", "05e044v0", "05e042v0", "05d013v0"]
  set tempHorn to getaProp(quickCarProps, #HornType)
  if tempHorn > 0 and tempHorn <= count(tempSounds) then
    set hornSound to getAt(tempSounds, getProp(quickCarProps, #HornType))
  else
    set hornSound to getAt(tempSounds, 1)
  end if
  return me
end

on convertCarProps me
  set gotElectricEngine to 0
  repeat with partId in getParts(the car of the user of gMulleGlobals)
    set part to getPart(the parts of gMulleGlobals, partId)
    if getProperty(part, #ElectricConsumption) > 0 then
      set gotElectricEngine to 1
      exit repeat
    end if
  end repeat
  if gotElectricEngine then
    if getaProp(quickCarProps, #ElectricConsumption) < 0 then
      setProp(quickCarProps, #ElectricConsumption, 0)
    end if
  else
    setProp(quickCarProps, #ElectricVolume, 0)
  end if
  if getaProp(quickCarProps, #FuelConsumption) = 0 then
    setProp(quickCarProps, #FuelVolume, 0)
  end if
  if getaProp(quickCarProps, #speed) = 5 then
    setProp(quickCarProps, #speed, getaProp(quickCarProps, #speed) * decimalPrec * 27 / 10)
  else
    setProp(quickCarProps, #speed, getaProp(quickCarProps, #speed) * decimalPrec * 20 / 10)
  end if
  setProp(quickCarProps, #break, getaProp(quickCarProps, #break) * decimalPrec * 3 / 10)
  if getaProp(quickCarProps, #acceleration) = 0 then
    setProp(quickCarProps, #acceleration, 1)
  end if
  setProp(quickCarProps, #acceleration, getaProp(quickCarProps, #acceleration) * decimalPrec * 2 / 10)
  setProp(quickCarProps, #Steering, (getaProp(quickCarProps, #Steering) + 3) * decimalPrec * 2 / 20)
  setProp(quickCarProps, #FuelVolume, getaProp(quickCarProps, #FuelVolume) * decimalPrec * 12)
  setProp(quickCarProps, #ElectricVolume, getaProp(quickCarProps, #ElectricVolume) * decimalPrec * 15)
  set maxAcc to getaProp(quickCarProps, #break)
  if maxAcc < getaProp(quickCarProps, #acceleration) then
    set maxAcc to getaProp(quickCarProps, #acceleration)
  end if
  set criteria to [#MudGrip: 8, #HolesDurability: 3, #BigHill: 3, #SmallHill: 2]
  if getProp(quickCarProps, #Grip) > getProp(criteria, #MudGrip) then
    setProp(criteria, #MudGrip, 1)
  else
    setProp(criteria, #MudGrip, 0)
  end if
  if getProp(quickCarProps, #Durability) > getProp(criteria, #HolesDurability) then
    setProp(criteria, #HolesDurability, 1)
  else
    setProp(criteria, #HolesDurability, 0)
  end if
  if getProp(quickCarProps, #Strength) > getProp(criteria, #BigHill) then
    setProp(criteria, #BigHill, 1)
  else
    setProp(criteria, #BigHill, 0)
  end if
  if getProp(quickCarProps, #Strength) > getProp(criteria, #SmallHill) then
    setProp(criteria, #SmallHill, 1)
  else
    setProp(criteria, #SmallHill, 0)
  end if
  setEngine(displayObject)
end

on kill me
  set wheels to kill(wheels)
  set displayObject to kill(displayObject)
  return 0
end

on init me, theWorld
  if not objectp(displayObject) then
    set displayObject to new(script("DisplayCar"), me)
  end if
  if not objectp(wheels) then
    set wheels to new(script("Wheels"), me)
  end if
  start(me, theWorld)
end

on start me, theWorld
  set speed to 0
  set Steering to 0
  set coordinate to decimalPrec * getProp(theWorld, #StartCoordinate)
  set direction to getProp(theWorld, #StartDirection)
  set internalDirection to decimalPrec * direction
  set tempFuel to getProp(theWorld, #startFuel)
  if listp(tempFuel) then
    set fuel to tempFuel
    updateProperties(the car of the user of gMulleGlobals)
    set quickCarProps to duplicate(the carProperties of the carCopy of gDir)
    convertCarProps(me)
  else
    fillErUp(me)
  end if
  setCoordinate(wheels, coordinate)
end

on getCoordinate me
  return coordinate / decimalPrec
end

on setCoordinate me, theCoord, theOption
  set coordinate to theCoord * decimalPrec
  if theOption = #AdjustTopo then
    checkTerrain(me)
    set coordinate to coordinate + point(0, 3) * altitude * decimalPrec
  end if
end

on getShowCoordinate me
  return coordinate / decimalPrec - point(0, 3) * altitude
end

on getInclination me
  return inclination
end

on getSpeed me
  return speed / decimalPrec
end

on getDirection me
  return direction
end

on show me, YesNo
  show(displayObject, YesNo)
end

on saveData me, before
  if integerp(before) then
    set rememberThis to duplicate(getAt(previousData, count(previousData) - before))
  else
    if before = #none then
      set rememberThis to 0
    else
      set rememberThis to [duplicate(coordinate), direction, thisHit]
    end if
  end if
end

on restoreData me
  if listp(rememberThis) then
    set coordinate to getAt(rememberThis, 1)
    set direction to getAt(rememberThis, 2)
    set thisHit to getAt(rememberThis, 3)
    set temp to count(previousData)
    set previousData to []
    repeat with n = 1 to temp
      add(previousData, duplicate(rememberThis))
    end repeat
  else
  end if
end

on steer me, theDirection
  if directionLock then
    exit
  end if
  set Steering to theDirection
  set reachForDirection to 0
end

on lockDirection me, YesNo
  set directionLock to YesNo
  set Steering to 0
end

on changeSpeed me, upDown
  set acceleration to upDown
  set reachForSpeed to 0
end

on stepback me, theNr
  if theNr = #Remembered then
    if listp(rememberThis) then
      set temp to duplicate(rememberThis)
    else
      set temp to getAt(previousData, count(previousData) - 1)
    end if
  else
    set temp to getAt(previousData, count(previousData) - theNr + 1)
  end if
  set coordinate to getAt(temp, 1)
  set direction to getAt(temp, 2)
end

on fillErUp me
  global gMulleGlobals
  updateProperties(the car of the user of gMulleGlobals)
  set quickCarProps to duplicate(the carProperties of the carCopy of gDir)
  convertCarProps(me)
  set tempExtra to getCacheProp(the car of the user of gMulleGlobals, #ExtraTank)
  if tempExtra = #NoProp then
    set tempExtra to 0
  end if
  sendSprite(getProp(the spriteList of gDir, #Petrol), #fillErUp, tempExtra)
  set tempExtra to tempExtra + 100
  set tempGas to tempExtra * getaProp(quickCarProps, #FuelVolume) / 100
  if gotElectricEngine then
    set tempElec to getaProp(quickCarProps, #ElectricVolume)
  else
    set tempElec to 0
  end if
  set fuel to [tempGas, tempElec]
end

on getFuel me
  return fuel
end

on setSpeed me, theSpeed
  set reachForSpeed to 0
  set acceleration to 0
  set speed to theSpeed * decimalPrec
  if speed > 0 then
    set forwardBackward to 1
  else
    if speed < 0 then
      set forwardBackward to -1
    else
      set forwardBackward to 0
    end if
  end if
end

on setTopology me, theTopo
  setTopology(wheels, theTopo)
end

on setDirection me, theDirection
  set direction to correctDirection(the drivingHandlers of gDir, theDirection)
  set internalDirection to direction * decimalPrec
end

on programControl me, YesNo, theCheck
  set userSteer to not YesNo
  if theCheck = #NoCheck then
    set shouldCheckGround to 0
  else
    set shouldCheckGround to 1
  end if
end

on step me
  set frameCount to frameCount + 1
  if userSteer and not keySteer and not directionLock then
    mouseSteer(me)
  end if
  calculateSpeed(me)
  if reachForSpeed then
    if acceleration = 1 then
      if speed >= reachForSpeed then
        set speed to reachForSpeed
        set reachForSpeed to 0
      end if
    else
      if speed <= reachForSpeed then
        set speed to reachForSpeed
        set reachForSpeed to 0
      end if
    end if
  end if
  if Steering then
    set tempLastIntDir to internalDirection
    set internalDirection to internalDirection + Steering * getaProp(quickCarProps, #Steering)
    if internalDirection > nrOfDirections * decimalPrec then
      set internalDirection to internalDirection - nrOfDirections * decimalPrec
    else
      if internalDirection <= 0 then
        set internalDirection to nrOfDirections * decimalPrec + internalDirection
      end if
    end if
    set tempLastDir to direction
    set direction to internalDirection / decimalPrec
    if direction > nrOfDirections then
      set direction to 1
    else
      if direction < 1 then
        set direction to nrOfDirections
      end if
    end if
    if speed = 0 then
      if shouldCheckGround then
        checkTerrain(me)
      end if
    end if
  end if
  if reachForDirection then
    set reachForDirection to 0
    set Steering to 0
  end if
  if speed then
    set tempChangedWheelCoord to 0
    set lastCoordinate to duplicate(coordinate)
    set diff to speed * getAt(directionList, direction) / decimalPrec
    set tryCoordinate to coordinate + diff
    setCoordinate(wheels, tryCoordinate)
    if shouldCheckGround then
      set info to quickCheck(wheels, 0, direction, forwardBackward)
      if info = 0 then
        set tryCoordinate to makeTheBestOfHit(me, tryCoordinate)
        setCoordinate(wheels, tryCoordinate)
        set tempChangedWheelCoord to 1
        set info to quickCheck(wheels, 0, direction, forwardBackward)
      end if
      if checkTerrain(me, info) then
        set coordinate to tryCoordinate
      end if
    else
      set coordinate to tryCoordinate
    end if
    setCoordinate(wheels, coordinate)
    set temp to checkBorders(wheels, direction, forwardBackward)
    if listp(temp) then
      if integerp(getNewMapId(the world of gMulleGlobals, temp, #Relational, 1)) then
        if getAt(temp, 1) = -1 then
          set coordinate to point((640 - 8 - 1) * decimalPrec, getAt(coordinate, 2))
        else
          if getAt(temp, 1) = 1 then
            set coordinate to point((4 + 8) * decimalPrec, getAt(coordinate, 2))
          else
            if getAt(temp, 2) = -1 then
              set coordinate to point(getAt(coordinate, 1), (396 - 1) * decimalPrec)
            else
              if getAt(temp, 2) = 1 then
                set coordinate to point(getAt(coordinate, 1), (4 + 8) * decimalPrec)
              end if
            end if
          end if
        end if
        changeMap(gDir, temp)
        setCoordinate(wheels, coordinate)
      else
        stepback(me, 1)
        setSpeed(me, 0)
      end if
    end if
  end if
  set tempNoFuel to 0
  set temp to getAt(fuel, 1)
  if temp > 0 then
    set temp to temp - abs(speed) * getaProp(quickCarProps, #FuelConsumption) / decimalPrec
    if temp > 0 then
      setAt(fuel, 1, temp)
    else
      setAt(fuel, 1, 0)
      if getAt(fuel, 2) = 0 then
        updateEngine(the drivingHandlers of gDir, #NoFuel)
        set tempNoFuel to 1
      else
        stopAllEffects(gSound)
        sendSprite(getProp(the spriteList of gDir, #medal), #stop)
        play(gSound, "05d015v0", #EFFECT)
        updateEngine(the drivingHandlers of gDir, #NoGas)
      end if
      set quickCarProps to duplicate(the carProperties of the car of the user of gMulleGlobals)
      convertCarProps(me)
    end if
  end if
  set temp to getAt(fuel, 2)
  if temp > 0 then
    set temp to temp - abs(speed) * getaProp(quickCarProps, #ElectricConsumption) / decimalPrec
    if temp > 0 then
      setAt(fuel, 2, temp)
    else
      setAt(fuel, 2, 0)
      if getAt(fuel, 1) = 0 then
        updateEngine(the drivingHandlers of gDir, #NoFuel)
        set tempNoFuel to 2
      else
        stopAllEffects(gSound)
        sendSprite(getProp(the spriteList of gDir, #medal), #stop)
        play(gSound, "05d016v0", #EFFECT)
        updateEngine(the drivingHandlers of gDir, #NoElectricity)
      end if
      set quickCarProps to duplicate(the carProperties of the car of the user of gMulleGlobals)
      convertCarProps(me)
    end if
  end if
  if tempNoFuel then
    if not getaProp(quickCarProps, #Pedals) then
      setProp(quickCarProps, #speed, decimalPrec)
      programControl(me, 1)
      setSpeed(me, 0)
      changecarSound(displayObject, 0)
      OutOfFuel(gDir, tempNoFuel)
      exit
    else
      stopAllEffects(gSound)
      sendSprite(getProp(the spriteList of gDir, #medal), #stop)
      play(gSound, "05d017v0", #EFFECT)
    end if
  end if
  if userSteer then
    set temp to [duplicate(coordinate), direction, thisHit]
    add(previousData, temp)
    deleteAt(previousData, 1)
    set thisHit to 0
  end if
end

on mouseSteer me
  set temp to getAt(getAt(previousData, count(previousData) - 1), 3)
  if temp = #stop or temp = #Turn then
    set Steering to 0
    set reachForDirection to 0
    exit
  end if
  set temp to calcDirection(the drivingHandlers of gDir, getShowCoordinate(me), point(the mouseH, the mouseV), #WithHypo)
  set tempDirection to getAt(temp, 1)
  set cursorDirection to tempDirection
  set hypo to getAt(temp, 2)
  set reachForDirection to 1
  set diff to tempDirection - direction
  if abs(diff) >= nrOfDirections / 2 then
    set diff to -diff
  end if
  if diff > 0 then
    set Steering to 1
  else
    if diff < 0 then
      set Steering to -1
    else
      set Steering to 0
    end if
  end if
end

on calculateSpeed me
  if stopTimer > 0 then
    set stopTimer to stopTimer - 1
  end if
  if acceleration then
    if stopTimer = 0 then
      if forwardBackward = 0 then
        set tempAcc to acceleration * getaProp(quickCarProps, #acceleration)
      else
        if forwardBackward = acceleration then
          set tempAcc to acceleration * getaProp(quickCarProps, #acceleration)
        else
          set tempAcc to acceleration * getaProp(quickCarProps, #break)
          if abs(speed) <= maxAcc then
            set speed to 0
            set stopTimer to 5
            set tempAcc to 0
          end if
        end if
      end if
      set tempMax to getaProp(quickCarProps, #speed) * (keySteer * 25 + 75) / 100
      if speed <= tempMax and speed >= -tempMax / 2 then
        set speed to speed + tempAcc
      end if
      if speed > tempMax then
        set speed to tempMax
      else
        if speed < -tempMax / 4 then
          set speed to -tempMax / 4
        end if
      end if
    end if
    if speed > 0 then
      set forwardBackward to 1
    else
      if speed < 0 then
        set forwardBackward to -1
      else
        set forwardBackward to 0
      end if
    end if
  end if
end

on makeTheBestOfHit me, tryCoordinate
  if objectp(wheels) then
    if keySteer then
      set sideStepLimit to decimalPrec * 4
    else
      set sideStepLimit to decimalPrec * 3
    end if
    set hitInfo to checkHit(wheels, coordinate, tryCoordinate, speed, direction, sideStepLimit)
    if listp(hitInfo) then
      if getAt(hitInfo, 2) = #sideStep then
        set thisHit to getAt(hitInfo, 2)
        set speed to 7 * speed / 8
        return getAt(hitInfo, 1)
        exit
      else
        return getAt(hitInfo, 1)
        exit
      end if
    end if
    set howBad to whichSideIsFree(wheels, coordinate, speed, direction)
    if howBad < 0 then
      set leftRight to -1
    else
      set leftRight to 1
    end if
    set howBad to abs(howBad)
    set tempTurn to 1
    if not (getAt(getAt(previousData, count(previousData)), 3) = #stop) then
      set tempTurn to 0
    end if
    if howBad > 2 or speed < 3 * decimalPrec and tempTurn = 0 then
      set speed to 0
      set forwardBackward to 0
      set thisHit to #stop
      setDirection(me, direction + leftRight)
      return findEdge(wheels, coordinate, tryCoordinate, speed, direction)
    else
      set speed to 3 * speed / 4
      if keySteer then
        setDirection(me, direction + leftRight)
      else
        setDirection(me, direction + leftRight * 2)
      end if
      set thisHit to #Turn
    end if
    if abs(speed) < maxAcc then
      set speed to 0
      set forwardBackward to 0
    end if
    return tryCoordinate
  end if
end

on checkTerrain me, info
  if voidp(info) then
    set info to quickCheck(wheels, 0, direction, forwardBackward)
  end if
  if info = 0 then
    return 1
  end if
  set inclination to getAt(info, 3) - getAt(info, 4)
  if inclination then
    if inclination > 0 then
      set speed to (100 - forwardBackward * 10) * speed / 100
      if inclination > 2 then
        set inclination to 2
        if getProp(quickCarProps, #Strength) <= getProp(criteria, #BigHill) then
          setSpeed(me, 0)
          stepback(me, 1)
          return 0
        else
          set tempMedalId to 1
          if getMedal(the car of the user of gMulleGlobals, tempMedalId) = 0 then
            playSound(me, #MedalMud)
            sendSprite(getProp(the spriteList of gDir, #medal), #Blink, tempMedalId)
            addMedal(the car of the user of gMulleGlobals, tempMedalId)
          end if
        end if
      else
        if inclination > 1 then
          if getProp(quickCarProps, #Strength) <= getProp(criteria, #SmallHill) then
            setSpeed(me, 0)
            stepback(me, 1)
            return 0
          end if
        end if
      end if
    else
      set speed to (100 + forwardBackward * 10) * speed / 100
      if inclination < -2 then
        set inclination to -2
      end if
    end if
  end if
  set altitude to (getAt(info, 3) + getAt(info, 4)) / 2
  if getAt(info, 1) or getAt(info, 2) then
    if getAt(info, 1) and getAt(info, 2) then
      case getAt(info, 1) of
        1:
          if getProp(criteria, #HolesDurability) = 0 then
            playSound(me, #Durability)
            set speed to 0
            return 0
          end if
          set speed to 80 * speed / 100
          if not inTerrain then
            set inTerrain to getAt(info, 1)
          end if
        2:
          if getProp(criteria, #MudGrip) = 0 then
            playSound(me, #Grip)
            set speed to 0
            return 0
          end if
          set speed to 80 * speed / 100
          if not inTerrain then
            set tempMedalId to 3
            if getMedal(the car of the user of gMulleGlobals, tempMedalId) = 0 then
              sendSprite(getProp(the spriteList of gDir, #medal), #Blink, tempMedalId)
              addMedal(the car of the user of gMulleGlobals, tempMedalId)
            end if
            set inTerrain to getAt(info, 1)
          end if
      end case
    else
      if speed > 0 then
        set tempInfo to getAt(info, 1)
      else
        set tempInfo to getAt(info, 2)
      end if
      case tempInfo of
        1:
          if getProp(criteria, #HolesDurability) = 0 then
            playSound(me, #Durability)
            set speed to 0
            return 0
          end if
        2:
          if getProp(criteria, #MudGrip) = 0 then
            playSound(me, #Grip)
            set speed to 0
            return 0
          end if
      end case
    end if
  else
    set inTerrain to 0
  end if
  return 1
end

on stopSound me
  global gSound
  stop(gSound, sndId)
end

on playSound me, what
  global gSound
  set tempList to [#Durability: ["05d002v0"], #Grip: ["05d003v0"], #Strength: ["05d004v0", "05d005v0"]]
  set temp to getaProp(tempList, what)
  if listp(temp) then
    set snd to getAt(temp, random(count(temp)))
    if finished(gSound, sndId) then
      set sndId to play(gSound, snd, #EFFECT)
    end if
  end if
end
