property users, maximumUsers

on new me
  set users to []
  set maximumUsers to 6
  return me
end

on kill me
  set users to 0
  return 0
end

on nrOfUsers me
  return count(users)
end

on getUsers me
  return users
end

on login me, userId
  global gMulleGlobals
  set knownUser to 0
  if objectp(the user of gMulleGlobals) then
    set the user of gMulleGlobals to kill(the user of gMulleGlobals)
  end if
  repeat with user in users
    if user = userId then
      set the user of gMulleGlobals to new(script("User"))
      fromList(the user of gMulleGlobals, value(the text of member("User" & userId & "DB")))
      set knownUser to 1
      exit repeat
    end if
  end repeat
  if not knownUser then
    if nrOfUsers(me) = maximumUsers then
      return #error
    else
      set dbMemberName to "User" & userId & "DB"
      if not copyMember(member("UserNewTemplateDB"), dbMemberName, "data") then
        return #error
      end if
      set the user of gMulleGlobals to new(script("User"))
      fromList(the user of gMulleGlobals, value(the text of member(dbMemberName)))
      setId(the user of gMulleGlobals, userId)
      initJunk(the user of gMulleGlobals)
      add(users, userId)
      return #Ok
    end if
  else
    return #Ok
  end if
end

on deleteUser me, userId
  set tempName to "User" & userId & "DB"
  if the number of member tempName > -1 then
    erase(member(tempName))
    deleteAt(users, getPos(users, userId))
    return #Ok
  else
    return #NotFound
  end if
end

on toList me
  return users
end

on fromList me, objectList
  set users to objectList
end
