property mode, leftBorder, rightBorder, activeClick, okToGoLeft
global gDir

on beginSprite me
  set mode to #Wait
  set leftBorder to 150 + 165
  set rightBorder to 150 + 195
  set okToGoLeft to 0
end

on activate me, theState
  set activeClick to theState
end

on exitFrame me
  global gMulleGlobals
  if the loadIndicator of gMulleGlobals = 0 then
    if activeClick then
      if mode = #Wait then
        if random(100) = 1 then
          randomMove(me, 3)
        end if
      end if
    end if
  else
    if the carOnYard of gDir = 0 then
      if mode <> #Sleep and mode <> #GetDown then
        set tempMode to #GetDown
        set mode to tempMode
        sendSprite(the spriteNum of me, #setAnimAction, mode)
      end if
    end if
  end if
end

on changePile me, whichWay
  if whichWay = -1 then
    sendSprite(the spriteNum of me, #SetLoc, point(640 - 140, -4711), 0)
    set mode to #WalkLeftStart
    sendSprite(the spriteNum of me, #setAnimAction, mode)
  else
    if whichWay = 1 then
      sendSprite(the spriteNum of me, #setAnimLoc, point(140, -4711), 0)
      set mode to #WalkRightStart
      sendSprite(the spriteNum of me, #setAnimAction, mode)
    end if
  end if
end

on randomMove me, maxRnd
  repeat while 1
    set tempMode to 0
    case random(maxRnd) of
      1:
        if okToGoLeft = 0 then
          set tempMode to #WalkRightStart
        end if
      2:
        if okToGoLeft = 1 then
          set tempMode to #WalkLeftStart
          sendSprite(the spriteNum of me, #setAnimLoc, point(-330, 0), 1)
        end if
      3:
        set tempMode to #GetDown
    end case
    if symbolp(tempMode) then
      set mode to tempMode
      exit repeat
    end if
  end repeat
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end

on mouseUp me
  if mode = #Wait then
    randomMove(me, 3)
  else
    if mode = #Sleep then
      set mode to #GetUp
      sendSprite(the spriteNum of me, #setAnimAction, mode)
    end if
  end if
end

on Stopped me
  case mode of
    #WalkRightStart:
      set tempMode to #WalkRight
    #WalkRight:
      set tempMode to #WalkRightStop
    #WalkRightStop:
      set okToGoLeft to 1
      sendSprite(the spriteNum of me, #setAnimLoc, point(200, 0), 1)
      set tempMode to #Wait
    #WalkLeftStart:
      set tempMode to #WalkLeft
    #WalkLeft:
      set tempMode to #WalkLeftStop
    #WalkLeftStop:
      set okToGoLeft to 0
      set tempMode to #Wait
      sendSprite(the spriteNum of me, #setAnimLoc, point(140, 0), 1)
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
  sendSprite(the spriteNum of me, #setAnimAction, mode)
end
