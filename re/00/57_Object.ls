property ObjectId, type, InnerRadius, OuterRadius, customObject, DirResource, sounds, FrameList, setWhenDone, checkFor, ifFound, spriteInfo, ancestor, active, myLoc, SPOver, SPUnder, optionalData, canEnter
global gMulleGlobals

on new me
  set objectType to #none
  set ObjectId to 0
  set InnerRadius to 0
  set OuterRadius to 0
  set customObject to EMPTY
  set DirResource to EMPTY
  set sounds to []
  set FrameList to []
  set setWhenDone to [:]
  set checkFor to [:]
  set ifFound to #none
  set spriteInfo to [:]
  set ancestor to 0
  set active to 1
  set SPOver to 0
  set SPUnder to 0
  set myLoc to point(0, 0)
  set optionalData to [:]
  set canEnter to 1
  return me
end

on kill me
  return 0
end

on init me, theSprites, theLoc, theOptional, theCarLoc
  set SPOver to getAt(theSprites, 1)
  set SPUnder to getAt(theSprites, 2)
  set myLoc to theLoc
  set optionalData to [:]
  set tempDir to VOID
  if listp(theOptional) then
    if count(theOptional) then
      set optionalData to theOptional
      set tempDir to getaProp(optionalData, #direction)
    end if
  end if
  if voidp(tempDir) then
    set tempDir to 1
  end if
  if count(FrameList) then
    set tempList to getaProp(FrameList, tempDir)
    if listp(tempList) then
      set FrameList to tempList
    end if
  end if
  set lookUp to 0
  if symbolp(ifFound) then
    if not (ifFound = #none) then
      set lookUp to 1
    end if
  end if
  if lookUp then
    set foundOne to 0
    repeat with n = 1 to count(checkFor)
      set tempProp to getPropAt(checkFor, n)
      set tempVal to getAt(checkFor, n)
      if not listp(tempVal) then
        set tempVal to [tempVal]
      end if
      set tempVal to duplicate(tempVal)
      case tempProp of
        #Cache:
          repeat with index in tempVal
            if not (getCacheProp(the car of the user of gMulleGlobals, index) = #NoProp) then
              set foundOne to 1
              exit repeat
            end if
          end repeat
        #medals:
          repeat with index in tempVal
            if getMedal(the car of the user of gMulleGlobals, index) then
              set foundOne to 1
              exit repeat
            end if
          end repeat
        #UserStuff:
          repeat with index in tempVal
            if not (getUserProp(the user of gMulleGlobals, index) = #NoProp) then
              set foundOne to 1
              exit repeat
            end if
          end repeat
        #missions:
          repeat with index in tempVal
            if isMissionCompleted(the user of gMulleGlobals, index) then
              set foundOne to 1
              exit repeat
            end if
          end repeat
        #parts:
          set foundOne to not getOnePart(me, #checkFor)
      end case
      if foundOne then
        exit repeat
      end if
    end repeat
    if foundOne then
      case ifFound of
        #NoDisplay:
          return 0
        #NoEnter:
          set canEnter to 0
      end case
    end if
  end if
  set temp to getaProp(optionalData, #InnerRadius)
  if integerp(temp) then
    set InnerRadius to temp
  end if
  set temp to getaProp(optionalData, #OuterRadius)
  if integerp(temp) then
    set OuterRadius to temp
  end if
  init(ancestor, theCarLoc)
  return 1
end

on getOnePart me, where
  if where = #setWhenDone then
    set tempVal to getaProp(setWhenDone, #parts)
  else
    set tempVal to getaProp(checkFor, #parts)
  end if
  if not listp(tempVal) then
    set tempVal to [tempVal]
  end if
  set tempVal to duplicate(tempVal)
  if getPos(tempVal, #random) then
    set tempRandomPart to 1
    deleteOne(tempVal, #random)
  else
    set tempRandomPart to 0
  end if
  set tempAvail to getCurrentlyAvailable(the externalParts of gMulleGlobals, #Destinations)
  repeat with index in tempVal
    if getPos(tempAvail, index) then
      return index
    end if
  end repeat
  if tempRandomPart then
    set tempAvail to getCurrentlyAvailable(the externalParts of gMulleGlobals, #random)
    if count(tempAvail) then
      return getAt(tempAvail, 1)
    end if
  end if
  return 0
end

on getId me
  return ObjectId
end

on getCacheProp me
  return getaProp(setWhenDone, #Cache)
end

on getOptionalData me
  return optionalData
end

on getGiftParts me
  return getaProp(setWhenDone, #parts)
end

on getSetWhenDone me, theWhat
  if voidp(theWhat) then
    return duplicate(setWhenDone)
  end if
  return getaProp(setWhenDone, theWhat)
end

on getCheckFor me, theWhat
  if voidp(theWhat) then
    return duplicate(checkFor)
  end if
  return getaProp(checkFor, theWhat)
end

on getType me
  return type
end

on getLoc me
  return myLoc
end

on getSpritesInfo me
  return spriteInfo
end

on getInnerRadius me
  return InnerRadius
end

on getOuterRadius me
  return OuterRadius
end

on getDirResource me
  return DirResource
end

on getFrameList me
  return FrameList
end

on toList me
  return [ObjectId, type, InnerRadius, OuterRadius, customObject, DirResource, sounds, FrameList, setWhenDone, checkFor, ifFound]
end

on fromList me, theid
  global gMulleGlobals
  set memberName to "Object" & string(theid) & "DB"
  if the number of member memberName = -1 then
    return 0
  end if
  set objectList to value(the text of member(memberName))
  set ObjectId to getaProp(objectList, #ObjectId)
  set type to getaProp(objectList, #type)
  set InnerRadius to getaProp(objectList, #InnerRadius)
  set OuterRadius to getaProp(objectList, #OuterRadius)
  set customObject to getaProp(objectList, #customObject)
  set DirResource to getaProp(objectList, #DirResource)
  set sounds to getaProp(objectList, #sounds)
  set FrameList to getaProp(objectList, #FrameList)
  set setWhenDone to getaProp(objectList, #setWhenDone)
  set checkFor to getaProp(objectList, #checkFor)
  set ifFound to getaProp(objectList, #ifFound)
  set spriteInfo to getaProp(objectList, #spriteInfo)
  if voidp(spriteInfo) then
    set spriteInfo to [#Under: 1]
  end if
  if not listp(checkFor) then
    set checkFor to [:]
  end if
  if not listp(setWhenDone) then
    set setWhenDone to [:]
  end if
  set tempUseCustom to 0
  if stringp(customObject) then
    if length(customObject) then
      set tempUseCustom to 1
      set tempMemb to "Object" & customObject & "Script"
      if the number of member tempMemb > 0 then
        set ancestor to new(script(tempMemb), me)
      else
        return 0
      end if
    end if
  end if
  if tempUseCustom = 0 then
    set ancestor to new(script("Destination"), me)
  end if
  return 1
end
