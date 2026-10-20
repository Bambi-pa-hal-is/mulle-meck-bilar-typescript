on exitFrame
  global gMulleGlobals
  put "the wherefrom ", the WhereFrom of gMulleGlobals
  set movieName to the WhereFrom of gMulleGlobals
  set the WhereFrom of gMulleGlobals to "UL"
  set pile to "j" & the myLastPile of the user of gMulleGlobals
  put "pile", pile
  go(pile, movieName)
end
