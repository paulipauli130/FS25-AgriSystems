AgriSystemsSprayer = {}

local Spec = AgriSystemsSprayer
local ROOT_KEY = "agriSystemsSprayer"
local MAX_RESIDUE_ENTRIES = 48
local MAX_NOZZLE_GROUPS = 32

local function safeNumber(value, minimum, maximum, fallback)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.max(minimum, math.min(maximum, value))
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
end

function Spec:onLoad(savegame)
    local spec = {}
    self.spec_agriSystemsSprayer = spec
    spec.condition = AgriSystemsSprayHygiene.SprayerCondition.createState()
    spec.cleaning = AgriSystemsSprayHygiene.SprayerCleaning.createState()
    spec.successfulWorkCycles = 0

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
    if not self.isServer then
        return
    end

    local spraySpec = self.spec_sprayer
    if spraySpec ~= nil and spraySpec.workAreaParameters ~= nil
        and spraySpec.workAreaParameters.isActive == true then
        self.spec_agriSystemsSprayer.successfulWorkCycles =
            self.spec_agriSystemsSprayer.successfulWorkCycles + 1
    end
end


-- Initial server-to-client snapshot. Clients receive state but never author it.
function Spec:onWriteStream(streamId, connection)
    if not self.isServer then
        return
    end

    local spec = self.spec_agriSystemsSprayer
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
    streamWriteUInt8(streamId, #residues)
    for _, residue in ipairs(residues) do
        streamWriteString(streamId, residue.compartment)
        streamWriteString(streamId, residue.productClass)
        streamWriteFloat32(streamId, residue.amount)
    end
end

function Spec:onReadStream(streamId, connection)
    if self.isServer then
        return
    end

    local spec = self.spec_agriSystemsSprayer
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

function Spec:saveToXMLFile(xmlFile, key, usedModNames)
    if not self.isServer then
        return
    end

    local spec = self.spec_agriSystemsSprayer
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
