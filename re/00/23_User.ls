property userId, car, junk, nrOfBuiltCars, saves, completedMissions, ownStuff, myLastPile, gifts, drivingInfo, toYardThroughDoor, givenMissions, figgeIsComing, missionIsComing
global gMulleGlobals

on new me
  set userId to EMPTY
  set car to new(script("Car"))
  set junk to []
  set nrOfBuiltCars to 0
  set saves to []
  set gifts to [[27, point(462, 179)]]
  set completedMissions to []
  set ownStuff to [:]
  set myLastPile to 1
  set drivingInfo to 0
  set figgeIsComing to 0
  set missionIsComing to 0
  return me
end

on kill me
  set car to kill(car)
  set junk to 0
  set saves to 0
  set completedMissions to 0
  return 0
end

on getUserId me
  return userId
end

on setId me, theid
  set userId to theid
end

on getDrivingInfo me
  return drivingInfo
end

on setDrivingInfo me, newInfo
  set drivingInfo to newInfo
end

on getJunk me, place
  return getaProp(junk, place)
end

on removeJunkPart me, fromWhere, partId
  set tempPart to getPart(the parts of gMulleGlobals, partId)
  set tempMaster to getMaster(tempPart)
  if integerp(tempMaster) then
    if tempMaster > 0 then
      set partId to tempMaster
    end if
  end if
  if not symbolp(fromWhere) then
    set foundIt to 0
    repeat with n = 1 to count(junk)
      set tempJunk to getAt(junk, n)
      deleteProp(tempJunk, partId)
      if the result = 1 then
        set foundIt to 1
        exit repeat
        next repeat
      end if
    end repeat
    if foundIt then
      setAt(junk, n, tempJunk)
    else
      alert("(RemoveJunk/User) Part not found:" && string(partId))
    end if
  else
    set tempJunk to getaProp(junk, fromWhere)
    deleteProp(tempJunk, partId)
    setProp(junk, fromWhere, tempJunk)
  end if
end

on addJunkPart me, toWhere, partId, extraInfo
  if voidp(extraInfo) and toWhere = #yard then
    addYardPart(me, toWhere, partId, extraInfo)
  else
    if listp(extraInfo) then
      set tempJunk to getaProp(junk, toWhere)
      addProp(tempJunk, partId, extraInfo)
      setProp(junk, toWhere, tempJunk)
    else
      if toWhere = #RandomPile then
        set tempJunkSymbol to getRandomPile(the junkPileHandlers of gMulleGlobals)
        if tempJunkSymbol = 0 then
          alert("All piles are full!")
          exit
        end if
      else
        if symbolp(toWhere) then
          set tempJunkSymbol to toWhere
        else
          set tempJunkSymbol to symbol("pile" & myLastPile)
        end if
      end if
      if checkFull(the junkPileHandlers of gMulleGlobals, tempJunkSymbol) then
        put string(tempJunkSymbol) & " is full"
        exit
      end if
      set tempJunk to getaProp(junk, tempJunkSymbol)
      set tempNewPos to setPartPosition(the junkPileHandlers of gMulleGlobals, tempJunkSymbol, partId)
      addProp(tempJunk, partId, tempNewPos)
      setProp(junk, tempJunkSymbol, tempJunk)
    end if
  end if
end

on addYardPart me, toWhere, partId, extraInfo
  set tempJunkSymbol to toWhere
  if checkFull(the junkPileHandlers of gMulleGlobals, tempJunkSymbol) then
    set removeId to getPropAt(getaProp(junk, tempJunkSymbol), 1)
    removeJunkPart(the user of gMulleGlobals, #yard, removeId)
    addJunkPart(me, #RandomPile, removeId)
  end if
  set tempJunk to getaProp(junk, tempJunkSymbol)
  set tempNewPos to setPartPosition(the junkPileHandlers of gMulleGlobals, tempJunkSymbol, partId)
  addProp(tempJunk, partId, tempNewPos)
  setProp(junk, tempJunkSymbol, tempJunk)
end

on getJunkPartProp me, where, partId
  set tempJunk to getaProp(junk, where)
  return getaProp(tempJunk, partId)
end

on setJunkPartProp me, where, partId, info
  set tempJunk to getaProp(junk, where)
  setaProp(tempJunk, partId, info)
  setProp(junk, where, tempJunk)
end

on initJunk me
  set junk to value(the text of member("InitialJunkDB"))
end

on addCompletedMission me, theid
  if getPos(completedMissions, theid) = 0 then
    add(completedMissions, theid)
  end if
  if getPos(givenMissions, theid) = 0 then
    add(givenMissions, theid)
  end if
end

on isMissionCompleted me, theid
  if getPos(completedMissions, theid) then
    return 1
  end if
  return 0
end

on getUserProp me, theProp
  set temp to getaProp(ownStuff, theProp)
  if voidp(temp) then
    return #NoProp
  else
    return temp
  end if
end

on setUserProp me, theProp, optionalData
  if voidp(optionalData) then
    set optionalData to 0
  end if
  if voidp(getaProp(ownStuff, theProp)) then
    addProp(ownStuff, theProp, optionalData)
  else
    setProp(ownStuff, theProp, optionalData)
  end if
end

on clearUserProps me
  set ownStuff to [:]
end

on saveCar me, which
  if which > 0 then
    setAt(saves, which, duplicate(toList(car)))
  end if
end

on loadCar me, which
  if which <= count(saves) and which > 0 then
    fromList(car, getAt(saves, which))
  end if
end

on changeCarName me, which, newName
  set tempCar to new(script("Car"))
  if which <= count(saves) and which > 0 then
    fromList(tempCar, getAt(saves, which))
    setName(tempCar, newName)
    setAt(saves, which, toList(tempCar))
  end if
  set tempCar to 0
end

on getSavedCars me, which
  if which = #All then
    return saves
  end if
  if integerp(which) then
    if which <= count(saves) and which > 0 then
      return getAt(saves, which)
    end if
  end if
  return 0
end

on findPart me, partId
  repeat with n = 1 to count(junk)
    if not voidp(getaProp(getAt(junk, n), partId)) then
      return getPropAt(junk, n)
    end if
  end repeat
  if findPart(car, partId) then
    return #car
  end if
  repeat with index in gifts
    if getAt(index, 1) = partId then
      return #Gift
    end if
  end repeat
  return 0
end

on toList me
  return [#userId: userId, #car: toList(car), #junk: junk, #nrOfBuiltCars: nrOfBuiltCars, #saves: saves, #completedMissions: completedMissions, #ownStuff: ownStuff, #myLastPile: myLastPile, #gifts: gifts, #toYardThroughDoor: toYardThroughDoor, #givenMissions: givenMissions, #figgeIsComing: figgeIsComing, #missionIsComing: missionIsComing]
end

on fromList me, objectList
  set userId to getaProp(objectList, #userId)
  fromList(car, getaProp(objectList, #car))
  set junk to getaProp(objectList, #junk)
  set nrOfBuiltCars to getaProp(objectList, #nrOfBuiltCars)
  set saves to getaProp(objectList, #saves)
  set completedMissions to getaProp(objectList, #completedMissions)
  set ownStuff to getaProp(objectList, #ownStuff)
  set myLastPile to getaProp(objectList, #myLastPile)
  set gifts to getaProp(objectList, #gifts)
  set toYardThroughDoor to getaProp(objectList, #toYardThroughDoor)
  set givenMissions to getaProp(objectList, #givenMissions)
  set figgeIsComing to getaProp(objectList, #figgeIsComing)
  set missionIsComing to getaProp(objectList, #missionIsComing)
end
