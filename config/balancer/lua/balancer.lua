local _M = {}

function _M.balance()
   local configuration = require("configuration")
   local cjson = require("cjson.safe")
   local ngx_balancer = require("ngx.balancer")
   local data
   local random_endpoint
   local request_uri = ngx.var.request_uri
   local ver = request_uri:match("/([%d%.%-]+%-[^/]+)/")
   local wopisrc = ngx.var.arg_WOPISrc 
   local shardkey = ngx.var.arg_shardkey
   local api_key
   
   if wopisrc then
     api_key = wopisrc
   end

   if shardkey then
     api_key = shardkey
   end

   print(ngx.var.request_uri)

   repeat
     data = configuration.get_backends_data()
     print(data)
     local decoded_table = cjson.decode(data)
     print(tostring(decoded_table))
     local address = decoded_table[1].address
     print(cjson.encode(address))
     if address == "none" then
       ngx.sleep(1)
       print("No active shards found, waiting...")
     end
   until address ~= "none"
   local decoded_data = cjson.decode(data)
   local matching_addresses = {}
   
   if not api_key and not ver then
     for _, entry in ipairs(decoded_data) do
           table.insert(matching_addresses, entry.address .. ":" .. entry.port)
     end
   end

   if api_key then
     for _, entry in ipairs(decoded_data) do
           table.insert(matching_addresses, entry.address .. ":" .. entry.port)
     end
   else
     if ver then
       -- Iterate through the decoded table
       for _, entry in ipairs(decoded_data) do
         if entry.ver == ver then
             table.insert(matching_addresses, entry.address .. ":" .. entry.port)
         end
       end
     end
   end

   if ver and next(matching_addresses) == nil then
     print(string.format("WARN: Can't find endpoint in live table. VER: %s", ver))
     local reserved_data
     repeat
       reserved_data = configuration.get_reserved_data()
       print(string.format("RESERVED_DATA:%s", reserved_data))
       local decoded_reserved_table = cjson.decode(reserved_data)
       print(tostring(decoded_reserved_table))
       local address = decoded_reserved_table[1].address
       print(cjson.encode(address))
       if address == "none" then
         ngx.sleep(1)
         print("No active shards found, waiting...")
       end
     until address ~= "none"
     local reserved_decoded_data = cjson.decode(reserved_data)
     local reserved_addresses = {}
     for _, entry in ipairs(reserved_decoded_data) do
       if entry.ver == ver then
           table.insert(reserved_addresses, entry.address .. ":" .. entry.port)
       end
     end
     random_endpoint = tostring((reserved_addresses[math.random(1, #reserved_addresses)]))
   else
     random_endpoint = tostring((matching_addresses[math.random(1, #matching_addresses)]))
   end

   if api_key then
     return random_endpoint
   else
     ngx_balancer.set_more_tries(1)                                                               
                                                                                  
     local ok, err = ngx_balancer.set_current_peer(random_endpoint)                           
     if not ok then                                                                     
      ngx.log(ngx.ERR, "error while setting current upstream peer ", peer,                       
            ": ", err)                                                                          
     end
   end
end

return _M
