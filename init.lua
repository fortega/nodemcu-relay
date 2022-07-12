pins = {5, 4, 0, 2};
state = gpio.HIGH
uptime = 0
max_uptime = 86400
switch_time = 64800

function writeState(pin)
    gpio.write(pin, state)
end

function setupPin(pin)
    gpio.mode(pin, gpio.OUTPUT)
end

function setupWifi()
    wifi.setmode(wifi.SOFTAP)
    result = wifi.ap.config({
        ssid = "NodeRelay",
        pwd = "12345678",
        auth = wifi.WPA2_PSK
    })
end

function buildResponse(json)
    return string.format("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\n\r\n%s",
        string.len(json), json)
end

function setupApi()
    srv = net.createServer(net.TCP)
    srv:listen(80, function(conn)
        conn:on("receive", function(conn, payload)
            new_uptime = payload: match "GET /([0-9]+) HTTP/"
            if(new_uptime ~= nil)
            then
                print("new uptime:", new_uptime)
                uptime = tonumber(new_uptime)
            end
            
            response = buildResponse(string.format("{\"uptime\": %d}", uptime))
            conn:send(response)
        end)
    end)
end

function foreach(f)
    for i = 1, 4, 1 do
        f(i)
    end
end

function switchState()
    turnon = (uptime < switch_time)

    if (turnon) then
        state = gpio.HIGH
    else
        state = gpio.LOW
    end
    foreach(writeState)

    uptime = (uptime + 1) % max_uptime
end

function setup()
    setupWifi()
    setupApi()
    foreach(setupPin)
    foreach(writeState)

    timer = tmr.create()
    timer:register(1000, tmr.ALARM_AUTO, switchState)
    timer:start()
end

setup()
