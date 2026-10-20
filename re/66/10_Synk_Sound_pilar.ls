property pTimerTime, p_list

on exitFrame me
  sinkronisering(me)
end

on sinkronisering me
  if the timer > pTimerTime then
    go(the frame + 1)
  else
    go(the frame)
  end if
end

on getPropertyDescriptionList
  set p_list to [#pTimerTime: [#comment: "The timerTime:", #format: #integer, #default: 0]]
  return p_list
end
