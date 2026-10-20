global gPathGlobals, gDir, gMulleGlobals

on getSavedCars
  set Path to the carPath of gPathGlobals
  set files to []
  repeat with n = 1 to the maxinteger
    set fileName to getNthFileNameInFolder(Path, n)
    if fileName = EMPTY then
      exit repeat
    end if
    add(files, fileName)
  end repeat
  return files
end

on filetest
  global gMainScroller
  set tempList to getSavedCars()
  set tempList to []
  sendSprite(gMainScroller, #setText, tempList)
end

on resultsFromScroller what, theStr
  if what = #ChoseLine then
    if the mode of gDir = #save then
    end if
    if objectp(gDir) then
      dialogueResult(gDir, #ChoseFile, theStr)
    end if
  else
    if what = #NewLine then
      if the mode of gDir = #save then
        dialogueResult(gDir, #NewFile, theStr)
      end if
    end if
  end if
end

on loadCar theName
  global gSound
  set Path to the carPath of gPathGlobals & theName
  set file to new(xtra("FileIO"))
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
        put gSound, "Missing:", index
        closeFile(file)
        set file to 0
        return 0
      end if
    end repeat
    closeFile(file)
    set file to 0
    return 1
  else
    alert("File corrupt")
  end if
  closeFile(file)
  set file to 0
  return 0
end

on cleanString theStr
  repeat while 1
    if char 1 of theStr = " " then
      delete char 1 of theStr
      next repeat
    end if
    exit repeat
  end repeat
  repeat while 1
    if the last char in theStr = " " then
      delete char -30000 of theStr
      next repeat
    end if
    exit repeat
  end repeat
  return theStr
end
