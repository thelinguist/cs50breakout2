LevelMaker = Class {}

function LevelMaker:createMap()
    local bricks = {}

    local numRows = math.random(1,5)

    local numCols = math.random(7,13)

    for y = 1, numRows do
        for x = 1, numCols do
            b = Brick(
                    (x-1)                   -- zero index it
                    * 32                    -- multiply by brick width
                    + 8                     -- plus padding
                    + (13 - numCols) * 16,  -- left side padding when there are 13
                    y * 16
            )

            table.insert(bricks, b)

        end
    end

    return bricks
end
