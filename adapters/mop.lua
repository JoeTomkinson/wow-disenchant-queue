local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════════════════
-- adapters/mop.lua — Classic MoP API implementation
-- ═══════════════════════════════════════════════════════════════════════════════

-- Only load this adapter for Classic MoP flavor
if not (ns.IsFlavor and ns.IsFlavor("classic-mop")) then
    return
end

if not _G.WDQ_ScanTip then
    CreateFrame("GameTooltip", "WDQ_ScanTip", nil, "GameTooltipTemplate")
end
local scanTip = _G.WDQ_ScanTip

-- Container APIs (MoP: support both C_Container and legacy functions)
local C_Container = _G.C_Container
local hasModernAPI = C_Container ~= nil

function ns.APIAdapter.GetContainerNumSlots(bag)
    if hasModernAPI then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    return GetContainerNumSlots(bag) or 0
end

function ns.APIAdapter.GetContainerItemLink(bag, slot)
    if hasModernAPI then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    return GetContainerItemLink(bag, slot)
end

function ns.APIAdapter.GetContainerItemCount(bag, slot)
    if hasModernAPI then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.stackCount or 0
    end
    local _, count = GetContainerItemInfo(bag, slot)
    return count or 0
end

-- Item APIs (tooltip scanning for MoP - no modern API)
function ns.APIAdapter.IsItemBound(bag, slot)
    if not bag or not slot then return false end
    
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetBagItem(bag, slot)
    
    for i = 2, scanTip:NumLines() do
        local text = _G["WDQ_ScanTipTextLeft" .. i]
        if text then
            local line = text:GetText()
            if line == ITEM_SOULBOUND or line == ITEM_BNETACCOUNTBOUND or line == ITEM_ACCOUNTBOUND then
                return true
            end
        end
    end
    return false
end

function ns.APIAdapter.IsItemRefundable(bag, slot)
    if not bag or not slot then return false end
    -- MoP doesn't have a direct API for this, conservative approach: never refundable
    return false
end

function ns.APIAdapter.HasCannotDisenchantLine(bag, slot)
    if not bag or not slot then return false end
    
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetBagItem(bag, slot)
    
    for i = 2, scanTip:NumLines() do
        local textObj = _G["WDQ_ScanTipTextLeft" .. i]
        if textObj then
            local line = textObj:GetText()
            if not line then break end
            
            if line == (_G.ITEM_DISENCHANT_NOT_DISENCHANTABLE or "")
                or line == (_G.ERR_CANT_BE_DISENCHANTED or "")
                or line == "Cannot be disenchanted"
                or line == "Item cannot be disenchanted" then
                return true
            end
            
            local r, g, b = textObj:GetTextColor()
            if r and r > 0.9 and g < 0.2 and b < 0.2 and line:find("[Dd]isenchant") then
                return true
            end
        end
    end
    return false
end

-- Spell APIs (legacy pre-C_Spell functions)
function ns.APIAdapter.IsSpellReady(spellID, spellName)
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    if not IsPlayerSpell(spellID) then
        return false
    end
    
    local start, duration = GetSpellCooldown(spellName)
    if start and start > 0 and duration > 0 then
        return false
    end
    
    return true
end

    ns.APIAdapter.AdapterId = "mop.lua"
