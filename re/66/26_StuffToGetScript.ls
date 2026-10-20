global gDir

on getItem me
  if top(the stack1 of gDir) <> the can1 of gDir then
    puppetSound("P36ef008")
  else
    set the loc of sprite the can1 of gDir to point(99, 457)
    updateStage()
    go(#next)
    abort()
  end if
end
