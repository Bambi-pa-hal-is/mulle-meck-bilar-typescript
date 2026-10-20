property lastSpeed, sndId, limitList, sndList, SP, mode, counter, FrameList, firstFrame, listLen, soundOn, visible, masterObject
global gDir, gSound

on new me, theMaster, isShow
  set limitList to [10, 20, 40, 70]
  set masterObject to theMaster
  sort(limitList)
  set lastSpeed to 0
  set SP to getProp(the spriteList of gDir, #car)
  if isShow = #show then
    set firstFrame to the number of member "ShowCarPic" - 36
  else
    set firstFrame to the number of member "CarPic"
  end if
  set mode to #normal
  set soundOn to 1
  set visible to 1
  addLoopObject(gDir, me)
  return me
end

on setEngine me, theEngineNr
  if voidp(theEngineNr) then
    set engine to getProp(the quickCarProps of masterObject, #EngineType)
  else
    set engine to theEngineNr
  end if
  if engine > 0 then
    set tempSnds to [["05e073v0", "05e079v0", "05e074v0", "05e075v0", "05e076v0", "05e077v0", "05e078v0"], ["05e067v0", "05e073v0", "05e068v0", "05e069v0", "05e070v0", "05e071v0", "05e072v0"], ["05e025v0", "05e031v0", "05e026v0", "05e027v0", "05e028v0", "05e029v0", "05e030v0"], ["05e004v0", "05e010v0", "05e005v0", "05e006v0", "05e007v0", "05e008v0", "05e009v0"], ["05e011v0", "05e017v0", "05e012v0", "05e013v0", "05e014v0", "05e015v0", "05e016v0"], ["05e053v0", "05e059v0", "05e054v0", "05e055v0", "05e056v0", "05e057v0", "05e058v0"], ["05e018v0", "05e024v0", "05e019v0", "05e020v0", "05e021v0", "05e022v0", "05e023v0"], ["05e060v0", "05e066v0", "05e061v0", "05e062v0", "05e063v0", "05e064v0", "05e065v0"], ["05e032v0", "05e038v0", "05e033v0", "05e034v0", "05e035v0", "05e036v0", "05e037v0"]]
    if engine < 1 or engine > count(tempSnds) then
      set engine to 1
    end if
    set sndList to getAt(tempSnds, engine)
    repeat with snd in sndList
      preloadMember(snd)
    end repeat
    changecarSound(me)
    changecarSound(me)
  end if
end

on kill me
  deleteLoopObject(gDir, me)
  set the member of sprite SP to member("Dummy")
  return 0
end

on changecarSound me, onOff
  if voidp(onOff) then
    set soundOn to not soundOn
  else
    set soundOn to onOff
  end if
  if soundOn then
    set lastSpeed to -4711
  else
    stop(gSound, sndId)
  end if
end

on show me, YesNo
  set visible to YesNo
  if YesNo = 0 then
    set the member of sprite SP to member("Dummy")
  else
    set SP to getProp(the spriteList of gDir, #car)
    display(me)
  end if
end

on display me
  if the mode of gDir = #Driving or the mode of gDir = #Showing then
    if visible then
      case mode of
        #normal:
          step(masterObject)
          set the loc of sprite SP to getShowCoordinate(masterObject)
          set the member of sprite SP to member(firstFrame + getDirection(masterObject) + (2 + getInclination(masterObject)) * 16)
          set speed to abs(getSpeed(masterObject))
          set maxSpeed to getProp(the quickCarProps of masterObject, #speed) / 100
          set percent to 100 * speed / maxSpeed
          if soundOn then
            add(limitList, percent)
            set tempPos to getPos(limitList, percent)
            deleteAt(limitList, tempPos)
            if tempPos <> lastSpeed then
              set lastSpeed to tempPos
              stop(gSound, sndId)
              set sndId to play(gSound, getAt(sndList, tempPos + 2), #BG)
            end if
          end if
      end case
    end if
  end if
end

on stopEngine me
  set sndId to play(gSound, getAt(sndList, 2), #BG)
end

on loop me
  display(me)
end
