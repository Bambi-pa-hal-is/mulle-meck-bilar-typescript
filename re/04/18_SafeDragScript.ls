property screenObject, reportObject
global gDir

on new me, theReportObject
  set reportObject to theReportObject
  set screenObject to new(script("ScreenObject"), me, rect(-1000, -1000, 2000, 2000), #ClosedHand)
  addScreenObject(gDir, screenObject, 1)
  checkDown(screenObject, point(320, 240))
  return me
end

on report me, theObject, what
  if what = #clicked then
    report(reportObject, me, #clicked)
  end if
end

on activate me, YesNo
  set the active of screenObject to YesNo
  if YesNo then
    checkDown(screenObject, point(320, 240))
  end if
end

on kill me
  deleteScreenObject(gDir, screenObject)
  return 0
end
