property whichCustomCursor, active, dragCheck
global gDir

on beginSprite me
  set active to 1
  set dragCheck to 0
end

on activate me, theState
  set active to theState
end

on activateClick me, theState
  set active to theState
end

on mouseEnter me
  set movieNr to char 1 to 2 of the movie
  if movieNr = "02" or movieNr = "03" then
    set dragCheck to the dragging of sprite(getaProp(the spriteList of gDir, #drag))
  else
    set dragCheck to 0
  end if
  if active then
    if not the mouseDown then
      case whichCustomCursor of
        #left:
          sendSprite(115, #c_Left)
        #right:
          sendSprite(115, #C_Right)
        #click:
          sendSprite(115, #c_click)
        #Grab:
          sendSprite(115, #c_grab)
        #Back:
          sendSprite(115, #C_Back)
        #Standard:
          sendSprite(115, #C_Standard)
      end case
    else
      case whichCustomCursor of
        #left:
          if dragCheck then
            sendSprite(115, #c_MoveLeft)
          else
            sendSprite(115, #c_Left)
          end if
        #right:
          if dragCheck then
            sendSprite(115, #c_MoveRight)
          else
            sendSprite(115, #C_Right)
          end if
        #click:
          if dragCheck then
            sendSprite(115, #c_MoveIn)
          else
            sendSprite(115, #c_click)
          end if
        #Grab:
          sendSprite(115, #c_grab)
        #Back:
          sendSprite(115, #C_Back)
        #Standard:
          sendSprite(115, #C_Standard)
      end case
    end if
  end if
end

on mouseLeave me
  if the mouseDown then
    set movieNr to char 1 to 2 of the movie
    if movieNr = "02" or movieNr = "03" or movieNr = "04" then
      set dragCheck to the dragging of sprite(getaProp(the spriteList of gDir, #drag))
      if dragCheck then
        sendSprite(115, #c_grab)
      else
        sendSprite(115, #C_Standard)
      end if
    end if
  else
    sendSprite(115, #C_Standard)
  end if
end

on getPropertyDescriptionList
  set p_list to [#whichCustomCursor: [#comment: "Command:", #format: #symbol, #range: [#left, #right, #Grab, #click, #Back, #Standard], #default: #Standard]]
  return p_list
end
