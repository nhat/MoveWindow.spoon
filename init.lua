--- Move the focused window using keyboard shortcuts

local obj = {}
obj.__index = obj
obj.name = "MoveWindow"

-- Configurable step size
obj.moveStep = 10
obj.margin = 8
obj.resizeStep = 20 -- How many pixels to grow/shrink in each direction

-- Internal function to move the window
local function moveWindow(dx, dy)
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:frame()
    f.x = f.x + dx
    f.y = f.y + dy
    win:setFrame(f, 0) -- no animation
end

-- Internal function to resize the window
local function resizeWindow(dw, dh)
    local win = hs.window.focusedWindow()
    if not win then return end
    
    local screen = win:screen()
    if not screen then return end
    
    local screenFrame = screen:frame()
    local maxFrame = {
        x = screenFrame.x + obj.margin,
        y = screenFrame.y + obj.margin,
        w = screenFrame.w - (obj.margin * 2),
        h = screenFrame.h - (obj.margin * 2)
    }
    
    local f = win:frame()
    -- Calculate new dimensions
    local newWidth = f.w + dw
    local newHeight = f.h + dh
    local newX = f.x - (dw / 2)
    local newY = f.y - (dh / 2)
    
    -- Enforce minimum size
    newWidth = math.max(50, newWidth)
    newHeight = math.max(50, newHeight)
    
    -- Respect the maximum frame with margins
    if newX < maxFrame.x then newX = maxFrame.x end
    if newY < maxFrame.y then newY = maxFrame.y end
    if newX + newWidth > maxFrame.x + maxFrame.w then
        newWidth = maxFrame.x + maxFrame.w - newX
    end
    if newY + newHeight > maxFrame.y + maxFrame.h then
        newHeight = maxFrame.y + maxFrame.h - newY
    end
    
    -- Apply the new frame
    f.w = newWidth
    f.h = newHeight
    f.x = newX
    f.y = newY
    win:setFrame(f, 0) -- no animation
end

--- WindowMover:start()
--- Method
--- Binds hotkeys for moving the window.
function obj:start()
    hs.hotkey.bind({ "ctrl", "alt" }, "h", function() moveWindow(-obj.moveStep, 0) end, nil, function() moveWindow(-obj.moveStep, 0) end)
    hs.hotkey.bind({ "ctrl", "alt" }, "l", function() moveWindow(obj.moveStep, 0) end, nil, function() moveWindow(obj.moveStep, 0) end)
    hs.hotkey.bind({ "ctrl", "alt" }, "k", function() moveWindow(0, -obj.moveStep) end, nil, function() moveWindow(0, -obj.moveStep) end)
    hs.hotkey.bind({ "ctrl", "alt" }, "j", function() moveWindow(0, obj.moveStep) end, nil, function() moveWindow(0, obj.moveStep) end)

    -- Hotkey to toggle maximize
    hs.hotkey.bind({"alt"}, "f", function() obj:toggleMaximizeFocusedWindow() end)
    
    -- Hotkeys for resizing (made repeatable)
    hs.hotkey.bind({"alt", "shift"}, "=", function() resizeWindow(obj.resizeStep, obj.resizeStep) end, nil, function() resizeWindow(obj.resizeStep, obj.resizeStep) end)
    hs.hotkey.bind({"alt", "shift"}, "-", function() resizeWindow(-obj.resizeStep, -obj.resizeStep) end, nil, function() resizeWindow(-obj.resizeStep, -obj.resizeStep) end)

    return self
end

-- === Maximize Toggle Feature ===
local previousWindowFrames = {}
local previousWindowScreens = {}

-- Clean up stored frames when a window is destroyed
hs.window.filter.default:subscribe(hs.window.filter.windowDestroyed, function(win)
    if win and win:id() then
        previousWindowFrames[win:id()] = nil
        previousWindowScreens[win:id()] = nil
    end
end)

function obj:isWindowMaximized(frame, maxFrame)
    return frame.x == maxFrame.x and frame.y == maxFrame.y and 
           frame.w == maxFrame.w and frame.h == maxFrame.h
end

function obj:isValidWindow(win)
    if win and win:isStandard() and not win:isFullScreen() then 
        return win:id() and win:frame().w >= 50 and win:frame().h >= 50
    else
        return false
    end
end

function obj:toggleMaximizeFocusedWindow()
    local win = hs.window.focusedWindow()
    if not self:isValidWindow(win) then return end

    local screen = win:screen()
    if not screen then return end

    local screenFrame = screen:frame()
    local maxFrame = {
        x = screenFrame.x + self.margin,
        y = screenFrame.y + self.margin,
        w = screenFrame.w - self.margin * 2,
        h = screenFrame.h - self.margin * 2
    }

    local id, frame = win:id(), win:frame()
    if self:isWindowMaximized(frame, maxFrame) and previousWindowFrames[id] then
        win:setFrame(previousWindowFrames[id], 0)
        previousWindowFrames[id], previousWindowScreens[id] = nil, nil
    else
        previousWindowFrames[id], previousWindowScreens[id] = frame, screen:id()
        win:setFrame(maxFrame, 0)
    end
end

return obj

