local jwt = require "resty.jwt"
local cjson = require "cjson"
local resty_rsa = require "resty.rsa"
local str = require "resty.string"

local rsa_public_key, rsa_private_key

function generate_key_pair()
    local rsa_config = {
        key_type = resty_rsa.KEY_TYPE.PRIVATE,
        key_size = 2048,
    }
    local rsa_public_key, rsa_priv_key, err = resty_rsa:generate_rsa_keys(2048)
    if not rsa_priv_key then
        ngx.log(ngx.ERR, "Failed to generate private key: ", err)
        return nil
    end
    return rsa_priv_key, rsa_public_key
end

function init_keys()
    if not rsa_private_key then
        local priv_key, pub_key = generate_key_pair()
        if not priv_key then
            return false
        end
        rsa_private_key, rsa_public_key = priv_key, pub_key
    end
    return true
end

function decode_and_set_headers()
    if not init_keys() then
        return
    end

    local jwt_token = ngx.req.get_headers()["x-amzn-oidc-data"]
    
    if not jwt_token then
        ngx.log(ngx.ERR, "No JWT token found in x-amzn-oidc-data header")
        return
    end

    local jwt_obj = jwt:load_jwt(jwt_token)
    
    if not jwt_obj.valid then
        ngx.log(ngx.ERR, "Invalid JWT token: " .. jwt_obj.reason)
        return
    end

    ngx.log(ngx.DEBUG, "Decoded JWT payload: " .. cjson.encode(jwt_obj.payload))

    -- Re-encode the JWT with our own key
    local claims = jwt_obj.payload
    claims.iss = "our-custom-issuer"  -- Set your custom issuer
    claims.iat = ngx.time()
    claims.exp = ngx.time() + 3600  -- 1 hour expiration

    local new_jwt, err = jwt:sign(rsa_private_key, {
        header = {typ = "JWT", alg = "RS256"},
        payload = claims
    })

    if not new_jwt then
        ngx.log(ngx.ERR, "Failed to create new JWT: ", err)
        return
    end

    -- Set the new JWT as a header
    ngx.req.set_header("X-Custom-JWT", new_jwt)
    ngx.log(ngx.ERR, "new JWT: ", new_jwt)

    -- Set individual claims as headers
    for k, v in pairs(claims) do
        ngx.req.set_header("X-User-" .. k, tostring(v))
    end
end

function get_public_key()
    init_keys()
    return rsa_public_key
end

decode_and_set_headers()

return {
    decode_and_set_headers = decode_and_set_headers,
    get_public_key = get_public_key
}