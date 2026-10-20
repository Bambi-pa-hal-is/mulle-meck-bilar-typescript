property direction, active, mySounds
global gSound, gDir

on activate me, theState
  set active to theState
end

on beginSprite me
  set active to 1
  set mySounds to ["02e011v0"]
end

on mouseEnter me
  put "entering sign"
  if not the goToLoad of gDir then
    set sound to getAt(mySounds, random(count(mySounds)))
    if the last char in the name of the member of sprite the spriteNum of me = "0" then
      set the member of sprite the spriteNum of me to the memberNum of sprite the currentSpriteNum + 1
    end if
    play(gSound, sound, #OPEFFECT)
  end if
end

on mouseLeave me
  if the last char in the name of the member of sprite the spriteNum of me = "1" then
    set the member of sprite the spriteNum of me to the memberNum of sprite the currentSpriteNum - 1
  end if
end

on mouseUp me
  put "isdraggin ", the dragging of sprite(getaProp(the spriteList of gDir, #drag))
  if not the dragging of sprite(getaProp(the spriteList of gDir, #drag)) then
    if active then
      case direction of
        #left:
          sendSprite(120, #GoLeft)
        #right:
          sendSprite(120, #GoRight)
      end case
    end if
  end if
end

on getPropertyDescriptionList me
  return [#direction: [#comment: "Sign direction:", #format: #integer, #default: #left, #range: [#left, #right]]]
end
