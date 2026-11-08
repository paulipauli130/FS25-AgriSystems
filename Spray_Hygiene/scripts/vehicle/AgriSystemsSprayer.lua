AgriSystemsSprayer = {}

local Spec = AgriSystemsSprayer
local MOD_NAME = g_currentModName or "FS25_AgriSystems_SprayHygiene"
local ROOT_KEY = MOD_NAME .. ".agriSystemsSprayer"
local SPEC_TABLE_NAME = "spec_" .. ROOT_KEY
local MAX_RESIDUE_ENTRIES = 48
local MAX_NOZZLE_GROUPS = 32

local function safeNumber(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.max(minimum, math.min(maximum, value))
end

local function writeState(streamId, spec)
    streamWriteFloat32(streamId, spec.condition.condition)
    streamWriteFloat32(streamId, spec.condition.wear)
    streamWriteFloat32(streamId, spec.condition.calibration)

    local groups = {}
    for groupId, blockage in pairs(spec.condition.nozzleBlockage) do
        local index = tonumber(groupId)
        if index ~= nil and index >= 1 and index <= MAX_NOZZLE_GROUPS
            and #groups < MAX_NOZZLE_GROUPS then
            table.insert(groups, {index = math.floor(index), blockage = blockage})
        end
    end
    table.sort(groups, function(a, b) return a.index < b.index end)

    streamWriteUInt8(streamId, #groups)
    for _, group in ipairs(groups) do
        streamWriteUInt8(streamId, group.index)
        streamWriteFloat32(streamId, group.blockage)
    end

    local residues = {}
    for compartment, entries in pairs(spec.cleaning.residues) do
        for productClass, amount in pairs(entries) do
            if #residues < MAX_RESIDUE_ENTRIES then
                table.insert(residues, {
                    compartment = compartment,
                    productClass = productClass,
                    amount = amount
                })
            end
        end
    end
    table.sort(residues, function(a, b)
        if a.compartment == b.compartment then
            return a.productClass < b.productClass
        end
        return a.compartment < b.compartment
    end)

    streamWriteUInt8(streamId, #residues)
    for _, residue in ipairs(residues) do
        streamWriteString(streamId, residue.compartment)
        streamWriteString(streamId, residue.productClass)
        streamWriteFloat32(streamId, residue.amount)
    end
end

local function readState(streamId, spec)
    local condition = {
        condition = streamReadFloat32(streamId),
        wear = streamReadFloat32(streamId),
        calibration = streamReadFloat32(streamId),
        nozzleBlockage = {}
    }

    local groupCount = math.min(streamReadUInt8(streamId), MAX_NOZZLE_GROUPS)
    for _ = 1, groupCount do
        local index = streamReadUInt8(streamId)
        local blockage = streamReadFloat32(streamId)
        if index >= 1 and index <= MAX_NOZZLE_GROUPS then
            condition.nozzleBlockage[tostring(index)] = blockage
        end
    end
    spec.condition = AgriSystemsSprayHygiene.SprayerCondition.validateState(condition)

    local cleaning = {residues = {tank = {}, lines = {}, filters = {}}}
    local residueCount = math.min(streamReadUInt8(streamId), MAX_RESIDUE_ENTRIES)
    for _ = 1, residueCount do
        local compartment = streamReadString(streamId)
        local productClass = streamReadString(streamId)
        local amount = streamReadFloat32(streamId)
        if cleaning.residues[compartment] ~= nil
            and type(productClass) == "string" and productClass ~= "" then
            cleaning.residues[compartment][productClass] = safeNumber(amount, 0, 1, 0)
        end
    end
    spec.cleaning = AgriSystemsSprayHygiene.SprayerCleaning.validateState(cleaning)
end

local function markStateDirty(vehicle, spec)
    if spec.dirtyFlag ~= nil then
        vehicle:raiseDirtyFlags(spec.dirtyFlag)
    end
end

function Spec.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Sprayer, specializations)
end

function Spec.initSpecialization()
    local schema = Vehicle.xmlSchemaSavegame
    local base = "vehicles.vehicle(?)." .. ROOT_KEY
    Vehicle.xmlSchemaSavegame:setXMLSpecializationType("AgriSystemsSprayer")
    schema:register(XMLValueType.INT, base .. "#schemaVersion", "AgriSystems state schema version")
    schema:register(XMLValueType.FLOAT, base .. "#condition", "Sprayer condition")
    schema:register(XMLValueType.FLOAT, base .. "#wear", "Sprayer wear")
    schema:register(XMLValueType.FLOAT, base .. "#calibration", "Sprayer calibration")
    schema:register(XMLValueType.INT, base .. ".nozzleGroup(?)#index", "Nozzle group index")
    schema:register(XMLValueType.FLOAT, base .. ".nozzleGroup(?)#blockage", "Nozzle group blockage")
    schema:register(XMLValueType.STRING, base .. ".residue(?)#compartment", "Residue compartment")
    schema:register(XMLValueType.STRING, base .. ".residue(?)#productClass", "Residue product class")
    schema:register(XMLValueType.FLOAT, base .. ".residue(?)#amount", "Residue amount")
    Vehicle.xmlSchemaSavegame:setXMLSpecializationType()
end

function Spec.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Spec)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Spec)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Spec)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Spec)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Spec)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Spec)
end

