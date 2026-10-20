property partId, position, part, active
global gMulleGlobals, gDir, gSound

on beginSprite me
  set active to 1
  if partId <> 0 then
    update(me)
    set tracking to 0
  end if
end

on activate me, theState
  set active to theState
end

on setPart me, newPart
  set partId to getAt(newPart, 1)
  set position to getAt(newPart, 2)
  if partId <> 0 then
    set part to getPart(the parts of gMulleGlobals, partId)
  end if
  update(me)
end

on update me
  if partId <> 0 then
    set the member of sprite the currentSpriteNum to member(getJunkView(part))
    set the loc of sprite the currentSpriteNum to position
  end if
end

on mouseDown me
  if active and partId <> 0 then
    sendSprite(120, #grabPart, partId, the currentSpriteNum)
  end if
end

on PlayDescription me
  set tmpSound to getaProp(part, #description)
  sendSprite(getaProp(the spriteList of gDir, #Mulle), #describepart, tmpSound)
end

on moveToShop me, currentPile
  if getaProp(the maxParts of the junkPileHandlers of gMulleGlobals, #shopFloor) <= count(getaProp(getaProp(the user of gMulleGlobals, #junk), #shopFloor)) then
    sendSprite(120, #flowBack)
    sendSprite(120, #putOnTop, the currentSpriteNum)
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #shopFull)
  else
    set tmpPileName to symbol("pile" & currentPile)
    removeJunkPart(the user of gMulleGlobals, tmpPileName, partId)
    addJunkPart(the user of gMulleGlobals, #shopFloor, partId)
    set the partsInShop of gDir to the partsInShop of gDir + 1
    kickPartSound(the SharedSound of gMulleGlobals, 0, partId, #ExternalGround)
  end if
end

on moveToDifferentPile me, fromPile, toPile
  if getaProp(the maxParts of the junkPileHandlers of gMulleGlobals, symbol("pile" & toPile)) <= count(getaProp(getaProp(the user of gMulleGlobals, #junk), symbol("pile" & toPile)) + 1) then
    put "alllright"
    sendSprite(120, #flowBack)
    sendSprite(getaProp(the spriteList of gDir, #Mulle), #MakeMulleSpeak, #pileFull)
  else
    kickPartSound(the SharedSound of gMulleGlobals, the currentSpriteNum, partId, #ExternalGround)
    removeJunkPart(the user of gMulleGlobals, symbol("pile" & fromPile), partId)
    addJunkPart(the user of gMulleGlobals, symbol("pile" & toPile), partId)
    sendSprite(120, #checkNrofParts)
  end if
end

on getPropertyDescriptionList me
  return [#partId: [#comment: "Which part (partId 0-999):", #format: #integer, #default: 0], #position: [#comment: "Which position", #format: #point, #default: point(0, 0)]]
end
