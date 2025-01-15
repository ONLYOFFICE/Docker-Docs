local endpoints_data = ngx.shared.endpoints_data
local reserved_data = ngx.shared.reserved_data
local cjson = require("cjson.safe")

local _M = {}

local function fetch_body()         
  ngx.req.read_body()
  local body = ngx.req.get_body_data()
  return body
end

local function check_none(endpoints)
  if string.match(endpoints, "none") then
	  return true
  end
end

function _M.get_backends_data()
    return endpoints_data:get("backends")
end

function _M.get_reserved_data()
    return reserved_data:get("backends")
end

local function handle_endpoints(type)
    local dict
    local dict_str
    
    if type == "live" then
      dict = ngx.shared.endpoints_data
      dict_str = "LIVE_ENDPOINTS"
    else if type == "reserved" then 
      dict = ngx.shared.reserved_data
      dict_str = "RESERVED_ENDPOINTS"
    end
    end

    print(string.format("[BALANCER.HANDLER]: New endpoints update request income. Used dict: %s", dict_str))
    if ngx.var.request_method ~= "POST" and ngx.var.request_method ~= "GET" then
      ngx.status = ngx.HTTP_BAD_REQUEST                                                  
      ngx.print("[BALANCER.HANDLER]: Only POST and GET requests are allowed!")
      return                                                                   
    end
  
    local endpoints = fetch_body()
    if not endpoints then                                                                             
       ngx.log(ngx.ERR, "[BALANCER.HANDLER]: look's like body empty. Unable to read valid request body")                   
       ngx.status = ngx.HTTP_BAD_REQUEST                                                              
       return                                                                                         
    end 
    
    local none_status = check_none(endpoints)
      
    if none_status then
       print(string.format("[BALANCER.HANDLER]: Empty endpoint table is come, seting backends to none in dict: %s", dict_str))
       local none_endpoints = '[{"address": "none"}]'
       local success, err = dict:set("backends", none_endpoints)
       if not success then
          ngx.log(ngx.ERR, "[BALANCER.HANDLER]: dynamic-configuration: error updating configuration: " .. tostring(err))
          ngx.status = ngx.HTTP_BAD_REQUEST
          return
       end
    else
       local success, err = dict:set("backends", endpoints)
       if not success then
          ngx.log(ngx.ERR, "[BALANCER.HANDLER]: dynamic-configuration: error updating configuration: " .. tostring(err))
          ngx.status = ngx.HTTP_BAD_REQUEST
          return
       end
    end
    
    ngx.status = ngx.HTTP_CREATED
  end

function _M.handle()
  if ngx.var.request_uri == "/configuration" then
    local type = "live"
    handle_endpoints(type)
    return
  end

  if ngx.var.request_uri == "/configuration_reserved" then
    local type = "reserved"
    handle_endpoints(type)
    return
  end
end

return _M
