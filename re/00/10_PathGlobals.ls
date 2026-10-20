property savePath, pluginPath, CDPath, folderDelimit, HDPath, helpFile, xtrasPath, carPath, translateLetters, xtraFileList

on new me
  global gCDPath, gHDPath, gHelpFile
  if the machineType = 256 then
    set folderDelimit to "\"
  else
    set folderDelimit to ":"
  end if
  set translateLetters to value(the text of member("00t001v0"))
  if voidp(gCDPath) then
    set CDPath to the moviePath
    set HDPath to the moviePath
    set tempOff to offset(folderDelimit, HDPath)
    set rootPath to char 1 to tempOff of HDPath
    if the machineType = 256 then
      set pluginPath to rootPath & "Levande" & folderDelimit & "MulleBil" & folderDelimit & "Plugins" & folderDelimit
      set helpFile to CDPath & "MulleBil.hlp"
    else
      set pluginPath to rootPath & "Levande" & folderDelimit & "Mulle Meck bygger bil" & folderDelimit & "Plugins" & folderDelimit
      set helpFile to CDPath & "Om Mulle"
    end if
    set carPath to "c:\levande\mullebil\bilar\"
    set xtrasPath to CDPath & "Xtras" & folderDelimit
  else
    set CDPath to gCDPath
    set HDPath to gHDPath
    set pluginPath to HDPath & "Plugins" & folderDelimit
    set helpFile to gHelpFile
    set carPath to HDPath & "Bilar" & folderDelimit
    if the machineType = 256 then
      set xtrasPath to CDPath & "Xtras" & folderDelimit
    else
      set xtrasPath to CDPath & "HiddenXtras" & folderDelimit
    end if
  end if
  set the searchPaths to [CDPath & "Movies" & folderDelimit, pluginPath, HDPath & "data" & folderDelimit]
  set xtraFileList to []
  repeat with n = 1 to the maxinteger
    set tempName to getNthFileNameInFolder(xtrasPath, n)
    if tempName = EMPTY then
      exit repeat
    end if
    add(xtraFileList, tempName)
  end repeat
  return me
end

on kill me
  return 0
end

on upperCase me, theStr
  global gPathGlobals
  repeat with n = 1 to length(theStr)
    set tempNum to charToNum(char n of theStr)
    if tempNum >= 97 then
      if tempNum <= 122 then
        put numToChar(tempNum - 32) into char n of theStr
        next repeat
      end if
      if the machineType = 256 then
        set temp to getProp(translateLetters, #PC)
      else
        set temp to getProp(translateLetters, #Mac)
      end if
      set found to getPos(temp, tempNum)
      if found then
        if found mod 2 = 0 then
          put numToChar(getAt(temp, found - 1)) into char n of theStr
        end if
      end if
    end if
  end repeat
  return theStr
end

on openXtra me, theXtra
  set temp to getXtraName(me, theXtra)
  set xtraName to getAt(temp, 1)
  set xtraFileName to getAt(temp, 2)
  if not findXtra(me, xtraName) then
    if findXtraFile(me, xtraFileName) then
      openXLib(xtrasPath & xtraFileName)
      if theXtra = #PrintOMatic then
        register(xtra("PrintOMatic"), "PMAT133-396-02312")
      end if
      return 1
    end if
  end if
  return 0
end

on closeXtra me, theXtra
  set temp to getXtraName(me, theXtra)
  set xtraName to getAt(temp, 1)
  set xtraFileName to getAt(temp, 2)
  if findXtra(me, xtraName) and findXtraFile(me, xtraFileName) then
    closeXLib(xtrasPath & xtraFileName)
  end if
end

on findXtra me, theXtraName
  repeat with xtraNr = 1 to the number of xtras
    if the name of xtra(xtraNr) = theXtraName then
      return 1
    end if
  end repeat
  return 0
end

on getXtraName me, theXtra
  if theXtra = #PrintOMatic then
    set xtraName to "PrintOMatic"
    if the machineType = 256 then
      set xtraFileName to "PMatic"
    else
      set xtraFileName to "PrintOMatic"
    end if
  else
    if theXtra = #KeyPoll then
      set xtraName to "KeyPoll"
      if the machineType = 256 then
        set xtraFileName to "KeyPoll"
      else
        set xtraFileName to "KeyPollFat"
      end if
    end if
  end if
  return [xtraName, xtraFileName]
end

on findXtraFile me, theFileName
  if the machineType = 256 then
    set theFileName to theFileName & ".x"
  end if
  repeat with index in xtraFileList
    if index contains theFileName then
      return 1
    end if
  end repeat
  return 0
end
