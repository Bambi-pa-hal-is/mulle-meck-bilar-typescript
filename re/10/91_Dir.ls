property spriteList, OKToEnd, OKToContinue
global gMulleGlobals

on new me
  set spriteList to [#EnterField: 14, #ScrollMain: 22, #MulleBody: 4, #MulleHead: 5, #Buffa: 8, #Loading: 114, #Cover: 113]
  set OKToEnd to 0
  return me
end

on init me
end

on startMovie me
  preloadMember("11d001v0")
  set the WhereFrom of gMulleGlobals to "10"
  sendSprite(115, #C_Standard)
  set tempPlugs to checkForPlugins()
  set plugCasts to getProp(tempPlugs, #cast)
  if count(plugCasts) then
    set transfer to 1
    set the member of sprite getProp(spriteList, #Loading) to member("10b008v0")
    set the loc of sprite getProp(spriteList, #Loading) to point(320, 240)
    updateStage()
    repeat with index in plugCasts
      xferPluginCasts(index)
    end repeat
    allFromList(gMulleGlobals)
  end if
  go(#next)
  sendSprite(getProp(spriteList, #ScrollMain), #setText, getUsers(the users of gMulleGlobals))
  set the member of sprite getProp(spriteList, #Cover) to member("Dummy")
end

on makeOKToEnd me
  set OKToEnd to 1
end

on tryToLeave me
  set tempStr to the text of member("EnterField")
  repeat while 1
    if char 1 of tempStr = " " then
      delete char 1 of tempStr
      next repeat
    end if
    exit repeat
  end repeat
  repeat while 1
    if the last char in tempStr = " " then
      delete char -30000 of tempStr
      next repeat
    end if
    exit repeat
  end repeat
  repeat while 1
    set tempOff to offset(RETURN, tempStr)
    if tempOff then
      delete char tempOff of tempStr
      next repeat
    end if
    exit repeat
  end repeat
  if length(tempStr) then
    sendSprite(getProp(spriteList, #ScrollMain), #AddLine, tempStr)
  end if
end

on resultsFromScroller me, type, theStr
  global gMulleGlobals, gDir
  if type = #ChoseLine then
    put "Login:", theStr
    if login(the users of gMulleGlobals, theStr) = #Ok then
      save(gMulleGlobals)
      go("IntroStart")
      set OKToEnd to 1
    else
      alert("Problem finding member. Try again.")
    end if
  else
    if type = #NewLine then
      put "Entered a new name:", theStr
      if login(the users of gMulleGlobals, theStr) = #Ok then
        save(gMulleGlobals)
        go("IntroStart")
        set OKToEnd to 1
      else
        sendSprite(getProp(spriteList, #ScrollMain), #deleteLine, theStr)
        alert("Problem creating member. Try again.")
      end if
    else
      if type = #DeletedLine then
        put "Deleted a name:", theStr
        deleteUser(the users of gMulleGlobals, theStr)
      end if
    end if
  end if
end

on kill me
  return 0
end
