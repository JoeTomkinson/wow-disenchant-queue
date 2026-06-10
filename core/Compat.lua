local _, ns = ...

-- Compat.lua - Runtime flavor and capability detection

local GetBuildInfo = rawget(_G, "GetBuildInfo")
local Settings = rawget(_G, "Settings")
local C_EncodingUtil = rawget(_G, "C_EncodingUtil")
local Enum = rawget(_G, "Enum")
local C_TooltipInfo = rawget(_G, "C_TooltipInfo")
local C_Spell = rawget(_G, "C_Spell")
local C_Container = rawget(_G, "C_Container")
local ItemLocation = rawget(_G, "ItemLocation")
local C_Item = rawget(_G, "C_Item")
local WOW_PROJECT_ID = rawget(_G, "WOW_PROJECT_ID")
local WOW_PROJECT_MAINLINE = rawget(_G, "WOW_PROJECT_MAINLINE")
local WOW_PROJECT_CLASSIC = rawget(_G, "WOW_PROJECT_CLASSIC")

local function getBuildInfoSafe()
    if GetBuildInfo then
        return GetBuildInfo()
    end
    return nil, nil, nil, 0
end

local function detectClassicFlavor(tocVersion)
    if tocVersion >= 50000 then
        return "classic-mop"
    end
    if tocVersion >= 40000 then
        return "classic-cata"
    end
    return "classic-era"
end

local function detectFlavor(tocVersion)
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        return "retail"
    end

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        return detectClassicFlavor(tocVersion)
    end

    -- Fallback for unknown project ids.
    if tocVersion >= 100000 then
        return "retail"
    end
    return detectClassicFlavor(tocVersion)
end

local FLAVOR_TO_ADAPTER = {
    retail = "retail.lua",
    ["classic-mop"] = "mop.lua",
}

local _, _, _, tocVersion = getBuildInfoSafe()
tocVersion = tonumber(tocVersion) or 0

ns.Flavor = {
    id = detectFlavor(tocVersion),
    tocVersion = tocVersion,
}

ns.ExpectedAdapterFile = FLAVOR_TO_ADAPTER[ns.Flavor.id]
ns.IsSupportedFlavor = ns.ExpectedAdapterFile ~= nil

ns.Capabilities = {
    modernSettingsAPI = Settings and Settings.RegisterVerticalLayoutCategory ~= nil,
    encodingUtil = C_EncodingUtil ~= nil
        and Enum ~= nil
        and Enum.CompressionMethod ~= nil
        and Enum.CompressionLevel ~= nil,
    tooltipInfo = C_TooltipInfo and C_TooltipInfo.GetBagItem ~= nil,
    cSpellNamespace = C_Spell and C_Spell.IsSpellUsable ~= nil and C_Spell.GetSpellCooldown ~= nil,
    cContainerNamespace = C_Container and C_Container.GetContainerNumSlots ~= nil,
    itemLocationAPI = ItemLocation ~= nil and C_Item ~= nil,
}

function ns.HasCapability(name)
    return ns.Capabilities and ns.Capabilities[name] == true
end

function ns.IsFlavor(id)
    return ns.Flavor and ns.Flavor.id == id
end

function ns.IsSupportedBuild()
    return ns.IsSupportedFlavor == true
end

function ns.GetExpectedAdapterFile()
    return ns.ExpectedAdapterFile
end
