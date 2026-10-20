property myCursor
global gDir

on mouseEnter me
  cursorChange(gDir, the spriteNum of me, myCursor)
end

on mouseLeave me
  cursorChange(gDir, the spriteNum of me, #none)
end

on mouseDown me
  if myCursor = #OpenHand then
    cursorChange(gDir, the spriteNum of me, #ClosedHand)
  end if
end

on getPropertyDescriptionList me
  set p_list to [#myCursor: [#comment: "Cursor Change:", #format: #symbol, #range: [#OpenHand, #ClosedHand, #FingerHand, #GoLeft, #GoRight, #GoUp, #GoDown], #default: #FingerHand]]
  return p_list
end
