modem = component.proxy(component.list("modem")())
eeprom = component.proxy(component.list("eeprom")())

modem.open(4300)
x,y,z = string.match(eeprom.getLabel(),"([^,]+):([^,]+):([^,]+)")

while true do
    repeat    
      ev,comp,sender,channel,dist,msg = computer.pullSignal()
    until ev=="modem_message" and channel == 4300
    if(msg=="PING") then
      modem.broadcast(4300,"PONG:"..x..":"..y..":"..z)
    end
end