property missionList, kickMission, currentMission, phoneSmallSP, phoneBigSP, currentSound, tmpLoc, frameCount, loopState
global gMulleGlobals, gDir, gSound

on new me
  set missionList to []
  set kickMission to 0
  set loopState to 0
  return me
end

on kill me
  set missionList to 0
  return 0
end

on loop me
  if getType(currentMission) = #Telephone then
    if loopState = #Shake then
      set frameCount to frameCount + 1
      if finished(gSound, currentSound) = 0 then
        if frameCount mod 2 = 0 then
          set the loc of sprite phoneSmallSP to point(getAt(the loc of sprite phoneSmallSP, 1) - 2, getAt(the loc of sprite phoneSmallSP, 2))
          updateStage()
        else
          set the loc of sprite phoneSmallSP to point(getAt(the loc of sprite phoneSmallSP, 1) + 2, getAt(the loc of sprite phoneSmallSP, 2))
          updateStage()
        end if
      else
        finishPhone(me)
        deleteLoopObject(gDir, me)
      end if
    else
      if loopState = #Talk then
        if finished(gSound, currentSound) = 1 then
          set loopState to EMPTY
          deleteLoopObject(gDir, me)
          hangUp(me)
        end if
      end if
    end if
  else
    if finished(gSound, currentSound) = 0 then
      nothing()
    else
      if the mouseDown then
        finishMail(me)
        deleteLoopObject(gDir, me)
      end if
    end if
  end if
end

on checkMissions me
  if the nrOfBuiltCars of the user of gMulleGlobals mod 2 = 0 and the missionIsComing of the user of gMulleGlobals = 1 and the nrOfBuiltCars of the user of gMulleGlobals > 0 then
    if objectp(currentMission) = 0 then
      set tmpDoneList to the givenMissions of the user of gMulleGlobals
      set tmpToDoList to missionList
      set tmpGiven to the completedMissions of the user of gMulleGlobals
      put "tmpgiven ", tmpGiven
      if count(tmpDoneList) > 0 then
        repeat with n = 1 to count(tmpDoneList)
          deleteOne(tmpToDoList, getAt(tmpDoneList, n))
        end repeat
      end if
      put "tmpToDoList after 1 ", tmpToDoList
      if count(tmpToDoList) > 0 then
        set kickMission to getAt(tmpToDoList, 1)
        loadMission(me, kickMission)
      end if
    end if
  end if
end

on performMission me
  activate(gDir, 0)
  set the missionIsComing of the user of gMulleGlobals to 0
  if getType(currentMission) = #Telephone then
    kickTelephone(me)
  else
    if getType(currentMission) = #Mail then
      kickMail(me)
    end if
  end if
end

on kickTelephone me
  set phoneSmallSP to getaProp(the spriteList of gDir, #TeleSmall)
  set phoneBigSP to getaProp(the spriteList of gDir, #TeleBig)
  set tmpLoc to the loc of sprite phoneSmallSP
  set currentSound to play(gSound, "03e001v0", #EFFECT)
  set frameCount to 0
  set loopState to #Shake
  addLoopObject(gDir, me)
end

on finishPhone me
  set the loc of sprite phoneSmallSP to tmpLoc
  set the member of sprite phoneBigSP to "03b002v0"
  set the loc of sprite phoneBigSP to point(320, 240)
  updateStage()
  set currentSound to play(gSound, getSound(currentMission), #EFFECT)
  set loopState to #Talk
  addLoopObject(gDir, me)
end

on hangUp me
  set the member of sprite phoneBigSP to "Dummy"
  updateStage()
  add(the givenMissions of the user of gMulleGlobals, kickMission)
  set the missionIsComing of the user of gMulleGlobals to 0
  set currentMission to kill(currentMission)
  set kickMission to 0
  activate(gDir, 1)
end

on kickMail me
  add(the givenMissions of the user of gMulleGlobals, kickMission)
  set the missionIsComing of the user of gMulleGlobals to 0
  set the member of sprite getProp(the spriteList of gDir, #addresNote) to getimage(currentMission)
  set the loc of sprite getaProp(the spriteList of gDir, #addresNote) to point(320, 240)
  updateStage()
  set currentSound to play(gSound, getSound(currentMission), #EFFECT)
  addLoopObject(gDir, me)
end

on finishMail me
  set the member of sprite getProp(the spriteList of gDir, #addresNote) to "dummy"
  set the member of sprite getProp(the spriteList of gDir, #mailBox) to "04n001v0"
  updateStage()
  set currentMission to kill(currentMission)
  set kickMission to 0
  activate(gDir, 1)
end

on toList me
  return missionList
end

on fromList me, objectList
  set missionList to objectList
  put "missionList", missionList
end

on loadMission me, MissionId
  set currentMission to new(script("mission"))
  fromList(currentMission, MissionId)
end
