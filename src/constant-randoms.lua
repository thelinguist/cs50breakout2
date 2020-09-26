function randomPowerupTime()
    return math.random(10,15)
end

function randomBallDx()
    return math.random(-200, 200)
end

function randomBallDy()
    return math.random(-50, -60)
end

function randomBallColor()
    return math.random(7)
end

function randomKeyTime()
    return math.random(1,1)
end

function randomLockLevel()
    local chance = math.random(1,10)
    return chance > 0
end
