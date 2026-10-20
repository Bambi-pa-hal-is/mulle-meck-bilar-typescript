on newMember newMemberType, newMemberName, newMemberLib
  set newMember to new(newMemberType, castLib(newMemberLib))
  set the name of newMember to newMemberName
end

on copyMember fromMember, newMemberName, newMemberLib
  set newMember to new(the type of fromMember, castLib(newMemberLib))
  set the name of newMember to newMemberName
  set the media of newMember to the media of fromMember
  set the name of newMember to newMemberName
  if the number of newMember = -1 then
    return 0
  end if
  if not (the name of newMember = newMemberName) then
    return 0
  end if
  return 1
end

on copyMemberList fromMemberList, newMemberLib
  set lastMemberNum to the number of castMembers of castLib newMemberLib
  repeat with n = 1 to count(fromMemberList)
    set fromMember to getAt(fromMemberList, n)
    set newMember to new(the type of fromMember, member(lastMemberNum + n, newMemberLib))
    set the name of newMember to the name of fromMember
    set the media of newMember to the media of fromMember
  end repeat
end

on copyMembers startMemberNum, endMemberNum, fromCastLib, toCastLib
  set membersXferred to []
  set membersToErase to []
  set lastMemberNum to the number of castMembers of castLib toCastLib
  repeat with n = 1 to endMemberNum - startMemberNum + 1
    if the freeBlock < 300 * 1024 then
      save(castLib(toCastLib))
      unloadMember()
    end if
    set fromMember to member(n + startMemberNum - 1, fromCastLib)
    if not (the type of member(fromMember) = #empty) then
      if not (the number of member(the name of fromMember, toCastLib) = -1) then
        add(membersToErase, member(the name of fromMember, toCastLib))
      end if
      set newMember to new(the type of fromMember, member(1 + the number of castMembers of castLib toCastLib, toCastLib))
      put the name of fromMember
      set the name of newMember to the name of fromMember
      set the media of newMember to the media of fromMember
      if the size of newMember < the size of fromMember / 2 then
        put the size of newMember, the size of fromMember
        alert("Out of memory! Plugin transfer cancelled.")
        repeat with index in membersXferred
          erase(index)
        end repeat
        return 0
      end if
      add(membersXferred, newMember)
    end if
  end repeat
  repeat with index in membersToErase
    erase(index)
  end repeat
  return 1
end

on checkForPlugins
  global gPathGlobals
  set castsToXfer to []
  set dirFiles to []
  repeat with n = 1 to the maxinteger
    set tempFile to getNthFileNameInFolder(the pluginPath of gPathGlobals, n)
    set tempLen to length(tempFile)
    if tempLen = 0 then
      exit repeat
      next repeat
    end if
    if char tempLen - 3 to tempLen of tempFile = ".cst" or char tempLen - 3 to tempLen of tempFile = ".cxt" then
      add(castsToXfer, tempFile)
      next repeat
    end if
    if char tempLen - 3 to tempLen of tempFile = ".dxr" then
      add(dirFiles, tempFile)
    end if
  end repeat
  return [#cast: castsToXfer, #Dir: dirFiles]
end

on xferPluginCasts theCastName
  global gMulleGlobals, gPathGlobals
  set tempCast to "TempPlug"
  set toCast to "data"
  set the fileName of castLib(tempCast) to the pluginPath of gPathGlobals & theCastName
  if the number of castMembers of castLib tempCast > 0 then
    set plugMain to ["PartsDB", "WorldsDB", "MapsDB", "ObjectsDB", "MissionsDB", "ExternalPartsDB"]
    set nrOfMembers to the number of castMembers of castLib tempCast
    set startMember to count(plugMain) + 1
    set wasOK to copyMembers(startMember, nrOfMembers, tempCast, toCast)
    if wasOK then
      repeat with n = 1 to count(plugMain)
        if the number of member(getAt(plugMain, n), tempCast) <> -1 then
          set toList to value(the text of member(getAt(plugMain, n), toCast))
          set fromList to value(the text of member(getAt(plugMain, n), tempCast))
          if listp(toList) and listp(fromList) then
            if getAt(plugMain, n) = "ExternalPartsDB" then
              repeat with m = 1 to count(fromList)
                set tempPlugProp to getPropAt(fromList, m)
                if not voidp(getaProp(toList, tempPlugProp)) then
                  set tempToList to getAt(toList, m)
                  set tempFromList to getAt(fromList, m)
                  repeat with tempPart in tempFromList
                    add(tempToList, tempPart)
                  end repeat
                  setProp(toList, tempPlugProp, tempToList)
                end if
              end repeat
              set the text of member(getAt(plugMain, n), toCast) to string(toList)
              next repeat
            end if
            if count(fromList) then
              repeat with index in fromList
                if not getPos(toList, index) then
                  add(toList, index)
                end if
              end repeat
              set the text of member(getAt(plugMain, n), toCast) to string(toList)
            end if
          end if
        end if
      end repeat
      set the fileName of castLib(tempCast) to the CDPath of gPathGlobals & "tempPlug"
      set tempFile to new(xtra("FileIO"))
      openFile(tempFile, the pluginPath of gPathGlobals & theCastName, 1)
      delete(tempFile)
      closeFile(tempFile)
      set tempFile to 0
      save(castLib(toCast))
      unloadMember()
    end if
  end if
  set the fileName of castLib(tempCast) to the CDPath of gPathGlobals & "tempPlug"
end
