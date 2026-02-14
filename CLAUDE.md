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
- `DevPackages/` — dev dependencies (Jest, JestGlobals)

All three directories are gitignored; run `wally install` after cloning.

## Testing

Unit tests use **[Jest Lua](https://github.com/jsdotlua/jest-lua)** (v3.10.0) — the Luau port of Jest by jsdotlua.

### Running Tests

```bash
# Build the test place
rojo build test.project.json -o test-place.rbxl

# Run tests via run-in-roblox
run-in-roblox --place test-place.rbxl --script scripts/run-tests.server.luau
```

Alternatively, open `test-place.rbxl` in Studio — the `RunTests` script in `ServerScriptService` will execute automatically.

### Test Structure

- **Test files:** `src/__tests__/*.spec.luau`
- **Config:** `src/__tests__/jest.config.luau`
- **Runner:** `scripts/run-tests.server.luau`
- **Rojo project:** `test.project.json` (separate from auto-generated `default.project.json`)

### Writing Tests

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

describe("MyModule", function()
    it("should do something", function()
        expect(1 + 1).toBe(2)
    end)
end)
```

### Test Coverage Guidelines

Every feature should have tests covering:
- **GameConfig/data tables** — completeness, valid values, relationships
- **Pure logic** — calculations, algorithms, utility functions
- **Service API** — public methods behavior (may need mocking for Roblox services)

## MCP Tools — Roblox Studio

This project has a `robloxstudio` MCP server configured (`mcp-config.json`). When Rojo is serving and Studio is connected, you can interact with the live game directly:

- **Read/write instance properties** — `get_instance_properties`, `set_property`, `mass_set_property`
- **Create/delete objects** — `create_object`, `create_object_with_properties`, `delete_object`, `smart_duplicate`
- **Script editing** — `get_script_source`, `set_script_source`, `edit_script_lines`, `insert_script_lines`
- **Search instances** — `search_objects`, `search_files`, `get_instance_children`
- **Project structure** — `get_project_structure`, `get_services`, `get_file_tree`
- **Attributes & tags** — `get_attribute`, `set_attribute`, `add_tag`, `get_tagged`
- **Execute Luau** — `execute_luau` runs arbitrary code in the plugin context
- **Playtesting** — `start_playtest`, `get_playtest_output`, `stop_playtest`

Use these tools when you need to inspect or modify the live Studio state (e.g., checking instance hierarchy, setting up spawn points, running test code).
