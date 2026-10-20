property myMember, SP

on beginSprite me
  set SP to the spriteNum of me
end

on mouseEnter me
  sendSprite(115, #MEnter, myMember, SP)
end

on mouseLeave me
  sendSprite(115, #MLeave, SP)
end

on getPropertyDescriptionList me
  set p_list to [#myMember: [#comment: "Member: ", #format: #string, #default: EMPTY]]
  return p_list
end
