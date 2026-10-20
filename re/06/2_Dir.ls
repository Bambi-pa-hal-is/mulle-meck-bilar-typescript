property ancestor, spriteList, slotOccupied, chosenSlot, introObject, keyPressed, firstFree, changedName, carSaved, mode, myMIAW, fileObject, defaultFilename, doNextFrame, savedCarFiles, currentCarSlot, cheatLoad, carPasted
global gSound, gMulleGlobals

on new me
  set the mouseUpScript to "virtualMouseUp"
  set the mouseDownScript to "virtualMouseDown"
  set ancestor to new(script("GeneralAncestor"), me)
  set spriteList to [#CarStart: 2, #DeleteCar: 112, #MedalsStart: 59, #SmallCarStart: 75, #PhotoBG: 74, #loadCar: 74, #YesButton: 111, #NoButton: 112, #EnterName: 65, #SlotStart: 46, #Flerp: 45, #InsertCar: 68, #Dialogue: 114, #DialogueButton: 113, #GoBack: 66]
  set slotOccupied to 0
  set keyPressed to 0
  set changedName to 0
  set carSaved to 0
  if the frameLabel = "Save" then
    set the WhereFrom of gMulleGlobals to "06"
    set mode to #save
    play(gSound, "06e002v0", #OPEFFECT)
    play(gSound, "06d001v0", #EFFECT)
  else
    set the WhereFrom of gMulleGlobals to "07"
    set mode to #load
    if count(getSavedCars(the user of gMulleGlobals, #All)) then
      play(gSound, "07d001v0", #EFFECT)
    else
      play(gSound, "07d003v0", #EFFECT)
    end if
  end if
  set carPasted to 0
  set cheatLoad to 0
  set fileObject to new(script("FileStuff"))
  set defaultFilename to EMPTY
  set doNextFrame to 0
  set savedCarFiles to []
  return me
end

on init me
  set the WhereFrom of gMulleGlobals to char 1 to 2 of the movieName
  findFirstFree(me)
end

on startMovie me
  sendSprite(115, #C_Standard)
  sendSprite(getProp(spriteList, #SlotStart) + firstFree - 1, #clicked)
  if mode = #save then
    set introObject to new(script("IntroScript"))
  end if
end

on checkText me
  set changedName to 1
  set tempKey to the key
  set tempStr to the text of member("SavedCarName")
  set tempLastLoc to getAt(charPosToLoc(member("SavedCarName"), length(tempStr)), 1)
  if tempLastLoc > 180 then
    delete char length(tempStr) of tempStr
  end if
  if tempKey = RETURN then
    repeat with n = 1 to length(tempStr)
      if char n of tempStr = RETURN then
        delete char n of tempStr
      end if
    end repeat
  end if
  set the text of member("SavedCarName") to tempStr
end

on choseSlot me, theChosenSlot, theSlotOccupied
  saveIfNecessary(me)
  set chosenSlot to theChosenSlot
  set slotOccupied to theSlotOccupied
  if mode = #load then
    if slotOccupied then
      set the member of sprite getProp(spriteList, #loadCar) to member("07b004v0")
    else
      set the member of sprite getProp(spriteList, #loadCar) to member("Dummy")
    end if
  end if
  set the member of sprite getProp(spriteList, #YesButton) to member("Dummy")
  set the member of sprite getProp(spriteList, #NoButton) to member("Dummy")
  set changedName to 0
  set carSaved to 0
end

on saveIfNecessary me
  if changedName then
    set newName to the text of member("SavedCarName")
    changeCarName(the user of gMulleGlobals, chosenSlot, newName)
    if chosenSlot = currentCarSlot then
      setName(the car of the user of gMulleGlobals, newName)
    end if
  end if
  if changedName then
    findFirstFree(me)
  end if
end

on replaceAsk me
  set tempObj to new(script("ReplaceScript"))
end

on prepareEnterName me
  set carPasted to 1
  set currentCarSlot to chosenSlot
  set carSaved to 1
  sendSprite(getProp(spriteList, #InsertCar), #activate, 0)
  set tempSP to getProp(spriteList, #CarStart) - 1
  repeat with n = 1 to 35
    set the member of sprite tempSP + n to member("Dummy")
  end repeat
  set the member of sprite getProp(spriteList, #PhotoBG) to member("Dummy")
  set tempSP to getProp(spriteList, #SmallCarStart) - 1
  repeat with n = 1 to 35
    set the member of sprite tempSP + n to member("Dummy")
  end repeat
  updateStage()
  stopAllEffects(gSound)
  play(gSound, "06e001v0", #EFFECT)
  play(gSound, "06d002v0", #EFFECT)
  puppetTransition(1, 2, 5, 0)
  sendSprite(getProp(spriteList, #CarStart), #drawCar, VOID, VOID)
  set the text of member("SavedCarName") to EMPTY
  set the editableText of sprite getProp(spriteList, #EnterName) to 1
  setName(the car of the user of gMulleGlobals, EMPTY)
  saveCar(the user of gMulleGlobals, chosenSlot)
  findFirstFree(me)
  sendSprite(getProp(spriteList, #SlotStart) + chosenSlot - 1, #clicked)
end

on loadCar me, theOption
  if voidp(theOption) then
    if slotOccupied then
      set theOption to getSavedCars(the user of gMulleGlobals, chosenSlot)
    else
      exit
    end if
  end if
  trash(the car of the user of gMulleGlobals)
  fromList(the car of the user of gMulleGlobals, theOption)
  repeat with partId in getParts(the car of the user of gMulleGlobals)
    if partId > 1 then
      removeJunkPart(the user of gMulleGlobals, VOID, partId)
    end if
  end repeat
  set doNextFrame to #jump
end

on keyDown me, which
end

on keyUp me
end

on mouseUp
end

on findFirstFree me
  set tempCars to getSavedCars(the user of gMulleGlobals, #All)
  set tempNrOfCars to count(tempCars)
  set firstFree to 0
  set tempSP to getProp(spriteList, #SlotStart) - 1
  repeat with n = 1 to tempNrOfCars
    if listp(getAt(tempCars, n)) then
      set the member of sprite tempSP + n to member(n - 1 + the number of member "06n002v0")
      next repeat
    end if
    if not firstFree then
      set firstFree to n
    end if
  end repeat
  if mode = #save then
    if not firstFree then
      if tempNrOfCars < 12 then
        set firstFree to tempNrOfCars + 1
      else
        set firstFree to 1
      end if
    end if
  else
    set firstFree to 1
  end if
end

on kill me
  if mode = #save and not (the runMode = "Author") then
    save(gMulleGlobals)
  end if
  set the text of member("SavedCarName") to " "
  set the editable of member("SavedCarName") to 0
  set fileObject to 0
  if objectp(introObject) then
    set introObject to kill(introObject)
  end if
  set ancestor to kill(ancestor)
  closeWindow(me)
  play(gSound, "06e003v0", #EFFECT)
  return 0
end

on openWindow me
  cursor(-1)
  activateScreen(me, 0)
  set savedCarFiles to checkFolder(fileObject)
  set myMIAW to window("Choose")
  set tempSize to point(336, 278)
  set tempLoc to point(300, 220)
  set tempLoc to tempLoc - tempSize / 2
  set tempLoc to tempLoc + point(the stageLeft, the stageTop)
  set tempRect to rect(getAt(tempLoc, 1), getAt(tempLoc, 2), getAt(tempLoc, 1) + getAt(tempSize, 1), getAt(tempLoc, 2) + getAt(tempSize, 2))
  set the rect of myMIAW to tempRect
  set the fileName of myMIAW to "13"
  set the titleVisible of myMIAW to 0
  open(myMIAW)
  cursor(200)
end

on closeWindow me
  if not (myMIAW = 0) then
    tell myMIAW
      cleanUp()
    end tell
    close(myMIAW)
    set myMIAW to 0
  end if
  set doNextFrame to #activateScreen
end

on activateScreen me, YesNo
  set tempSP to getProp(spriteList, #SlotStart)
  repeat with n = 1 to 12
    sendSprite(tempSP + n - 1, #activate, YesNo)
  end repeat
  if YesNo = 0 or YesNo and mode = #save and carPasted = 0 then
    sendSprite(getProp(spriteList, #InsertCar), #activate, YesNo)
    sendSprite(getProp(spriteList, #PhotoBG), #activate, YesNo)
  end if
  sendSprite(getProp(spriteList, #DialogueButton), #activate, YesNo)
  sendSprite(getProp(spriteList, #GoBack), #activate, YesNo)
end

on dialogueResult me, what, theFile
  if what = #ChoseFile then
    if mode = #load then
      set tempList to loadCar(fileObject, theFile)
      if listp(tempList) then
        closeWindow(me)
        loadCar(me, tempList)
        exit
      else
        if stringp(tempList) then
          closeWindow(me)
          alert(tempList)
        end if
      end if
    else
      saveCar(fileObject, theFile)
      closeWindow(me)
    end if
  else
    if what = #NewFile then
      saveCar(fileObject, theFile)
      closeWindow(me)
    else
      if what = #Cancel then
        closeWindow(me)
      end if
    end if
  end if
end
