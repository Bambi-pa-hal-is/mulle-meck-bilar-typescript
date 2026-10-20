property unit, waitNr, doWhat, counter

on beginSprite me
  if unit = #Seconds then
    set waitNr to waitNr * the frameTempo
  end if
  set counter to 0
end

on exitFrame me
  set counter to counter + 1
  if counter >= waitNr then
    case doWhat of
      #GoNextFrame:
        go(the frame + 1)
      #GoNextMarker:
        go(the marker + 1)
    end case
  end if
end

on getPropertyDescriptionList me
  set p_list to [#unit: [#comment: "Wait unit:", #format: #symbol, #range: [#Seconds, #Frames], #default: #Seconds], #waitNr: [#comment: "Wait nr:", #format: #integer, #default: 1], #doWhat: [#comment: "Do what:", #format: #symbol, #range: [#GoNextFrame, #GoNextMarker], #default: #GoNextFrame]]
  return p_list
end
