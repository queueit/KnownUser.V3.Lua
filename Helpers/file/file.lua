----------------------------------------------------------------------------------------------------
-- file.lua
----------------------------------------------------------------------------------------------------
-- MODULE: file
--
-- DESCRIPTION:
--    This module contains a function to read the contents of a file into a string variable.
--    Note that this is intended for smaller files that can be read into memory as a whole.
--    The implementation of this module is heavily based on the implementation provided on
--    stackoverflow.com (https://stackoverflow.com/a/10387949/3433306) by the users
--    lhf (https://stackoverflow.com/users/107090/lhf) and
--    VasiliNovikov (https://stackoverflow.com/users/1091436/vasilinovikov).
--
-- USAGE:
--    local file = require("file")
--    local contents = file.readAll("path/to/file")
--
-- AUTHOR: Simon Studer (mail@studer.si)
--
-- LICENSE: Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
--
-- VERSION: 1 (2020-01-10)
----------------------------------------------------------------------------------------------------


local file = {}

-- Read file contents into a string variable and return that variable
function file.readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

return file
