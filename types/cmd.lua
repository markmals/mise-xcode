---@meta cmd

---@class CommandOptions
---@field cwd? string
---@field env? table<string, string>
---@field timeout? number Seconds, greater than zero

---@class mise.cmd
local cmd = {}

---@param command string Shell code; quote interpolated arguments
---@param options? CommandOptions
---@return string stdout
function cmd.exec(command, options) end

return cmd
