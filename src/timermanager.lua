do
    -- will hold the currently playing sources
    local timers = {}

    -- check for sources that finished playing and remove them
    -- add to love.update
    function love.timer.update(dt, gamestate)
        for _,s in pairs(timers) do
            if s.gamestate == gamestate then
                s.curr = s.curr - dt
                if s.curr < 0 then
                    if s.func then
                        s.func()
                    end
                    if s.loop then
                        s.curr = s.max
                    else
                        s.curr = 0
                    end
                end
            end
        end
    end

    -- create a named timer
    function love.timer.create(name, max, gamestate, loop, func)
        timers[name] = {curr = max, max = max, loop = loop or false, gamestate = gamestate, func = func or false}
    end

    -- clear all timers
    function love.timer.clear()
        timers = {}
    end

    -- value of a named timer
    function love.timer.value(name)
        return timers[name].curr
    end

    -- get named timer
    function love.timer.get(name)
        return timers[name]
    end
end