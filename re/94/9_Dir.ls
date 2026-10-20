property rating, testing, medal
global gMulleGlobals

on new me
  return me
end

on init me
  set testing to 0
  if objectp(the world of gMulleGlobals) then
    set objId to getEnteredObject(the world of gMulleGlobals)
  else
    set objId to 0
  end if
  if objId then
    set tempObj to new(script("Object"))
    fromList(tempObj, objId)
    set medalId to getAt(getSetWhenDone(tempObj, #medals), 1)
    set cacheProp to getAt(getSetWhenDone(tempObj, #Cache), 1)
    set MissionId to getAt(getSetWhenDone(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set medalId to 4
    set cacheProp to #Exhibition
    set MissionId to 2
  end if
  setCacheProp(the car of the user of gMulleGlobals, cacheProp)
  addCompletedMission(the user of gMulleGlobals, MissionId)
  set funny to getProperty(the car of the user of gMulleGlobals, #FunnyFactor)
  if funny < 2 then
    set rating to 1
  else
    if funny < 3 then
      set rating to 2
    else
      if funny < 5 then
        set rating to 3
      else
        if funny < 7 then
          set rating to 4
        else
          set rating to 5
        end if
      end if
    end if
  end if
  if funny > 8 and not getMedal(the car of the user of gMulleGlobals, medalId) then
    set medal to 1
    addMedal(the car of the user of gMulleGlobals, medalId)
  else
    set medal to 0
  end if
  if testing then
    set rating to 1
    set medal to 1
  end if
end

on startMovie me
  sendSprite(115, #C_Standard)
end

on kill me
  return 0
end
