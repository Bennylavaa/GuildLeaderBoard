-- Create a frame for displaying guild members
local frame = CreateFrame("Frame", "GuildListFrame", UIParent)
frame:SetSize(220, 250)  -- Decrease the height to 250 pixels
frame:SetScale(0.8)  -- Set the scale to 0.8
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Create a header for the frame
local header = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
header:SetPoint("TOP", 0, -10)  -- Position the header at the top of the frame
header:SetText("Guild Leader Board")  -- Set the text of the header

-- Create a backdrop for the frame (border)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", -- Set a background texture
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Set a border texture
    edgeSize = 16, -- Adjust the size of the border
    insets = {left = 4, right = 4, top = 4, bottom = 4}, -- Adjust the spacing between the frame and the border
})

-- Set the backdrop's color
frame:SetBackdropColor(0, 0, 0, 0.5) -- Background color (black with 50% transparency)
frame:SetBackdropBorderColor(0.4, 0.4, 0.4) -- Border color (gray)

-- Create a scroll frame for the list of guild members
local scrollFrame = CreateFrame("ScrollFrame", "GuildListScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -30)  -- Adjust the vertical position to leave space for the header
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)  -- Adjust the right padding to accommodate the border and scroll bar


-- Create a child frame for the scroll frame
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(200, 1)  -- Adjust the width to accommodate the border
scrollFrame:SetScrollChild(scrollChild)

-- Initialize members table
scrollChild.members = {}

local showOnlineOnly = false -- Initially set to false to show all members

-- Variable to track the state of the toggle button
local showOnlineOnly = false

-- Function to update the text of the toggle button based on its state
local function UpdateToggleButton()
    if toggleButton then
        if showOnlineOnly then
            toggleButton:SetText("Show All Members")
        else
            toggleButton:SetText("Show Online Only")
        end
    end
end

-- Function to update the guild member list based on the showOnlineOnly flag
local function UpdateGuildList()
    GuildRoster()
    -- Clear the existing list
    for _, playerNameButton in ipairs(scrollChild.members) do
        playerNameButton:Hide()
    end
    wipe(scrollChild.members)

    -- Get guild member info
    local guildMembers = {}
    local numGuildMembers = GetNumGuildMembers()
    local playerName = UnitName("player") -- Get your own character's name
    for i = 1, numGuildMembers do
        local name, _, _, level, _, _, _, _, online = GetGuildRosterInfo(i)
        if name and level then
            if not showOnlineOnly or online then
                table.insert(guildMembers, {name = name, level = level, online = online})
            end
        end
    end

    -- Sort the guild member list by level in descending order
    table.sort(guildMembers, function(a, b) return a.level > b.level end)

    -- Display guild member info
    local yOffset = -5
    for _, memberInfo in ipairs(guildMembers) do
        local playerNameButton = CreateFrame("Button", nil, scrollChild)
        playerNameButton:SetPoint("TOPLEFT", 5, yOffset)
        playerNameButton:SetSize(200, 20)  -- Adjust the size as needed
        playerNameButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        local playerNameText = playerNameButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        playerNameText:SetPoint("LEFT", 0, 0)
        playerNameText:SetText(memberInfo.name .. " - Level " .. memberInfo.level)
        playerNameText:SetFont(playerNameText:GetFont(), 16, "OUTLINE")
        if memberInfo.online then
            playerNameText:SetTextColor(0, 1, 0) -- Green color for online players
        else
            playerNameText:SetTextColor(1, 1, 1) -- White color for offline players
        end

        -- Check if the member's name matches your own name
        if memberInfo.name == playerName then
            playerNameText:SetTextColor(1, 0.82, 0) -- Set golden color for your own name
        end

        playerNameButton:SetScript("OnClick", function(self, button)
            if button == "LeftButton" then
                ChatFrame_OpenChat("/w " .. memberInfo.name .. " ", ChatFrame1)
            end
        end)

        table.insert(scrollChild.members, playerNameButton)
        yOffset = yOffset - 20
    end

    -- Update the scroll frame size
    scrollChild:SetSize(200, math.max(1, math.abs(yOffset) + 10))
end

-- Define toggleButton variable
local toggleButton

-- Function to toggle between showing only online members and updating the list
local function ToggleOnlineOnly()
    showOnlineOnly = not showOnlineOnly
    UpdateGuildList()  -- Update the guild member list based on the new value of showOnlineOnly
    if toggleButton then
        if showOnlineOnly then
            toggleButton:SetText("Show All")
        else
            toggleButton:SetText("Online Only")
        end
    end
end

-- Create a button to toggle showing only online members
toggleButton = CreateFrame("Button", "GuildListToggleButton", frame, "UIPanelButtonTemplate")
toggleButton:SetText("Online Only")
toggleButton:SetSize(100, 20)
toggleButton:SetPoint("BOTTOMLEFT", 10, 10)
toggleButton:SetScript("OnClick", ToggleOnlineOnly)

-- Create a button to manually update the list
local updateButton = CreateFrame("Button", "GuildListUpdateButton", frame, "UIPanelButtonTemplate")
updateButton:SetText("Update")
updateButton:SetSize(100, 20)
updateButton:SetPoint("BOTTOMRIGHT", -10, 10)
updateButton:SetScript("OnClick", UpdateGuildList)

-- Update the guild member list initially
UpdateGuildList()

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP") -- Register PLAYER_LEVEL_UP event to detect player level up

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        UpdateGuildList()
        -- Schedule automatic update every 1/2 minutes (30 seconds)
        self.timeSinceLastUpdate = 0
        self:SetScript("OnUpdate", function(self, elapsed)
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            if self.timeSinceLastUpdate >= 30 then
                self.timeSinceLastUpdate = 0
                UpdateGuildList()
            end
        end)
    elseif event == "GUILD_ROSTER_UPDATE" then
        UpdateGuildList()
    elseif event == "PLAYER_LEVEL_UP" then
        SendChatMessage("ding", "GUILD") -- Send "ding" message to guild chat when player levels up
    end
end)