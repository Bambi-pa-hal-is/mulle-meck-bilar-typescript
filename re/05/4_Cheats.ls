global gMulleGlobals

on noMedals
  set the medals of the car of the user of gMulleGlobals to []
end

on noMissions
  set the completedMissions of the user of gMulleGlobals to []
end

on putMissions
  put the completedMissions of the user of gMulleGlobals
end

on fullGas
end

on cacheThis theProp
  setCacheProp(the car of the user of gMulleGlobals, theProp)
end

on gotDog
  setCacheProp(the car of the user of gMulleGlobals, #GotDogOnce)
end

on makeCar which
  set brake to 105
  set clutch to 133
  set wheel to 115
  set steer to 54
  set battery to 49
  set tank to 172
  set solar to 91
  set Horn to 195
  if which = #All then
    set temp to [1, 11, 102, 132]
  else
    if which = #NoComb then
      set temp to [1, 102, 132]
    else
      if which = #NoElec then
        set temp to [1, 11, 132]
      else
        if which = #NoPeda then
          set temp to [1, 11, 102]
        else
          if which = #Comb then
            set temp to [1, 11]
          else
            if which = #Elec then
              set temp to [1, 102]
            else
              if which = #Peda then
                set temp to [1, 132]
              else
                if which = #Speed3 then
                  set temp to [1, 7]
                else
                  if which = #Speed4 then
                    set temp to [1, 10]
                  else
                    if which = #Speed5 then
                      set temp to [1, 306]
                    else
                      if which = #Sail then
                        set temp to [115, 115, 105, 54, 233]
                        trash(the car of the user of gMulleGlobals)
                        repeat with index in temp
                          addPart(the car of the user of gMulleGlobals, index)
                        end repeat
                        updateProperties(the car of the user of gMulleGlobals)
                        exit
                      else
                        if which = #Ok then
                          set temp to [82, 241, 188, 133, 39, 144, 224, 122, 92, 184, 13, 89]
                          trash(the car of the user of gMulleGlobals)
                          repeat with index in temp
                            addPart(the car of the user of gMulleGlobals, index)
                          end repeat
                          updateProperties(the car of the user of gMulleGlobals)
                          exit
                        else
                          if which = #Good then
                            set temp to [82, 238, 149, 91, 272, 102, 129, 54, 264, 65]
                            trash(the car of the user of gMulleGlobals)
                            repeat with index in temp
                              addPart(the car of the user of gMulleGlobals, index)
                            end repeat
                            updateProperties(the car of the user of gMulleGlobals)
                            exit
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
    end if
  end if
  add(temp, brake)
  add(temp, clutch)
  add(temp, wheel)
  add(temp, wheel)
  add(temp, steer)
  add(temp, battery)
  add(temp, tank)
  add(temp, Horn)
  set the parts of the car of the user of gMulleGlobals to duplicate(temp)
  updateProperties(the car of the user of gMulleGlobals)
  setUserProp(the user of gMulleGlobals, #FerryTicket)
  setCacheProp(the car of the user of gMulleGlobals, #RoadThing4)
end
