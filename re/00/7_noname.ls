on prepareMovie
  global gPathGlobals, gMulleGlobals, gDir, gSound
  if not objectp(gPathGlobals) then
    set gPathGlobals to new(script("PathGlobals"))
  end if
  if not objectp(gMulleGlobals) then
    set gMulleGlobals to new(script("MulleGlobals"))
    if not (char 1 to 2 of the movieName = "10") then
      login(the users of gMulleGlobals, "Jesper")
    end if
  end if
  if not objectp(gSound) then
    set gSound to new(script("Sound"))
  end if
  if the number of member "Dir" > -1 then
    set gDir to new(script("Dir"))
    init(gDir)
  end if
  set the loc of sprite 115 to point(-20, -20)
  if the CustomCursorActive of gMulleGlobals then
    cursor(200)
  else
    sendSprite(115, #C_Standard)
  end if
  set tempMovie to char 1 to 2 of the movieName
  if not (tempMovie = "12" or tempMovie = "13" or tempMovie = "18" or tempMovie = "10" or tempMovie = "08") then
    set fromMovie to chars(the WhereFrom of gMulleGlobals, 1, 2)
    if fromMovie = "00" then
      set the member of sprite 119 to "dummy"
      set the member of sprite 118 to "dummy"
    else
      if fromMovie = "02" then
        if char 1 to 2 of the movie = "03" then
          set the member of sprite 119 to "00b013v0"
        end if
      else
        if fromMovie = "03" then
          if char 1 to 2 of the movie = "04" then
            if the toYardThroughDoor of the user of gMulleGlobals = 0 then
              set the member of sprite 119 to "00b009v0"
            else
              set the member of sprite 119 to "00b010v0"
            end if
          end if
          if char 1 to 2 of the movie = "02" then
          end if
        else
          if fromMovie = "04" then
            if char 1 to 2 of the movie = "03" then
              if the toYardThroughDoor of the user of gMulleGlobals = 0 then
                if the WhereFrom of gMulleGlobals = "04_car" then
                  set the member of sprite 119 to "00b015v0"
                else
                  if the WhereFrom of gMulleGlobals = "04_nocar" then
                    set the member of sprite 119 to "00b016v0"
                  end if
                end if
              else
                set the member of sprite 119 to "00b011v0"
              end if
            end if
          else
            if fromMovie = "05" then
              set the member of sprite 119 to "00b008v0"
            else
              if fromMovie = "06" then
                set the member of sprite 119 to "00b020v0"
              else
                if fromMovie = "08" then
                  set the member of sprite 119 to "00b022v0"
                else
                  if fromMovie = "10" then
                    set the member of sprite 119 to "03b007v0"
                  else
                    if fromMovie = "UL" then
                      set the member of sprite 119 to "02b024v0"
                    else
                      if fromMovie = "UR" then
                        set the member of sprite 119 to "02b023v0"
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end if
  end if
end

on stopMovie
  global gDir
  if objectp(gDir) then
    set gDir to kill(gDir)
  end if
  unloadMember()
end

on killall
  global gPathGlobals, gMulleGlobals, gSound
  if objectp(gPathGlobals) then
    set gPathGlobals to kill(gPathGlobals)
  end if
  if objectp(gMulleGlobals) then
    set gMulleGlobals to kill(gMulleGlobals)
  end if
  if objectp(gSound) then
    set gSound to kill(gSound)
  end if
  cursor(-1)
end
