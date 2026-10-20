property partId, junkView, UseView, UseView2, description, offset, partProperties, requiredPoints, coveredPoints, newPoints, morphList, master

on new me
  set partId to 0
  set MorphsTo to []
  set junkView to EMPTY
  set UseView to EMPTY
  set UseView2 to EMPTY
  set description to EMPTY
  set offset to point(0, 0)
  set partProperties to [:]
  set requiredPoints to EMPTY
  set coveredPoints to []
  set newPoints to []
  set morphList to []
  set master to 0
  return me
end

on kill me
  set partProperties to 0
  set requiredPoints to 0
  set coveredPoints to 0
  set newPoints to 0
  set morphList to 0
  return 0
end

on getId me
  return partId
end

on getJunkView me
  return junkView
end

on getHeight me
  return the height of member(junkView) / 2
end

on getWidth me
  return the width of member(junkView) / 2
end

on getUseView me
  return UseView
end

on getUseView2 me
  return UseView2
end

on getDescription me
  return description
end

on getOffset me
  return offset
end

on getRequiredPoints me
  return requiredPoints
end

on getCoveredPoints me
  return coveredPoints
end

on getNewPoints me
  return newPoints
end

on getMorphList me
  return morphList
end

on getMaster me
  return master
end

on isMaster me
  return master <> 0
end

on isMorphPart me
  return listp(morphList)
end

on isNormalpart me
  return master = 0 and not listp(morphList)
end

on getProperty me, prop
  return getaProp(partProperties, prop)
end

on toList me
  return [#partId: partId, #junkView: junkView, #UseView: UseView, #UseView2: UseView2, #description: description, #offset: offset, #partProperties: partProperties, #requiredPoints: requiredPoints, #coveredPoints: coveredPoints, #newPoints: newPoints, #morphList: morphList, #master: master]
end

on fromList me, theid
  set memberName to "Part" & string(theid) & "DB"
  if the number of member memberName = -1 then
    alert(memberName & " not found!")
    stop()
    return 0
  end if
  set objectList to value(the text of member(memberName))
  set partId to getaProp(objectList, #partId)
  set master to getaProp(objectList, #master)
  set morphList to getaProp(objectList, #MorphsTo)
  set description to getaProp(objectList, #description)
  set junkView to getaProp(objectList, #junkView)
  set UseView to getaProp(objectList, #UseView)
  set UseView2 to getaProp(objectList, #UseView2)
  set offset to getaProp(objectList, #offset)
  set partProperties to getaProp(objectList, #Properties)
  set requiredPoints to getaProp(objectList, #Requires)
  set coveredPoints to getaProp(objectList, #Covers)
  set newPoints to getaProp(objectList, #new)
  return 1
end

on import me, fileName
end
