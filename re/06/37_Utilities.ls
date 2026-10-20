on changeChars theChar, toWhat, theString
  set assembleString to EMPTY
  if toWhat = EMPTY then
    repeat while 1
      set tempOff to offset(theChar, theString)
      if tempOff then
        set assembleString to assembleString & char 1 to tempOff of theString
        delete char -30000 of assembleString
        delete char 1 to tempOff of theString
        next repeat
      end if
      set assembleString to assembleString & theString
      exit repeat
    end repeat
  else
    set realNum to charToNum(theChar)
    repeat while 1
      set tempOff to offset(theChar, theString)
      if tempOff then
        set assembleString to assembleString & char 1 to tempOff of theString
        if charToNum(char tempOff of theString) = realNum then
          put toWhat into char length(assembleString) of assembleString
        end if
        delete char 1 to tempOff of theString
        next repeat
      end if
      set assembleString to assembleString & theString
      exit repeat
    end repeat
  end if
  return assembleString
end

on changeToLowerCase theStr
  set tempLen to length(theStr)
  repeat with n = 1 to tempLen
    set tempNum to charToNum(char n of theStr)
    if tempNum >= 65 and tempNum <= 90 then
      put numToChar(tempNum + 32) into char n of theStr
    end if
  end repeat
  return theStr
end

on findStrings theStr
  set temp to []
  set foundFirst to 0
  repeat with z = 1 to length(theStr)
    if char z of theStr = QUOTE then
      if not foundFirst then
        set foundFirst to z
        next repeat
      end if
      set aStr to char foundFirst to z of theStr
      set foundFirst to 0
      delete char 1 of aStr
      delete char -30000 of aStr
      add(temp, aStr)
    end if
  end repeat
  return temp
end

on correctFileName theName
  if the machineType = 256 then
    set theName to changeChars(" ", EMPTY, theName)
    set theName to changeChars("\", EMPTY, theName)
    set theName to changeChars("*", EMPTY, theName)
    set theName to changeChars(":", EMPTY, theName)
    set theName to changeChars("?", EMPTY, theName)
    set theName to changeChars(".", EMPTY, theName)
    set theName to changeChars(QUOTE, EMPTY, theName)
  else
    set theName to changeChars(":", EMPTY, theName)
    set theName to changeChars(".", EMPTY, theName)
    set theName to changeChars(QUOTE, EMPTY, theName)
  end if
  return theName
end
