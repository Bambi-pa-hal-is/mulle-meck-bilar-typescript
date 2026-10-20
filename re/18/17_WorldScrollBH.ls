property mode, counter, postList, lookinAtPost, postSP, middleLoc, nrOfPosts, maxSigns, cpList, usedSprites, width, steps, memberList
global gTheseAreTheWorlds, gMulleGlobals, gSound

on beginSprite me
  play(gSound, "18d001v0", #EFFECT)
  set postSP to 2
  set maxSigns to 6
  set middleLoc to point(200, 150)
  set mode to #Still
  set width to the width of sprite the spriteNum of me
  set steps to 10
  set cpList to []
  repeat with n = 1 to maxSigns
    add(cpList, n)
  end repeat
  if objectp(gMulleGlobals) and 1 then
    set gTheseAreTheWorlds to [:]
    set tempObj to new(script("World"))
    repeat with index in the worlds of the worlds of gMulleGlobals
      if fromList(tempObj, index) then
        set tempId to getId(tempObj)
        set tempSign to getPosition(tempObj)
        addProp(gTheseAreTheWorlds, tempSign, tempId)
      end if
    end repeat
  else
    set gTheseAreTheWorlds to [1: "World1", 2: "World2", 3: "World3", 4: "World4", 5: "World5", 6: "World6", 1: "World3", 3: "World4", 1: "World4"]
  end if
  calcPosts(me)
end

on calcPosts me
  global gTheseAreTheWorlds
  set postList to []
  set tempObj to new(script("World"))
  repeat with n = 1 to count(gTheseAreTheWorlds)
    set nr to getPropAt(gTheseAreTheWorlds, n)
    set id to getAt(gTheseAreTheWorlds, n)
    if fromList(tempObj, id) then
      set memb to getSymbol(tempObj)
    else
      set memb to id
    end if
    set foundPlace to 0
    repeat with m = 1 to count(postList)
      set tempList to getAt(postList, m)
      if voidp(getaProp(tempList, nr)) then
        addProp(tempList, nr, [#id: id, #member: memb])
        set foundPlace to 1
        exit repeat
      end if
    end repeat
    if not foundPlace then
      set temp to [:]
      addProp(temp, nr, [#id: id, #member: memb])
      add(postList, temp)
    end if
  end repeat
  set nrOfPosts to count(postList)
  set lookinAtPost to 1
  prepareDraw(me)
  draw(me)
  drawArrows(me)
end

on scroll me, rightLeft
  if rightLeft = 1 then
    set lookinAtPost to lookinAtPost + 1
    if lookinAtPost > nrOfPosts then
      set lookinAtPost to nrOfPosts
    else
      prepareDraw(me, rightLeft)
      set mode to #right
    end if
  else
    set lookinAtPost to lookinAtPost - 1
    if lookinAtPost < 1 then
      set lookinAtPost to 1
    else
      prepareDraw(me, rightLeft)
      set mode to #left
    end if
  end if
  drawArrows(me)
  set counter to 0
end

on exitFrame me
  if not (mode = #Still) then
    set counter to counter + 1
    if counter = steps + 1 then
      set mode to #Still
    end if
    if mode = #right then
      draw(me, 1, (steps - counter) * width / steps)
    else
      if mode = #left then
        draw(me, -1, -(steps - counter) * width / steps)
      end if
    end if
  end if
end

on prepareDraw me, rightLeft
  set tempStartSP to postSP
  set usedSprites to []
  set isTwo to 2
  if nrOfPosts = 1 then
    set isTwo to 1
  end if
  repeat with X = 1 to isTwo
    set freeSprites to duplicate(cpList)
    set tempList to getAt(postList, lookinAtPost + (X - 1) * -rightLeft)
    set tempUsed to []
    repeat with n = 1 to count(tempList)
      set tempSP to getPropAt(tempList, n)
      deleteOne(freeSprites, tempSP)
      add(tempUsed, tempSP)
      set tempSP to tempSP + tempStartSP
      set the member of sprite tempSP to member(getProp(getAt(tempList, n), #member))
      set the locH of sprite tempSP to -4711
    end repeat
    repeat with index in freeSprites
      set tempSP to index + tempStartSP
      set the member of sprite tempSP to member("Dummy")
    end repeat
    set tempStartSP to postSP + maxSigns + 1
    add(usedSprites, duplicate(tempUsed))
  end repeat
end

on draw me, rightLeft, theOffsetH
  if voidp(theOffsetH) then
    set theOffsetH to 0
  end if
  if voidp(rightLeft) then
    set rightLeft to -1
  end if
  set tempStartSP to postSP
  set isTwo to 2
  if nrOfPosts = 1 then
    set isTwo to 1
  end if
  repeat with X = 1 to isTwo
    set the member of sprite tempStartSP to member("18b005v0")
    set the loc of sprite tempStartSP to middleLoc + point(theOffsetH, 0)
    set tempList to getAt(postList, lookinAtPost + (X - 1) * -rightLeft)
    repeat with n = 1 to count(tempList)
      set tempSP to getPropAt(tempList, n) + tempStartSP
      set the loc of sprite tempSP to middleLoc + point(theOffsetH, 0)
    end repeat
    set tempStartSP to postSP + maxSigns + 1
    set theOffsetH to theOffsetH - width * rightLeft
  end repeat
end

on drawArrows me
  set tempLeft to 18
  set tempRight to 17
  if nrOfPosts > 1 then
    if lookinAtPost > 1 then
      set the member of sprite tempLeft to member("18b003v0")
    else
      set the member of sprite tempLeft to member("Dummy")
    end if
    if lookinAtPost < nrOfPosts then
      set the member of sprite tempRight to member("18b004v0")
    else
      set the member of sprite tempRight to member("Dummy")
    end if
  else
    set the member of sprite tempLeft to member("Dummy")
    set the member of sprite tempRight to member("Dummy")
  end if
end

on choseWorld me, theName
  global gDir
  set foundIt to 0
  if stringp(theName) then
    repeat with aList in postList
      repeat with bList in aList
        if getProp(bList, #member) = theName then
          set foundIt to getProp(bList, #id)
          exit repeat
        end if
      end repeat
      if stringp(foundIt) then
        exit repeat
      end if
    end repeat
  end if
  if objectp(gDir) then
    cursor(200)
    choseWorld(gDir, foundIt)
    cursor(200)
    set the activeWorld of the worlds of gMulleGlobals to foundIt
    cursor(-1)
    cursor(200)
  else
    put foundIt
  end if
end
