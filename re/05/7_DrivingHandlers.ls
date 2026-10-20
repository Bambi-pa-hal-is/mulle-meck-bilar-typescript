property nrOfDirections

on new me
  set nrOfDirections to 16
  return me
end

on kill me
  return 0
end

on calcDirection me, theStart, theEnd, option
  set diffX to getAt(theEnd, 1) - getAt(theStart, 1)
  set diffY to getAt(theStart, 2) - getAt(theEnd, 2)
  set hypo to sqrt(diffX * diffX + diffY * diffY)
  if diffY = 0 then
    set diffY to 0.10000000000000001
  end if
  set tempDirection to atan(diffX / float(diffY))
  if diffX > 0 then
    if diffY > 0 then
      nothing()
    else
      set tempDirection to tempDirection + PI
    end if
  else
    if diffY > 0 then
      set tempDirection to tempDirection + 2 * PI
    else
      set tempDirection to tempDirection + PI
    end if
  end if
  set tempDirection to tempDirection / PI
  set tempDirection to integer(tempDirection * nrOfDirections / 2)
  if tempDirection = 0 then
    set tempDirection to nrOfDirections
  end if
  if option = #WithHypo then
    return [tempDirection, hypo]
  end if
  return tempDirection
end

on checkRadius me, reportObject, carLoc, myLoc, option
  set tempDiff to carLoc - myLoc
  set tempH to getAt(tempDiff, 1)
  set tempV to getAt(tempDiff, 2)
  set hypo to sqrt(tempH * tempH + tempV * tempV)
  if voidp(option) or option = #both then
    if hypo <= the OuterRadius of reportObject then
      if hypo <= the InnerRadius of reportObject then
        if not the insideInner of reportObject then
          set the insideInner of reportObject to 1
          if the insideOuter of reportObject then
            return #EnterInnerRadius
          else
            set the insideOuter of reportObject to 1
            return #EnterBoth
          end if
        end if
      else
        if not the insideOuter of reportObject then
          set the insideOuter of reportObject to 1
          return #enterOuterRadius
        end if
        if the insideInner of reportObject then
          set the insideInner of reportObject to 0
          return #ExitInnerRadius
        end if
      end if
    else
      if the insideOuter of reportObject then
        set the insideOuter of reportObject to 0
        if the insideInner of reportObject then
          set the insideInner of reportObject to 0
          return #ExitBoth
        else
          return #ExitOuterRadius
        end if
      end if
    end if
  else
    if option = #Inner then
      if hypo <= the InnerRadius of reportObject then
        if not the insideInner of reportObject then
          set the insideInner of reportObject to 1
          return #EnterInnerRadius
        end if
      else
        if the insideInner of reportObject then
          set the insideInner of reportObject to 0
          return #ExitInnerRadius
        end if
      end if
    else
      if option = #Outer then
        if hypo <= the OuterRadius of reportObject then
          if not the insideOuter of reportObject then
            set the insideOuter of reportObject to 1
            return #enterOuterRadius
          end if
        else
          if the insideOuter of reportObject then
            set the insideOuter of reportObject to 0
            return #ExitOuterRadius
          end if
        end if
      end if
    end if
  end if
  return 0
end

on correctDirection me, theDir
  if theDir > nrOfDirections then
    return theDir - nrOfDirections
  else
    if theDir < 1 then
      return theDir + nrOfDirections
    end if
  end if
  return theDir
end

on updateEngine me, what
  global gMulleGlobals
  set parts to getParts(the car of the user of gMulleGlobals)
  set carProperties to [#speed: 0, #Strength: 0, #EngineType: 0]
  repeat with partId in parts
    set part to getPart(the parts of gMulleGlobals, partId)
    if getProperty(part, #Strength) > 0 then
      set elecCons to getProperty(part, #ElectricConsumption)
      set gasCons to getProperty(part, #FuelConsumption)
      if not (elecCons > 0 and what = #NoElectricity) and not (gasCons > 0 and what = #NoGas) and not ((gasCons > 0 or elecCons > 0) and what = #NoFuel) then
        if getProperty(part, #speed) > getaProp(carProperties, #speed) then
          setProp(carProperties, #speed, getProperty(part, #speed))
        end if
        setProp(carProperties, #Strength, getaProp(carProperties, #Strength) + getProperty(part, #Strength))
        if getProperty(part, #EngineType) > getaProp(carProperties, #EngineType) then
          setProp(carProperties, #EngineType, getProperty(part, #EngineType))
        end if
      end if
    end if
  end repeat
  setProp(the carProperties of the car of the user of gMulleGlobals, #speed, getProp(carProperties, #speed))
  setProp(the carProperties of the car of the user of gMulleGlobals, #Strength, getProp(carProperties, #Strength))
  setProp(the carProperties of the car of the user of gMulleGlobals, #EngineType, getProp(carProperties, #EngineType))
end
