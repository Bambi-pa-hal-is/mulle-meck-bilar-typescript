property direction
global gDir, gSound

on beginSprite me
  if direction = #up then
    set direction to -1
  else
    set direction to 1
  end if
end

on mouseUp me
  sendSprite(getProp(the spriteList of gDir, #Scroller), #scroll, direction)
end

on getPropertyDescriptionList me
  set p to [#direction: [#comment: "Direction: ", #format: #symbol, #range: [#up, #down], #default: #up]]
  return p
end
