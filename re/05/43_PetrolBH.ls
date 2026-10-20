property SP, maxVolume, firstMember, maxElec, maxFuel, gotElectricEngine, gotCombustionEngine, mode, nrOfSteps, nr, fillMax, Wait
global gDir, gMulleGlobals

on beginSprite me
  set SP to the spriteNum of me
  set nrOfSteps to 13
  set firstMember to the number of member "01a001v0"
  set mode to #normal
end

on init me
  updateFuelMeter(me)
  addLoopObject(gDir, me)
  set mode to #normal
end

on updateFuelMeter me
  set tempGas to getaProp(the quickCarProps of the carDriving of gDir, #FuelVolume)
  set tempElec to getaProp(the quickCarProps of the carDriving of gDir, #ElectricVolume)
  set gotElectricEngine to the gotElectricEngine of the carDriving of gDir
  set gotCombustionEngine to not (getaProp(the quickCarProps of the carDriving of gDir, #FuelConsumption) = 0)
  set maxFuel to 0
  if gotElectricEngine then
    set maxFuel to maxFuel + tempElec
  end if
  if gotCombustionEngine then
    set maxFuel to maxFuel + tempGas
  end if
  if maxFuel = 0 then
    set maxFuel to 1
  else
    set the member of sprite SP to member(firstMember + nrOfSteps - 1)
  end if
end

on loop me
  if the mode of gDir = #Driving then
    if mode = #normal then
      set percentElec to 0
      set percentComb to 0
      if gotElectricEngine then
        set percentElec to 100 * getAt(getFuel(the carDriving of gDir), 2)
      end if
      if gotCombustionEngine then
        set percentComb to 100 * getAt(getFuel(the carDriving of gDir), 1)
      end if
      set percent to (percentElec + percentComb) / maxFuel
      if percent > 0 then
        if percent = 100 then
          set percent to 99
        end if
        set nr to percent * nrOfSteps / 100
        set the member of sprite SP to member(firstMember + nr)
      else
        set the member of sprite SP to member(firstMember)
      end if
    else
      if mode = #Filling then
        if Wait then
          set Wait to Wait - 1
        else
          set the member of sprite SP to member(firstMember + nr / 10)
          set nr to nr + 5
          if nr / 10 > nrOfSteps + fillMax then
            set mode to #normal
          end if
        end if
      end if
    end if
  end if
end

on fillErUp me, xtra
  set mode to #Filling
  set Wait to 20
  set nr to nr * 10
  if xtra > 0 then
    set fillMax to 3
  else
    set fillMax to 0
  end if
end
