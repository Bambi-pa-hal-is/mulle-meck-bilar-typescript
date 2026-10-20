property mode, leftBorder, rightBorder, SP

on beginSprite me
  set mode to #Wait
  set leftBorder to 150 + 200
  set rightBorder to 350 + 200
  set SP to the spriteNum of me
  sendSprite(SP, #setAnimNormal)
end

on exitFrame me
  case mode of
    #Wait:
      if random(100) = 1 then
        randomMove(me, 1)
      end if
  end case
end

on randomMove me, maxRnd
  repeat while 1
    set tempMode to 0
    case random(maxRnd) of
      1:
        set tempMode to #GetDown
    end case
    if symbolp(tempMode) then
      set mode to tempMode
      exit repeat
    end if
  end repeat
  sendSprite(SP, #setAnimAction, mode)
end

on mouseUp me
  if mode = #Wait then
    randomMove(me, 1)
  else
    if mode = #Sleep then
      set mode to #GetUp
      sendSprite(SP, #setAnimAction, mode)
    end if
  end if
end

on Stopped me
  case mode of
    #GetDown:
      set tempMode to #Sleep
    #Sleep:
      if random(30) = 1 then
        set tempMode to #GetUp
      else
        set tempMode to #Sleep
      end if
    otherwise:
      set tempMode to #Wait
  end case
  set mode to tempMode
  sendSprite(SP, #setAnimAction, mode)
end
