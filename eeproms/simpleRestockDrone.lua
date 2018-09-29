-- Drone to simply handle restocking using a list of apiaries

modem = component.proxy(component.list("modem"){})
inv = component.proxy(component.list("inventory_controller"){})

beePort = 25
modem.open(beePort)

function move(X, Y, Z)
    drone.move(X,Y,Z)
    while drone.getOffset() > 0.02 and drone.getVelocity() > 0.02 do
        computer.pullSignal(1)
    end
end

function receiveCoords()
    msgType,_,_,_,_,X = computer.pullSignal(20)
    msgType,_,_,_,_,Y = computer.pullSignal(20)
    msgType,_,_,_,_,Z = computer.pullSignal(20)
    coords = {X,Y,Z}
    return coords
end

function restock()
    local nSlots = 8
    local side = 0
    -- empty apiary and refill apiary
    for iSlot = 1,nSlots do
        drone.select(iSlot)
        if inv.getStackInSlot(0,iSlot) ~= nil then
            inv.suckFromSlot(0,iSlot)
        end
        inv.dropIntoSlot(0, iSlot)
    end
end

-- main loop
coordList = {}
while true do
    --listen for new coords
    drone.setStatusText("Listening...")
    modem.broadcast(beePort, "listening")
    newCoords = receiveCoords()
    if newCoords ~= nil then
        table.insert(coordList, newCoords)
    end
    drone.setStatusText("Working")
    -- restock every entry
    if coordList ~= nil then
        for coord in coordList do
            move(coord[1], coord[2], coord[3])
            restock()
            move(-coord[1], -coord[2], -coord[3])
        end
    end
end