property offset, offsetH, offsetV, useChassisLoc, ShowDirect

on beginSprite me
  if ShowDirect then
    drawCar(me, the spriteNum of me)
  end if
end

on new me, theUseChassisLoc
  set useChassisLoc to theUseChassisLoc
  return me
end

on drawCar me, theStartSP, theOffset, theParts, thePercentage
  global gMulleGlobals, gDir
  set chassisSP to the chassisSPOffset of the car of the user of gMulleGlobals
  if voidp(theStartSP) then
    set theStartSP to the spriteNum of me
  end if
  if useChassisLoc then
    set offsetH to the locH of sprite theStartSP + chassisSP
    set offsetV to the locV of sprite theStartSP + chassisSP
    set theOffset to point(offsetH, offsetV)
  end if
  if voidp(theOffset) then
    set theOffset to point(offsetH, offsetV)
  end if
  if voidp(theParts) then
    set tempCar to the car of the user of gMulleGlobals
    set parts to getParts(tempCar)
  else
    set tempCar to new(script("Car"))
    set objectList to [#parts: theParts, #medals: [], #name: EMPTY, #cacheList: [:]]
    fromList(tempCar, objectList)
    set parts to theParts
  end if
  set mulleLayer to the driverLayer of the car of the user of gMulleGlobals
  repeat with X = 1 to count(parts)
    set partToMount to getPart(the parts of gMulleGlobals, getAt(parts, X))
    set tempSnaps to getRequiredPoints(partToMount)
    if listp(tempSnaps) then
      set firstSnapPoint to getAt(tempSnaps, 1)
      set useLayers to getSnapInfo(tempCar, firstSnapPoint, #layers)
      set snapOffset to duplicate(getSnapInfo(tempCar, firstSnapPoint, #offset))
    else
      set useLayers to [chassisSP]
      set snapOffset to point(0, 0)
    end if
    set tempSP to getAt(useLayers, 1)
    if tempSP > mulleLayer - 1 then
      set tempSP to tempSP + 2
    end if
    setSpriteThings(me, theStartSP + tempSP, partToMount, theOffset, snapOffset, thePercentage, 1)
    if count(useLayers) = 2 then
      set tempSP to getAt(useLayers, 2)
      if tempSP > -1 then
        if tempSP > mulleLayer - 1 then
          set tempSP to tempSP + 2
        end if
        setSpriteThings(me, theStartSP + getAt(useLayers, 2), partToMount, theOffset, snapOffset, thePercentage, 2)
      end if
    end if
  end repeat
  if char 1 to 2 of the movieName = "03" then
    freeOrBindParts(the partsCommon of gDir)
  end if
end

on setSpriteThings me, theSP, partToMount, theOffset, theSnapOffset, thePercentage, theNr
  if theNr = 1 then
    set tempMember to getUseView(partToMount)
  else
    set tempMember to getUseView2(partToMount)
    if length(tempMember) = 0 then
      exit
    end if
  end if
  set the member of sprite theSP to tempMember
  set partOffset to duplicate(getOffset(partToMount))
  if not voidp(thePercentage) then
    setAt(partOffset, 1, integer(getAt(partOffset, 1) * thePercentage))
    setAt(partOffset, 2, integer(getAt(partOffset, 2) * thePercentage))
    setAt(theSnapOffset, 1, integer(getAt(theSnapOffset, 1) * thePercentage))
    setAt(theSnapOffset, 2, integer(getAt(theSnapOffset, 2) * thePercentage))
    set the width of sprite theSP to integer(the width of member(tempMember) * thePercentage)
    set the height of sprite theSP to integer(the height of member(tempMember) * thePercentage)
  end if
  set the loc of sprite theSP to theOffset + partOffset + theSnapOffset
  sendSprite(theSP, #setPart, getId(partToMount))
end

on getPropertyDescriptionList me
  set p_list to [#ShowDirect: [#comment: "Show car directly:", #format: #boolean, #default: 1], #useChassisLoc: [#comment: "Use chassis loc as midpoint: ", #format: #boolean, #default: 1], #offsetH: [#comment: "If not, use these:  LocH:", #format: #integer, #range: [#min: -200, #max: 840], #default: 320], #offsetV: [#comment: "LocV:", #format: #integer, #range: [#min: -200, #max: 680], #default: 240]]
  return p_list
end

on getBehaviorDescription me
  return "Draw Mulles car. Set this behaviour to the first of 35 sprites reserved for the car"
end
