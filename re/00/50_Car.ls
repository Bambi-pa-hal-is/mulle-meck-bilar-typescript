property parts, name, medals, carProperties, cacheList, chassisSPOffset, carSnapPoints, carSnapOffsets, driverLayer, fuel, enterParts, newCarName
global gMulleGlobals

on new me
  set parts to []
  set enterParts to []
  set name to EMPTY
  set medals to []
  set carSnapOffsets to [:]
  set carProperties to [#Weight: 0, #break: 0, #Durability: 0, #Grip: 0, #Steering: 0, #acceleration: 0, #speed: 0, #Strength: 0, #FuelConsumption: 0, #FuelVolume: 0, #ElectricConsumption: 0, #ElectricVolume: 0, #Comfort: 0, #FunnyFactor: 0, #Horn: 0, #ExhaustPipe: 0, #Lamps: 0, #LoadCapacity: 0, #EngineType: 0, #HornType: 0, #Pedals: 0]
  set cacheList to [:]
  set carSnapPoints to []
  set chassisSPOffset to 7
  set driverLayer to 18
  set newCarName to the text of member("00t002v0")
  return me
end

on kill me
  set parts to 0
  set medals to 0
  set carProperties to 0
  set cacheList to 0
  return 0
end

on getCacheProp me, theProp
  set temp to getaProp(cacheList, theProp)
  if voidp(temp) then
    return #NoProp
  else
    return temp
  end if
end

on setCacheProp me, theProp, optionalData
  if voidp(optionalData) then
    set optionalData to 0
  end if
  if voidp(getaProp(cacheList, theProp)) then
    addProp(cacheList, theProp, optionalData)
  else
    setProp(cacheList, theProp, optionalData)
  end if
end

on deleteCacheProp me, theProp
  deleteProp(cacheList, theProp)
end

on areTheseFree me, theList
  if count(theList) = 0 then
    return 0
  end if
  repeat with index in theList
    if getPos(carSnapPoints, index) = 0 then
      return 0
    end if
  end repeat
  return 1
end

on deletePart me, partId
  set foundIt to getPos(parts, partId)
  if foundIt then
    deleteAt(parts, foundIt)
  else
    alert("NOT FOUND!")
  end if
end

on rebuild me
  set tempParts to duplicate(parts)
  set parts to []
  set carSnapPoints to []
  set carSnapOffsets to [:]
  repeat with part in tempParts
    addPart(me, part)
  end repeat
end

on findPart me, partId
  set part to getPart(the parts of gMulleGlobals, partId)
  if not objectp(part) then
    return 0
  end if
  set morphs to getMorphList(part)
  if not listp(morphs) then
    set morphs to [partId]
  end if
  repeat with index in morphs
    if getPos(parts, index) then
      return 1
    end if
  end repeat
  return 0
end

on clearCar me
  set cacheList to [:]
  set name to newCarName
  set medals to []
end

on trash me
  global gMulleGlobals
  set chassis to the chassis of gMulleGlobals
  repeat with n = 1 to count(parts)
    set partId to getAt(parts, n)
    set tempPart to getPart(the parts of gMulleGlobals, partId)
    set tempMaster to getMaster(tempPart)
    if integerp(tempMaster) then
      if tempMaster > 0 then
        set partId to tempMaster
      end if
    end if
    if partId <> chassis then
      addJunkPart(the user of gMulleGlobals, #RandomPile, partId)
    end if
  end repeat
  set parts to []
  set carSnapOffsets to [:]
  set carProperties to [#Weight: 0, #break: 0, #Durability: 0, #Grip: 0, #Steering: 0, #acceleration: 0, #speed: 0, #Strength: 0, #FuelConsumption: 0, #FuelVolume: 0, #ElectricConsumption: 0, #ElectricVolume: 0, #Comfort: 0, #FunnyFactor: 0, #Horn: 0, #ExhaustPipe: 0, #Lamps: 0, #LoadCapacity: 0, #EngineType: 0, #HornType: 0, #Pedals: 0]
  set carSnapPoints to []
  clearCar(me)
  addPart(me, the chassis of gMulleGlobals)
end

on addMedal me, newMedalId
  if getPos(medals, newMedalId) = 0 then
    add(medals, newMedalId)
  end if
end

on getMedal me, medalId
  if getPos(medals, medalId) then
    return 1
  end if
  return 0
end

on getSnapInfo me, snapPoint, what
  if what = #layers then
    return getAt(getaProp(carSnapOffsets, snapPoint), 1)
  else
    if what = #offset then
      return getAt(getaProp(carSnapOffsets, snapPoint), 2)
    end if
  end if
  return getaProp(carSnapOffsets, snapPoint)
end

on addPart me, newPartId
  global gMulleGlobals
  add(parts, newPartId)
  set part to getPart(the parts of gMulleGlobals, newPartId)
  if not objectp(part) then
    stop()
  end if
  set coversPoints to getCoveredPoints(part)
  if listp(coversPoints) then
    repeat with index in coversPoints
      deleteOne(carSnapPoints, index)
    end repeat
  end if
  set newPoints to getNewPoints(part)
  if listp(newPoints) then
    repeat with index in newPoints
      set tempSnap to getAt(index, 1)
      add(carSnapPoints, tempSnap)
      set tempLayers to getAt(index, 2)
      set tempOffset to getAt(index, 3)
      addProp(carSnapOffsets, tempSnap, [tempLayers, tempOffset])
    end repeat
  end if
end

on removePart me, partId
  global gMulleGlobals
  set foundIt to getPos(parts, partId)
  if foundIt then
    deleteAt(parts, foundIt)
    set part to getPart(the parts of gMulleGlobals, partId)
    set coversPoints to getCoveredPoints(part)
    if listp(coversPoints) then
      repeat with index in coversPoints
        add(carSnapPoints, index)
      end repeat
    end if
    set newPoints to getNewPoints(part)
    if listp(newPoints) then
      repeat with index in newPoints
        set tempSnap to getAt(index, 1)
        deleteOne(carSnapPoints, tempSnap)
        deleteProp(carSnapOffsets, tempSnap)
      end repeat
    end if
  end if
end

on getParts me
  return parts
end

on setName me, newName
  set name to newName
end

on getName me
  return name
end

on updateProperties me
  global gMulleGlobals
  set carProperties to [#Weight: 0, #break: 0, #Durability: 0, #Grip: 0, #Steering: 0, #acceleration: 0, #speed: 0, #Strength: 0, #FuelConsumption: 0, #FuelVolume: 0, #ElectricConsumption: 0, #ElectricVolume: 0, #Comfort: 0, #FunnyFactor: 0, #Horn: 0, #ExhaustPipe: 0, #Lamps: 0, #Pedals: 0, #LoadCapacity: 0, #EngineType: 0, #HornType: 0]
  repeat with partId in parts
    set part to getPart(the parts of gMulleGlobals, partId)
    setProp(carProperties, #Weight, getaProp(carProperties, #Weight) + getProperty(part, #Weight))
    setProp(carProperties, #break, getaProp(carProperties, #break) + getProperty(part, #break))
    set tempDur to getProperty(part, #Durability)
    if integerp(tempDur) then
      if tempDur < getaProp(carProperties, #Durability) or tempDur <> 0 and getaProp(carProperties, #Durability) = 0 then
        setProp(carProperties, #Durability, getProperty(part, #Durability))
      end if
    end if
    setProp(carProperties, #Grip, getaProp(carProperties, #Grip) + getProperty(part, #Grip))
    if getProperty(part, #Steering) > getaProp(carProperties, #Steering) then
      setProp(carProperties, #Steering, getProperty(part, #Steering))
    end if
    if getProperty(part, #acceleration) > getaProp(carProperties, #acceleration) then
      setProp(carProperties, #acceleration, getProperty(part, #acceleration))
    end if
    if getProperty(part, #speed) > getaProp(carProperties, #speed) then
      setProp(carProperties, #speed, getProperty(part, #speed))
    end if
    setProp(carProperties, #Strength, getaProp(carProperties, #Strength) + getProperty(part, #Strength))
    setProp(carProperties, #FuelConsumption, getaProp(carProperties, #FuelConsumption) + getProperty(part, #FuelConsumption))
    setProp(carProperties, #FuelVolume, getaProp(carProperties, #FuelVolume) + getProperty(part, #FuelVolume))
    setProp(carProperties, #ElectricConsumption, getaProp(carProperties, #ElectricConsumption) + getProperty(part, #ElectricConsumption))
    setProp(carProperties, #ElectricVolume, getaProp(carProperties, #ElectricVolume) + getProperty(part, #ElectricVolume))
    setProp(carProperties, #Comfort, getaProp(carProperties, #Comfort) + getProperty(part, #Comfort))
    setProp(carProperties, #FunnyFactor, getaProp(carProperties, #FunnyFactor) + getProperty(part, #FunnyFactor))
    if getProperty(part, #Horn) then
      setProp(carProperties, #Horn, 1)
    end if
    if getProperty(part, #ExhaustPipe) then
      setProp(carProperties, #ExhaustPipe, 1)
    end if
    if getProperty(part, #Lamps) then
      setProp(carProperties, #Lamps, 1)
    end if
    if getProperty(part, #Pedals) then
      setProp(carProperties, #Pedals, 1)
    end if
    setProp(carProperties, #LoadCapacity, getaProp(carProperties, #LoadCapacity) + getProperty(part, #LoadCapacity))
    if getProperty(part, #EngineType) > getaProp(carProperties, #EngineType) then
      setProp(carProperties, #EngineType, getProperty(part, #EngineType))
    end if
    if getProperty(part, #HornType) > getaProp(carProperties, #HornType) then
      setProp(carProperties, #HornType, getProperty(part, #HornType))
    end if
  end repeat
end

on getProperty me, prop
  return getaProp(carProperties, prop)
end

on toList me
  return [#parts: parts, #name: name, #medals: medals, #cacheList: cacheList]
end

on fromList me, objectList
  global gMulleGlobals
  set tempParts to getaProp(objectList, #parts)
  set name to getaProp(objectList, #name)
  set medals to getaProp(objectList, #medals)
  set cacheList to getaProp(objectList, #cacheList)
  set parts to []
  set carSnapOffsets to [:]
  set carSnapPoints to []
  if count(tempParts) = 0 then
    set tempParts to [the chassis of gMulleGlobals]
  else
    if getAt(tempParts, 1) = 0 then
      set tempParts to [the chassis of gMulleGlobals]
    end if
  end if
  repeat with part in tempParts
    addPart(me, part)
  end repeat
end
