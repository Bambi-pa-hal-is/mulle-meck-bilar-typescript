global gDir

on mouseUp me
  sendSprite(getProp(the spriteList of gDir, #fDialog), #functionDialogSwitch)
end
