# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Roblox game project using Rojo for filesystem-to-Studio syncing, written in Luau. Uses React (via jsdotlua) for UI, Networker for client-server communication, Promise for async operations, and ProfileService for data persistence.

## Toolchain

Managed via [Rokit](https://github.com/rojo-rbx/rokit):
- **Rojo** 7.5.1 — syncs filesystem to Roblox Studio
- **Wally** 0.3.2 — package manager (packages go to `Packages/` and `ServerPackages/`)
- **Selene** — Luau linter (configured with `std = "roblox"`)

## Common Commands

```bash
# Build the place file from scratch
rojo build -o "didactic-fortnight.rbxlx"

# Start Rojo dev server (connect from Studio with Rojo plugin)
rojo serve

# Regenerate default.project.json after adding/removing/moving .luau files
node tools/genRojoTree.js

# Watch for file changes and auto-regenerate project file
npm run watch:rojo

# Regenerate sourcemap
rojo sourcemap -o sourcemap.json

# Install Wally packages
wally install

# Lint with selene
selene src/
```

## Architecture

### Rojo Project Generation

`default.project.json` is **auto-generated** — do not edit it by hand. Run `node tools/genRojoTree.js` after any file additions, removals, or moves under `src/`. The generator (`tools/genRojoTree.js`) walks `src/` and maps files into the Rojo tree with these rules:

- `src/startup/` is **blacklisted** from auto-generation (hardcoded in the tree template)
- Files with "server" in the name map to `ServerScriptService`; all others map to `ReplicatedStorage.Source`
- Files named `init.luau` promote their parent folder to a `$path` entry (claiming the folder)
- Files named `server.luau`, `client.luau`, `utils.luau`, `types.luau` get prefixed with their parent folder name in PascalCase (e.g., `ExampleService/Client.luau` → `ExampleServiceClient`)

### Source Layout

- **`src/startup/`** — Entry points. `Server.server.luau` and `Client.client.luau` bootstrap services. `MountUI.luau` handles React UI mounting.
- **`src/services/`** — Services split into `Server.luau`, `Client.luau`, and `Utils.luau` per service. Each service module is a table with an `:init()` method called from the startup scripts.
- **`src/features/`** — Feature modules, each containing its own classes, UI (components/screens), client/server logic, and state slices (`<Name>Slice.luau`).
- **`src/core/`** — Shared utilities and core modules.
- **`src/game/`** — Game assets and configuration.

### Service Pattern

Services follow a consistent module pattern:
```luau
local MyService = {}
function MyService.init(self: MyService)
    -- setup logic
end
export type MyService = typeof(MyService) & {}
return MyService
```

Server startup requires services from `ServerScriptService.Services` and calls `:init()`. Client code requires from `ReplicatedStorage.Source.Services`.

### Dependencies (Wally)

- `Packages/` — shared dependencies (React, ReactRoblox, Promise, Networker)
- `ServerPackages/` — server-only dependencies (ProfileService)

Both directories are gitignored; run `wally install` after cloning.
