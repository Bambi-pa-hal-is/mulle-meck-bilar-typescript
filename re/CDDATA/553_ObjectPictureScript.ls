property child, FrameList, listLen, counter, SP
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set FrameList to getaProp(getOptionalData(child), #FrameList)
  if voidp(temp) then
    set FrameList to getProp(getFrameList(child), #normal)
  end if
  set SP to the SPOver of child
  if voidp(SP) then
    set SP to the SPUnder of child
  else
    if SP = 0 then
      set SP to the SPUnder of child
    end if
  end if
  set the loc of sprite SP to the myLoc of child
  set listLen to count(FrameList)
  set counter to 1
  step(me)
end

on step me, carLoc
  set the member of sprite SP to member(getAt(FrameList, counter))
  set counter to counter + 1
  if counter > listLen then
    set counter to 1
  end if
end
