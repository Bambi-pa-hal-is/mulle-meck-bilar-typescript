property reportObject, Topology, wheelPositions, decimalPrec, directionList, clockList, coordinate, mapOffset, lastCoordinate
global gDir

on new me, theReportObject
  set reportObject to theReportObject
  set decimalPrec to the decimalPrec of reportObject
  set directionList to duplicate(the directionList of reportObject)
  set wheelPositions to []
  repeat with n = 1 to count(directionList)
    add(wheelPositions, 5 * getAt(directionList, n) / decimalPrec)
  end repeat
  set clockList to [point(1, -1), point(1, 0), point(1, 1), point(0, 1), point(-1, 1), point(-1, 0), point(-1, -1), point(0, -1)]
  set coordinate to point(0, 0)
  set mapOffset to point(4, 4)
  return me
end

on kill me
  return 0
end

on setTopology me, theTopo
  set Topology to the text of member(theTopo) & the text of member(theTopo & "-2")
end

on setCoordinate me, theCoordinate
  set lastCoordinate to coordinate
  set coordinate to (theCoordinate / decimalPrec - mapOffset) / 2
end

on checkBorders me, theDirection, theForward
  set tempH to getAt(coordinate, 1)
  set tempV to getAt(coordinate, 2)
  if theForward = 1 then
    set temp to getAt(wheelPositions, abs(theDirection))
    set tempH to tempH + getAt(temp, 1)
    set tempV to tempV + getAt(temp, 2)
  end if
  set tempIn to 2
  if tempH < 1 + tempIn then
    return point(-1, 0)
  else
    if tempH > 316 - tempIn then
      return point(1, 0)
    else
      if tempV < 1 + tempIn then
        return point(0, -1)
      else
        if tempV > 198 - tempIn then
          return point(0, 1)
        end if
      end if
    end if
  end if
  return 0
end

on quickCheck me, theCoordinate, theWhat, theForward
  if not listp(theCoordinate) then
    set theCoordinate to coordinate
  end if
  if integerp(theWhat) then
    if theWhat >= 1 and theWhat <= 16 then
      set tempH to getAt(theCoordinate, 1)
      set tempV to getAt(theCoordinate, 2)
      set middle to charToNum(char tempH + (tempV - 1) * 316 of Topology)
      set temp to getAt(wheelPositions, abs(theWhat))
      set tempH to tempH + getAt(temp, 1)
      set tempV to tempV + getAt(temp, 2)
      set front to charToNum(char tempH + (tempV - 1) * 316 of Topology)
      if theForward >= 0 and front >= 240 then
        return 0
      else
        if theForward < 0 and middle >= 240 then
          return 0
        end if
      end if
      if front >= 240 then
        set front to middle
      else
        if middle >= 240 then
          set middle to front
        end if
      end if
      return [front / 16, middle / 16, front mod 16, middle mod 16]
    end if
  else
    set tempH to getAt(theCoordinate, 1)
    set tempV to getAt(theCoordinate, 2)
    set middle to charToNum(char tempH + (tempV - 1) * 316 of Topology)
    if middle >= 240 then
      return 0
    end if
    return 1
  end if
end

