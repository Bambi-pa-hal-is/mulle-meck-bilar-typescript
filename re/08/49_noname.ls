on changeRect val, startMemb, endMemb
  repeat with n = startMemb to endMemb
    set tempRect to the rect of member(n)
    set the rect of member(n) to rect(0, 0, val, getAt(tempRect, 4))
    set the textFont of member n to "Times"
    set the textSize of member n to 16
  end repeat
end
