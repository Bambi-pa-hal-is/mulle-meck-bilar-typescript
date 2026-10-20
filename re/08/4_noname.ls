global gDir

on exitFrame me
  set the returnTo of gDir to the frameLabel
  go(1)
end
