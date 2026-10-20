global gMulleGlobals

on exitFrame
  set the loc of sprite the currentSpriteNum to point(the mouseH, the mouseV)
end

on C_Standard me
  set the member of sprite the currentSpriteNum to "C_Standard"
end

on c_grab me
  set the member of sprite the currentSpriteNum to "C_Grab"
end

on c_Left me
  set the member of sprite the currentSpriteNum to "C_Left"
end

on c_MoveLeft me
  set the member of sprite the currentSpriteNum to "C_MoveLeft"
end

on c_click me
  set the member of sprite the currentSpriteNum to "C_Click"
end

on c_MoveIn me
  set the member of sprite the currentSpriteNum to "C_MoveIn"
end

on C_Right me
  set the member of sprite the currentSpriteNum to "C_Right"
end

on c_MoveRight me
  set the member of sprite the currentSpriteNum to "C_MoveRight"
end
