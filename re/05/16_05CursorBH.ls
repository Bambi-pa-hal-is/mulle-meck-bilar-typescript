property SP, firstFrame, mode, cursorList, spriteRect, insideLast
global gDir

on beginSprite me
  set SP to the spriteNum of me
  set insideLast to 0
  set firstFrame to the number of member "05n002v0"
  set spriteRect to rect(0, 0, 640, 480)
  set cursorList to [:]
  sort(cursorList)
end

on display me
  set mouseLoc to point(the mouseH, the mouseV)
  set the loc of sprite SP to mouseLoc
  if mode = #mouse then
    if count(cursorList) = 1 then
      cursor([firstFrame + 2 * the cursorDirection of the carDriving of gDir - 2, firstFrame + 2 * the cursorDirection of the carDriving of gDir - 1])
      set the member of sprite SP to member("Dummy")
    end if
  end if
end

on exitFrame me
  display(me)
end

on setMode me, theMode
  set mode to theMode
  if mode = #Keys then
    cursor(200)
    set the member of sprite SP to member(getAt(cursorList, count(cursorList)))
  end if
end

on MEnter me, theCursor, theChannel
  cursor(200)
  if voidp(theChannel) then
    set theChannel to 200
  end if
  deleteProp(cursorList, theChannel)
  addProp(cursorList, theChannel, theCursor)
  set the member of sprite SP to member(getAt(cursorList, count(cursorList)))
end

on MLeave me, theChannel
  cursor(200)
  if voidp(theChannel) then
    set theChannel to 200
  end if
  deleteProp(cursorList, theChannel)
  set the member of sprite SP to member(getAt(cursorList, count(cursorList)))
end

on C_Standard me
  MEnter(me, "C_Standard")
end

on c_grab me
  MEnter(me, "C_Grab")
end

on c_Left me
  MEnter(me, "C_Left")
end

on c_click me
  MEnter(me, "C_Click")
end

on C_Back me
  MEnter(me, "C_Back")
end

on C_Right me
  MEnter(me, "C_Right")
end
