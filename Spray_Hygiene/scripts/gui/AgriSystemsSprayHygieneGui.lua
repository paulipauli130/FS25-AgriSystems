AgriSystemsSprayHygieneGui = AgriSystemsSprayHygieneGui or {}
local Gui = AgriSystemsSprayHygieneGui
local Gui_mt = Class(Gui)

local MOD_DIR = g_currentModDirectory or ""
local PAGE_NAME = AgriSystemsSprayHygieneMenuPage.MENU_PAGE_NAME
local PAGE_ICON_UVS = {0, 0, 128, 128}

function Gui.new()
    local self = setmetatable({}, Gui_mt)
    self.pageController = nil
    self.guiLoaded = false
    self.registered = false
    self.pending = false
    self.retryTimer = 0
    return self
end

function Gui:loadPageXml()
    if self.guiLoaded then
        return true
    end
    if g_gui == nil then
        return false
    end

    self.pageController = AgriSystemsSprayHygieneMenuPage.new()
    g_gui:loadGui(
        AgriSystemsSprayHygieneMenuPage.getXmlFilename(),
        AgriSystemsSprayHygieneMenuPage.CLASS_NAME,
        self.pageController,
        true
    )
    self.guiLoaded = true
    return true
end

function Gui:registerPage()
    if self.registered then
        return true
    end
    if g_gui == nil or InGameMenu == nil then
        return false
    end

    local inGameMenu = g_gui.screenControllers[InGameMenu] or g_inGameMenu
    if inGameMenu == nil or inGameMenu.pagingElement == nil
        or inGameMenu.pagingElement.elements == nil
        or inGameMenu.pagingElement.pages == nil then
        return false
    end

    if inGameMenu[PAGE_NAME] ~= nil then
        self.registered = true
        return true
    end

    if not self:loadPageXml() then
        return false
    end

    if inGameMenu.controlIDs ~= nil then
        inGameMenu.controlIDs[PAGE_NAME] = nil
    end

    inGameMenu[PAGE_NAME] = self.pageController
    inGameMenu.pagingElement:addElement(self.pageController)
    inGameMenu:exposeControlsAsFields(PAGE_NAME)
    inGameMenu.pagingElement:updateAbsolutePosition()
    inGameMenu.pagingElement:updatePageMapping()
    inGameMenu:registerPage(self.pageController, nil, function() return true end)

    local iconPath = Utils.getFilename("icon.dds", MOD_DIR)
    inGameMenu:addPageTab(
        self.pageController,
        iconPath,
        GuiUtils.getUVs(PAGE_ICON_UVS)
    )
    inGameMenu:rebuildTabList()

    if self.pageController.initialize ~= nil then
        self.pageController:initialize()
    end

    self.registered = true
    Logging.info("[AgriSystems Spray & Hygiene] In-game menu page registered.")
    return true
end

function Gui:tryRegister()
    if self.registered then
        return true
    end
    if not self:loadPageXml() then
        return false
    end
    return self:registerPage()
end

function Gui:onMapLoaded()
    if g_client == nil then
        return
    end
    self.pending = true
    self:tryRegister()
end

function Gui:update(dt)
    if not self.pending or self.registered or g_client == nil then
        return
    end

    self.retryTimer = self.retryTimer + (dt or 0)
    if self.retryTimer >= 1000 then
        self.retryTimer = 0
        self:tryRegister()
    end
end

function Gui:deleteMap()
    self.pending = false
    self.retryTimer = 0
end

local instance = Gui.new()
AgriSystemsSprayHygieneGui.INSTANCE = instance
if type(addModEventListener) == "function" then
    addModEventListener(instance)
else
    Logging.warning("[AgriSystems Spray & Hygiene] addModEventListener unavailable; menu registration skipped.")
end