function Spec:onLoad(savegame)
    local spec = {}
    self[SPEC_TABLE_NAME] = spec
    spec.condition = AgriSystemsSprayHygiene.SprayerCondition.createState()
    spec.cleaning = AgriSystemsSprayHygiene.SprayerCleaning.createState()
    spec.successfulWorkCycles = 0
    spec.lastWorkUpdateMs = 0
    spec.dirtyFlag = type(self.getNextDirtyFlag) == "function" and self:getNextDirtyFlag() or nil

    Logging.info(string.format(
        "[AgriSystems Spray & Hygiene][DIAG] specialization onLoad: vehicle=%s typeName=%s specKey=%s nativeSprayerSpec=%s",
        tostring(self.getName ~= nil and self:getName() or self.configFileName or "unknown"),
        tostring(self.typeName or "unknown"),
        SPEC_TABLE_NAME,
        tostring(self.spec_sprayer ~= nil)
    ))

    if not self.isServer or savegame == nil or savegame.resetVehicles then
        return
    end

    local xmlFile = savegame.xmlFile
    local base = savegame.key .. "." .. ROOT_KEY
    if not xmlFile:hasProperty(base) then
        return
    end

    local schemaVersion = xmlFile:getValue(base .. "#schemaVersion", 1)
    if schemaVersion ~= 1 then
        Logging.xmlWarning(xmlFile, "Unsupported AgriSystems sprayer state schema %s; defaults used", tostring(schemaVersion))
        return
    end

    local condition = {
        condition = xmlFile:getValue(base .. "#condition", 100),
        wear = xmlFile:getValue(base .. "#wear", 0),
        calibration = xmlFile:getValue(base .. "#calibration", 100),
        nozzleBlockage = {}
    }

    for _, key in xmlFile:iterator(base .. ".nozzleGroup") do
        local index = xmlFile:getValue(key .. "#index")
        local blockage = xmlFile:getValue(key .. "#blockage")
        if index ~= nil and index >= 1 and index <= MAX_NOZZLE_GROUPS and blockage ~= nil then
            condition.nozzleBlockage[tostring(math.floor(index))] = blockage
        end
    end
    spec.condition = AgriSystemsSprayHygiene.SprayerCondition.validateState(condition)

    local residueState = {residues = {tank = {}, lines = {}, filters = {}}}
    local entryCount = 0
    for _, key in xmlFile:iterator(base .. ".residue") do
        entryCount = entryCount + 1
        if entryCount > MAX_RESIDUE_ENTRIES then
            break
        end
        local compartment = xmlFile:getValue(key .. "#compartment")
        local productClass = xmlFile:getValue(key .. "#productClass")
        local amount = xmlFile:getValue(key .. "#amount")
        if residueState.residues[compartment] ~= nil
            and type(productClass) == "string" and productClass ~= "" and amount ~= nil then
            residueState.residues[compartment][productClass] = safeNumber(amount, 0, 1, 0)
        end
    end
    spec.cleaning = AgriSystemsSprayHygiene.SprayerCleaning.validateState(residueState)
end

