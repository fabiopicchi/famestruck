local ipairs = ipairs
local utils = require "utils"
local circularBuffer = require "circularBuffer"

local gamepad = {}
setfenv (1, gamepad)

local gamepadButtons = {
    "a",
    "b",
    "x",
    "y",
    "rightshoulder",
    "leftshoulder",
    "rightstick",
    "leftstick",
    "back",
    "guide",
    "start",
    "dpup",
    "dpdown",
    "dpright",
    "dpleft"
}

local gamepadAxes = {
    "leftx",
    "lefty",
    "rightx",
    "righty",
    "triggerleft",
    "triggerright"
}

-- Button state data structure
local ButtonState = utils.defineStruct ({pressed = false})

-- Axis state data structure
local AxisState = utils.defineStruct ({value = 0})

-- Gamepad state data structure
local GamepadState = utils.defineStruct (
function ()
    local instance = {}
    
    for i, value in ipairs(gamepadButtons) do
        instance[value] = ButtonState()
    end

    for i, value in ipairs(gamepadAxes) do
        instance[value] = AxisState()
    end
   
    return instance
end
)

Gamepad = utils.defineClass (
function (self, bufferSize, id)
    self.id = id
    local buffer = {}
    for i = 1, bufferSize do
        buffer[i] = GamepadState()
    end
    
    self.inputBuffer = circularBuffer.CircularBuffer(buffer)
end
)

function Gamepad:update()
    self.inputBuffer:insertElement (utils.copyTable(self.inputBuffer:head()))
end

function Gamepad:updateButton(button, buttonState)
    self.inputBuffer:head()[button].pressed = buttonState
end

function Gamepad:updateAxis(axis, axisValue)
    self.inputBuffer:head()[axis].value = axisValue
end

function Gamepad:buttonPressed(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 1 then frameTolerance = self.inputBuffer:size() - 1 end    

    for i, state in circularBuffer.iterator(self.inputBuffer) do
        if state[button].pressed then
            return true
        end

        frameTolerance = frameTolerance - 1
        if frameTolerance < 0 then break end
    end
    return false
end

function Gamepad:buttonJustPressed(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end    

    for i, state in circularBuffer.iterator(self.inputBuffer) do
        if state[button].pressed and not self.inputBuffer:element(i - 1)[button].pressed then
            return true
        end

        frameTolerance = frameTolerance - 1
        if frameTolerance < 0 then break end
    end
    return false
end

function Gamepad:buttonJustReleased(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end

    for i, state in circularBuffer.iterator(self.inputBuffer) do
        if not state[button].pressed and self.inputBuffer:element(i - 1)[button].pressed then
            return true
        end

        frameTolerance = frameTolerance - 1
        if frameTolerance < 0 then break end
    end
    return false
end

return gamepad
