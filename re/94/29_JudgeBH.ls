property type, animObject
global gDir

on beginSprite me
  set type to #Judge
  set objects to the scriptInstanceList of sprite the spriteNum of me
  repeat with index in objects
    if the type of index = #SpriteAnim then
      set animObject to index
      exit repeat
    end if
  end repeat
  case the rating of gDir of
    1:
      set snd to "94d008v0"
    2:
      set snd to "94d007v0"
    3:
      set snd to "94d006v0"
    4:
      set snd to "94d005v0"
    5:
      set snd to "94d004v0"
  end case
  makeAnimSpeech(animObject, snd)
  setAnimAction(animObject, #Talk)
end
