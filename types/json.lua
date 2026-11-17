---@meta json
--- Mise's `json` module: https://mise.jdx.dev/plugin-lua-modules.html#json. JSON `null` decodes to
--- a truthy sentinel, not `nil`; compare against `json.decode("null")`.

---@class mise.json
local json = {}

---@param value any
---@return string
function json.encode(value) end

--- Raises on invalid JSON.
---@param text string
---@return any
function json.decode(text) end

return json
