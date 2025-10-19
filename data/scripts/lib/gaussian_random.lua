-- Generates a normally distributed number with Gaussian bell curve bias
-- mu = mean (center), sigma = standard deviation
function gaussianRandom(mu, sigma)
    local u1 = math.random()
    local u2 = math.random()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return z * sigma + mu
end


-- not sure
function gaussianRandom20p(value)
    local stddev = 0.1 * value
    return gaussianRandom(value, stddev)
end

function gaussianRandom50p(value)
    local stddev = 0.25 * value
    return gaussianRandom(value, stddev)
end