-- Observe the native callback only. Do not modify workAreaParameters or fill usage.
function Spec:onEndWorkAreaProcessing(dt, hasProcessed)
    if not self.isServer then return end
    local config = AgriSystemsSprayHygiene ~= nil and AgriSystemsSprayHygiene.CONFIG or nil
    local spec = self[SPEC_TABLE_NAME]
    local spraySpec = self.spec_sprayer
    if config == nil or config.enabled == false or spec == nil
        or spraySpec == nil or spraySpec.workAreaParameters == nil
        or spraySpec.workAreaParameters.isActive ~= true or hasProcessed ~= true then
        return
    end

    spec.successfulWorkCycles = spec.successfulWorkCycles + 1
    if config.wearEnabled == false then return end

    local elapsedMs = safeNumber(dt, 0, 60000, 0)
    if elapsedMs <= 0 then return end
    spec.lastWorkUpdateMs = spec.lastWorkUpdateMs + elapsedMs
    if spec.lastWorkUpdateMs < 1000 then return end

    local updateMs = math.min(spec.lastWorkUpdateMs, 10000)
    spec.lastWorkUpdateMs = spec.lastWorkUpdateMs - updateMs
    local rate = safeNumber(config.engineering and config.engineering.wearPerHour, 0, 10, 0.75)
        * safeNumber(config.wearRateMultiplier, 0, 3, 1)
    local calibrationFactor = config.calibrationEnabled ~= false and 0.5 or 0
    local updatedCondition = AgriSystemsSprayHygiene.SprayerCondition.applyOperatingTime(
        spec.condition, updateMs, rate, calibrationFactor
    )

    if updatedCondition.condition ~= spec.condition.condition
        or updatedCondition.wear ~= spec.condition.wear
        or updatedCondition.calibration ~= spec.condition.calibration then
        spec.condition = updatedCondition
        markStateDirty(self, spec)
    end
end

-- Initial server-to-client snapshot for newly connected clients.
function Spec:onWriteStream(streamId, connection)
    if not self.isServer then
        return
    end

    local spec = self[SPEC_TABLE_NAME]
    if spec ~= nil then
        writeState(streamId, spec)
    end
end

function Spec:onReadStream(streamId, connection)
    if self.isServer then
        return
    end

    local spec = self[SPEC_TABLE_NAME]
    if spec ~= nil then
        readState(streamId, spec)
    end
end

-- Incremental server-to-client synchronization. The vehicle dirty mask controls
-- when the bounded state snapshot is sent; no state is sent every frame.
function Spec:onWriteUpdateStream(streamId, connection, dirtyMask)
    if connection == nil or type(connection.getIsServer) ~= "function"
        or connection:getIsServer() then
        return
    end

    local spec = self[SPEC_TABLE_NAME]
    if spec == nil or spec.dirtyFlag == nil then
        return
    end

    if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
        writeState(streamId, spec)
    end
end

function Spec:onReadUpdateStream(streamId, timestamp, connection)
    if connection == nil or type(connection.getIsServer) ~= "function"
        or not connection:getIsServer() then
        return
    end

    local spec = self[SPEC_TABLE_NAME]
    if spec ~= nil and streamReadBool(streamId) then
        readState(streamId, spec)
    end
end

function Spec:saveToXMLFile(xmlFile, key, usedModNames)
    if not self.isServer then
        return
    end

    local spec = self[SPEC_TABLE_NAME]
    if spec == nil then
        return
    end

    local base = key
    xmlFile:setValue(base .. "#schemaVersion", 1)
    xmlFile:setValue(base .. "#condition", spec.condition.condition)
    xmlFile:setValue(base .. "#wear", spec.condition.wear)
    xmlFile:setValue(base .. "#calibration", spec.condition.calibration)

    local index = 0
    for groupId, blockage in pairs(spec.condition.nozzleBlockage) do
        local groupIndex = tonumber(groupId)
        if groupIndex ~= nil and groupIndex >= 1 and groupIndex <= MAX_NOZZLE_GROUPS then
            local groupKey = string.format("%s.nozzleGroup(%d)", base, index)
            xmlFile:setValue(groupKey .. "#index", math.floor(groupIndex))
            xmlFile:setValue(groupKey .. "#blockage", blockage)
            index = index + 1
        end
    end

    index = 0
    for compartment, residues in pairs(spec.cleaning.residues) do
        for productClass, amount in pairs(residues) do
            if index >= MAX_RESIDUE_ENTRIES then
                return
            end
            local residueKey = string.format("%s.residue(%d)", base, index)
            xmlFile:setValue(residueKey .. "#compartment", compartment)
            xmlFile:setValue(residueKey .. "#productClass", productClass)
            xmlFile:setValue(residueKey .. "#amount", amount)
            index = index + 1
        end
    end
end
