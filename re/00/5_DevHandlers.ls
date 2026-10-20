on ccc
  clearGlobals()
end

on props what
  global gMulleGlobals
  set prop to the carProperties of the car of the user of gMulleGlobals
  if what = 0 then
  else
  end if
end

on fff
  global gMulleGlobals
  sendSprite(8, #doFigge)
  set the figgeIsComing of the user of gMulleGlobals to 0
  set the figgeBeenHere of the junkPileHandlers of gMulleGlobals to 1
end

on rrr
  global gMulleGlobals
  loadMission(the missions of gMulleGlobals, 4)
  performMission(the missions of gMulleGlobals)
end

on mm
  sendSprite(13, #runMikro)
end

on Mail
end

on getFiggeList
  set X to [5, 13, 14, 17, 18, 19, 20, 21, 22, 24, 25, 26, 27, 28, 31, 32, 33, 35, 38, 41, 42, 43, 48, 53, 55, 64, 65, 69, 74, 75, 76, 89, 91, 92, 93, 96, 100, 101, 104, 107, 129, 130, 132, 134, 137, 140, 146, 149, 154, 155, 158, 161, 167, 168, 174, 175, 177, 181, 184, 185, 186, 189, 190, 191, 192, 193, 195, 196, 199, 200, 203, 208, 209, 211, 212, 213, 216, 219, 220, 221, 227, 228, 229, 230, 233, 234, 235, 236, 239, 242, 245, 248, 251, 257, 260, 261, 264, 265, 271, 272, 273, 278, 279, 280, 281, 282, 286, 288, 289, 290, 291, 294, 295, 296, 297]
  put count(X)
  set max to count(X)
  set y to []
  repeat while X <> []
    set value to random(count(X))
    add(y, getAt(X, value))
    deleteAt(X, value)
  end repeat
  put count(y)
  set fList to []
  set rList to []
  repeat with n = 1 to count(y)
    if getAt(y, n) mod 2 = 0 then
      add(fList, getAt(y, n))
      next repeat
    end if
    add(rList, getAt(y, n))
  end repeat
  addAt(fList, 2, 176)
  addAt(fList, 9, 173)
  put "fCount ", count(fList)
  put "fList", fList
  put "rList", rList
end
