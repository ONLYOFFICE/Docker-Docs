local _M = {}

function _M.balance()
   local configuration = require("configuration")
   local cjson = require("cjson.safe")
   local ngx_balancer = require("ngx.balancer")
   local data
   local random_endpoint
   local wopisrc = ngx.var.arg_WOPISrc 
   local shardkey = ngx.var.arg_shardkey
   local api_key
   
   if wopisrc then
     api_key = wopisrc
   end

   if shardkey then
     api_key = shardkey
   end

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
   
       -- Iterate through the decoded table
   for _, entry in ipairs(decoded_data) do
             table.insert(matching_addresses, entry.address .. ":" .. entry.port)
   end

   random_endpoint = tostring((matching_addresses[math.random(1, #matching_addresses)]))

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
