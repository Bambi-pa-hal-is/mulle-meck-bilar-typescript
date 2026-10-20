property headSP

on beginSprite me
  global gDir
  set headSP to getProp(the spriteList of gDir, #MulleHead)
end

on Stopped me
  sendSprite(headSP, #Stopped)
end
