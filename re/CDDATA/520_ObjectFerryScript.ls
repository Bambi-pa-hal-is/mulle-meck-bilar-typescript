property child, counter, Back, insideInner, waitCounter, carOnBoard, step, carLeaving, carCounter, endLocs, maxCounter, decimalPrec, endLoc, nrOfDirections, carOrgLoc, carStep, atStart, myDirections, myLoc, active, carWasntOnBoard, sndId
global gDir, gSound

on new me, theChild
  set child to theChild
  set insideInner to 0
  set carOnBoard to 0
  set carCounter to 0
  set carLeaving to 0
  set waitCounter to 0
  set decimalPrec to 100
  set nrOfDirections to 16
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  global gMulleGlobals
  set sndId to 0
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set Back to -1
  set the member of sprite the SPUnder of child to member(getAt(FrameList, 1))
  set tempEndLoc to getaProp(the optionalData of child, #endLoc)
  if voidp(tempEndLoc) then
    set tempEndLoc to point(0, 0)
  end if
  set endLocs to [the myLoc of child, tempEndLoc]
  set myDirections to [calcDirection(the drivingHandlers of gDir, getAt(endLocs, 1), getAt(endLocs, 2)), calcDirection(the drivingHandlers of gDir, getAt(endLocs, 2), getAt(endLocs, 1))]
  set myLoc to the myLoc of child * decimalPrec
  set tempSpeed to 5
  set diff to getAt(endLocs, 2) - getAt(endLocs, 1)
  set hypo to sqrt(getAt(diff, 1) * getAt(diff, 1) + getAt(diff, 2) * getAt(diff, 2))
  set fact to hypo / float(tempSpeed)
  set step to point(integer(decimalPrec * getAt(diff, 1) / fact), integer(decimalPrec * getAt(diff, 2) / fact))
  set maxCounter to integer(fact)
  set counter to random(maxCounter - 2) + 1
  set Back to integer(random(2) * 1.5 - 2)
  set myLoc to myLoc + counter * step
  set the loc of sprite the SPUnder of child to myLoc / decimalPrec
  if Back = 1 then
    set atStart to -1
    set endLoc to getAt(endLocs, 2)
  else
    set atStart to 1
    set endLoc to getAt(endLocs, 1)
  end if
  set tempProp to getAt(getCheckFor(child, #UserStuff), 1)
  if getUserProp(the user of gMulleGlobals, tempProp) = #NoProp then
    set active to 0
  else
    set active to 1
  end if
  set carWasntOnBoard to 1
end

on step me, carLoc
  if counter > maxCounter then
    set counter to maxCounter
    set waitCounter to 15
    set Back to -1
    if carOnBoard then
      carBoardInit(me, 1)
    else
      if carClose(me, carLoc) then
        carBoardInit(me, -1)
      end if
    end if
  else
    if counter < 0 then
      set counter to 0
      set waitCounter to 15
      set Back to 1
      if carOnBoard then
        carBoardInit(me, 1)
      else
        if carClose(me, carLoc) then
          carBoardInit(me, -1)
        end if
      end if
    else
      if counter = maxCounter / 2 then
        if Back = 1 then
          set endLoc to getAt(endLocs, 2)
          set atStart to -1
        else
          set endLoc to getAt(endLocs, 1)
          set atStart to 1
        end if
      end if
    end if
  end if
  if waitCounter then
    set waitCounter to waitCounter - 1
    if carOnBoard then
      carBoarding(me)
    else
      if carWasntOnBoard then
        if carClose(me, carLoc) then
          carBoardInit(me, -1)
          set waitCounter to 15
        end if
      end if
    end if
    if waitCounter = 0 and not carOnBoard then
      set carWasntOnBoard to 1
    end if
  else
    set counter to counter + Back
    set myLoc to myLoc + step * Back
    set the loc of sprite the SPUnder of child to myLoc / decimalPrec
    if carOnBoard then
      setCoordinate(the carDriving of gDir, myLoc / decimalPrec)
    end if
  end if
end

on carClose me, carLoc
  if active then
    set tempDiff to carLoc - myLoc / decimalPrec
    set tempH to getAt(tempDiff, 1)
    set tempV to getAt(tempDiff, 2)
    set hypo to sqrt(tempH * tempH + tempV * tempV)
    if hypo < the InnerRadius of child then
      return 1
    end if
  else
    if finished(gSound, sndId) then
      set tempDiff to carLoc - myLoc / decimalPrec
      set tempH to getAt(tempDiff, 1)
      set tempV to getAt(tempDiff, 2)
      set hypo to sqrt(tempH * tempH + tempV * tempV)
      if hypo < the InnerRadius of child then
        set sndId to play(gSound, getAt(the sounds of child, 1), #EFFECT)
      end if
    end if
  end if
  return 0
end

on carBoardInit me, theLeave
  if active then
    set carLeaving to theLeave
    set carOrgLoc to getCoordinate(the carDriving of gDir)
    if carLeaving = -1 then
      set carWasntOnBoard to 0
      set carOnBoard to 1
      setDirection(the carDriving of gDir, calcDirection(the drivingHandlers of gDir, carOrgLoc, endLoc))
      set carStep to (endLoc - carOrgLoc) * decimalPrec / 10
    else
      set carStep to -step / 2 * atStart
    end if
  end if
end

on carBoarding me
  if carLeaving then
    set carCounter to carCounter + 1
    setCoordinate(the carDriving of gDir, carOrgLoc + carStep * carCounter / decimalPrec)
    if carCounter > 10 then
      if carLeaving = 1 then
        stop(gSound, sndId)
        programControl(the carDriving of gDir, 0)
        set carOnBoard to 0
      else
        play(gSound, getAt(the sounds of child, 2), #EFFECT)
        set sndId to play(gSound, getAt(the sounds of child, 3), #EFFECT)
        programControl(the carDriving of gDir, 1, #NoCheck)
        setDirection(the carDriving of gDir, getAt(myDirections, integer((-atStart + 2) / 1.5)))
      end if
      set carCounter to 0
      set carLeaving to 0
    end if
  end if
end

on enterOuterRadius me
end

on ExitOuterRadius me
end

on EnterInnerRadius me
end

on ExitInnerRadius me
end
