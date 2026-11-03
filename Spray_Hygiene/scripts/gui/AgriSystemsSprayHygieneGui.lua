AgriSystemsSprayHygieneGui = AgriSystemsSprayHygieneGui or {}
local Gui = AgriSystemsSprayHygieneGui

local MOD_DIR = g_currentModDirectory or ""
local PAGE_NAME = "menuAgriSystemsSprayHygiene"
-- GuiUtils.getUVs expects pixel coordinates as a string, not a Lua table.
-- The generated mod icon is a single 128x128 image, so use the full texture.
local ICON_UVS = "0 0 128 128"

function Gui:loadMap()
    if self.registered then
        return
    end

    if g_gui == nil or g_inGameMenu == nil then
        Logging.warning("[AgriSystems Spray & Hygiene] In-game menu is not available during loadMap; page registration skipped.")
        return
    end

    local page = AgriSystemsSprayHygieneMenuPage.new()
    local xmlFilename = Utils.getFilename("gui/AgriSystemsSprayHygieneMenuPage.xml", MOD_DIR)

    local ok, errorMessage = pcall(function()
        g_gui:loadGui(xmlFilename, PAGE_NAME, page, true)

        g_inGameMenu.controlIDs[PAGE_NAME] = nil
        g_inGameMenu[PAGE_NAME] = page
        g_inGameMenu.pagingElement:addElement(page)
        g_inGameMenu:exposeControlsAsFields(PAGE_NAME)

        g_inGameMenu.pagingElement:updateAbsolutePosition()
        g_inGameMenu.pagingElement:updatePageMapping()

        g_inGameMenu:registerPage(page, nil, function()
            return true
        end)

        local iconFilename = Utils.getFilename("icon.dds", MOD_DIR)
        g_inGameMenu:addPageTab(page, iconFilename, GuiUtils.getUVs(ICON_UVS))
        g_inGameMenu:rebuildTabList()

        page:initialize()
    end)

    if not ok then
        Logging.error("[AgriSystems Spray & Hygiene] Failed to register in-game menu page: %s", tostring(errorMessage))
        return
    end

    self.registered = true
    Logging.info("[AgriSystems Spray & Hygiene] In-game menu page registered successfully.")
end

function Gui:deleteMap()
    self.registered = false
end

addModEventListener(Gui)
