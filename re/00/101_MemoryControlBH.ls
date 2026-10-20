property fieldName
global gMulleGlobals

on beginSprite me
  set checkingMemory to 0
  set fieldName to "ShowMemoryField"
  if the checkmemory of gMulleGlobals then
    set the member of sprite the spriteNum of me to member(fieldName)
    set the loc of sprite the spriteNum of me to point(550, 0)
  end if
end

on exitFrame me
  if the checkmemory of gMulleGlobals then
    set the text of member(fieldName) to string(the freeBlock / 1024)
  end if
end

on checkmemory me
  if the checkmemory of gMulleGlobals then
    set the checkmemory of gMulleGlobals to 0
    set the member of sprite the spriteNum of me to member("Dummy")
  else
    set the checkmemory of gMulleGlobals to 1
    set the member of sprite the spriteNum of me to member(fieldName)
    set the loc of sprite the spriteNum of me to point(550, 0)
  end if
end