on checkHit me, theLastCoordinate, theTryCoordinate, speed, direction, theSideStepLimit
  if abs(speed) <= 2 * decimalPrec then
    set myLastCoord to (theLastCoordinate / decimalPrec - mapOffset) / 2
    if speed > 0 then
      set myLastCoord to myLastCoord + getAt(wheelPositions, direction)
    end if
    set lastTry to moveAtLeastAStep(me, direction, #Tangent, speed, myLastCoord)
    if not (lastTry = 0) then
      if speed > 0 then
        set lastTry to lastTry - getAt(wheelPositions, direction) * decimalPrec * 2
      end if
      return [lastTry, #Rounding]
    end if
    return 0
  end if
  if speed > theSideStepLimit then
    set theTryCoordinate to (theTryCoordinate / decimalPrec - mapOffset) / 2
    set theTryCoordinate to theTryCoordinate + getAt(wheelPositions, direction)
    set sideStep to moveAtLeastAStep(me, direction, #normal, 1, theTryCoordinate)
    if not (sideStep = 0) then
      set sideStep to sideStep - getAt(wheelPositions, direction) * decimalPrec * 2
      return [sideStep, #sideStep]
    end if
    set sideStep to moveAtLeastAStep(me, direction, #normal, -1, theTryCoordinate)
    if not (sideStep = 0) then
      set sideStep to sideStep - getAt(wheelPositions, direction) * decimalPrec * 2
      return [sideStep, #sideStep]
    end if
  end if
  return 0
end

on findEdge me, theCoordinate, theTryCoordinate, speed, direction
  return theCoordinate
  set myLastCoord to (theCoordinate / decimalPrec - mapOffset) / 2
  set theTryCoordinate to (theTryCoordinate / decimalPrec - mapOffset) / 2
  set diff to theTryCoordinate - myLastCoord
  if speed > 0 then
    set hereCoord to myLastCoord + getAt(wheelPositions, direction)
  end if
  if abs(getAt(diff, 1)) >= abs(getAt(diff, 2)) then
    set nrOfSteps to getAt(diff, 1)
  else
    set nrOfSteps to getAt(diff, 2)
  end if
  set latestHit to 0
  set latestFree to abs(nrOfSteps)
  put latestHit, latestFree
  if abs(nrOfSteps) <= 1 then
    set nrOfSteps to 1
  else
    if nrOfSteps < 0 then
      set sign to -1
    else
      set sign to 1
    end if
    set nrOfSteps to abs(nrOfSteps)
    set step to 0
    set half to 2
    set free to 0
    repeat while 1
      set tempDiff to 10 * nrOfSteps / half
      if abs(tempDiff) < 10 then
        if abs(latestFree - latestHit) = 1 then
          exit repeat
        else
          if tempDiff > 0 then
            set tempDiff to 10
          else
            set tempDiff to -10
          end if
        end if
      end if
      set step to step + tempDiff / 10
      set newCoord to hereCoord + 100 * diff * step / nrOfSteps / 100
      set middle to charToNum(char getAt(newCoord, 1) + (getAt(newCoord, 2) - 1) * 316 of Topology)
      if middle >= 240 then
        set free to 0
        set latestHit to step
        set half to abs(half) * 2
        next repeat
      end if
      set free to 1
      set latestFree to step
      set half to abs(half) * -2
    end repeat
  end if
  put latestHit, latestFree
  return ((myLastCoord + 100 * diff * latestFree / nrOfSteps / 100) * 2 + mapOffset) * decimalPrec
end

on showPoints me, theSide
  set tempMid to (theSide + 1) / 2
  repeat with y = 1 to theSide
    repeat with X = 1 to theSide
      set the foreColor of sprite 63 + X + (y - 1) * 5 to charToNum(char getAt(coordinate, 1) + X - tempMid + (getAt(coordinate, 2) + y - tempMid - 1) * 316 of Topology)
    end repeat
  end repeat
end

on moveAtLeastAStep me, theDirection, how, option, optCoord
  if how = #normal then
    set theDirection to theDirection + 4 * option
    set theDirection to correctDirection(the drivingHandlers of gDir, theDirection)
    set option to 2 * decimalPrec
    if listp(optCoord) then
      set thisCoord to optCoord
    else
      set thisCoord to coordinate
    end if
  end if
  set tempStep to getAt(directionList, theDirection)
  set tempMax to abs(getAt(tempStep, 1))
  set tempMin to abs(getAt(tempStep, 2))
  if tempMin > tempMax then
    set tempMax to tempMin
  end if
  if how = #Tangent then
    if option < 0 then
      set tempSign to -1
    else
      set tempSign to 1
    end if
    if abs(option) * tempMax >= decimalPrec then
      set option to tempSign * decimalPrec
    end if
    set thisCoord to optCoord
  end if
  set tempStep to option * tempStep / tempMax
  if how = #normal then
    set tempCoord to thisCoord + (tempStep + tempStep / 3) / decimalPrec
    set realCoord to thisCoord + tempStep / 2 / decimalPrec
  else
    set tempCoord to thisCoord + tempStep / decimalPrec
  end if
  if not (quickCheck(me, tempCoord) = 0) then
    if how = #normal then
      return (realCoord * 2 + mapOffset) * decimalPrec
    else
      return (tempCoord * 2 + mapOffset) * decimalPrec
    end if
  end if
  return 0
end

on whichSideIsFree me, theCoordinate, speed, direction
  set theCoordinate to (theCoordinate / decimalPrec - mapOffset) / 2
  set tempFree to 0
  repeat with n = 1 to 5
    repeat with m = 1 to 2
      if n = 2 then
        set leftRight to -1
      else
        set leftRight to 1
      end if
      set tempDirection to correctDirection(the drivingHandlers of gDir, direction + leftRight * n)
      set diff to speed / decimalPrec * getAt(directionList, tempDirection) / decimalPrec
      if speed > 0 then
        set tempCoordinate to theCoordinate + getAt(wheelPositions, tempDirection)
      end if
      set newPoint to tempCoordinate + diff / 2
      if quickCheck(me, newPoint) then
        set tempFree to 1
        exit repeat
      end if
    end repeat
    if tempFree then
      exit repeat
    end if
  end repeat
  return n * leftRight
end
