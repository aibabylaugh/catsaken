-- this aint catsken source fuck off

local HttpService = game:GetService('HttpService')

local OLD_CONFIGS = 'catsakenconfigs.json'
local OLD_AUTOLOAD = 'catsakenautoload.txt'
local FOLDER = 'CatsakenRemastered'
local SETTINGS = FOLDER .. '/settings'
local MARKER = FOLDER .. '/old_ui_configs_migrated.txt'

local MULTI = {SilentAimValues = true, AimbotValues = true, AutoBlockAims = true}
local SKIP = {
    SelectedEditCharacter = true, SelectedEditKey = true, EditorLoadSave = true, EditorSaveName = true,
    OldForsakenMenu = true, NotificationLayout = true,
}

local function IsSkipped(Flag)
    return SKIP[Flag] or Flag:sub(1, 3) == 'cfg' or Flag:sub(1, 10) == 'currentcfg'
end

local function SafeName(Name)
    return (tostring(Name):gsub('%.json$', ''):gsub('[\\/:*?"<>|%c]', '_'):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function Convert(Flag, Record)
    if type(Record) ~= 'table' then
        return nil
    end

    if type(Record.Color) == 'string' then
        local Parts = Record.Color:split('/')
        local H, S, V = tonumber(Parts[1]), tonumber(Parts[2]), tonumber(Parts[3])
        if H and S and V then
            return {
                type = 'ColorPicker',
                idx = Flag,
                value = Color3.fromHSV(math.clamp(H, 0, 1), math.clamp(S, 0, 1), math.clamp(V, 0, 1)):ToHex(),
                transparency = 0,
            }
        end
    elseif type(Record.CurrentKeybind) == 'string' then
        if Record.CurrentKeybind ~= '' then
            return {type = 'KeyPicker', idx = Flag, mode = 'Press', key = Record.CurrentKeybind, modifiers = {}}
        end
    elseif type(Record.CurrentOption) == 'table' then
        local Options = Record.CurrentOption
        if MULTI[Flag] or Flag:sub(-14) == 'GhostAnimation' or #Options > 1 then
            local Value = {}
            for _, Option in ipairs(Options) do
                Value[tostring(Option)] = true
            end
            return {type = 'Dropdown', idx = Flag, value = Value, multi = true, mutli = true}
        elseif Options[1] ~= nil then
            return {type = 'Dropdown', idx = Flag, value = tostring(Options[1]), multi = false, mutli = false}
        end
    else
        local Value = Record.CurrentValue
        if type(Value) == 'boolean' then
            return {type = 'Toggle', idx = Flag, value = Value}
        elseif type(Value) == 'number' then
            return {type = 'Slider', idx = Flag, value = tostring(Value)}
        elseif type(Value) == 'string' then
            return {type = 'Input', idx = Flag, text = Value}
        end
    end
    return nil
end

local function Migrate()
    if isfile(MARKER) or not isfile(OLD_CONFIGS) then
        return
    end

    local Decoded, Configs = pcall(function()
        return HttpService:JSONDecode(readfile(OLD_CONFIGS))
    end)
    if not Decoded or type(Configs) ~= 'table' then
        warn('[Catsaken migrator] could not read ' .. OLD_CONFIGS .. ', skipping')
        return
    end

    if not isfolder(FOLDER) then
        makefolder(FOLDER)
    end
    if not isfolder(SETTINGS) then
        makefolder(SETTINGS)
    end

    local Migrated, Skipped, Names = 0, 0, {}
    for OldName, Flags in pairs(Configs) do
        local Name = SafeName(OldName)
        local Path = SETTINGS .. '/' .. Name .. '.json'
        if Name == '' or type(Flags) ~= 'table' then
            Skipped += 1
        elseif isfile(Path) then
            Names[OldName] = Name
            Skipped += 1
        else
            local Objects = {}
            for Flag, Record in pairs(Flags) do
                local Object = not IsSkipped(Flag) and Convert(Flag, Record)
                if Object then
                    Objects[#Objects + 1] = Object
                end
            end
            table.sort(Objects, function(A, B)
                return A.idx < B.idx
            end)
            local Ok, Err = pcall(writefile, Path, HttpService:JSONEncode({objects = Objects}))
            if Ok then
                Migrated += 1
                Names[OldName] = Name
            else
                Skipped += 1
                warn('[Catsaken migrator] failed to write "' .. Name .. '": ' .. tostring(Err))
            end
        end
    end

    local AutoloadPath = SETTINGS .. '/autoload.txt'
    local Autoload = nil
    if isfile(OLD_AUTOLOAD) and not isfile(AutoloadPath) then
        local OldAutoload = (readfile(OLD_AUTOLOAD):gsub('^%s+', ''):gsub('%s+$', ''))
        Autoload = Names[OldAutoload] or Names[OldAutoload .. '.json']
        if Autoload then
            writefile(AutoloadPath, Autoload)
        end
    end

    writefile(MARKER, ('migrated=%d skipped=%d autoload=%s'):format(Migrated, Skipped, tostring(Autoload)))
    print(('[Catsaken migrator] migrated %d config(s), skipped %d, autoload: %s'):format(Migrated, Skipped, tostring(Autoload)))
end

local Ok, Err = pcall(Migrate)
if not Ok then
    warn('[Catsaken migrator] failed: ' .. tostring(Err))
end
