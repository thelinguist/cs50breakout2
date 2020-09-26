LevelMaker = Class {}

-- global patterns (used to make the entire map a certain shape)
NONE = 1
SINGLE_PYRAMID = 2
MULTI_PYRAMID = 3

-- per-row patterns
SOLID = 1           -- all colors the same in this row
ALTERNATE = 2       -- alternate colors
SKIP = 3            -- skip every other block
NONE = 4            -- no blocks this row
BRICK_WIDTH = 32

function LevelMaker.createMap(level, lockedBrickFlag)
    local bricks = {}

    local numRows = TESTING and 1 or math.random(1,5)

    -- randomly choose the number of columns, ensuring odd
    local numCols = math.random(7, 13)
    numCols = numCols % 2 == 0 and (numCols + 1) or numCols

    -- highest possible spawned brick color in this level; ensure we
    -- don't go above 3
    local highestTier = math.min(3, math.floor(level / 5))

    -- highest color of the highest tier
    local highestColor = math.min(5, level % 5 + 3)

    for y = 1, numRows do
        -- here we're gonna pick some patterns for each row to challenge the player.

        -- whether we want to enable skipping for this row, ex math.random == 1 ? true : false
        local skipPattern = math.random(1, 2) == 1 and true or false

        -- whether we want to enable alternating colors for this row
        local alternatePattern = math.random(1, 2) == 1 and true or false

        -- choose two colors to alternate between
        local alternateColor1 = math.random(1, highestColor)
        local alternateColor2 = math.random(1, highestColor)
        local alternateTier1 = math.random(0, highestTier)  -- I guess tier can be zero, but not color
        local alternateTier2 = math.random(0, highestTier)

        -- temp var used only when we want to skip a block, for skip pattern
        local skipFlag = math.random(2) == 1 and true or false

        -- temp var used only when we want to alternate a block, for alternate pattern
        local alternateFlag = math.random(2) == 1 and true or false

        -- solid color for the row we'll use if we're not alternating
        local solidColor = math.random(1, highestColor)
        local solidTier = math.random(0, highestTier)

        for x = 1, numCols do

            -- if skipping is turned on and we're on a skip iteration...
            if skipPattern and skipFlag then
                -- turn skipping off for the next iteration
                skipFlag = not skipFlag

                -- Lua doesn't have a continue statement, so this is the workaround
                goto continue
            else
                -- flip the flag to true on an iteration we don't use it
                skipFlag = not skipFlag
            end

            b = Brick(
                    (x-1)                   -- zero index it
                    * BRICK_WIDTH           -- multiply by brick width
                    + 8                     -- plus padding
                    + (13 - numCols) * 16,  -- left side padding when there are 13
                    y * 16
            )

            -- if we're alternating, figure out which color/tier we're on
            if alternatePattern and alternateFlag then
                b.color = alternateColor1
                b.tier = alternateTier1
                alternateFlag = not alternateFlag
            else
                b.color = alternateColor2
                b.tier = alternateTier2
                alternateFlag = not alternateFlag
            end

            -- if not alternating and we made it here, use the solid color/tier
            if not alternatePattern then
                b.color = solidColor
                b.tier = solidTier
            end

            table.insert(bricks, b)

            -- Lua's version of the 'continue' statement
            ::continue::
        end
    end

    -- use locked brick less often. Replace a brick with lockedBrick
    if lockedBrickFlag then
        local i = math.random(1,#bricks)
        bricks[i].isLocked = true
        bricks[i].tier = 1
        bricks[i].color = 6
    end

    -- in the event we didn't generate any bricks, try again
    if #bricks == 0 then
        return self.createMap(level)
    else
        return bricks
        end
end
