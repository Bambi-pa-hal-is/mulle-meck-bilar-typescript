property active, p_list, pName
global gDir

on dropItem me
  set the active of me to 1
  drop(the spriteNum of me)
end

on getItem me
  set the active of me to 1
  drag(the spriteNum of me)
end

on setActive me
  if the active of me = 0 then
    set the active of me to 1
  end if
end

on killActive me
  if the active of me = 1 then
    set the active of me to 0
  end if
end

on beginSprite me
  set the active of me to 0
end

on getPropertyDescriptionList
  set p_list to [#pName: [#comment: "The name of member:", #format: #string, #default: "can2"]]
  return p_list
end
