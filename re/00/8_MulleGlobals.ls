property parts, externalParts, user, users, world, worlds, maps, missions, chassis, junkPileHandlers, SharedSound, justStarted, WhereFrom, CustomCursorActive, loadIndicator, checkmemory

on new me
  set parts to new(script("Parts"))
  set externalParts to new(script("ExternalParts"))
  set users to new(script("Users"))
  set worlds to new(script("Worlds"))
  set maps to new(script("Maps"))
  set missions to new(script("Missions"))
  set junkPileHandlers to new(script("junkPileHandlers"))
  set SharedSound to new(script("SharedSound"))
  set justStarted to 1
  set WhereFrom to "00"
  set CustomCursorActive to 1
  set loadIndicator to 0
  set checkmemory to 0
  set tempPlugs to checkForPlugins()
  set plugCasts to getProp(tempPlugs, #cast)
  if count(plugCasts) = 0 then
    allFromList(me)
  end if
  set chassis to 1
  set user to 0
  set world to 0
  return me
end

on kill me
  save(me)
  set parts to kill(parts)
  set externalParts to kill(externalParts)
  set users to kill(users)
  set worlds to kill(worlds)
  set maps to kill(maps)
  set missions to kill(missions)
  set junkPileHandlers to kill(junkPileHandlers)
  set SharedSound to kill(SharedSound)
  if objectp(user) then
    set user to kill(user)
  end if
  if objectp(world) then
    set world to kill(world)
  end if
  return 0
end

on allFromList me
  fromList(parts, value(the text of member("PartsDB", "data")))
  fromList(externalParts, value(the text of member("ExternalPartsDB", "data")))
  fromList(users, value(the text of member("UsersDB", "data")))
  fromList(worlds, value(the text of member("WorldsDB", "data")))
  fromList(maps, value(the text of member("MapsDB", "data")))
  fromList(missions, value(the text of member("MissionsDB", "data")))
end

on save me
  set the text of member("UsersDB", "data") to string(toList(users))
  if objectp(user) then
    set tempMember to "User" & getUserId(user) & "DB"
    if the number of member(tempMember, "data") > -1 then
      set the text of member(tempMember, "data") to string(toList(user))
    else
      alert("Save member not found: " & tempMember & ". Game not saved!")
    end if
  end if
  save(castLib("data"))
end

on emptyDbs me
  set tempList to ["PartsDB", "JunkManPartsDB", "WorldPartsDB", "UsersDB", "WorldsDB", "MapsDB", "ObjectsDB", "MissionsDB"]
  repeat with index in tempList
    set the text of member(index) to "[]"
  end repeat
end
