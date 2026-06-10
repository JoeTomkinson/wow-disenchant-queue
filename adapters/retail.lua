local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════════════════
-- adapters/retail.lua — Retail (11.x+) API implementation
-- ═══════════════════════════════════════════════════════════════════════════════

-- Only load this adapter for Retail flavor
if not (ns.IsFlavor and ns.IsFlavor("retail")) then
    return
end

local C_Container = _G.C_Container
local C_Item = _G.C_Item
local ItemLocation = _G.ItemLocation
local C_Spell = _G.C_Spell
local C_TooltipInfo = _G.C_TooltipInfo

if not _G.WDQ_ScanTip then
    CreateFrame("GameTooltip", "WDQ_ScanTip", nil, "GameTooltipTemplate")
end
local scanTip = _G.WDQ_ScanTip

-- Container APIs (all C_Container namespace in Retail)
function ns.APIAdapter.GetContainerNumSlots(bag)
    return C_Container.GetContainerNumSlots(bag) or 0
end

function ns.APIAdapter.GetContainerItemLink(bag, slot)
    return C_Container.GetContainerItemLink(bag, slot)
end

function ns.APIAdapter.GetContainerItemCount(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    return info and info.stackCount or 0
end

-- Item APIs (modern C_Item and C_TooltipInfo)
function ns.APIAdapter.IsItemBound(bag, slot)
    if not bag or not slot then return false end
    local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if itemLocation and itemLocation:IsValid() then
        return C_Item.IsBound(itemLocation)
    end
    return false
end

function ns.APIAdapter.IsItemRefundable(bag, slot)
    if not bag or not slot then return false end
    local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if itemLocation and itemLocation:IsValid() then
        return C_Item.CanBeRefunded(itemLocation)
    end
    return false
end

function ns.APIAdapter.HasCannotDisenchantLine(bag, slot)
    if not bag or not slot then return false end
    
    -- Try modern tooltip API first
    local data = C_TooltipInfo.GetBagItem(bag, slot)
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            if line.type and line.type == 41 and line.leftText
                and line.leftText:find("[Dd]isenchant") then
                return true
            end
            if line.leftText then
                local text = line.leftText
                if text == (_G.ITEM_DISENCHANT_NOT_DISENCHANTABLE or "")
                    or text == (_G.ERR_CANT_BE_DISENCHANTED or "")
                    or text == "Cannot be disenchanted"
                    or text == "Item cannot be disenchanted" then
                    return true
                end
                if line.leftColor and line.leftColor.r and line.leftColor.r > 0.9
                    and line.leftColor.g < 0.2 and line.leftColor.b < 0.2 then
                    if text:find("[Dd]isenchant") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Spell APIs (all C_Spell namespace in Retail)
function ns.APIAdapter.IsSpellReady(spellID, spellName)
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        return false
    end
    
    if not C_Spell.IsSpellUsable(spellID) then
        return false
    end
    
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if cdInfo and cdInfo.startTime and cdInfo.startTime > 0 and cdInfo.duration > 0 then
        return false
    end
    
    return true
end

    ns.APIAdapter.AdapterId = "retail.lua"
