on mouseUp
  global gDir
  if the OKToEnd of gDir then
    sound(#stop, 1)
    sound(#stop, 2)
    sound(#stop, 3)
    go(1, "03")
  end if
end
