property SaveNr, screenObject, active
global gMulleGlobals, gDir, gSound

on beginSprite me
  set active to 1
  set tempRect to the rect of sprite the spriteNum of me
  set extend to 12
  set tempRect to rect(getAt(tempRect, 1) - extend, getAt(tempRect, 2) - extend, getAt(tempRect, 3) + extend, getAt(tempRect, 4) + extend)
  set screenObject to new(script("ScreenObject"), me, tempRect, #normal)
  addScreenObject(gDir, screenObject)
end

on activate me, YesNo
  set active to YesNo
end

on report me, theObject, what
  if what = #clicked then
    clicked(me)
  end if
end

on clicked me
  if active then
    set tempCar to getSavedCars(the user of gMulleGlobals, SaveNr)
    if SaveNr <> the chosenSlot of gDir then
      play(gSound, "06e003v0", #OPEFFECT)
    end if
    if listp(tempCar) then
      set occupied to 1
      choseSlot(gDir, SaveNr, occupied)
      eraseCar(me)
      set medals to getaProp(tempCar, #medals)
      set tempStartLoc to point(570, 65)
      set tempSP to getProp(the spriteList of gDir, #MedalsStart)
      repeat with index in medals
        case index of
          1:
            set tempMedal to "00n004v0"
          2:
            set tempMedal to "00n005v0"
          3:
            set tempMedal to "00n006v0"
          4:
            set tempMedal to "00n007v0"
          5:
            set tempMedal to "00n010v0"
          6:
            set tempMedal to "00n009v0"
        end case
        set the member of sprite tempSP + index - 1 to member(tempMedal)
        set the loc of sprite tempSP + index - 1 to tempStartLoc + point(0, 62) * (index - 1)
      end repeat
      set name to getaProp(tempCar, #name)
      set the text of member("SavedCarName") to name
      if the mode of gDir = #save then
        set the editable of member("SavedCarName") to 1
      end if
      set the selStart to length(name)
      set the selEnd to length(name)
      sendSprite(getProp(the spriteList of gDir, #CarStart), #drawCar, VOID, VOID, getaProp(tempCar, #parts))
    else
      set occupied to 0
      choseSlot(gDir, SaveNr, occupied)
      set the editable of member("SavedCarName") to 0
      eraseCar(me)
      set the text of member("SavedCarName") to " "
      set the editable of member("SavedCarName") to 0
    end if
    set the member of sprite getProp(the spriteList of gDir, #Flerp) to member(SaveNr - 1 + the number of member "06n003v0")
  end if
end

on eraseCar me
  set tempSP to getProp(the spriteList of gDir, #CarStart) - 1
  repeat with n = 1 to 35
    set the member of sprite tempSP + n to member("Dummy")
  end repeat
  repeat with n = 1 to 6
    set the member of sprite getProp(the spriteList of gDir, #MedalsStart) + n - 1 to member("Dummy")
  end repeat
end

on getPropertyDescriptionList me
  set p_list to [#SaveNr: [#comment: "Which save:", #format: #integer, #range: [#min: 1, #max: 12], #default: 1]]
  return p_list
end
