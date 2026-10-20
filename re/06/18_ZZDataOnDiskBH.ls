property mode
global gMulleGlobals, gDir

on mouseUp me
  global gSound
  set file to new(xtra("FileIO"))
  if mode = #save then
    if the slotOccupied of gDir then
      set tempCar to the chosenSlot of gDir
      set tempDefault to correctFileName(me, the text of member("SavedCarName"))
      set tempDefault to char 1 to 8 of tempDefault & ".car"
    else
      set file to 0
      exit
      set tempCar to 0
      set tempDefault to "MinBil.car"
    end if
    set tempTitle to "Spara din bil"
    set Path to displaySave(file, tempTitle, tempDefault)
    if length(Path) = 0 then
      set file to 0
      exit
    end if
    if the machineType = 256 then
      set tempLength to length(Path)
      repeat with n = tempLength down to 1
        if char n of Path = "\" then
          set tempPath to char 1 to n of Path
          set tempName to char n + 1 to tempLength of Path
          exit repeat
        end if
      end repeat
      set tempOff to offset(".", tempName)
      if tempOff then
        delete char tempOff to length(tempName) of tempName
      end if
      set tempName to correctFileName(me, tempName)
      set tempName to char 1 to 8 of tempName
      set Path to tempPath & tempName & ".car"
    end if
    openFile(file, Path, 0)
    if status(file) = 0 then
      alert("File already exists")
      set file to 0
      exit
    end if
    createFile(file, Path)
    openFile(file, Path, 2)
    if status(file) <> 0 then
      alert("Problem creating file (" & string(status(file)) & ")")
    end if
    if tempCar then
      set tempCar to getSavedCars(the user of gMulleGlobals, tempCar)
      set tempStr to string(tempCar)
    else
      set tempStr to string(toList(the car of the user of gMulleGlobals))
    end if
    writeString(file, tempStr)
    closeFile(file)
  else
    if mode = #load then
      if the machineType = 256 then
        setFilterMask(file, "Cars *.car, *.car, All Files *.*, *.*")
      end if
      set Path to displayOpen(file)
      if stringp(Path) then
        openFile(file, Path, 0)
        if status(file) <> 0 then
          alert("Problem opening file")
          set file to 0
          exit
        end if
        set tempStr to readFile(file)
        set tempList to value(tempStr)
        if listp(tempList) then
          set tempCar to new(script("Car"))
          fromList(tempCar, tempList)
          set tempParts to the parts of tempCar
          repeat with index in tempParts
            if findPart(the user of gMulleGlobals, index) = 0 then
              play(gSound, "07d002v0", #EFFECT)
              closeFile(file)
              set file to 0
              exit
            end if
          end repeat
          closeFile(file)
          set file to 0
          loadCar(gDir, tempList)
          exit
        else
          alert("File corrupt")
        end if
      end if
    end if
  end if
  closeFile(file)
  set file to 0
end

on correctFileName me, theName
  if the machineType = 256 then
    set theName to changeChars(" ", EMPTY, theName)
    set theName to changeChars("\", EMPTY, theName)
    set theName to changeChars("*", EMPTY, theName)
    set theName to changeChars(":", EMPTY, theName)
    set theName to changeChars("?", EMPTY, theName)
    set theName to changeChars(QUOTE, EMPTY, theName)
    set theName to changeChars(".", EMPTY, theName)
  else
    set theName to changeChars(":", EMPTY, theName)
    set theName to changeChars(".", EMPTY, theName)
  end if
  return theName
end

on getPropertyDescriptionList me
  set p_list to [#mode: [#comment: "Save or load", #format: #symbol, #range: [#save, #load], #default: #save]]
  return p_list
end
