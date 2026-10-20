property SP, left, right, nrOfSigns, signSpace, nowH, SPSign, nrOfSignsAtATime, width, scrollOK, signList, clockOK

on beginSprite me
  set clockOK to 0
  set SP to the spriteNum of me
  set SPSign to SP + 1
  set left to the left of sprite SP
  set width to the width of sprite SP
  set right to left + width
  set signList to ["Jojoo", "Jojoo2", "Jojoo3", "Jojoo4", "Jojoo5", "Jojoo6", "Jojoo7", "Jojoo8", "Jojoo9", "Jojoo10"]
  set nrOfSigns to count(signList)
  set signSpace to 170
  set nowH to 0
  set nrOfSignsAtATime to 2 + width / signSpace
  if nrOfSigns < nrOfSignsAtATime - 1 then
    set tempMax to nrOfSigns
    set scrollOK to 0
  else
    if nrOfSigns = nrOfSignsAtATime - 1 then
      set tempMax to nrOfSignsAtATime - 1
    else
      set tempMax to nrOfSignsAtATime
    end if
    set scrollOK to 1
  end if
  repeat with n = 1 to tempMax
    set the member of sprite SPSign + n - 1 to member(getAt(signList, n))
    set the locV of sprite SPSign + n - 1 to the top of sprite SP + 90
  end repeat
  scroll(me, 0)
end

on exitFrame me
  if scrollOK then
    set mH to the mouseH
    if mH < left + 120 then
      set diff to mH - left
      if diff < 10 then
        scroll(me, -4)
      else
        if diff < 30 then
          scroll(me, -3)
        else
          if diff < 70 then
            scroll(me, -2)
          else
            scroll(me, -1)
          end if
        end if
      end if
    else
      if mH > right - 120 then
        set diff to right - mH
        if diff < 10 then
          scroll(me, 4)
        else
          if diff < 30 then
            scroll(me, 3)
          else
            if diff < 70 then
              scroll(me, 2)
            else
              scroll(me, 1)
            end if
          end if
        end if
      end if
    end if
  end if
end

on scroll me, rightLeft
  if clockOK then
    set nowH to (nowH + 5 * rightLeft) mod (nrOfSigns * signSpace)
    if nowH < 0 then
      set nowH to nrOfSigns * signSpace + nowH
    end if
  else
    set nowH to nowH + 5 * rightLeft
    if nowH < 0 then
      set nowH to 0
    else
      if nowH > (nrOfSigns - 1) * signSpace then
        set nowH to (nrOfSigns - 1) * signSpace
      end if
    end if
  end if
  set midSignNr to nowH / signSpace
  set leftSignNr to (nowH / signSpace - nrOfSignsAtATime / 2) mod nrOfSigns
  if leftSignNr < 0 then
    set leftSignNr to nrOfSigns + leftSignNr
  end if
  set offsetH to midSignNr * signSpace - nowH
  repeat with n = 1 to nrOfSignsAtATime
    set tempSP to n + SPSign - 1
    set tempSign to (leftSignNr + n) mod nrOfSigns + 1
    if clockOK then
      set the member of sprite tempSP to member(getAt(signList, tempSign))
    else
      if abs(tempSign - (midSignNr + 1)) < nrOfSigns - 2 then
        set the member of sprite tempSP to member(getAt(signList, tempSign))
      else
        set the member of sprite tempSP to member("Dummy")
      end if
    end if
    set the locH of sprite tempSP to offsetH + (n - 1) * signSpace
  end repeat
end
