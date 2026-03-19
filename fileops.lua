local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")

local FileOps = {
    _root_dir = "/mnt/us",
}

function FileOps:setRootDir(dir)
    self._root_dir = dir
end

--- Resolve and validate a path, preventing path traversal.
--- Returns the full absolute path, or nil and an error message.
function FileOps:_resolvePath(rel_path)
    if not rel_path or rel_path == "" then
        rel_path = "/"
    end

    -- Normalize: remove double slashes, trim whitespace
    rel_path = rel_path:gsub("//+", "/"):gsub("^%s+", ""):gsub("%s+$", "")

    -- Block path traversal
    if rel_path:match("%.%.") then
        return nil, "Path traversal not allowed"
    end

    -- Ensure it starts with /
    if rel_path:sub(1, 1) ~= "/" then
        rel_path = "/" .. rel_path
    end

    local full_path = self._root_dir .. rel_path

    -- Normalize again after combining
    full_path = full_path:gsub("//+", "/")

    -- Remove trailing slash (except for root)
    if #full_path > 1 and full_path:sub(-1) == "/" then
        full_path = full_path:sub(1, -2)
    end

    -- Verify the resolved path is under root_dir
    if full_path:sub(1, #self._root_dir) ~= self._root_dir then
        return nil, "Access denied: path outside root directory"
    end

    return full_path
end

--- Validate a filename (no slashes, no dots-only, no null bytes)
function FileOps:_validateFilename(name)
    if not name or name == "" then
        return false, "Empty filename"
    end
    if name:match("[/\x00]") then
        return false, "Invalid characters in filename"
    end
    if name == "." or name == ".." then
        return false, "Invalid filename"
    end
    if #name > 255 then
        return false, "Filename too long"
    end
    return true
end

--- Get the relative path from root_dir
function FileOps:_getRelativePath(full_path)
    if full_path:sub(1, #self._root_dir) == self._root_dir then
        local rel = full_path:sub(#self._root_dir + 1)
        if rel == "" then rel = "/" end
        return rel
    end
    return full_path
end

--- Format file size for display
function FileOps:_formatSize(size)
    if size < 1024 then
        return size .. " B"
    elseif size < 1024 * 1024 then
        return string.format("%.1f KB", size / 1024)
    elseif size < 1024 * 1024 * 1024 then
        return string.format("%.1f MB", size / (1024 * 1024))
    else
        return string.format("%.1f GB", size / (1024 * 1024 * 1024))
    end
end

--- Detect MIME type from extension
function FileOps:_getMimeType(filename)
    local ext = filename:match("%.([^%.]+)$")
    if not ext then return "application/octet-stream" end
    ext = ext:lower()

    local mime_types = {
        -- Ebook formats
        epub = "application/epub+zip",
        pdf = "application/pdf",
        mobi = "application/x-mobipocket-ebook",
        azw = "application/vnd.amazon.ebook",
        azw3 = "application/vnd.amazon.ebook",
        fb2 = "application/x-fictionbook+xml",
        djvu = "image/vnd.djvu",
        cbz = "application/x-cbz",
        cbr = "application/x-cbr",
        -- Text
        txt = "text/plain",
        html = "text/html",
        htm = "text/html",
        css = "text/css",
        js = "application/javascript",
        json = "application/json",
        xml = "application/xml",
        -- Documents
        doc = "application/msword",
        docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        rtf = "application/rtf",
        -- Images
        png = "image/png",
        jpg = "image/jpeg",
        jpeg = "image/jpeg",
        gif = "image/gif",
        svg = "image/svg+xml",
        -- Archives
        zip = "application/zip",
        gz = "application/gzip",
        tar = "application/x-tar",
    }

    return mime_types[ext] or "application/octet-stream"
end

--- Get file type category
function FileOps:_getFileType(filename)
    local ext = filename:match("%.([^%.]+)$")
    if not ext then return "file" end
    ext = ext:lower()

    local ebook_exts = {epub=true, pdf=true, mobi=true, azw=true, azw3=true, fb2=true, djvu=true, cbz=true, cbr=true, kfx=true}
    local doc_exts = {txt=true, doc=true, docx=true, rtf=true, html=true, htm=true, md=true}
    local image_exts = {png=true, jpg=true, jpeg=true, gif=true, svg=true, bmp=true}

    if ebook_exts[ext] then return "ebook"
    elseif doc_exts[ext] then return "document"
    elseif image_exts[ext] then return "image"
    else return "file"
    end
end

--- List directory contents
function FileOps:listDirectory(rel_path, sort_by, sort_order, filter)
    local full_path, err = self:_resolvePath(rel_path)
    if not full_path then
        return nil, err
    end

    local attr = lfs.attributes(full_path)
    if not attr or attr.mode ~= "directory" then
        return nil, "Not a directory"
    end

    local entries = {}
    local ok, iter_err = pcall(function()
        for name in lfs.dir(full_path) do
            if name ~= "." and name ~= ".." then
                -- Skip hidden files starting with .
                if name:sub(1, 1) ~= "." then
                    -- Apply filter if present
                    local include = true
                    if filter and filter ~= "" then
                        include = name:lower():find(filter:lower(), 1, true) ~= nil
                    end

                    if include then
                        local entry_path = full_path .. "/" .. name
                        local entry_attr = lfs.attributes(entry_path)
                        if entry_attr then
                            local entry = {
                                name = name,
                                path = self:_getRelativePath(entry_path),
                                is_dir = entry_attr.mode == "directory",
                                size = entry_attr.size or 0,
                                size_formatted = self:_formatSize(entry_attr.size or 0),
                                modified = entry_attr.modification or 0,
                                type = entry_attr.mode == "directory" and "directory" or self:_getFileType(name),
                            }
                            table.insert(entries, entry)
                        end
                    end
                end
            end
        end
    end)

    if not ok then
        return nil, "Cannot read directory: " .. tostring(iter_err)
    end

    -- Sort entries (directories first, then by specified criteria)
    sort_by = sort_by or "name"
    sort_order = sort_order or "asc"

    table.sort(entries, function(a, b)
        -- Directories always come first
        if a.is_dir and not b.is_dir then return true end
        if not a.is_dir and b.is_dir then return false end

        local result
        if sort_by == "name" then
            result = a.name:lower() < b.name:lower()
        elseif sort_by == "size" then
            result = a.size < b.size
        elseif sort_by == "date" then
            result = a.modified < b.modified
        elseif sort_by == "type" then
            if a.type == b.type then
                result = a.name:lower() < b.name:lower()
            else
                result = a.type < b.type
            end
        else
            result = a.name:lower() < b.name:lower()
        end

        if sort_order == "desc" then
            return not result
        end
        return result
    end)

    -- Build breadcrumbs
    local breadcrumbs = {{name = "Home", path = "/"}}
    if rel_path and rel_path ~= "/" then
        local parts = {}
        for part in rel_path:gmatch("[^/]+") do
            table.insert(parts, part)
        end
        local cumulative = ""
        for _, part in ipairs(parts) do
            cumulative = cumulative .. "/" .. part
            table.insert(breadcrumbs, {name = part, path = cumulative})
        end
    end

    return {
        path = rel_path or "/",
        entries = entries,
        breadcrumbs = breadcrumbs,
        count = #entries,
    }
end

--- Download a file, sending it directly to the client socket
function FileOps:downloadFile(client, rel_path, server)
    local full_path, err = self:_resolvePath(rel_path)
    if not full_path then
        return false, err
    end

    local attr = lfs.attributes(full_path)
    if not attr or attr.mode ~= "file" then
        return false, "Not a file"
    end

    local f = io.open(full_path, "rb")
    if not f then
        return false, "Cannot open file"
    end

    local filename = full_path:match("([^/]+)$") or "download"
    local mime_type = self:_getMimeType(filename)
    local file_size = attr.size

    -- Send headers
    server:sendResponseHeaders(client, 200, {
        ["Content-Type"] = mime_type,
        ["Content-Length"] = tostring(file_size),
        ["Content-Disposition"] = 'attachment; filename="' .. filename .. '"',
        ["Connection"] = "close",
    })

    -- Send file in chunks
    local CHUNK_SIZE = 65536
    while true do
        local chunk = f:read(CHUNK_SIZE)
        if not chunk then break end
        local sent, send_err = client:send(chunk)
        if not sent then
            f:close()
            return false, "Send error: " .. tostring(send_err)
        end
    end

    f:close()
    return true
end

--- Handle multipart file upload
function FileOps:handleUpload(rel_dir, body, boundary)
    local dir_path, err = self:_resolvePath(rel_dir)
    if not dir_path then
        return false, err
    end

    local attr = lfs.attributes(dir_path)
    if not attr or attr.mode ~= "directory" then
        return false, "Upload directory does not exist"
    end

    -- Parse multipart form data
    local delimiter = "--" .. boundary
    local end_delimiter = delimiter .. "--"

    -- Split by boundary
    local parts = {}
    local search_start = 1
    while true do
        local boundary_start = body:find(delimiter, search_start, true)
        if not boundary_start then break end

        local part_start = body:find("\r\n", boundary_start, true)
        if not part_start then break end
        part_start = part_start + 2

        local next_boundary = body:find(delimiter, part_start, true)
        if not next_boundary then break end

        local part_data = body:sub(part_start, next_boundary - 3) -- -3 for preceding \r\n
        table.insert(parts, part_data)
        search_start = next_boundary
    end

    local uploaded_count = 0
    for _, part in ipairs(parts) do
        -- Split headers from body
        local header_end = part:find("\r\n\r\n", 1, true)
        if header_end then
            local headers_str = part:sub(1, header_end - 1)
            local file_data = part:sub(header_end + 4)

            -- Extract filename from Content-Disposition
            local filename = headers_str:match('filename="([^"]+)"')
            if filename and filename ~= "" then
                -- Clean up filename (remove path components from some browsers)
                filename = filename:match("([^/\\]+)$") or filename

                -- Validate filename
                local valid, valid_err = self:_validateFilename(filename)
                if valid then
                    local file_path = dir_path .. "/" .. filename
                    local f = io.open(file_path, "wb")
                    if f then
                        f:write(file_data)
                        f:close()
                        uploaded_count = uploaded_count + 1
                        logger.info("FileSync: Uploaded", filename, "to", dir_path)
                    else
                        logger.warn("FileSync: Cannot write file", file_path)
                    end
                else
                    logger.warn("FileSync: Invalid filename:", filename, valid_err)
                end
            end
        end
    end

    if uploaded_count > 0 then
        return true
    else
        return false, "No files were uploaded"
    end
end

--- Create a directory
function FileOps:createDirectory(rel_path)
    local full_path, err = self:_resolvePath(rel_path)
    if not full_path then
        return false, err
    end

    -- Check parent directory exists
    local parent = full_path:match("(.+)/[^/]+$")
    if parent then
        local parent_attr = lfs.attributes(parent)
        if not parent_attr or parent_attr.mode ~= "directory" then
            return false, "Parent directory does not exist"
        end
    end

    -- Check if already exists
    local attr = lfs.attributes(full_path)
    if attr then
        return false, "Path already exists"
    end

    -- Validate directory name
    local dir_name = full_path:match("([^/]+)$")
    local valid, valid_err = self:_validateFilename(dir_name)
    if not valid then
        return false, valid_err
    end

    local ok, mkdir_err = lfs.mkdir(full_path)
    if not ok then
        return false, "Cannot create directory: " .. tostring(mkdir_err)
    end

    logger.info("FileSync: Created directory", full_path)
    return true
end

--- Rename a file or directory
function FileOps:rename(old_rel_path, new_rel_path)
    local old_path, err1 = self:_resolvePath(old_rel_path)
    if not old_path then
        return false, err1
    end

    local new_path, err2 = self:_resolvePath(new_rel_path)
    if not new_path then
        return false, err2
    end

    -- Check source exists
    local attr = lfs.attributes(old_path)
    if not attr then
        return false, "Source does not exist"
    end

    -- Check destination doesn't exist
    local dest_attr = lfs.attributes(new_path)
    if dest_attr then
        return false, "Destination already exists"
    end

    -- Validate new name
    local new_name = new_path:match("([^/]+)$")
    local valid, valid_err = self:_validateFilename(new_name)
    if not valid then
        return false, valid_err
    end

    local ok, rename_err = os.rename(old_path, new_path)
    if not ok then
        return false, "Cannot rename: " .. tostring(rename_err)
    end

    logger.info("FileSync: Renamed", old_path, "to", new_path)
    return true
end

--- Delete a file or directory (directory must be empty)
function FileOps:delete(rel_path)
    local full_path, err = self:_resolvePath(rel_path)
    if not full_path then
        return false, err
    end

    -- Prevent deleting the root directory
    if full_path == self._root_dir then
        return false, "Cannot delete root directory"
    end

    local attr = lfs.attributes(full_path)
    if not attr then
        return false, "Path does not exist"
    end

    if attr.mode == "directory" then
        -- Recursively delete directory contents
        local ok, del_err = self:_deleteRecursive(full_path)
        if not ok then
            return false, del_err
        end
    else
        local ok, del_err = os.remove(full_path)
        if not ok then
            return false, "Cannot delete file: " .. tostring(del_err)
        end
    end

    logger.info("FileSync: Deleted", full_path)
    return true
end

--- Recursively delete a directory and its contents
function FileOps:_deleteRecursive(path)
    for name in lfs.dir(path) do
        if name ~= "." and name ~= ".." then
            local entry_path = path .. "/" .. name
            local entry_attr = lfs.attributes(entry_path)
            if entry_attr then
                if entry_attr.mode == "directory" then
                    local ok, err = self:_deleteRecursive(entry_path)
                    if not ok then return false, err end
                else
                    local ok, err = os.remove(entry_path)
                    if not ok then
                        return false, "Cannot delete: " .. tostring(err)
                    end
                end
            end
        end
    end

    local ok, err = lfs.rmdir(path)
    if not ok then
        return false, "Cannot remove directory: " .. tostring(err)
    end
    return true
end

return FileOps
