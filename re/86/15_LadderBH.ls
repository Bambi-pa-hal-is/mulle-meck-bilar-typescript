global gDir, gMulleGlobals

on beginSprite me
  set SP to the SPToChange of gDir
  if SP >= the driverLayer of the car of the user of gMulleGlobals then
    set SP to SP + 2
  end if
  set SP to getProp(the spriteList of gDir, #CarStart) + SP
  set the member of sprite SP to member("Stege")
  set the loc of sprite SP to the loc of sprite getProp(the spriteList of gDir, #CarStart) + the chassisSPOffset of the car of the user of gMulleGlobals
end
