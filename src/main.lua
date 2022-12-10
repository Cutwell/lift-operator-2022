-- import soundmanager
local soundmanager = require("soundmanager")
local timermanager = require("timermanager")

local gameCanvas, cutsceneCanvas, bgm, sfx, assets, debug, gamestate, requestedFloors, floors, lift, textBlink, mute
assets = {}
sfx = {}
mute = false
gamestate = 1
debug = false

function Reset()
    -- 1 = load assets, 2 = start screen, 3 = intro, 4 = game, 5 = game over
    gamestate = 1
    textBlink = false

    love.timer.clear()
    -- text blinks for gamestates 2, 3, 5
    love.timer.create("titleTextBlink", 0.75, 2, true, function() textBlink = not textBlink end)
    love.timer.create("introTextBlink", 0.75, 3, true, function() textBlink = not textBlink end)
    love.timer.create("gameoverTextBlink", 0.75, 5, true, function() textBlink = not textBlink end)
    love.timer.create("scoreTextBlink", 0.75, 6, true, function() textBlink = not textBlink end)
    love.timer.create("titleScreenLiftAnimation", 10.0, 2, false)
    love.timer.create("introCutscene", 2.0, 3, false)
    love.timer.create("gameoverCutscene", 2.0, 5, false)
    love.timer.create("passengerSpawn", 2.5, 4, true, function() SpawnPassenger() end)

    requestedFloors = {}
    -- hover, queued, x, y
    requestedFloors[1] = {false, false, 34, 24}
    requestedFloors[2] = {false, false, 40, 24}
    requestedFloors[3] = {false, false, 46, 24}
    requestedFloors[4] = {false, false, 34, 37}
    requestedFloors[5] = {false, false, 40, 37}

    floors = {}
    -- x, y
    floors[1] = {16, 45}
    floors[2] = {16, 36}
    floors[3] = {16, 27}
    floors[4] = {16, 18}
    floors[5] = {16,  9}

    floors.passengers = {}
    floors.passengers[1] = {}
    floors.passengers[2] = {}
    floors.passengers[3] = {}
    floors.passengers[4] = {}
    floors.passengers[5] = {}

    floors.timerMax = 30.0  -- seconds before game over
    floors.timers = {}
    floors.timers[1] = {}
    floors.timers[2] = {}
    floors.timers[3] = {}
    floors.timers[4] = {}
    floors.timers[5] = {}

    lift = {}
    lift.destinations = {}
    -- x, y
    lift.destinations[5] = {0, 6}
    lift.destinations[4] = {0, 15}
    lift.destinations[3] = {0, 24}
    lift.destinations[2] = {0, 33}
    lift.destinations[1] = {0, 42}
    lift.queue = {}
    lift.x = 0
    lift.y = 33
    lift.floor = 2  -- current floor
    lift.score = 0 -- score
    lift.maxload = 4 -- max number of people in lift
    lift.currload = 0 -- current number of people in lift
    lift.moveTimerMax = 0.1 -- seconds per pixel movement
    lift.moveTimer = 0
    lift.floorTimerMax = {0.2, 0.5, 0.5, 0.2} -- seconds to wait to open doors / load / unload / close doors
    lift.floorTimer = {0, 0, 0, 0}
    lift.passengers = {} -- passenger objects: {destination, model}

    -- ensure bgm is playing
    if not mute then
        love.audio.play(bgm)
    end
end

function love.load()
    math.randomseed(os.time())
    love.graphics.setDefaultFilter( 'nearest', 'nearest', 1 )
    love.graphics.setBackgroundColor(0, 0, 0)

    -- music (load before update loop starts)
    bgm = love.audio.load("assets/music/Puzzles.wav", "stream", true) -- stream and loop background music
    sfx.ding = love.audio.load("assets/sfx/ding.mp3", "static")
    sfx.powerdown = love.audio.load("assets/sfx/powerdown.wav", "static")

    -- create 52x52 gameCanvas
    gameCanvas = love.graphics.newCanvas(52, 52)

    -- create 104x104 title / intro / game over cutscene canvas
    cutsceneCanvas = love.graphics.newCanvas(104, 104)

    assets.building = love.graphics.newImage("assets/building.png")
    assets.panel = love.graphics.newImage("assets/panel.png")
    assets.box = love.graphics.newImage("assets/lift.png")
    assets.scoreText = love.graphics.newImage("assets/score.png")

    -- intro, gameover, score screens
    assets.intro = love.graphics.newImage("assets/intro.png")
    assets.gameover = love.graphics.newImage("assets/gameover.png")
    assets.continueText = love.graphics.newImage("assets/continue-text.png")
    assets.continueTextWhite = love.graphics.newImage("assets/continue-text-white.png")

    -- title screen assets
    assets.titleLift = love.graphics.newImage("assets/title-lift.png")
    assets.titleText = love.graphics.newImage("assets/title-text.png")
    assets.titleStartText = love.graphics.newImage("assets/title-start-text.png")

    assets.numbers = {}
    for i = 0, 9 do
        assets.numbers[i] = love.graphics.newImage("assets/numbers/"..i..".png")
    end

    assets.people = {}
    for i = 1, 4 do
        assets.people[i] = love.graphics.newImage("assets/people/"..i..".png")
    end

    Reset() -- init values

    gamestate = 2
