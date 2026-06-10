local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════════════════
-- APIAdapter.lua — Version-agnostic API abstraction layer
-- ═══════════════════════════════════════════════════════════════════════════════
-- This module defines the interface that version-specific adapters must implement.
-- Each adapter (retail.lua, mop.lua) provides concrete implementations for their
-- respective game versions.
-- ═══════════════════════════════════════════════════════════════════════════════

ns.APIAdapter = {
    -- Container APIs
    -- Get the number of slots in a bag
    GetContainerNumSlots = nil,

    -- Get the item link for a bag/slot
    GetContainerItemLink = nil,

    -- Get the item count in a bag/slot
    GetContainerItemCount = nil,

    -- Item APIs
    -- Check if item at bag/slot is bound
    IsItemBound = nil,

    -- Check if item at bag/slot can be refunded
    IsItemRefundable = nil,

    -- Check if item at bag/slot has "cannot disenchant" tooltip line
    HasCannotDisenchantLine = nil,

    -- Spell APIs
    -- Check if a spell is usable (known, off cooldown, not casting)
    IsSpellReady = nil,

    AdapterId = nil,
}

local REQUIRED_METHODS = {
    "GetContainerNumSlots",
    "GetContainerItemLink",
    "GetContainerItemCount",
    "IsItemBound",
    "IsItemRefundable",
    "HasCannotDisenchantLine",
    "IsSpellReady",
}

function ns.APIAdapter.Validate(expectedAdapterFile)
    local missing = {}
    for _, methodName in ipairs(REQUIRED_METHODS) do
        if type(ns.APIAdapter[methodName]) ~= "function" then
            table.insert(missing, methodName)
        end
    end

    if #missing > 0 then
        return false, "Missing adapter methods: " .. table.concat(missing, ", ")
    end

    if expectedAdapterFile and ns.APIAdapter.AdapterId ~= expectedAdapterFile then
        return false, ("Loaded adapter '%s' but expected '%s'"):format(
            tostring(ns.APIAdapter.AdapterId or "none"),
            tostring(expectedAdapterFile)
        )
    end

    return true
end
