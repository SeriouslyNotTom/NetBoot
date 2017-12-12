VERSION = "NetBios 2.1.1"

c = component
invoke = c.invoke

modem = c.proxy(c.list("modem")())
eeprom = c.proxy(c.list("eeprom")())

CHANNEL=64
KEY=""
SERVER=""

PBuff = ""

modem.open(CHANNEL)

code = function() end

function LoadCode(msg) PBuff=""..string.sub(msg,2,string.len(msg)) code = load("do component = c "..PBuff.." end","=code") end
function send(rec,msg) modem.broadcast(64,msg) end
function FlashEEPROM(msg) return eeprom.set(string.sub(msg,2,string.len(msg))) end

function Exec()
  pass,result = pcall(function() return code() end)
  return tostring(pass)..string.char(150)..tostring(result)
end

function input(sender,msg)
  cmd = string.byte(string.sub(msg,1,1))
  if(cmd==130)then LoadCode(msg) send(sender,string.char(140)) end
  if(cmd==131)then send(sender,string.char(141)..Exec()) end
  if(cmd==132)then FlashEEPROM(msg) send(sender,string.char(142)) computer.shutdown(true) end
end

send(1,string.char(160))

while true do
  repeat
  event,component,sender,channel,distance,message = computer.pullSignal()  
  until event=="modem_message" and message
  
  cmd = string.byte(string.sub(message,1,1))

  if(cmd>=130 and cmd<=170) then
    input(sender,message)
  end
end