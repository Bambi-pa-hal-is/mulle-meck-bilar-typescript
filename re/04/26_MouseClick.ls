on virtualmouseDown theLoc
  global gDir, gMBStat
  if the mouseButtonActive of gDir then
    if gMBStat = 1 then
      exit
    end if
    set gMBStat to 1
    if objectp(gDir) then
      set temp to 0
      if voidp(theLoc) then
        set theLoc to point(the mouseH, the mouseV)
      end if
      repeat with index in the screenObjects of gDir
        if checkDown(index, theLoc) then
          set temp to 1
          exit repeat
        end if
      end repeat
    end if
    if temp then
      set the screenDownOn of gDir to 1
    else
      set the screenDownOn of gDir to 0
    end if
  end if
end

on virtualmouseUp theLoc
  global gDir, gMBStat
  if the mouseButtonActive of gDir then
    if gMBStat = 0 then
      exit
    end if
    set gMBStat to 0
    if objectp(gDir) then
      set temp to 0
      if voidp(theLoc) then
        set theLoc to point(the mouseH, the mouseV)
      end if
      repeat with index in the screenObjects of gDir
        if checkUp(index, theLoc) then
          set temp to 1
          exit repeat
        end if
      end repeat
    end if
    if temp then
      set the screenClicked of gDir to 1
    else
      set the screenClicked of gDir to 0
    end if
    set the clicked of gDir to 1
    mouseClick(gDir, temp)
  end if
end

on rightMouseDown
end

on rightMouseUp
  global gMBStat
  if gMBStat = 1 then
    virtualmouseUp()
  end if
end
