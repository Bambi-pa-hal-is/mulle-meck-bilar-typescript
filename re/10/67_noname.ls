on resultsFromScroller type, theStr
  global gMulleGlobals, gDir
  if type = #EnteredSomething then
    makeOKToContinue(gDir)
  else
    if type = #ChoseLine then
      put "Login:", theStr
      login(the users of gMulleGlobals, theStr)
      go("IntroStart")
      makeOKToEnd(gDir)
    else
      if type = #NewLine then
        put "Entered a new name:", theStr
        login(the users of gMulleGlobals, theStr)
        go("IntroStart")
        makeOKToEnd(gDir)
      else
        if type = #DeletedLine then
          put "Deleted a name:", theStr
          deleteUser(the users of gMulleGlobals, theStr)
        end if
      end if
    end if
  end if
end
