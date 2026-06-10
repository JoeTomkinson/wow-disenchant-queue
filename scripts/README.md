# Disenqueue Scripts

This folder contains the PowerShell scripts used to build and link the addon during development.

## Scripts

- `build.ps1` packages the addon into release, PTR, and classic Mists of Pandaria archives.
- `link-addon.ps1` creates a junction from the game AddOns folder to this repository.
- `unlink-addon.ps1` removes the junction created by `link-addon.ps1`.
- `retail/`, `retail-ptr/`, and `classic/mop/` contain variant-specific link scripts.

## Variant Matrix

The build uses a single variant configuration table in `build.ps1`:

- Enabled: `release`, `ptr`, `classic-mop`
- Disabled placeholders: `classic-cata`, `classic-era`

Disabled variants are intentional scaffolding for future support and are never packaged unless explicitly enabled.

## Build

Run the build from this directory:

```powershell
cd d:\Repos\Disenqueue\scripts
./build.ps1
```

To bump the addon version before building:

```powershell
./build.ps1 -Bump patch
```

## Output

The build creates archives under `dist/` for:

- `release`
- `ptr`
- `classic-mop`

Each archive contains the addon in the structure expected by World of Warcraft.

During packaging, the script patches each copied TOC to:

- Set the correct `## Interface` value for the target client
- Include only the adapter line required for that artifact

## Notes

- The build script copies files from the current repository layout.
- Version bumps update both `Disenqueue.toc` and `core/Core.lua`.
- The generated archives are ready for upload to CurseForge.
