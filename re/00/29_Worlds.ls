property worlds, activeWorld, lastWorld

on new me
  set worlds to []
  set activeWorld to 0
  set lastWorld to 0
  return me
end

on kill me
  set worlds to 0
  return 0
end

on nrOfWorlds me
  return count(worlds)
end

on isSameWorld me
  if activeWorld = 0 then
    return 0
  end if
  return activeWorld = lastWorld
end

on getWorldSymbols me
  set symbolList to []
  set tempWorld to new(script("World"))
  repeat with l in worlds
    if fromList(tempWorld, l) then
      add(symbolList, [getSymbol(tempWorld), l])
      next repeat
    end if
  end repeat
  return duplicate(symbolList)
end

on loadWorld me, world, WorldId
  if not objectp(world) then
    return #InvalidObject
  end if
  if getPos(worlds, WorldId) = 0 then
    return #InvalidId
  end if
  if fromList(world, WorldId) then
    set lastWorld to WorldId
    set activeWorld to WorldId
    return 0
  else
    return #InvalidMember
  end if
end

on toList me
  return worlds
end

on fromList me, objectList
  set worlds to objectList
end
