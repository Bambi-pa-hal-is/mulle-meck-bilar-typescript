property name, prio, sndId, WaitForSound
global gSound

on beginSprite me
  set sndId to play(gSound, name, prio)
end

on exitFrame me
  if not (WaitForSound = #none) then
    if finished(gSound, sndId) then
      case WaitForSound of
        #GoNextFrame:
          go(the frame + 1)
        #GoNextMarker:
          go(the marker + 1)
      end case
    end if
  end if
end

on getPropertyDescriptionList me
  set p_list to [#name: [#comment: "Enter member name:", #format: #string, #default: EMPTY], #prio: [#comment: "Priority:", #format: #symbol, #range: [#EFFECT, #BG, #OPEFFECT], #default: #EFFECT], #WaitForSound: [#comment: "Wait for sound to finish, do:", #format: #symbol, #range: [#none, #GoNextFrame, #GoNextMarker], #default: #none]]
  return p_list
end
