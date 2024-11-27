local jwt = require "resty.jwt"
local cjson = require "cjson"



function decode_and_set_headers()
    local jwt_token = ngx.req.get_headers()["x-amzn-oidc-data"]
    
    if not jwt_token then
        ngx.log(ngx.ERR, "No JWT token found in x-amzn-oidc-data header")
        ngx.req.set_header("Jwt-Parse", "NoToken")
        return
    end

    local jwt_obj = jwt:load_jwt(jwt_token)
    
    if not jwt_obj.valid then
        ngx.log(ngx.ERR, "Invalid JWT token: " .. jwt_obj.reason)
        ngx.req.set_header("Jwt-Parse", "InvalidToken")
        return
    end

    ngx.log(ngx.DEBUG, "Decoded JWT payload: " .. cjson.encode(jwt_obj.payload))

    -- Re-encode the JWT with our own key
    local claims = jwt_obj.payload

    -- Set individual claims as headers
    for k, v in pairs(claims) do
        ngx.req.set_header("X-User-" .. k, tostring(v))
    end

    ngx.req.set_header("Jwt-Parse", "Success")
end

decode_and_set_headers()

return {
    decode_and_set_headers = decode_and_set_headers,
}