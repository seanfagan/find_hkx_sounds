--- Interactive shell script which scans the designated HKX files for
-- instances of "SoundPlay.____" tags (indicating that a sound descriptor
-- will be triggered by the animation). Prints the results in a JSON format.

local json = require'json'  -- JSON, to print results in JSON format
local lfs = require'lfs'  -- LuaFileSystem, to read files in directory

local SCRIPT_VERSION = '0.2'
local SEARCH_PATTERN = 'SoundPlay%.([%w%p]+)%z'

print('==============================')
print('Running find_hkx_sounds.lua...')
print('Script version: '..SCRIPT_VERSION)
print('Lua version: '.._VERSION)
print()

--- Check the file extension at path and return if it is .hkx
-- @param path string: Path to file
-- @return bool: If the file is HKX
local function is_hkx(path)
    return string.find(path, '%.[hH][kK][xX]', -4) and true or false
end


--- Open the file at path in binary read mode. Search for any
-- matches of the search pattern and print the results.
-- @param path string: Path to HKX file
-- @return table: All sound names found in HKX file
local function scan_hkx_for_sounds(path)
    local file = assert(io.open(path, 'rb'))
    local data = file:read('*all')
    local results = {}
    local count = 0

    for match in string.gfind(data, SEARCH_PATTERN) do
        count = count + 1
        results[count] = match
    end
    return results
end

--- Open the directory at path and search for HKX files. If
-- this is a dry run, return the number of HKX files found.
-- Otherwise, scan each HKX file for sounds and return the
-- results.
-- @param path string: Path to directory containing HKX files
-- @param is_dry_run bool: If true, do not open the HKX files
-- @return int, table: Count of HKX files, and sounds found in each file
local function scan_dir_for_hkx(path, is_dry_run)
    local count = 0
    local results = {}

    for file in lfs.dir(path) do
        if is_hkx(file) then
            count = count + 1
            if is_dry_run == false then
                local file_result = scan_hkx_for_sounds(path..'/'..file)
                if next(file_result) ~= nil then
                    results[file] = file_result
                end
            end
        end
    end
    return count, results
end


--- Encode results in JSON format and print
-- @param results table: Table to print
local function print_results_json(results)
    print('Printing results in JSON format...')
    print(json.encode(results))
end

--- Interactive flow for users that provided a path to a directory.
-- @param path string: Path to directory
-- @return table: Sounds found in files within directory
local function user_flow_directory(path)
    print('Scanning directory for hkx files...')
    local hkx_count, _ = scan_dir_for_hkx(path, true)
    if hkx_count == 0 then
        print('No hkx files found in directory.')
        return
    end

    print(hkx_count..' hkx files found. Scan them for sounds? y/n: ')
    local in_consent = io.read()
    if in_consent ~= 'y' then
        return
    end
    local _, results = scan_dir_for_hkx(path, false)
    return results
end


--- Interactive flow for users that provided a path to a file.
-- @param path string: Path to file
-- @return table: Sounds found in file
local function user_flow_file(path)
    print('Scanning file for sounds...')
    local results = {}
    local file_result = scan_hkx_for_sounds(path)
    if next(file_result) == nil then
        print('No sounds found in hkx.')
    else
        return file_result
    end
end



--- Interactive flow for users.
local function user_flow()
    local results

    print('Please provide a path to hkx files:')
    local in_path = io.read()
    in_path = string.gsub(in_path, '"(.+)"', '%1')  -- remove ""
    local in_path_attr = lfs.attributes(in_path)

    if in_path_attr == nil then
        print('Error: Bad path')
    elseif in_path_attr.mode == 'directory' then
        results = user_flow_directory(in_path)
    elseif is_hkx(in_path) then
        results = user_flow_file(in_path)
    else
        print('Error: Not an hkx or directory')
    end

    if results ~= nil then
        print_results_json(results)
    end
end

user_flow()
