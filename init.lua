--- Move the focused window using keyboard shortcuts

local obj = {}
obj.__index = obj
obj.name = "MoveWindow"

-- Configurable step size
obj.moveStep = 10
obj.margin = 8
obj.resizeStep = 20 -- How many pixels to grow/shrink in each direction

-- Helper functions for window operations
local function getMaxFrame(screen, margin)
    local screenFrame = screen:frame()
    return {
        x = screenFrame.x + margin,
        y = screenFrame.y + margin,
        w = screenFrame.w - (margin * 2),
        h = screenFrame.h - (margin * 2)
    }
end

local function isValidWindow(win)
    if win and win:isStandard() and not win:isFullScreen() then 
        return win:id() and win:frame().w >= 50 and win:frame().h >= 50
    end
    return false
end

local function getFocusedWindowAndScreen()
    local win = hs.window.focusedWindow()
    if not isValidWindow(win) then return nil, nil end
    
    local screen = win:screen()
    if not screen then return nil, nil end
    
    return win, screen
end

-- Internal function to move the window
local function moveWindow(dx, dy)
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:frame()
    f.x = f.x + dx
    f.y = f.y + dy
    win:setFrame(f, 0) -- no animation
end

-- Functions to check if window edges are at margins
local function edgesAtMargins(frame, maxFrame)
    return {
        left = math.abs(frame.x - maxFrame.x) < 2,
        right = math.abs((frame.x + frame.w) - (maxFrame.x + maxFrame.w)) < 2,
        top = math.abs(frame.y - maxFrame.y) < 2,
        bottom = math.abs((frame.y + frame.h) - (maxFrame.y + maxFrame.h)) < 2
    }
end

-- Internal function to resize the window
local function resizeWindow(dw, dh)
    local win, screen = getFocusedWindowAndScreen()
    if not win then return end
    
    local maxFrame = getMaxFrame(screen, obj.margin)
    local f = win:frame()
    
    -- Calculate new dimensions based on edge constraints
    local edges = edgesAtMargins(f, maxFrame)
    local newFrame = {
        w = f.w,
        h = f.h,
        x = f.x,
        y = f.y
    }
    
    -- Handle horizontal resizing
    if dw ~= 0 then
        if edges.left and edges.right then
            -- Can't resize horizontally if both edges are at margins
        elseif edges.left then
            -- Left edge fixed, expand right only
            newFrame.w = f.w + dw
        elseif edges.right then
            -- Right edge fixed, expand left only
            newFrame.w = f.w + dw
            newFrame.x = f.x - dw
        else
            -- Normal case, expand from center
            newFrame.w = f.w + dw
            newFrame.x = f.x - (dw / 2)
        end
    end
    
    -- Handle vertical resizing
    if dh ~= 0 then
        if edges.top and edges.bottom then
            -- Can't resize vertically if both edges are at margins
        elseif edges.top then
            -- Top edge fixed, expand bottom only
            newFrame.h = f.h + dh
        elseif edges.bottom then
            -- Bottom edge fixed, expand top only
            newFrame.h = f.h + dh
            newFrame.y = f.y - dh
        else
            -- Normal case, expand from center
            newFrame.h = f.h + dh
            newFrame.y = f.y - (dh / 2)
        end
    end
    
    -- Enforce minimum size
    newFrame.w = math.max(50, newFrame.w)
    newFrame.h = math.max(50, newFrame.h)
    
    -- Final boundary checks
    if newFrame.x < maxFrame.x then newFrame.x = maxFrame.x end
    if newFrame.y < maxFrame.y then newFrame.y = maxFrame.y end
    if newFrame.x + newFrame.w > maxFrame.x + maxFrame.w then
        newFrame.w = maxFrame.x + maxFrame.w - newFrame.x
    end
    if newFrame.y + newFrame.h > maxFrame.y + maxFrame.h then
        newFrame.h = maxFrame.y + maxFrame.h - newFrame.y
    end
    
    -- Apply the new frame
    win:setFrame(newFrame, 0) -- no animation
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
    return isValidWindow(win)
end

function obj:toggleMaximizeFocusedWindow()
    local win, screen = getFocusedWindowAndScreen()
    if not win then return end
    
    local maxFrame = getMaxFrame(screen, self.margin)
    local id, frame = win:id(), win:frame()
    
    if self:isWindowMaximized(frame, maxFrame) and previousWindowFrames[id] then
        win:setFrame(previousWindowFrames[id], 0)
        previousWindowFrames[id], previousWindowScreens[id] = nil, nil
    else
        previousWindowFrames[id], previousWindowScreens[id] = frame, screen:id()
        win:setFrame(maxFrame, 0)
    end
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

return obj

