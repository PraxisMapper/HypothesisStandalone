local sockets = require("socket")

--debugging helper function
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 --Split a string, since there's no built in split in lua.
 function Split(s, delimiter)
   result = {};
   for match in (s..delimiter):gmatch("(.-)"..delimiter) do
       table.insert(result, match);
   end
   return result;
end

function doesFileExist( fname, path )
    local results = false
   -- Path for the file
   local filePath = system.pathForFile( fname, path )
   if ( filePath ) then
       local file, errorString = io.open( filePath, "r" )
       if not file then
           -- doesnt exist or an error locked it out
           print("file doesnt exist")
           print(errorString)
       else
            print("Exists")
           -- File exists!
           results = true
           -- Close the file handle
           file:close()
       end
   end
   return results
end

--not a real sleep function but close enough?
function sleep(sec)
   sockets.select(nil, nil, sec)
end

function copyFile(srcName, srcPath, dstName, dstPath, overwrite)

   local results = false

   local fileExists = doesFileExist(srcName, srcPath)
   if (fileExists == false) then
       return nil -- nil = Source file not found
   end

   -- Check to see if destination file already exists
   if not (overwrite) then
       if (doesFileExist(dstName, dstPath)) then
           return 1 -- 1 = File already exists (don't overwrite)
       end
   end

   -- Copy the source file to the destination file
   local rFilePath = system.pathForFile(srcName, srcPath)
   local wFilePath = system.pathForFile(dstName, dstPath)

   local rfh = io.open(rFilePath, "rb")
   local wfh, errorString = io.open(wFilePath, "wb")

   if not (wfh) then
       -- Error occurred; output the cause
       print("File error: " .. errorString)
       return false
   else
       -- Read the file and write to the destination directory
       local data = rfh:read("*a")
       if not (data) then
           print("Read error!")
           return false
       else
           if not (wfh:write(data)) then
               print("Write error!")
               return false
           end
       end
   end

   results = 2 -- 2 = File copied successfully!

   -- Close file handles
   rfh:close()
   wfh:close()

   return results
end