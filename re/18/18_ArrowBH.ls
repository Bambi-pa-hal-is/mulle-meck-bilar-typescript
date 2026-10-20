property direction

on beginSprite me
  if direction = #right then
    set direction to 1
  else
    set direction to -1
  end if
end

on mouseUp
  sendSprite(1, #scroll, direction)
end

on getPropertyDescriptionList me
  set p to [#direction: [#comment: "Direction: ", #format: #symbol, #range: [#left, #right], #default: #left]]
  return p
end
