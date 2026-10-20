property stack, locH, locV, currentV

on new me, X, y
  set the stack of me to []
  set the locH of me to X
  set the locV of me to y
  set the currentV of me to y
  return me
end

on top me
  return getLast(the stack of me)
end

on Pop me, gDir
  set top to getLast(the stack of me)
  if top <> 0 then
    deleteAt(the stack of me, count(the stack of me))
    set the currentV of me to the currentV of me + getAt(the canHeights of gDir, top - the can1 of gDir + 1)
    set next to getLast(the stack of me)
    if next <> 0 and next <> the can1 of gDir then
      sendSprite(next, #setActive)
    end if
    return top
  else
    puppetSound("P36ef008")
    return 0
  end if
end

on push me, can, gDir
  set top to getLast(the stack of me)
  if top < can then
    add(the stack of me, can)
    set the locV of sprite can to the currentV of me
    set the locH of sprite can to the locH of me
    set the currentV of me to the currentV of me - getAt(the canHeights of gDir, can - the can1 of gDir + 1)
    if top <> 0 then
      sendSprite(top, #killActive)
    end if
    sendSprite(can, #setActive)
    return 1
  else
    return 0
  end if
end

on isEmpty me
  if stack = [] then
    return 1
  else
    return 0
  end if
end