end

function love.draw()
    if gamestate == 1 or gamestate == 4 then
        -- set gameCanvas as target
        love.graphics.setCanvas(gameCanvas)
    elseif gamestate == 2 or gamestate == 3 or gamestate == 5 or gamestate == 6 then
        -- set cutsceneCanvas as target
        love.graphics.setCanvas(cutsceneCanvas)
    end

    -- clear canvas
    love.graphics.clear()

    if gamestate == 2 then
        -- animate raising lift
        local timer = love.timer.get("titleScreenLiftAnimation")
        local animationTimer, animationTimerMax = timer.curr, timer.max

        local y = 0-312*((animationTimerMax-animationTimer)/animationTimerMax)
        love.graphics.draw(assets.titleLift, 0, y)

        -- draw title screen
        love.graphics.draw(assets.titleText, 6, 19)
        if textBlink then
            love.graphics.draw(assets.titleStartText, 31, 77)
        end
    elseif gamestate == 3 then
        -- intro
        -- spin and scale the image around the center
        local timer = love.timer.get("introCutscene")
        local animationTimer, animationTimerMax = timer.curr, timer.max

        local scale = 1.0*((animationTimerMax-animationTimer)/animationTimerMax)
        local angle = 360*((animationTimerMax-animationTimer)/animationTimerMax)
        love.graphics.draw(assets.intro, 104/2, 104/2, math.rad(angle), scale, scale, 104/2, 104/2)

        -- blink continue text
        if textBlink then
            love.graphics.draw(assets.continueText, 26, 90)
        end
    elseif gamestate == 4 then
        -- draw elements
        love.graphics.draw(assets.building, 0, 0)

        -- lift box
        love.graphics.draw(assets.box, lift.x, lift.y)

        -- draw 1 px white line from 1,6 and 8,6 to lift.y
        love.graphics.setLineWidth(1)
        love.graphics.line(2, 6, 2, lift.y)
        love.graphics.line(8, 6, 8, lift.y)

        -- draw passengers in lift
        -- set lift passenger colour to #828282
        love.graphics.setColor(love.math.colorFromBytes(130, 130, 130))
        local x, y, len = lift.x+2, lift.y+3, #lift.passengers
        if len > 0 then
            -- iterate to len of people
            for a = 1, len do
                love.graphics.draw(assets.people[lift.passengers[a][2]], x, y)
                x = x + 2
            end
        end
        -- reset color
        love.graphics.setColor(1, 1, 1)

        -- iterate floors
        for i, v in ipairs(floors.passengers) do
            local x, y, len = floors[i][1], floors[i][2], #v

            if len > 0 then
                -- iterate to len of people
                for a = 1, len do
                    -- get wait timer for this passenger
                    local timer = floors.timers[i][a]
                    -- get colour range between green and red based on timer, where green is floors.timerMax and red is 0
                    local r, g = 1 - (1 * (timer / floors.timerMax)), (1 * (timer / floors.timerMax))
                    -- set colour
                    love.graphics.setColor(r, g, 0)
                    -- draw passenger
                    love.graphics.draw(assets.people[v[a]], x, y)
                    -- reset colour
                    love.graphics.setColor(1, 1, 1)
                    -- increment x
                    x = x + 2
                end
            end
        end

        -- get list of requested floors from passengers in lift
        local reqFloors = {false, false, false, false, false}
        -- iterate to len of people
        for i, v in ipairs(lift.passengers) do
            local req = v[1]
            reqFloors[req] = true
        end

        -- iterate reqFloors
        for i, req in ipairs(reqFloors) do
            if req then
                -- get x, y from requestedFloors
                local x, y = requestedFloors[i][3], requestedFloors[i][4]
                -- draw 3x2 white rectangle below number
                love.graphics.rectangle("fill", x, y+7, 3, 2)
            end
        end

        -- iterate requestedFloors
        for i, v in ipairs(requestedFloors) do
            local hov, que, x, y = v[1], v[2], v[3], v[4]

            -- if requested, draw number black with white background
            if hov or que then
                -- draw a white background
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", x-1, y-1, 5, 7)

                -- draw the number in black
                love.graphics.setColor(0, 0, 0)
                love.graphics.draw(assets.numbers[i], x, y)

                love.graphics.setColor(1, 1, 1)   -- reset colour
            else
                love.graphics.draw(assets.numbers[i], x, y)
            end
        end

        love.graphics.draw(assets.panel, 31, 15)

        -- draw score text
        love.graphics.draw(assets.scoreText, 32, 2)
        -- translate lift.score to string
        local score = tostring(lift.score)
        -- iterate to len of score
        for i = 1, #score do
            -- draw the number
            love.graphics.draw(assets.numbers[tonumber(string.sub(score, i, i))], 32+((i-1)*4), 8)
        end
    elseif gamestate == 5 then
        -- game over
        -- spin and scale the image around the center
        local timer = love.timer.get("gameoverCutscene")
        local animationTimer, animationTimerMax = timer.curr, timer.max

        local scale = 1.0*((animationTimerMax-animationTimer)/animationTimerMax)
        local angle = 360*((animationTimerMax-animationTimer)/animationTimerMax)
        love.graphics.draw(assets.gameover, 104/2, 104/2, math.rad(angle), scale, scale, 104/2, 104/2)

        -- blink continue text
        if textBlink then
            love.graphics.draw(assets.continueText, 26, 90)
        end
    elseif gamestate == 6 then
        -- draw final score
        -- draw score text (scaled to fit 104x104)
        love.graphics.draw(assets.scoreText, 38, 27, 0, 2, 2)

        -- translate lift.score to string
        local score = tostring(lift.score)
        -- if score is less than 3 digits, add 0s to the start
        if #score < 3 then
            for i = 1, 3-#score do
                score = "0"..score
            end
        end
        -- center score on x axis
        local w = 8
        local y = 39
        local x = 104/2 - (#score*w)/2
        -- iterate to len of score
        for i = 1, #score do
            -- draw the number (scaled to fit 104x104)
            love.graphics.draw(assets.numbers[tonumber(string.sub(score, i, i))], x+((i-1)*w), y, 0, 2, 2)
        end

        -- blink continue text
        if textBlink then
            love.graphics.draw(assets.continueTextWhite, 26, 90)
        end
    end

    love.graphics.setCanvas()
    if gamestate == 1 or gamestate == 4 then
        -- scale gameCanvas to fit window and draw
        local scale_y, scale_x = love.graphics.getHeight() / gameCanvas:getHeight(), love.graphics.getWidth() / gameCanvas:getWidth()
        -- if scale_y is less than scale_x, use scale_y
        if scale_y < scale_x then
            scale_x = scale_y
        else
            scale_y = scale_x
        end
        -- center the gameCanvas
        love.graphics.translate((love.graphics.getWidth() - (gameCanvas:getWidth() * scale_x)) / 2, (love.graphics.getHeight() - (gameCanvas:getHeight() * scale_y)) / 2)
        love.graphics.draw(gameCanvas, 0, 0, 0, scale_x, scale_y)
    elseif gamestate == 2 or gamestate == 3 or gamestate == 5 or gamestate == 6 then
        -- scale cutsceneCanvas to fit window and draw
        local scale_y, scale_x = love.graphics.getHeight() / cutsceneCanvas:getHeight(), love.graphics.getWidth() / cutsceneCanvas:getWidth()
        -- if scale_y is less than scale_x, use scale_y
        if scale_y < scale_x then
            scale_x = scale_y
        else
            scale_y = scale_x
        end
        -- center the cutsceneCanvas
        love.graphics.translate((love.graphics.getWidth() - (cutsceneCanvas:getWidth() * scale_x)) / 2, (love.graphics.getHeight() - (cutsceneCanvas:getHeight() * scale_y)) / 2)
        love.graphics.draw(cutsceneCanvas, 0, 0, 0, scale_x, scale_y)
    end

    if debug then
        -- fps
        love.graphics.print("FPS: "..love.timer.getFPS(), 10, 10)
    end
end

function love.update(dt)
    love.audio.update()
    love.timer.update(dt, gamestate)

    -- mute stop bgm if mute is true and bgm is playing
    if mute and bgm:isPlaying() then
        love.audio.stop(bgm)
    -- unmute bgm if mute is false and bgm is not playing and gamestate is not game over
    elseif not mute and not bgm:isPlaying() and (gamestate ~= 5 and gamestate ~= 6) then
        love.audio.play(bgm)
    end

    if gamestate == 4 then
        -- iterate floor passengers
        for i, v in ipairs(floors.timers) do
            if #v > 0 then  -- if passengers waiting
                -- decrease all wait timers on that floor
                for a=1, #v do
                    -- reduce timer
                    floors.timers[i][a] = floors.timers[i][a] - dt

                    -- if timer < 0, flag for game end
                    if floors.timers[i][a] < 0 then
                        gamestate = 5   -- game over state
                        if not mute then
                            -- pause bgm
                            love.audio.stop(bgm)
                            -- play game over sfx
                            love.audio.play(sfx.powerdown)
                        end
                    end
                end
            end
        end

        -- if lift.floorTimer has a value > 0
        local activeFloorTimer = false
        for i, v in ipairs(lift.floorTimer) do
            if v > 0 then
                -- decrement lift.floorTimer
                lift.floorTimer[i] = lift.floorTimer[i] - dt

                -- if lift.floorTimer reaches 0, perform action
                if lift.floorTimer[i] <= 0 then
                    -- set to 0
                    lift.floorTimer[i] = 0

                    -- if i == 2, remove passengers intended for this floor
                    if i == 2 then
                        local offloaded = OffloadPassengers()

                        if offloaded == true and not mute then
                            -- play sfx
                            love.audio.play(sfx.ding)
                        end
                    end

                    -- if i == 3, add passengers waiting on this floor to total lift.maxload
                    if i == 3 then
                        AddPassengers()
                    end
                end

                activeFloorTimer = true
                break -- only decrement one timer per update
            end
        end

        -- if not busy at floor, and lift.queue has a value, move lift
        if not activeFloorTimer and #lift.queue > 0 then
            lift.moveTimer = lift.moveTimer - dt

            -- get destination floor
            local dest = lift.queue[1]
            -- get target y from dest index in lift.destinations
            local y = lift.destinations[dest][2]

            -- if lift.moveTimer reaches 0, move lift
            if lift.moveTimer <= 0 then
                -- reset lift.moveTimer
                lift.moveTimer = lift.moveTimerMax

                -- if lift is above floor y, move lift down, else move lift up
                if lift.y > y then
                    lift.y = lift.y - 1
                elseif lift.y < y then
                    lift.y = lift.y + 1
                end

                -- if lift reaches destination, remove destination from queue
                if lift.y == y then
                    -- lookup current floor using index that matches current lift.y
                    lift.floor = dest

                    table.remove(lift.queue, 1)

                    -- remove que from requestedFloors
                    requestedFloors[lift.floor][2] = false

                    -- copy lift.floorTimerMax to lift.floorTimer
                    for i, v in ipairs(lift.floorTimerMax) do
                        lift.floorTimer[i] = v
                    end

                    activeFloorTimer = true -- don't load passengers on first frame of lift arriving at floor
                end
            end
        end

        -- if lift is idle, load passengers
        if not activeFloorTimer and #lift.queue == 0 then
            AddPassengers()
        end
    end
end

function love.mousemoved( x, y, dx, dy, istouch )
    -- get relative mouse position within 52x52 gameCanvas, accounting for scaling and centering
    local scale_y, scale_x = love.graphics.getHeight() / gameCanvas:getHeight(), love.graphics.getWidth() / gameCanvas:getWidth()
    -- if scale_y is less than scale_x, use scale_y
    if scale_y < scale_x then
        scale_x = scale_y
    else
        scale_y = scale_x
    end
    -- center the gameCanvas
    local x = (x - ((love.graphics.getWidth() - (gameCanvas:getWidth() * scale_x)) / 2)) / scale_x
    local y = (y - ((love.graphics.getHeight() - (gameCanvas:getHeight() * scale_y)) / 2)) / scale_y

    if gamestate == 4 then
        -- check if mouse is in bounding boxes of panel numbers
        for i, v in ipairs(requestedFloors) do
            local hov, que, bx, by = v[1], v[2], v[3], v[4]

            -- if mouse is in bounding box, set hov to true
            if x >= bx and x <= bx+5 and y >= by and y <= by+7 then
                requestedFloors[i][1] = true
            else
                requestedFloors[i][1] = false
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    -- get relative mouse position within 52x52 gameCanvas, accounting for scaling and centering
    local scale_y, scale_x = love.graphics.getHeight() / gameCanvas:getHeight(), love.graphics.getWidth() / gameCanvas:getWidth()
    -- if scale_y is less than scale_x, use scale_y
    if scale_y < scale_x then
        scale_x = scale_y
    else
        scale_y = scale_x
    end
    -- center the gameCanvas
    local x = (x - ((love.graphics.getWidth() - (gameCanvas:getWidth() * scale_x)) / 2)) / scale_x
    local y = (y - ((love.graphics.getHeight() - (gameCanvas:getHeight() * scale_y)) / 2)) / scale_y

    if gamestate == 2 then
        gamestate = 3
    elseif gamestate == 3 then
        gamestate = 4
    elseif gamestate == 4 then
        -- check if mouse is in bounding boxes of panel numbers
        for i, v in ipairs(requestedFloors) do
            local hov, que, bx, by = v[1], v[2], v[3], v[4]

            -- if mouse is in bounding box, set queued to true
            if x >= bx and x <= bx+5 and y >= by and y <= by+7 then
                requestedFloors[i][2] = true

                -- add floor to queue
                table.insert(lift.queue, i)
            end
        end
    elseif gamestate == 5 then
        gamestate = 6
    elseif gamestate == 6 then
        -- reset to title screen
        Reset()
        gamestate = 2
    end
end

function love.keypressed(k)
    if k == "escape" then
        love.event.quit()
    elseif k == "f1" then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif k == "f3" then
        -- toggle debug
        debug = not debug
    elseif k == "m" then
        -- toggle mute
        mute = not mute
    elseif k == "r" then
        -- reset to title screen
        Reset()
        gamestate = 2
    end
    if gamestate ~= 1 and debug then
        if k == "2" then
            gamestate = 2
        elseif k == "3" then
            gamestate = 3
        elseif k == "4" then
            gamestate = 4
        elseif k == "5" then
            gamestate = 5
        elseif k == "6" then
            gamestate = 6
        end
    end
end

function SpawnPassenger()
    -- get a random floor
    local i = math.random(1, 5)

    local len = #floors.passengers[i]

    -- if floor is not full, add a person
    if len < 4 then
        -- get a random person
        local person = math.random(1, 4)

        -- add person to floor
        table.insert(floors.passengers[i], person)
        -- add wait timer
        table.insert(floors.timers[i], floors.timerMax)
    end
end

function AddPassengers()
    local floorPassengers = floors.passengers[lift.floor]
    local len = #floorPassengers

    if len > 0 then
        for i = 1, len do
            -- if lift.currload < lift.maxload, add passenger to lift
            if lift.currload < lift.maxload then
                -- add passenger to lift
                lift.currload = lift.currload + 1

                -- select a random destination floor that is not the current floor
                local dest = math.random(1, 5)
                while dest == lift.floor do
                    dest = math.random(1, 5)
                end

                local passenger = {dest, floorPassengers[1]}

                table.insert(lift.passengers, passenger)

                -- remove passenger from floor
                table.remove(floors.passengers[lift.floor], 1)
                -- remove timer from floor
                table.remove(floors.timers[lift.floor], 1)
            else
                break -- end loop if lift is full
            end
        end
    end
end

function OffloadPassengers()
    -- new table to hold passengers that are not offloading
    local newPassengers = {}
    local offloaded = false -- flag for if a passenger is delivered

    -- iterate lift.passengers
    for i, v in ipairs(lift.passengers) do
        local dest = v[1]
        -- if dest == lift.floor, remove passenger
        if dest == lift.floor then
            lift.currload = lift.currload - 1
            lift.score = lift.score + 1
            offloaded = true
        else
            -- add passenger to newPassengers
            table.insert(newPassengers, v)
        end
    end

    lift.passengers = {}

    -- copy newPassengers to lift.passengers
    for i, v in ipairs(newPassengers) do
        lift.passengers[i] = v
    end

    return offloaded
end