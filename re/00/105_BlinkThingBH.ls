property isPart, id, freq, isOn, waitFrames, doWhat, soundName, repeatSound, sndId, active, counter, SP
global gMulleGlobals, gSound, gDir

on beginSprite me
  if waitFrames = "sound" then
    set waitFrames to #sound
  else
    set waitFrames to value(waitFrames)
  end if
  if waitFrames = 0 then
    set waitFrames to 9999
  end if
  if length(soundName) then
    set sndId to play(gSound, soundName, #OPEFFECT)
  end if
  if id = "Auto" then
    set isPart to 1
    set id to getPartToGive(gDir)
  end if
  if isPart then
    set part to getPart(the parts of gMulleGlobals, id)
    set id to getJunkView(part)
  end if
  set isOn to 1
  set SP to the spriteNum of me
  set tempHeight to getAt(the rect of member(id), 4)
  if isPart then
    set the loc of sprite SP to the loc of sprite SP - point(0, tempHeight / 2)
  end if
  set the member of sprite SP to member(id)
  set counter to 0
  set active to 1
end

on exitFrame me
  if active then
    set counter to counter + 1
    if freq then
      if counter mod freq = 0 then
        if isOn then
          set isOn to 0
          set the member of sprite SP to member("dummy")
        else
          if repeatSound then
            set sndId to play(gSound, soundName, #OPEFFECT)
          end if
          set isOn to 1
          set the member of sprite SP to member(id)
        end if
      end if
    end if
    if waitFrames = #sound then
      if finished(gSound, sndId) then
        set the member of sprite SP to member("dummy")
        doTheWhat(me)
      end if
    else
      if counter = waitFrames then
        doTheWhat(me)
      end if
    end if
  end if
end

on doTheWhat me
  set active to 0
  if doWhat = #GoNextFrame then
    go(the frame + 1)
  else
    if doWhat = #GoNextMarker then
      go(#next)
    end if
  end if
end

on getPropertyDescriptionList me
  set p_list to [#isPart: [#comment: "Is it a part:", #format: #boolean, #default: 1], #id: [#comment: "PartId, 'Auto' or resource name:", #format: #string, #default: "Auto"], #freq: [#comment: "Frequency, frames per blink:", #format: #integer, #default: 2], #waitFrames: [#comment: "Wait nr of frames (or Sound):", #format: #string, #default: EMPTY], #doWhat: [#comment: "Then:", #format: #symbol, #range: [#none, #GoNextFrame, #GoNextMarker], #default: #none], #soundName: [#comment: "Play sound:", #format: #string, #default: EMPTY], #repeatSound: [#comment: "Repeat sound every blink:", #format: #boolean, #default: 0]]
  return p_list
end
