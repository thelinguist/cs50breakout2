PlayState = Class{__includes = BaseState}

function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {params.ball}
    self.level = params.level
    self.pointsCounters = params.pointsCounters

    self.powerup = nil
    self.key = nil
    self.hasKey = params.hasKey

    -- give ball random starting velocity
    self.balls[1].dx = randomBallDx()
    self.balls[1].dy = randomBallDy()
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k,ball in pairs(self.balls) do
        ball:update(dt)
    end

    if self.powerup then
        self.powerup:update(dt)
        if self.powerup.y > VIRTUAL_HEIGHT then
            self.powerup = nil
        end
    end

    if self.key then
        self.key:update(dt)
        if self.key.y > VIRTUAL_HEIGHT then
            self.key = nil
        end
    end

    self:ballCollision()

    for k,brick in pairs(self.bricks) do
        for j,ball in pairs(self.balls) do
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
                self.pointsCounters.checkpoint = self.pointsCounters.checkpoint + (brick.tier * 200 + brick.color * 25)
                self.pointsCounters.powerup = self.pointsCounters.powerup - 1
                self.pointsCounters.key = self.pointsCounters.key - 1

                -- add paddle points
                if self.pointsCounters.checkpoint >= CHANGE_PADDLE_POINTS then
                    self.paddle:changeSize(self.paddle.size + 1)
                    self.pointsCounters.checkpoint = self.pointsCounters.checkpoint - CHANGE_PADDLE_POINTS
                end

                -- add powerup points
                if self.pointsCounters.powerup == 0 and self.powerup == nil then
                    self.pointsCounters.powerup = randomPowerupTime()
                    self.powerup = Powerup(4)
                end

                -- add key points
                if not self.hasKey and self.pointsCounters.key == 0 and self.key == nil then
                    self.pointsCounters.key = randomKeyTime()
                    self.key = Powerup(10)
                end

                brick:hit(self.hasKey)

                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.balls[1],
                        pointsCounters = self.pointsCounters
                    })
                end
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly
                --

                -- left edge; only check if we're moving right
                -- add 2 so that this might not trigger on corners (and defer to y stuff)
                if ball.x + 2 < brick.x and ball.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8

                    -- right edge; only check if we're moving left
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + brick.width

                    -- top edge if no X collisions, always check
                elseif ball.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8

                    -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game
                ball.dy = ball.dy * 1.02

                -- only allow colliding with one brick, for corners
                break
            end

        end
    end

    -- add balls if we catch a powerup
    if self.powerup and self.powerup:collides(self.paddle) then
        self.powerup = nil
        local ball1 = Ball()
        ball1.dx = randomBallDx()
        ball1.dy = randomBallDy()
        ball1.skin = randomBallColor()
        ball1.x = self.balls[1].x
        ball1.y = self.balls[1].y
        local ball2 = Ball()
        ball2.dx = randomBallDx()
        ball2.dy = randomBallDy()
        ball2.skin = randomBallColor()
        ball2.x = self.balls[1].x
        ball2.y = self.balls[1].y
        table.insert(self.balls, ball1)
        table.insert(self.balls, ball2)
    end

    if self.key and self.key:collides(self.paddle) then
        self.hasKey = true
        self.key = nil
    end


        -- delete any balls that go off screen
    for k,ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls,k)
        end
    end

    -- detect if there are no more balls and take a life point / end game
    if #self.balls == 0 then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            self.paddle:changeSize(self.paddle.size - 1)
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                pointsCounters = self.pointsCounters,
                hasKey = self.hasKey
            })
        end

    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end


function PlayState:render()

    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    for k, ball in pairs(self.balls) do
        ball:render()
    end

    if self.powerup then
        self.powerup:render()
    end

    if self.key then
        self.key:render()
    end

    renderKey(self.hasKey)
    renderScore(self.score)
    renderHealth(self.health)

    if self.paused then
    love.graphics.setFont(gFonts['large'])
    love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end
    return true
end

function PlayState:ballCollision()
    for k,ball in pairs(self.balls) do

        if ball:collides(self.paddle) then
            -- reverse Y velocity if collision detected between paddle and ball
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

                -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end
end
