global gDir, gMulleGlobals

on beginSprite me
end

on mouseDown me
  if the number of member the member of sprite the currentSpriteNum = the number of member "04b006v0" then
    put the gCurrentSound of gDir
    if the gCurrentSound of gDir <> "04d023v0" then
      set the member of sprite the currentSpriteNum to "Dummy"
      sendAllSprites(#activateClick, 1)
      set tmpParts to the gifts of the user of gMulleGlobals
      set nr to count(tmpParts)
      repeat with n = 1 to nr
        set tmpId to getAt(getAt(tmpParts, 1), 1)
        deleteAt(tmpParts, 1)
        addYardPart(the user of gMulleGlobals, #yard, tmpId)
      end repeat
      set the gifts of the user of gMulleGlobals to tmpParts
      sendSprite(getProp(the spriteList of gDir, #JunkStart), #drawJunk)
      set the member of sprite getaProp(the spriteList of gDir, #giftSprite) to "Dummy"
      go(the frame)
    end if
  end if
end
