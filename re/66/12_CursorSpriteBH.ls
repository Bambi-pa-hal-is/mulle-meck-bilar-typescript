global gMulleGlobals

on exitFrame me
  set the loc of sprite 115 to point(the mouseH, the mouseV)
end

on C_Standard me
  set the member of sprite the currentSpriteNum to "C_Standard"
end
