property rects, over, downOn, reportObject, mouseOver, active, regLoc, closeHand
global gDir

on new me, theReportObject, theRects, theMouseOver, theRegLoc
  set active to 1
  set rects to theRects
  set reportObject to theReportObject
  set mouseOver to theMouseOver
  set closeHand to 0
  set downOn to 0
  if stringp(mouseOver) then
    if theMouseOver = #OpenHand then
      set closeHand to 1
    end if
  end if
  if voidp(theRegLoc) then
  else
    set regLoc to theRegLoc
  end if
  return me
end

on checkDown me, thePoint
  if active then
    if inside(thePoint, rects) then
      set downOn to 1
      report(reportObject, me, #downOn)
      screenPriority(gDir, me, 1)
      return 1
    end if
  end if
  return 0
end

on checkUp me, thePoint
  if active then
    if downOn then
      screenPriority(gDir, me, 0)
      report(reportObject, me, #stillDown)
      if inside(thePoint, rects) then
        set downOn to 0
        report(reportObject, me, #clicked)
        return 1
      else
        report(reportObject, me, #UpOutside)
      end if
    end if
    set downOn to 0
  end if
  return 0
end

on checkBetween me, thePoint, mouseChange
  if active then
    if downOn then
      report(reportObject, me, #stillDown)
    end if
    set oldOver to over
    set over to 0
    if inside(thePoint, rects) then
      set over to 1
      if not oldOver then
        report(reportObject, me, #over)
      end if
      if not (mouseOver = #normal) and mouseChange then
        if downOn then
          if closeHand then
            cursorChange(gDir, 120, #ClosedHand)
          else
            cursorChange(gDir, 120, mouseOver)
          end if
        else
          cursorChange(gDir, 120, mouseOver)
        end if
        return 1
      end if
    end if
    if not over and oldOver then
      report(reportObject, me, #NotOver)
    end if
  end if
  return 0
end

on moveRegLoc me, newLoc
  set diffH to getAt(newLoc, 1) - getAt(regLoc, 1)
  set diffV to getAt(newLoc, 2) - getAt(regLoc, 2)
  set rects to offset(rects, diffH, diffV)
  set regLoc to newLoc
end

on kill me
  return 0
end
