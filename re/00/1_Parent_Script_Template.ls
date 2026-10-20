property X, y

on new me
  return me
end

on kill me
  return 0
end

on setX me, newX
  set X to newX
end

on getX me
  return X
end

on toList me
  return [X, y]
end

on fromList me, objectList
  set X to getaProp(objectList, #X)
  set y to getaProp(objectList, #y)
end
