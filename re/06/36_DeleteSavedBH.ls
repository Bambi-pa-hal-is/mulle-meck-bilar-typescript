property YesNo
global gMulleGlobals, gDir

on mouseUp me
  if YesNo then
    prepareEnterName(gDir)
  end if
  set the member of sprite getProp(the spriteList of gDir, #YesButton) to member("Dummy")
  set the member of sprite getProp(the spriteList of gDir, #NoButton) to member("Dummy")
end

on getPropertyDescriptionList me
  set p_list to [#YesNo: [#comment: "Yes:", #format: #boolean, #default: 1]]
  return p_list
end
