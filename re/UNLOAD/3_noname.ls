on exitFrame
  global gMulleGlobals
  set movieName to the WhereFrom of gMulleGlobals
  set the WhereFrom of gMulleGlobals to "UR"
  set pile to "j" & the myLastPile of the user of gMulleGlobals
  put "pile", pile
  go(pile, movieName)
end
