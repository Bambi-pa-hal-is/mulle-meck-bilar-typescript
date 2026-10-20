property sndId
global gDir, gPathGlobals, gMulleGlobals

on new me
  set sndId to 0
  return me
end

on checkFolder me
  set file to new(xtra("FileIO"))
  set Path to the carPath of gPathGlobals
  set fileList to []
  sort(fileList)
  repeat with n = 1 to the maxinteger
    set tempStr to getNthFileNameInFolder(Path, n)
    if tempStr = EMPTY then
      exit repeat
    end if
    set tempLen to length(tempStr)
    if char tempLen - 3 to tempLen of tempStr = ".car" then
      if the mode of gDir = #load then
        openFile(file, Path & tempStr, 1)
        set tempStr to char 1 to tempLen - 4 of tempStr
        if status(file) = 0 then
          set tempLen to getLength(file)
          if tempLen > 0 and tempLen < 10 * 1024 then
            set tempCar to value(readFile(file))
            if listp(tempCar) then
              if checkCar(me, tempCar) then
                add(fileList, tempStr)
              else
                add(fileList, "?" & tempStr)
              end if
            end if
          end if
        end if
      else
        set tempStr to char 1 to tempLen - 4 of tempStr
        add(fileList, tempStr)
      end if
      closeFile(file)
    end if
  end repeat
  set file to 0
  return fileList
end

on checkCar me, theCar
  set tempParts to getaProp(theCar, #parts)
  if not listp(tempParts) then
    return 0
  end if
  if the cheatLoad of gDir then
    repeat with index in tempParts
      set part to getPart(the parts of gMulleGlobals, index)
      if part = 0 then
        return 0
      end if
      set partId to getMaster(part)
      if not (getMaster(part) > 0) then
        set partId to index
      end if
      if getPart(the parts of gMulleGlobals, partId) = 0 then
        return 0
      end if
    end repeat
  else
    repeat with index in tempParts
      set part to getPart(the parts of gMulleGlobals, index)
      set partId to getMaster(part)
      if not (getMaster(part) > 0) then
        set partId to index
      end if
      if findPart(the user of gMulleGlobals, partId) = 0 then
        return 0
      end if
    end repeat
  end if
  return 1
end

on loadCar me, theName
  global gSound
  set Path to the carPath of gPathGlobals & theName & ".car"
  set file to new(xtra("FileIO"))
  openFile(file, Path, 0)
  if status(file) <> 0 then
    set file to 0
    return "Problem opening file"
  end if
  set tempStr to readFile(file)
  set tempList to value(tempStr)
  if listp(tempList) then
    set tempResult to checkCar(me, tempList)
    if tempResult = 0 then
      stopAllEffects(gSound)
      play(gSound, "07d002v0", #EFFECT)
      closeFile(file)
      set file to 0
      return 0
    end if
    closeFile(file)
    set file to 0
    return tempList
  else
    closeFile(file)
    set file to 0
    return "File corrupt"
  end if
  closeFile(file)
  set file to 0
  return 0
end

on saveCar me, theName
  if the slotOccupied of gDir then
    set tempCar to the chosenSlot of gDir
  else
    set tempCar to 0
  end if
  set theName to correctFileName(theName) & ".car"
  set Path to the carPath of gPathGlobals & theName
  set file to new(xtra("FileIO"))
  openFile(file, Path, 2)
  if status(file) = 0 then
    setPosition(file, 0)
    writeString(file, EMPTY)
    setPosition(file, 0)
  else
    createFile(file, Path)
    openFile(file, Path, 2)
  end if
  if status(file) <> 0 then
    alert("Problem creating file (" & string(status(file)) & ")")
    closeFile(file)
    set file to 0
    exit
  end if
  if tempCar then
    set tempCar to getSavedCars(the user of gMulleGlobals, tempCar)
    set tempStr to string(tempCar)
  else
    set tempStr to string(toList(the car of the user of gMulleGlobals))
  end if
  writeString(file, tempStr)
  closeFile(file)
  set file to 0
end
