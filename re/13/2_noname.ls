on startMovie
  global gDir, gMainScroller, gPathGlobals
  set gMainScroller to 7
  if objectp(gDir) then
    set mode to the mode of gDir
    if mode = #save then
      set the text of member("EnterField") to the defaultFilename of gDir
    end if
    sendSprite(gMainScroller, #setText, the savedCarFiles of gDir)
  else
    set mode to #save
    filetest()
  end if
  if mode = #save then
    sendSprite(gMainScroller, #AllowedToAdd, 1)
  else
    sendSprite(gMainScroller, #AllowedToAdd, 0)
  end if
  set the text of member("DirectoryField") to the carPath of gPathGlobals
  sendSprite(115, #C_Standard)
end

on idle
  global gJustPressedKey, gMsgFromSP
  if gJustPressedKey then
    sendSprite(gMsgFromSP, #GotIt)
    set gJustPressedKey to 0
  end if
end

on cleanUp
  set the text of member("MainScroller") to " "
  set the text of member("EnterField") to " "
end
