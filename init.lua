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

local function isWindowMaximized(frame, maxFrame)
    return frame.x == maxFrame.x and frame.y == maxFrame.y and
           frame.w == maxFrame.w and frame.h == maxFrame.h
end

-- Internal function to resize the window
local function calculateHorizontalResize(frame, maxFrame, dw, edges)
    local newWidth = frame.w
    local newX = frame.x

    if dw == 0 then
        -- No horizontal resizing
        return newWidth, newX
    end

    local isMaximized = isWindowMaximized(frame, maxFrame)
    if not isMaximized and edges.left and edges.right then
        -- Can't resize horizontally if both edges are at margins
        return newWidth, newX
    elseif not isMaximized and edges.left then
        -- Left edge fixed, expand right only
        newWidth = frame.w + dw
    elseif not isMaximized and edges.right then
        -- Right edge fixed, expand left only
        newWidth = frame.w + dw
        newX = frame.x - dw
    else
        -- Normal case, expand from center
        newWidth = frame.w + dw
        newX = frame.x - (dw / 2)
    end

    return newWidth, newX
end

local function calculateVerticalResize(frame, maxFrame, dh, edges)
    local newHeight = frame.h
    local newY = frame.y

    if dh == 0 then
        -- No vertical resizing
        return newHeight, newY
    end

    local isMaximized = isWindowMaximized(frame, maxFrame)
    if not isMaximized and edges.top and edges.bottom then
        -- Can't resize vertically if both edges are at margins
        return newHeight, newY
    elseif not isMaximized and edges.top then
        -- Top edge fixed, expand bottom only
        newHeight = frame.h + dh
    elseif not isMaximized and edges.bottom then
        -- Bottom edge fixed, expand top only
        newHeight = frame.h + dh
        newY = frame.y - dh
    else
        -- Normal case, expand from center
        newHeight = frame.h + dh
        newY = frame.y - (dh / 2)
    end

    return newHeight, newY
end

local function enforceFrameBoundaries(frame, maxFrame)
    local newFrame = {
        w = math.max(50, frame.w), -- Minimum width
        h = math.max(50, frame.h), -- Minimum height
        x = frame.x,
        y = frame.y
    }

    -- Enforce screen boundaries with margins
    if newFrame.x < maxFrame.x then newFrame.x = maxFrame.x end
    if newFrame.y < maxFrame.y then newFrame.y = maxFrame.y end
    if newFrame.x + newFrame.w > maxFrame.x + maxFrame.w then
        newFrame.w = maxFrame.x + maxFrame.w - newFrame.x
    end
    if newFrame.y + newFrame.h > maxFrame.y + maxFrame.h then
        newFrame.h = maxFrame.y + maxFrame.h - newFrame.y
    end

    return newFrame
end

local function resizeWindow(dw, dh)
    local win, screen = getFocusedWindowAndScreen()
    if not win then return end

    local maxFrame = getMaxFrame(screen, obj.margin)
    local f = win:frame()

    -- Calculate new dimensions based on edge constraints
    local edges = edgesAtMargins(f, maxFrame)

    -- Calculate new dimensions
    local newWidth, newX = calculateHorizontalResize(f, maxFrame, dw, edges)
    local newHeight, newY = calculateVerticalResize(f, maxFrame, dh, edges)

    local newFrame = {
        w = newWidth,
        h = newHeight,
        x = newX,
        y = newY
    }

    -- Enforce boundaries
    newFrame = enforceFrameBoundaries(newFrame, maxFrame)

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

local function toggleMaximizeFocusedWindow()
    local win, screen = getFocusedWindowAndScreen()
    if not win then return end

    local maxFrame = getMaxFrame(screen, obj.margin)
    local id, frame = win:id(), win:frame()

    if isWindowMaximized(frame, maxFrame) and previousWindowFrames[id] then
        win:setFrame(previousWindowFrames[id], 0)
        previousWindowFrames[id], previousWindowScreens[id] = nil, nil
    else
        previousWindowFrames[id], previousWindowScreens[id] = frame, screen:id()
        win:setFrame(maxFrame, 0)
    end
end

local function bindHotkeyWithRepeat(modifiers, key, pressFn, ...)
    local args = {...}
    hs.hotkey.bind(modifiers, key, function() pressFn(table.unpack(args)) end, nil, function() pressFn(table.unpack(args)) end)
end

function obj:start()
    -- Bind hotkeys to move window
    bindHotkeyWithRepeat({ "ctrl", "alt" }, "h", moveWindow, -obj.moveStep, 0)
    bindHotkeyWithRepeat({ "ctrl", "alt" }, "l", moveWindow, obj.moveStep, 0)
    bindHotkeyWithRepeat({ "ctrl", "alt" }, "k", moveWindow, 0, -obj.moveStep)
    bindHotkeyWithRepeat({ "ctrl", "alt" }, "j", moveWindow, 0, obj.moveStep)
    -- Bind hotkeys to resize windows
    bindHotkeyWithRepeat({"alt", "shift"}, "=", resizeWindow, obj.resizeStep, obj.resizeStep)
    bindHotkeyWithRepeat({"alt", "shift"}, "-", resizeWindow, -obj.resizeStep, -obj.resizeStep)

    -- Bind hotkey to toggle maximize
    hs.hotkey.bind({"alt"}, "f", toggleMaximizeFocusedWindow)

    return self
end

return obj

