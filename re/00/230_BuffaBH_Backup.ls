property mode, leftBorder, rightBorder, SP, BuffaFreezed

on beginSprite me
  set mode to #Wait
  set leftBorder to 150 + 200
  set rightBorder to 350 + 200
  set SP to the spriteNum of me
  sendSprite(SP, #setAnimNormal)
  set BuffaFreezed to 0
end

on exitFrame me
  case mode of
    #Wait:
      if random(10) = 1 then
        randomMove(me, 4)
      end if
  end case
end

on changePile me, whichWay
  if not BuffaFreezed then
    if whichWay = -1 then
      sendSprite(SP, #setAnimLoc, point(640 - 140, -4711), 0)
      set mode to #WalkLeftStart
      sendSprite(SP, #setAnimAction, mode)
    else
      if whichWay = 1 then
        sendSprite(SP, #setAnimLoc, point(140, -4711), 0)
        set mode to #WalkRightStart
        sendSprite(SP, #setAnimAction, mode)
      end if
    end if
  end if
end

on randomMove me, maxRnd
  repeat while 1
    set tempMode to 0
    case random(maxRnd) of
      1:
        if the locH of sprite SP < rightBorder then
          set tempMode to #WalkRightStart
        end if
      2:
        if the locH of sprite SP > leftBorder then
          set tempMode to #WalkLeftStart
          sendSprite(SP, #setAnimLoc, point(-330, 0), 1)
        end if
      3:
        set tempMode to #Talk
      4:
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
    randomMove(me, 3)
  else
    if mode = #Sleep then
      set mode to #GetUp
      sendSprite(SP, #setAnimAction, mode)
    end if
  end if
end

on Stopped me
  case mode of
    #WalkRightStart:
      set tempMode to #WalkRight
    #WalkRight:
      if random(2) > 1 then
        set tempMode to #WalkRightStop
      else
        if the locH of sprite SP < rightBorder then
          sendSprite(SP, #setAnimLoc, point(80, 0), 1)
          set tempMode to #WalkRight
        else
          set tempMode to #WalkRightStop
        end if
      end if
    #WalkRightStop:
      sendSprite(SP, #setAnimLoc, point(200, 0), 1)
      set tempMode to #Wait
    #WalkLeftStart:
      set tempMode to #WalkLeft
    #WalkLeft:
      if random(2) > 1 then
        set tempMode to #WalkLeftStop
      else
        if the locH of sprite SP > leftBorder then
          sendSprite(SP, #setAnimLoc, point(-80, 0), 1)
          set tempMode to #WalkLeft
        else
          set tempMode to #WalkLeftStop
        end if
      end if
    #WalkLeftStop:
      set tempMode to #Wait
      sendSprite(SP, #setAnimLoc, point(140, 0), 1)
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
