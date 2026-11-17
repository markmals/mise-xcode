---@meta http
--- Mise's `http` module: https://mise.jdx.dev/plugin-lua-modules.html#http. Requests retry
--- transient failures, and requests to api.github.com get Mise's GitHub token. Calling these
--- functions inside `pcall` fails; use the `try_` variants when a request may fail.

---@class HttpRequest
---@field url string
---@field headers? table<string, string>

---@class HttpResponse
---@field status_code integer
---@field headers table<string, string> Header names are lower case
---@field body string Empty for `head`

---@class mise.http
local http = {}

--- Raises on a network error and returns every HTTP status, so check `status_code`.
---@param request HttpRequest
---@return HttpResponse
function http.get(request) end

---@param request HttpRequest
---@return HttpResponse
function http.head(request) end

--- Raises on a network error or an HTTP error status. Verifies nothing it downloads.
---@param request HttpRequest
---@param path string
function http.download_file(request, path) end

---@param request HttpRequest
---@return HttpResponse|nil response
---@return string|nil err
function http.try_get(request) end

---@param request HttpRequest
---@return HttpResponse|nil response
---@return string|nil err
function http.try_head(request) end

---@param request HttpRequest
---@param path string
---@return true|nil ok
---@return string|nil err
function http.try_download_file(request, path) end

return http
