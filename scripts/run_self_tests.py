#!/usr/bin/env python3
"""Run the pure-logic SelfTests outside Roblox Studio with the Luau CLI.

Usage:  python3 scripts/run_self_tests.py

Needs the `luau` command on PATH (https://github.com/luau-lang/luau/releases).
It bundles src/shared and src/server/Tests into one Luau file with a tiny mock of the
Roblox instance tree (only what the pure modules use), then runs SelfTests.run().
This does not replace a Studio playtest; it only checks scoring, rules, and config.
"""
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
FOLDERS = {
    # Mock path (as in Roblox) -> source folder, following default.project.json.
    "ReplicatedStorage/DarkSky": ROOT / "src" / "shared",
    "ServerScriptService/DarkSky/Tests": ROOT / "src" / "server" / "Tests",
}

PRELUDE = r"""
local function newInstance(name, parent)
    local inst = { Name = name, Parent = parent, _children = {} }
    function inst:WaitForChild(childName)
        local child = self._children[childName]
        if child == nil then error("Mock: " .. self.Name .. " has no child " .. childName) end
        return child
    end
    function inst:FindFirstChild(childName) return self._children[childName] end
    if parent then parent._children[name] = inst end
    return inst
end

local services = {}
local game = { GetService = function(_, name)
    services[name] = services[name] or newInstance(name, nil)
    return services[name]
end }

local function ensurePath(path)
    local parts = string.split(path, "/")
    local node = game:GetService(parts[1])
    for i = 2, #parts do
        node = node._children[parts[i]] or newInstance(parts[i], node)
    end
    return node
end

local Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }
local Color3 = { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end }

local cache = {}
local function mockRequire(module)
    if cache[module] ~= nil then return cache[module] end
    if module._source == nil then error("Mock: " .. module.Name .. " is not a module") end
    local chunk, err = loadstring(module._source, "=" .. module._path)
    if not chunk then error(err) end
    local env = setmetatable({
        script = module, game = game, require = mockRequire,
        Vector3 = Vector3, Color3 = Color3,
    }, { __index = getfenv(1) })
    setfenv(chunk, env)
    local result = chunk()
    cache[module] = result
    return result
end

local function addModule(folderPath, relPath, source)
    local parts = string.split(relPath, "/")
    local folder = ensurePath(folderPath)
    for i = 1, #parts - 1 do
        folder = folder._children[parts[i]] or newInstance(parts[i], folder)
    end
    local module = newInstance(parts[#parts], folder)
    module._source = source
    module._path = folderPath .. "/" .. relPath
end
"""

RUNNER = r"""
local tests = mockRequire(ensurePath("ServerScriptService/DarkSky/Tests"):WaitForChild("SelfTests"))
local passed, failures = tests.run()
for _, failure in failures do print("FAIL  " .. failure) end
local scores = tests.scoreReport()
print(string.format("Leo score balance: start %d, all shielded %d, all fixed %d",
    scores.start, scores.allShielded, scores.allFixed))
print(string.format("%d passed, %d failed", passed, #failures))
if #failures > 0 then error("self tests failed", 0) end
"""


def long_string(text: str) -> str:
    level = 1
    while f"]{'=' * level}]" in text:
        level += 1
    eq = "=" * level
    return f"[{eq}[\n{text}]{eq}]"


def main() -> int:
    chunks = [PRELUDE]
    for mock_path, folder in FOLDERS.items():
        for file in sorted(folder.rglob("*.luau")):
            if file.name.endswith((".server.luau", ".client.luau")):
                continue
            rel = file.relative_to(folder).with_suffix("").as_posix()
            chunks.append(f'addModule("{mock_path}", "{rel}", {long_string(file.read_text())})')
    chunks.append(RUNNER)
    with tempfile.TemporaryDirectory() as tmp:
        bundle = pathlib.Path(tmp) / "self_tests_bundle.luau"
        bundle.write_text("\n".join(chunks))
        return subprocess.run(["luau", str(bundle)]).returncode


if __name__ == "__main__":
    sys.exit(main())
