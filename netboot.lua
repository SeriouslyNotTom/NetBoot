tArgs = {...}
modes = {}

component = require("component")
computer = require("computer")
modem = component.modem
modem.open(64)

Commands = {UPLOAD = 130, EXECUTE = 131, FLASH = 132}
Responses = {[140]="UPLOAD_RESPONSE",[141]="EXECUTE_RESPONSE",[142]="FLASH_RESPONSE",[160]="STARTUP"}
Constants = {DELIMETER=150}

function WaitFor(thing)
    repeat
        ev,component,sender,channel,distance,message = computer.pullSignal()
        if(ev=="modem_message") then
            command = string.byte(string.sub(message,1,1))
        end
    until ev=="modem_message" and command~=nil and command>=130 and command<=170
    print(message)
end

function ReadFile(path)
    fl = io.open(path,"r")
    size = fl.stream:seek("end",0)
    fl.stream:seek("set",0)
    if not fl then return error("file does not exist") end
    data = fl:read("*a")
    fl:close()
    return data,size
end

modes.upload = function(tArgs)
    if not tArgs[2] then return error("please specify file for upload") end
    data = ReadFile(tArgs[2])
    modem.broadcast(64,string.char(Commands.UPLOAD)..data)
    WaitFor()
    modem.broadcast(64,string.char(Commands.EXECUTE))
    WaitFor()
end

modes.flash = function(tArgs)
    if not tArgs[2] then return error("please specify file for flashing") end
    data,size = ReadFile(tArgs[2])
    if size>(1024*4) then return error("Bios cannot be over 4 Kilobytes in length") end
    modem.broadcast(64,string.char(Commands.FLASH)..data)
    WaitFor()
end

modeSelected = tArgs[1]
if(modes[modeSelected]==nil) then
    print("please select mode")
else
    modes[modeSelected](tArgs)
end

