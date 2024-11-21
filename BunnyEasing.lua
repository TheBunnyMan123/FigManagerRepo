local ease = {}

function ease.sinIn(maxTime, currentTime)
  maxTime = maxTime or 1

  return -math.cos((1/(2*maxTime))*math.pi*currentTime)+1
end
function ease.sinOut(maxTime, currentTime)
  maxTime = maxTime or 1

  return -math.cos((1/(2*maxTime))*math.pi*(currentTime+maxTime))
end
function ease.sinInOut(maxTime, currentTime)
  maxTime = maxTime or 1

  return (-math.cos((1/maxTime)*math.pi*currentTime)+1)/2
end

function ease.quadIn(maxTime, currentTime, halfSqMax)
  maxTime = maxTime or 1

  if halfSqMax then
    return currentTime^2 / (maxTime^2 / 4)
  end
  
  return currentTime^2 / maxTime^2
end
function ease.quadOut(maxTime, currentTime, halfSqMax)
  maxTime = maxTime or 1

  local sqMax = sqMax^2
  
  if halfSqMax then
    sqMax = sqMax / 2
  end
  
  return (sqMax - (maxTime - currentTime)^2) / sqMax
end
function ease.quadInOut(maxTime, currentTime)
  maxTime = maxTime or 1

  if currentTime > (maxTime / 2) then
    return ease.quadOut(maxTime, currentTime, true)
  else
    return ease.quadIn(maxTime, currentTime, true)
  end
end

function ease.cubicIn(maxTime, currentTime, quarterCuMax)
  maxTime = maxTime or 1

  if quarterCuMax then
    return currentTime^3 / (maxTime^3 / 4)
  end
  
  return currentTime^3 / maxTime^3
end
function ease.cubicOut(maxTime, currentTime, quarterCuMax)
  maxTime = maxTime or 1

  local cuMax = cuMax^3
  
  if quarterCuMax then
    cuMax = cuMax / 4
  end
  
  return (cuMax - (maxTime - currentTime)^3) / cuMax
end
function ease.cubicInOut(maxTime, currentTime)
  maxTime = maxTime or 1

  if currentTime > (maxTime / 2) then
    return ease.cubicIn(maxTime, currentTime, true)
  else
    return ease.cubicIn(maxTime, currentTime, true)
  end
end

return ease
