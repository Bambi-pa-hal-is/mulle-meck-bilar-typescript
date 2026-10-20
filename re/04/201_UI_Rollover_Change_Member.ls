property standardImage, alternateImage, nextCM

on mouseEnter me
  set the member of sprite the spriteNum of me to the alternateImage of me
end

on mouseLeave me
  set the member of sprite the spriteNum of me to the standardImage of me
end

on beginSprite me
  set the standardImage of me to the member of sprite the spriteNum of me
  if nextCM = 1 then
    set memref to the member of sprite the currentSpriteNum
    set castLibNum to the castLibNum of memref
    set memdefault to member(the memberNum of member(memref) + 1, castLibNum)
    set alternateImage to memdefault
  end if
end

on getPropertyDescriptionList
  if the currentSpriteNum = 0 then
    set memdefault to 0
  else
    set memref to the member of sprite the currentSpriteNum
    set castLibNum to the castLibNum of memref
    set memdefault to member(the memberNum of member(memref) + 1, castLibNum)
  end if
  set p_list to [#nextCM: [#comment: "Use Next Member:", #format: #boolean, #default: 1], #alternateImage: [#comment: "Rollover Cast Member:", #format: #graphic, #default: memdefault]]
  return p_list
end

on getBehaviorDescription
  return "Change the sprite's cast member when the mouse rolls over the current sprite." & RETURN & "PARAMETERS:" & RETURN & "¥ Use Next Member - Turn this option on to automatically display the next cast member in the cast when mouse rolls over the sprite." & RETURN & "¥ Rollover Cast Member - Choose a specific cast member to appear when the mouse rolls over the sprite. This setting is ignored if Use Next Member is on."
end
