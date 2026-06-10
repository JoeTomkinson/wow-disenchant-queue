# Disenqueue API Adapter Architecture

## Overview

Disenqueue now uses an **adapter pattern** for cross-version compatibility. This provides a clean separation between game-version-specific APIs and business logic.

Supported targets in the current release policy:

- Retail Live (`release` artifact)
- Retail PTR/Beta (`ptr` artifact)
- Classic MoP (`classic-mop` artifact)

Detected but intentionally unsupported targets:

- Classic Era
- Classic Cata

## Pattern Structure

```txt
lib/APIAdapter.lua          - Interface/contract definition
├── Defines: GetContainerNumSlots, GetContainerItemLink, GetContainerItemCount
├── Defines: IsItemBound, IsItemRefundable, HasCannotDisenchantLine
├── Defines: IsSpellReady
├── Defines: Validate(expectedAdapterFile)
└── Exposes AdapterId set by the loaded adapter

adapters/retail.lua         - Retail (11.x+) implementation
├── Only loads if ns.IsFlavor("retail")
├── Uses modern C_* namespaces (C_Container, C_Item, C_Spell, C_TooltipInfo)
├── Uses modern ItemLocation API
└── Overrides all ns.APIAdapter methods with Retail implementations

adapters/mop.lua            - Classic MoP implementation
├── Only loads if ns.IsFlavor("classic-mop")
├── Uses legacy global functions (GetContainerNumSlots, GetContainerItemLink)
├── Uses tooltip scanning for item queries (no C_Item API)
├── Uses legacy GetSpellCooldown for spell checks
└── Overrides all ns.APIAdapter methods with MoP implementations

core/Core.lua               - Business logic (VERSION AGNOSTIC)
├── Calls ns.APIAdapter.* methods instead of direct WoW APIs
├── No version-specific conditionals needed
├── Verifies adapter readiness during ADDON_LOADED
├── Enters safe mode if adapter contract validation fails
└── Works on both Retail and MoP via adapter abstraction
```

## Load Order (in Disenqueue.toc)

1. `core/Compat.lua`          - Detects game version/flavor
2. `lib/APIAdapter.lua`       - Interface definition and validation helper
3. Adapter line (variant-specific at package time) - Retail or MoP adapter
4. `core/Core.lua`            - Business logic and runtime guards
5. Supporting libs and UI modules

## Packaging Strategy

`scripts/build.ps1` uses a variant matrix to build release artifacts.

- Every enabled variant sets its own interface number.
- Every enabled variant includes exactly one adapter file.
- The copied TOC is rewritten so adapter load lines match the packaged adapter.
- Future Classic variants remain disabled placeholders until adapters are added and validated.

## Example Usage in Core.lua

**Before (Mixed version checks):**

```lua
local function getContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    end
    if GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
end
```

**After (Adapter pattern):**

```lua
local function getContainerItemLink(bag, slot)
    return ns.APIAdapter.GetContainerItemLink(bag, slot)
end
```

## Adding a New Version-Specific API

1. Add the method to `lib/APIAdapter.lua` with descriptive comments
2. Implement it in `adapters/retail.lua` for Retail
3. Implement it in `adapters/mop.lua` for MoP
4. Call it from `core/Core.lua` via `ns.APIAdapter.MethodName(...)`
