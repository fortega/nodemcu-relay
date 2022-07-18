-- constants

PINS = {5, 4, 0, 2};
MAX_UPTIME = 86400
ON_TIME = 61200
OFF_TIME = 39600
STATE_ON = gpio.LOW
STATE_OFF = gpio.HIGH

-- variables

local uptime = 0
local states = {STATE_OFF, STATE_OFF, STATE_OFF, STATE_OFF}

-- logic

function calcStates()
    local state
    if ((uptime < OFF_TIME) or (uptime > ON_TIME)) then
        state = STATE_ON
    else
        state = STATE_OFF
    end

    states[1] = state
    states[2] = state
    states[3] = state
    states[4] = state
end

-- system io

function writeState(pin)
    print(PINS[pin], states[pin])
    gpio.write(PINS[pin], states[pin])
end

function setupPin(pin)
    gpio.mode(PINS[pin], gpio.OUTPUT)
end

-- Wifi

function setupWifi()
    wifi.setmode(wifi.SOFTAP)
    result = wifi.ap.config({
        ssid = "NodeRelay",
        pwd = "12345678",
        auth = wifi.WPA2_PSK
    })
end

-- api

function buildResponse(json)
    return string.format("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\n\r\n%s",
        string.len(json), json)
end

function setupApi()
    srv = net.createServer(net.TCP)
    srv:listen(80, function(conn)
        conn:on("receive", function(conn, payload)
            new_uptime = payload:match "GET /([0-9]+) HTTP/"
            if (new_uptime ~= nil) then
                uptime = tonumber(new_uptime)
            end

            response = buildResponse(string.format("{\"uptime\": %d}", uptime))
            conn:send(response)
        end)
    end)
end

-- timer

function tick()
    calcStates()
    foreach(writeState)

    uptime = (uptime + 1) % MAX_UPTIME
end

function startTimer()
    timer = tmr.create()
    timer:register(1000, tmr.ALARM_AUTO, tick)
    timer:start()
end

-- utils

function foreach(f)
    for i = 1, 4, 1 do
        f(i)
    end
end

function setup()
    setupWifi()
    setupApi()
    foreach(setupPin)
    foreach(writeState)
end

-- setup and start

setup()
startTimer()
