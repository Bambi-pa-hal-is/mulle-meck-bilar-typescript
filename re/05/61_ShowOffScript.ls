property counter, SP, active, actionList, keyList, firstFrame, ShowOff, waitAndKill, delayList
global gDir, gMulleGlobals, gSound

on beginSprite me
  if (the WhereFrom of gMulleGlobals = "04" or the WhereFrom of gMulleGlobals = "03") and the nrOfBuiltCars of the user of gMulleGlobals < 4 then
    set ShowOff to new(script("ShowCarDriving"))
    init(ShowOff)
    set SP to getProp(the spriteList of gDir, #ShowOff)
    set keyList to [#left: ["05b003v0", "05b004v0"], #right: ["05b007v0", "05b008v0"], #up: ["05b001v0", "05b002v0"], #down: ["05b005v0", "05b006v0"]]
    repeat with n = 1 to 4
      set the member of sprite SP + n to member(getAt(getAt(keyList, n), 1))
    end repeat
    set the loc of sprite SP + 1 to point(260, 240)
    set the loc of sprite SP + 2 to point(380, 240)
    set the loc of sprite SP + 3 to point(320, 190)
    set the loc of sprite SP + 4 to point(320, 240)
    set actionList to [0, 0, 0, [#Accelerate: 1], 0, 0, 0, 0, [#Accelerate: 0], 0, 0, 0, 0, [#Accelerate: -1], 0, 0, 0, 0, 0, [#Accelerate: 0], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [#Accelerate: -1], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [#Accelerate: 0], 0, 0, 0, 0, 0, 0, 0, 0, 0, [#Accelerate: 1], 0, 0, 0, 0, [#Accelerate: 0], [#stop: 1], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [#steer: 1], 0, 0, 0, 0, 0, [#steer: 0], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, [#steer: -1], 0, 0, 0, 0, 0, [#steer: 0], 0, 0, 0, 0, 0, 0, 0, 0, 0]
    set counter to 0
    if the machineType = 256 then
      set delayList to [0, 0, 0, 0, 0, 0, 0, 0, 0]
    else
      set delayList to [0]
    end if
    set active to 1
    set the member of sprite SP to member("Platta")
    set the loc of sprite SP to point(320, 220)
    set waitAndKill to 0
  else
    set active to 1
    set waitAndKill to 1
  end if
end

on kill me
  if objectp(ShowOff) then
    set the member of sprite SP to member("Dummy")
    set the member of sprite SP + 1 to member("Dummy")
    set the member of sprite SP + 2 to member("Dummy")
    set the member of sprite SP + 3 to member("Dummy")
    set the member of sprite SP + 4 to member("Dummy")
    set ShowOff to kill(ShowOff)
  end if
  setProp(the spriteList of gDir, #car, getProp(the spriteList of gDir, #RealCar))
  startCar(gDir)
  set active to 0
end

on mouseUp me
  set waitAndKill to 1
end

on fakeMouse me
  set waitAndKill to 1
end

on exitFrame me
  if active then
    if waitAndKill then
      kill(me)
      exit
    end if
    set counter to counter + 1
    set tempList to getAt(actionList, counter)
    doIt(me, tempList)
    if counter = count(actionList) then
      set counter to 0
    end if
  end if
end

on doIt me, tempList
  add(delayList, tempList)
  deleteAt(delayList, 1)
  if listp(tempList) then
    repeat with n = 1 to count(tempList)
      case getPropAt(tempList, n) of
        #steer:
          set Dir to getAt(tempList, n)
          if Dir then
            play(gSound, "P38ef005", #EFFECT)
          end if
        #Accelerate:
          set acc to getAt(tempList, n)
          if acc then
            play(gSound, "P38ef005", #EFFECT)
          end if
      end case
    end repeat
  end if
  memberChange(me, getAt(delayList, 1))
end

on memberChange me, tempList
  if listp(tempList) then
    repeat with n = 1 to count(tempList)
      case getPropAt(tempList, n) of
        #stop:
          setSpeed(ShowOff, 0)
        #steer:
          set Dir to getAt(tempList, n)
          steer(ShowOff, Dir)
          if Dir = 1 then
            set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 2))
            set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 1))
          else
            if Dir = -1 then
              set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 2))
              set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 1))
            else
              set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 1))
              set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 1))
            end if
          end if
        #Accelerate:
          set acc to getAt(tempList, n)
          changeSpeed(ShowOff, acc)
          if acc = 1 then
            set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 2))
            set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 1))
          else
            if acc = -1 then
              set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 2))
              set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 1))
            else
              set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 1))
              set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 1))
            end if
          end if
      end case
    end repeat
  end if
end

on ZZdoIt me, tempList
  add(delayList, tempList)
  deleteAt(delayList, 1)
  if listp(tempList) then
    repeat with n = 1 to count(tempList)
      case getPropAt(tempList, n) of
        #stop:
          setSpeed(ShowOff, 0)
        #steer:
          set Dir to getAt(tempList, n)
          steer(ShowOff, Dir)
          if Dir = 1 then
            play(gSound, "P38ef005", #EFFECT)
            set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 2))
            set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 1))
          else
            if Dir = -1 then
              play(gSound, "P38ef005", #EFFECT)
              set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 2))
              set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 1))
            else
              play(gSound, "P38ef006", #EFFECT)
              set the member of sprite SP + 2 to member(getAt(getProp(keyList, #right), 1))
              set the member of sprite SP + 1 to member(getAt(getProp(keyList, #left), 1))
            end if
          end if
        #Accelerate:
          set acc to getAt(tempList, n)
          changeSpeed(ShowOff, acc)
          if acc = 1 then
            play(gSound, "P38ef005", #EFFECT)
            set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 2))
            set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 1))
          else
            if acc = -1 then
              play(gSound, "P38ef005", #EFFECT)
              set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 2))
              set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 1))
            else
              play(gSound, "P38ef006", #EFFECT)
              set the member of sprite SP + 3 to member(getAt(getProp(keyList, #up), 1))
              set the member of sprite SP + 4 to member(getAt(getProp(keyList, #down), 1))
            end if
          end if
      end case
    end repeat
  end if
  memberChange(me, tempList)
end
