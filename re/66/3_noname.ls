global gDir

on drag can, myLoc
  if not the active of sprite(can) then
    return 
  end if
  set the dragLoc of gDir to the loc of sprite can
  set the dragging of gDir to can
  puppetSound("P36ef004")
end

on drop can
  if not (the dragging of gDir = can) then
    return 
  end if
  set the dragging of gDir to 0
  set tmpH to the locH of sprite can
  if tmpH > 100 and tmpH < 300 and top(the stack1 of gDir) < can then
    if isEmpty(the stack1 of gDir) then
      puppetSound("P09ef004")
    else
      puppetSound("P09ef005")
    end if
    push(the stack1 of gDir, can, gDir)
    if top(the stack2 of gDir) = can then
      Pop(the stack2 of gDir, gDir)
    else
      if top(the stack3 of gDir) = can then
        Pop(the stack3 of gDir, gDir)
      end if
    end if
  else
    if tmpH > 300 and tmpH < 380 and top(the stack2 of gDir) < can then
      if isEmpty(the stack2 of gDir) then
        puppetSound("P09ef004")
      else
        puppetSound("P09ef005")
      end if
      push(the stack2 of gDir, can, gDir)
      if top(the stack1 of gDir) = can then
        Pop(the stack1 of gDir, gDir)
      end if
      if top(the stack3 of gDir) = can then
        Pop(the stack3 of gDir, gDir)
      end if
      if not the pGotPart of gDir and can = the can2 of gDir then
        go("NoGive")
        abort()
      end if
    else
      if tmpH > 380 and tmpH < 620 and top(the stack3 of gDir) < can then
        if isEmpty(the stack3 of gDir) then
          puppetSound("P09ef004")
        else
          puppetSound("P09ef005")
        end if
        push(the stack3 of gDir, can, gDir)
        if top(the stack1 of gDir) = can then
          Pop(the stack1 of gDir, gDir)
        end if
        if top(the stack2 of gDir) = can then
          Pop(the stack2 of gDir, gDir)
        end if
        if not the pGotPart of gDir and can = the can2 of gDir then
          go("NoGive")
          abort()
        end if
      else
        set the loc of sprite can to the dragLoc of gDir
        puppetSound("P09ef001")
      end if
    end if
  end if
end
