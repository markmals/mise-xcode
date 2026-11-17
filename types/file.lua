---@meta file
--- Mise's `file` module: https://mise.jdx.dev/plugin-lua-modules.html#file. Relative paths resolve
--- against the directory Mise runs in, so build paths from the absolute paths in `ctx`.

---@class FileStat
---@field size integer
---@field is_file boolean
---@field is_dir boolean
---@field is_symlink boolean
---@field modified? integer
---@field accessed? integer
---@field created? integer
---@field mode? string Octal permissions such as `"644"`; nil on Windows

---@class mise.file
local file = {}

--- Joins the non-empty arguments with the host's separator; normalizes nothing.
---@param ... string
---@return string
function file.join_path(...) end

--- Raises when the file is missing or not UTF-8.
---@param path string
---@return string
function file.read(path) end

---@param path string
---@return boolean
function file.exists(path) end

--- Describes the link itself, not its target; nil when the path is missing.
---@param path string
---@return FileStat|nil
function file.stat(path) end

--- Full paths of the directory's immediate entries, sorted.
---@param dir string
---@return string[]
function file.list(dir) end

---@param pattern string
---@return string[]
function file.glob(pattern) end

--- Renames a file or directory, creating the parents of `to`; both must be on one file system.
---@param from string
---@param to string
function file.move(from, to) end

--- Creates the link `dst` pointing at `src`.
---@param src string
---@param dst string
function file.symlink(src, dst) end

return file
