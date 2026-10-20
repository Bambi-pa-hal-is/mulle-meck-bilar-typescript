property sndId
global gDir

on new me, outOfWhat
  set tempList to [["05d001v0", "05d011v0", "05d012v0"], ["05d014v0"]]
  set tempList to getAt(tempList, outOfWhat)
  set tempSnd to getAt(tempList, random(count(tempList)))
  stopAllEffects(gSound)
  sendSprite(getProp(the spriteList of gDir, #medal), #stop)
  set sndId to play(gSound, tempSnd, #EFFECT)
  addLoopObject(gDir, me)
  return me
end

on loop me
  if finished(gSound, sndId) then
    prepareToLeave(gDir, "03")
    kill(me)
  end if
end

on kill me
  deleteLoopObject(gDir, me)
  return 0
end
