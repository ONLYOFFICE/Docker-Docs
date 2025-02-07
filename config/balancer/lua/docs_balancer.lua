local _M = {}
function _M.balance_ep()
   local configuration = require("configuration")
   local cjson = require("cjson.safe")
   local ngx_balancer = require("ngx.balancer")
   local data
   local random_endpoint
   local request_uri = ngx.var.request_uri
   local ver = request_uri:match("/([%d%.%-]+%-[^/]+)/")
   local wopisrc = ngx.var.arg_WOPISrc 
   local shardkey = ngx.var.arg_shardkey
   local log_level = os.getenv("LOG_LEVEL")

   local rr_live_dict = ngx.shared.rr_live_index
   local rr_reserved_dict = ngx.shared.rr_reserved_index

   local api_key

   if wopisrc then
     api_key = wopisrc
   end
   if shardkey then
     api_key = shardkey
   end

   repeat
     data = configuration.get_backends_data()
     if log_level == "DEBUG" then
       print(string.format("DEBUG: CURRENT LIVE TABLE:%s", data))
     end
     local decoded_table = cjson.decode(data)
     local address = decoded_table[1].address
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
     if log_level == "DEBUG" then
       print(string.format("DEBUG: Can't find endpoint in live table. VER: %s", ver))
     end
     local reserved_data
     repeat
       reserved_data = configuration.get_reserved_data()
       if log_level == "DEBUG" then
         print(string.format("DEBUG: CURRENT RESERVER TABLE:%s", reserved_data))
       end
       local decoded_reserved_table = cjson.decode(reserved_data)
       local address = decoded_reserved_table[1].address
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

     local idx = rr_reserved_dict:get("last_used_index") or 1
     local max_index = #reserved_addresses

     if idx > max_index then
       idx = 1
     end

     random_endpoint = reserved_addresses[idx]

     -- Update to the next index for the next request
     idx = idx + 1
     if idx > #reserved_addresses then
       idx = 1
     end

     rr_reserved_dict:set("last_used_index", idx)
   else
     local idx = rr_live_dict:get("last_used_index") or 1
     local max_index = #matching_addresses

     if idx > max_index then
       idx = 1
     end

     random_endpoint = matching_addresses[idx]

     -- Update to the next index for the next request
     idx = idx + 1
     if idx > #matching_addresses then
       idx = 1
     end

     rr_live_dict:set("last_used_index", idx)
   end

   if api_key and string.len(api_key) > 0 then
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
