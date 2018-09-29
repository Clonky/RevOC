-- Manage apiaries using an opencomputers drone
-- Include components

inv = component.proxy(component.list("Inventory_Controller"){})
modem = component.proxy(component.list("Modem"){})
robot = component.proxy(component.list("Robot"){})

-- setup
beePort = 255
modem.open(beePort)

-- Idle until msg received

-- movement functions
function move(targetCoords)
    x = targetCoords[1]
    y = targetCoords[2]
    z = targetCoords[3]
    drone.move(x,y,z)
    while drone.getOffset() > 0.02 and drone.getVelocity > 0.02 do
        computer.pullSignal(1)
    end
end

-- apiary interaction functions
function clearApiary()
    -- clear out every slot in an apiary
    local nSlots = 8
    local side = 0
    for iSlot = 1,nSlots do
        drone.select(iSlot)
        if inv.getStackInSlot(side, iSlot) ~= nil then
            inv.suckFromSlot(0, iSlot)
        end
    end
end

function repopulate()
    -- fill in queen and drone slot
    local nSlots = 8
    local side = 0
    for iSlot = 1,nSlots do
        drone.select(iSlot)
        inv.dropIntoSlot(side,1)
        inv.dropIntoSlot(side,2)
    end
end
        

function restock()
    -- restocks currently hovered over apiary
    clearApiary()
    repopulate()
end

        
    
-- Network messages
function handshake(receivedMsg, senderAdress, port)
    -- confirm the received message with the sender
    modem.send(senderAdress, port, receivedMsg) -- send the previous msg to sender, confirm remotely
    hasAnswered = false
    while hasAnswered = false do
        local signalType,_,_,_,_,msg = computer.pullSignal()
        if signalType == "modem_message" and msg == "ok" then
            hasAnswered = true
            return true
        elseif signalType == "modem_message" and msg == "not ok" then
            hasAnswered = false
            return false
        end
    end
end


function parseinstructions(instructionType, senderAdress, port)
    -- Which instruction has been sent
    if instructionType == "restock"
        checkMsg = false
        while checkMsg == false do
            checkMsg = handshake("restock", senderAdress, port)
        end
        modem.send(senderAdress, port, "restock:coords") -- ask for coords
        -- receive X, Y and Z in single packages
        local _,_,_,_,_,X = computer.pullSignal()
        local _,_,_,_,_,Y = computer.pullSignal()
        local _,_,_,_,_,Z = computer.pullSignal()
        local coords = {X, Y, Z}
        move(coords)
        restock()
        local coords = {-X, -Y, -Z}
        move(coords)
    end
end

function waitforinstructions()
    -- Lie idle until you receive instructions
    hasReceived = false
    while hasReceived == false do
        local signalType,_,senderAdress,port,_,msg = computer.pullSignal()
        if signalType == "modem_message" then
            instructionType = msg
            completeInstruction = parseinstructions(instructionType, senderAdress, port)
            hasReceived = true
        end
    end
end

-- main loop

while true do
    waitforinstructions()
end