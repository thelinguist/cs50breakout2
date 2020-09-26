Brick = Class{}


-- some of the colors in our palette (to be used with particle systems)
paletteColors = {
    -- blue
    [1] = {
        --['r'] = 99,
        --['g'] = 155,
        --['b'] = 255
        ['r'] = .39,
        ['g'] = .61,
        ['b'] = 1
    },
    -- green
    [2] = {
        ['r'] = .42,
        ['g'] = .75,
        ['b'] = .18
    },
    -- red
    [3] = {
        ['r'] = .85,
        ['g'] = .34,
        ['b'] = .39
    },
    -- purple
    [4] = {
        ['r'] = .84,
        ['g'] = .49,
        ['b'] = .73
    },
    -- gold
    [5] = {
        ['r'] = .99,
        ['g'] = .95,
        ['b'] = .2
    },
    [6] = {
        ['r'] = .8,
        ['g'] = .8,
        ['b'] = .8
    }
}

function Brick:init(x, y)
    self.tier = 0
    self.color = 1

    self.x = x
    self.y = y
    self.width = 32
    self.height = 16

    self.isLocked = false
    self.inPlay = true

    -- particle system belonging to the brick, emitted on hit
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- various behavior-determining functions for the particle system
    -- https://love2d.org/wiki/ParticleSystem

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- spread of particles; normal looks more natural than uniform, which is clumpy; numbers
    -- are amount of standard deviation away in X and Y axis
    self.psystem:setEmissionArea('normal', 10, 10)
end

function Brick:update(dt)
    self.psystem:update( dt )
end

function Brick:hit(withKey)
    if not isLocked or withKey then
        -- set the particle system to interpolate between two colors; in this case, we give
        -- it our self.color but with varying alpha; brighter for higher tiers, fading to 0
        -- over the particle's lifetime (the second color)
        self.psystem:setColors(
                paletteColors[self.color].r,
                paletteColors[self.color].g,
                paletteColors[self.color].b,
                .2 * (self.tier + 1),
                paletteColors[self.color].r,
                paletteColors[self.color].g,
                paletteColors[self.color].b,
                0
        )
        self.psystem:emit(64)

        -- sound on hit
        gSounds['brick-hit-2']:stop()
        gSounds['brick-hit-2']:play()

        -- if we're at a higher tier than the base, we need to go down a tier
        -- if we're already at the lowest color, else just go down a color
        if self.tier > 0 then
            if self.color == 1 then
                self.tier = self.tier - 1
                self.color = 5
            else
                self.color = self.color - 1
            end
        else
            -- if we're in the first tier and the base color, remove brick from play
            if self.color == 1 then
                self.inPlay = false
            else
                self.color = self.color - 1
            end
        end

        -- play a second layer sound if the brick is destroyed
        if not self.inPlay then
            gSounds['brick-hit-1']:stop()
            gSounds['brick-hit-1']:play()
        end
    end
end

function Brick:render()
    if self.inPlay then
        if self.isLocked then
            love.graphics.draw(gTextures['main'], gFrames['bricks'][22],
                    self.x, self.y) -- pick a brick by tier and color
        else
            love.graphics.draw(gTextures['main'], gFrames['bricks'][1 + ((self.color - 1) * 4) + self.tier],
                    self.x, self.y) -- pick a brick by tier and color
        end
    end
end

--[[
    Need a separate render function for our particles so it can be called after all bricks are drawn;
    otherwise, some bricks would render over other bricks' particle systems.
]]
function Brick:renderParticles()
    love.graphics.draw(self.psystem, self.x + 16, self.y + 8)
end
