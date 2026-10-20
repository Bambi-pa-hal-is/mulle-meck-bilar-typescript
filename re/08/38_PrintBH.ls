global gDir, gMulleGlobals, gSound

on mouseUp me
  play(gSound, "SndMouseClick", #EFFECT)
  print(me)
end

on print me
  openXtra(gPathGlobals, #PrintOMatic)
  set doc to new(xtra("PrintOMatic"))
  if not objectp(doc) then
    unloadMember()
    set doc to new(xtra("PrintOMatic"))
    if not objectp(doc) then
      alert("Unable to contact printer", the freeBlock)
      exit
    end if
  end if
  sendSprite(getProp(the spriteList of gDir, #Scroller), #ScrollToMid)
  updateStage()
  setMargins(doc, rect(20, 20, 20, 20))
  newPage(doc)
  set w to getPageWidth(doc)
  set h to getPageHeight(doc)
  set carTop to 272
  set carLeft to 50
  set carWidth to 490
  set carHeight to 530
  drawStagePicture(doc, rect(carLeft, carTop, carLeft + carWidth, carTop + carHeight), the rect of sprite getProp(the spriteList of gDir, #ToBeCaptured))
  append(doc, member("Title"), 0)
  set tempTop to 160
  set tempLeft to 130
  set tempOffset to getAt(charPosToLoc(member("UserName"), 1), 1)
  newFrame(doc, rect(tempLeft + tempOffset, tempTop, tempLeft + 400, tempTop + 50), 0)
  append(doc, member("UserName"), 0)
  set tempTop to tempTop + 40
  set tempOffset to getAt(charPosToLoc(member("08t007v0"), 1), 1)
  newFrame(doc, rect(tempLeft + tempOffset, tempTop, tempLeft + 400, tempTop + 50), 0)
  append(doc, member("08t007v0"), 0)
  set tempTop to tempTop + 20
  set tempOffset to getAt(charPosToLoc(member("SavedCarName"), 1), 1)
  newFrame(doc, rect(tempLeft + tempOffset, tempTop, tempLeft + 400, tempTop + 50), 0)
  append(doc, member("SavedCarName"), 0)
  set signHeight to 55
  set left to 0
  set right to w - 1
  set tempCorrect to 25
  set bottom to h - signHeight + 40 - tempCorrect
  newFrame(doc, rect(195, h - signHeight - tempCorrect, w - 100, h - tempCorrect), 0)
  append(doc, member("08b005v0"), 0)
  drawLine(doc, point(left, 0), point(left, bottom))
  drawLine(doc, point(right, 0), point(right, bottom))
  drawLine(doc, point(left, bottom), point(left + 185, bottom))
  drawLine(doc, point(left + 365, bottom), point(right, bottom))
  set medalSpace to 80
  set medalLeft to 50
  set medalTop to 620
  set tempList to ["00n004v0", "00n005v0", "00n006v0", "00n007v0", "00n010v0", "00n009v0"]
  set tempText to ["08t001v0", "08t002v0", "08t003v0", "08t004v0", "08t005v0", "08t006v0"]
  repeat with n = 1 to 6
    if getMedal(the car of the user of gMulleGlobals, n) then
      newFrame(doc, rect(medalLeft + medalSpace * (n - 1), medalTop, medalLeft + medalSpace * (n - 1) + medalSpace, medalTop + 80), 0)
      append(doc, member(getAt(tempList, n)))
      newFrame(doc, rect(medalLeft + medalSpace * (n - 1) - 10, medalTop + 60, medalLeft + medalSpace * (n - 1) + medalSpace - 10, medalTop + 80 + 60), 0)
      append(doc, member(getAt(tempText, n)))
    end if
  end repeat
  cursor(-1)
  cursor(200)
  print(doc)
  set doc to 0
  cursor(200)
end
