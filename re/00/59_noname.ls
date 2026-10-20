global gMulleGlobals

on getStartPile
  return [2, 6, 12, 23, 29, 30, 47, 66, 90, 96, 112, 119, 121, 126, 131, 143, 153, 158, 178, 190, 203, 210, 211, 214, 215, 307]
end

on makerandomJunkParts
  set tempList to checkForNonMorphs()
  repeat while 1
    set junkList to [#Pile1: [:], #Pile2: [:], #Pile3: [:], #Pile4: [:], #Pile5: [:], #Pile6: [:]]
    repeat with partId in tempList
      set pile to symbol("Pile" & string(random(6)))
      set tempLoc to setPartPosition(the junkPileHandlers of gMulleGlobals, pile, partId)
      set tempJunk to getProp(junkList, pile)
      addProp(tempJunk, partId, tempLoc)
    end repeat
    set max to 0
    set min to count(tempList)
    repeat with n = 1 to 6
      set nr to count(getAt(junkList, n))
      if nr > max then
        set max to nr
      end if
      if nr < min then
        set min to nr
      end if
    end repeat
    if max - min <= 10 then
      exit repeat
    end if
  end repeat
  put max, min
  put junkList
end

on leftOvers
  set startList to [1, 82, 133, 152]
  set destParts to checkForDestParts()
  set tempList to getStartPile()
  repeat with index in startList
    set part to getPart(the parts of gMulleGlobals, index)
    set tempMaster to getMaster(part)
    if tempMaster > 0 then
      set index to tempMaster
    end if
    add(tempList, index)
  end repeat
  repeat with index in destParts
    add(tempList, index)
  end repeat
  set total to checkForNonMorphs()
  repeat with partId in tempList
    set tempPos to getPos(total, partId)
    if tempPos then
      deleteAt(total, tempPos)
      next repeat
    end if
    put "Wrong id:", partId
  end repeat
  set tempList to getPlugReserved()
  repeat with partId in tempList
    deleteOne(total, partId)
  end repeat
  set largePartsList to checkForNonMorphs([13, 14, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 35, 91, 119, 124, 126, 129, 134, 137, 146, 149, 154, 158, 168, 173, 174, 175, 177, 189, 191, 192, 193, 199, 208, 209, 210, 212, 215, 221, 227, 229, 233, 235, 251, 264, 278, 279, 281, 282, 283, 294, 295, 306])
  set figgeList to []
  repeat with index in largePartsList
    set tempPos to getPos(total, index)
    if tempPos then
      add(figgeList, index)
      deleteAt(total, tempPos)
    end if
  end repeat
  put "For random:", total
  put "For Figge:", figgeList
end

on checkForDestParts
  set destParts to []
  set tempList to value(the text of member("ObjectsDB"))
  repeat with index in tempList
    set temp to value(the text of member("Object" & string(index) & "DB"))
    set xopo to getaProp(temp, #setWhenDone)
    if listp(xopo) then
      if count(xopo) then
        set tempParts to getaProp(xopo, #parts)
        if listp(tempParts) then
          if getPos(tempParts, #random) then
            deleteOne(tempParts, #random)
          end if
          if count(tempParts) then
            repeat with partId in tempParts
              set part to getPart(the parts of gMulleGlobals, partId)
              set tempMaster to getMaster(part)
              if tempMaster > 0 then
                put "Warning: destpart is morph " & partId
                set partId to tempMaster
              end if
              add(destParts, partId)
            end repeat
          end if
        end if
      end if
    end if
  end repeat
  return destParts
end

on checkForNonMorphs tempList
  if listp(tempList) then
    repeat with n = 1 to count(tempList)
      setAt(tempList, n, getPart(the parts of gMulleGlobals, getAt(tempList, n)))
    end repeat
  else
    set tempList to the partList of the parts of gMulleGlobals
  end if
  set resultList to []
  repeat with index in tempList
    if objectp(index) then
      add(resultList, getId(index))
      set tempMassa to getMaster(index)
      if integerp(tempMassa) then
        if tempMassa > 0 then
          deleteOne(resultList, getId(index))
        end if
      end if
    end if
  end repeat
  return resultList
end

on checkForNonJunk
  put makerandomJunkParts(checkForNonMorphs())
end

on fromIdToSound
  set parts to checkForNonMorphs()
  set str to EMPTY
  repeat with partId in parts
    set part to getPart(the parts of gMulleGlobals, partId)
    set sound to getDescription(part)
    set str to str & string(partId) & ": " & char 4 to 6 of sound & RETURN
  end repeat
  put str
end

on fromSoundToId
  set soundList to [65, 142, 120, 4, 82, 22, 135, 23, 97, 30, 24, 25, 92, 28, 108, 31, 121]
  set soundList to [30]
  set partList to checkForNonMorphs()
  set convertList to [:]
  set resultList to []
  repeat with partId in partList
    set part to getPart(the parts of gMulleGlobals, partId)
    set sound to value(char 4 to 6 of getDescription(part))
    addProp(convertList, sound, partId)
  end repeat
  repeat with sound in soundList
    set temp to getaProp(convertList, sound)
    if temp then
      add(resultList, temp)
      next repeat
    end if
    put "Missing! sound:", sound
  end repeat
  sort(resultList)
  put resultList
  sort(resultList)
  put "And sorted: " & resultList
end

on checkForSoundDoubles
  set partList to checkForNonMorphs()
  set convertList to [:]
  sort(convertList)
  repeat with partId in partList
    set part to getPart(the parts of gMulleGlobals, partId)
    set sound to value(char 4 to 6 of getDescription(part))
    set found to getaProp(convertList, sound)
    if voidp(found) then
      addProp(convertList, sound, [partId])
      next repeat
    end if
    add(found, partId)
    setProp(convertList, sound, found)
  end repeat
  put "Sound: partIdList"
  repeat with n = 1 to count(convertList)
    set temp to getAt(convertList, n)
    if count(temp) > 1 then
      put getPropAt(convertList, n) & ": " & string(temp)
    end if
  end repeat
end

on DBsToFile
  set castToCheck to "CDData"
  set file to new(xtra("FileIO"))
  if the machineType = 256 then
    set delim to ":"
  else
    set delim to "\"
  end if
  set Path to displaySave(file, "Directory for output", "xxx")
  if length(Path) = 0 then
    set file to 0
    exit
  end if
  repeat with n = length(Path) down to 1
    if char n of Path = delim then
      set Path to char 1 to n of Path
      exit repeat
    end if
  end repeat
  set max to the number of castMembers of castLib castToCheck
  repeat with n = 1 to max
    if the type of member(n, castToCheck) = #field then
      set tempName to the name of member(n, castToCheck)
      set dbType to 0
      if tempName contains "part" and charToNum(char 5 of tempName) < 64 then
        set dbType to #partId
        set prefix to "20t"
      else
        if char 1 to 6 of tempName = "Object" and char length(tempName) of tempName = "B" then
          set dbType to #ObjectId
          set prefix to "31t"
        else
          if char 1 to 7 of tempName = "Mission" and char length(tempName) of tempName = "B" then
            set dbType to #MissionId
            set prefix to "50t"
          else
            if char 1 to 7 of tempName = "World" and char length(tempName) of tempName = "B" then
              set dbType to #WorldId
              set prefix to "32t"
            else
              if char 1 to 3 of tempName = "Map" and char length(tempName) of tempName = "B" then
                set dbType to #MapId
                set prefix to "30t"
              end if
            end if
          end if
        end if
      end if
      if symbolp(dbType) then
        set tempList to value(the text of member(n, castToCheck))
        set id to getaProp(tempList, dbType)
        if dbType = #WorldId then
          set name to prefix & string(id) & "v0.txt"
        else
          if id < 10 then
            set zeros to "00"
          else
            if id < 100 then
              set zeros to "0"
            else
              set zeros to EMPTY
            end if
          end if
          set name to prefix & zeros & string(id) & "v0.txt"
        end if
        set tempStr to EMPTY
        repeat with m = 1 to count(tempList)
          set tempStr to tempStr & getPropAt(tempList, m) & ":" & getAt(tempList, m) & RETURN & numToChar(10)
        end repeat
        delete char length(tempStr) - 1 to length(tempStr) of tempStr
        createFile(file, Path & name)
        openFile(file, Path & name, 2)
        if status(file) = 0 then
          writeString(file, tempStr)
          closeFile(file)
          next repeat
        end if
        alert("Problem writing file")
      end if
    end if
  end repeat
  set file to 0
end

on UserStuff
  put the ownStuff of the user of gMulleGlobals
end

on getPlugReserved
  set tempList to [279, 280, 281, 282, 291, 31, 69, 5, 184, 289, 167, 300, 301, 302, 303, 304, 305]
  return includeMorphs(tempList)
end

on includeMorphs tempList
  set result to []
  repeat with index in tempList
    set part to getPart(the parts of gMulleGlobals, index)
    if objectp(part) then
      set temp to getMorphList(part)
      add(result, index)
      if listp(temp) then
        repeat with morph in temp
          put "New" && morph
          add(result, morph)
        end repeat
      end if
      next repeat
    end if
    put "Not found" && index
  end repeat
  return result
end

on getStartParts
  set junk to value(the text of member("InitialJunkDB"))
  set result to []
  sort(result)
  repeat with index in junk
    repeat with n = 1 to count(index)
      add(result, getPropAt(index, n))
    end repeat
  end repeat
  put result
end

on checkAllPartsValid
  set All to value(the text of member("ExternalPartsDB"))
  repeat with aList in All
    repeat with partId in aList
      if not objectp(getPart(the parts of gMulleGlobals, partId)) then
        put "Missing: ", partId
      end if
    end repeat
  end repeat
  set All to value(the text of member("InitialJunkDB"))
  repeat with aList in All
    repeat with n = 1 to count(aList)
      if not objectp(getPart(the parts of gMulleGlobals, getPropAt(aList, n))) then
        put "Missing: ", partId
      end if
    end repeat
  end repeat
end
