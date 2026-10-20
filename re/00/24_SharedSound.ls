global gMulleGlobals, gSound

on new me
  return me
end

on kill me
  return 0
end

on kickPartSound me, theSP, theid, what
  if the partProperties of getPart(the parts of gMulleGlobals, theid) = 0 then
    set idToCheck to getAt(getMorphList(getPart(the parts of gMulleGlobals, theid)), 1)
  else
    set idToCheck to theid
  end if
  set Weight to getProperty(getPart(the parts of gMulleGlobals, idToCheck), #Weight)
  if what = #InternalGround then
    case Weight of
      1:
        play(gSound, "00e001v0", #OPEFFECT)
      2, 3:
        play(gSound, "00e002v0", #OPEFFECT)
      4, 5:
        play(gSound, "00e003v0", #OPEFFECT)
    end case
  else
    if what = #ExternalGround then
      case Weight of
        1:
          play(gSound, "00e004v0", #OPEFFECT)
        2, 3:
          play(gSound, "00e005v0", #OPEFFECT)
        4, 5:
          play(gSound, "00e006v0", #OPEFFECT)
      end case
    else
      if what = #car then
        case Weight of
          1:
            play(gSound, "03e003v0", #OPEFFECT)
          2, 3:
            play(gSound, "03e003v1", #OPEFFECT)
          4, 5:
            play(gSound, "03e003v2", #OPEFFECT)
        end case
      end if
    end if
  end if
end
