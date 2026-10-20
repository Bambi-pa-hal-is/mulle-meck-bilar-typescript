property WorldId, map, symbol, StartMap, currentMap, StartCoordinate, StartDirection, enteredObjectId, rDests, symbolPosition, allRDests

on new me
  set WorldId to EMPTY
  set map to []
  set symbol to EMPTY
  set StartMap to point(0, 0)
  set StartCoordinate to point(0, 0)
  set StartDirection to 0
  set enteredObjectId to 0
  set rDests to [:]
  set allRDests to [:]
  set symbolPosition to 0
  return me
end

on kill me
  set map to 0
  return 0
end

on getId me
  return WorldId
end

on getPosition me
  return symbolPosition
end

on enteredObject me, theid
  set enteredObjectId to theid
end

on getEnteredObject me, theid
  return enteredObjectId
end

on getStartInfo me
  return [#map: StartMap, #coordinate: StartCoordinate, #direction: StartDirection, #fuel: #Full]
end

on getSymbol me
  return symbol
end

on getCurrentMapId me
  set tempY to getAt(currentMap, 2)
  if tempY >= 1 and tempY <= count(map) then
    set tempList to getAt(map, tempY)
  else
    return #InvalidYIndex
  end if
  set tempX to getAt(currentMap, 1)
  if tempX >= 1 and tempX <= count(tempList) then
    return getAt(tempList, tempX)
  else
    return #InvalidXIndex
  end if
end

on getNewMapId me, thePoint, theMode, theJustCheck
  if theMode = #Relational then
    set thePoint to thePoint + currentMap
  end if
  if getAt(thePoint, 2) >= 1 and getAt(thePoint, 2) <= count(map) then
    set tempList to getAt(map, getAt(thePoint, 2))
  else
    return #InvalidYIndex
  end if
  if getAt(thePoint, 1) >= 1 and getAt(thePoint, 1) <= count(tempList) then
    if not (theJustCheck = 1) then
      set currentMap to thePoint
    end if
    return getAt(tempList, getAt(thePoint, 1))
  else
    return #InvalidXIndex
  end if
end

on calcRandomDestinations me
  set tempMap to new(script("Map"))
  set tempObj to new(script("Object"))
  set allRDests to [:]
  repeat with y = 1 to count(map)
    set yArray to getAt(map, y)
    repeat with X = 1 to count(yArray)
      set MapId to getAt(yArray, X)
      fromList(tempMap, MapId)
      set tempObjects to getObjects(tempMap)
      repeat with index in tempObjects
        set tempObjId to getAt(index, 1)
        if fromList(tempObj, tempObjId) then
          set tempType to getType(tempObj)
          if tempType = #rdest then
            set tempProp to getaProp(allRDests, tempObjId)
            if voidp(tempProp) then
              addProp(allRDests, tempObjId, [point(X, y)])
              next repeat
            end if
            add(tempProp, point(X, y))
            setProp(allRDests, tempObjId, tempProp)
          end if
        end if
      end repeat
    end repeat
  end repeat
end

on randomizeDestinations me
  set rDests to [:]
  repeat with n = 1 to count(allRDests)
    set tempDest to getAt(allRDests, n)
    set tempNrOfMaps to count(tempDest)
    set tempMap to random(tempNrOfMaps)
    addProp(rDests, getPropAt(allRDests, n), getAt(tempDest, tempMap))
  end repeat
end

on getRandomDestinations me
  return rDests
end

on toList me
  return [#WorldId: WorldId, #map: map, #symbol: symbol, #StartMap: StartMap, #StartCoordinate: StartCoordinate, #StartDirection: StartDirection, #symbolPosition: symbolPosition]
end

on fromList me, theid
  set memberName to "World" & theid & "DB"
  if the number of member memberName = -1 then
    alert(memberName & " not found!")
    return 0
  end if
  set objectList to value(the text of member(memberName))
  set WorldId to getaProp(objectList, #WorldId)
  set map to getaProp(objectList, #map)
  set symbol to getaProp(objectList, #symbol)
  set StartMap to getaProp(objectList, #StartMap)
  set currentMap to StartMap
  set StartCoordinate to getaProp(objectList, #StartCoordinate)
  set StartDirection to getaProp(objectList, #StartDirection)
  set symbolPosition to getaProp(objectList, #symbolPosition)
  return 1
end
