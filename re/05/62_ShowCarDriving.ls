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
  setProp(quickCarProps, #acceleration, getaProp(quickCarProps, #acceleration) * decimalPrec * 2 / 10)
  setProp(quickCarProps, #Steering, (getaProp(quickCarProps, #Steering) + 3) * decimalPrec * 2 / 20)
  setProp(quickCarProps, #FuelVolume, getaProp(quickCarProps, #FuelVolume) * decimalPrec * 12)
  setProp(quickCarProps, #ElectricVolume, getaProp(quickCarProps, #ElectricVolume) * decimalPrec * 15)
  set maxAcc to getaProp(quickCarProps, #break)
  if maxAcc < getaProp(quickCarProps, #acceleration) then
    set maxAcc to getaProp(quickCarProps, #acceleration)
  end if
  setEngine(displayObject)
end

on kill me
  set displayObject to kill(displayObject)
  return 0
end

on init me, theWorld
  set displayObject to new(script("DisplayCar"), me, #show)
  start(me, theWorld)
end

on start me, theWorld
  set speed to 0
  set Steering to 0
  set coordinate to decimalPrec * point(290, 280)
  set direction to 4
  set internalDirection to decimalPrec * direction
  set quickCarProps to [#break: 3, #Grip: 8, #Steering: 4, #acceleration: 4, #speed: 3, #FuelConsumption: 3, #FuelVolume: 3, #ElectricConsumption: 2, #ElectricVolume: 5, #Strength: 5, #Durability: 4, #HornType: 5, #EngineType: getProperty(the car of the user of gMulleGlobals, #EngineType), #Pedals: 0]
  if not getProp(quickCarProps, #EngineType) > 0 then
    setProp(quickCarProps, #EngineType, 3)
  end if
  convertCarProps(me)
end

on getCoordinate me
  return coordinate / decimalPrec
end

on setCoordinate me, theCoord, theOption
  set coordinate to theCoord * decimalPrec
  if theOption = #AdjustTopo then
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
    end if
  end if
  if reachForDirection then
    set reachForDirection to 0
    set Steering to 0
  end if
  if speed then
    set lastCoordinate to duplicate(coordinate)
    set diff to speed * getAt(directionList, direction) / decimalPrec
    set coordinate to coordinate + diff
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
