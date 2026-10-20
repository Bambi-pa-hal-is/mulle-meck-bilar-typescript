property SP, leftLocH, spacePix, maxSpeed
global gDir

on beginSprite me
  set SP to the spriteNum of me
  set spacePix to 300
  set maxSpeed to 14
  set leftLocH to 100
  addLoopObject(gDir, me)
end

on loop me
  if the mode of gDir = #Driving then
    set speed to abs(spacePix * the speed of the carDriving of gDir / maxSpeed / 100)
    set the locH of sprite SP to leftLocH + speed
  end if
end
