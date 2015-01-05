MovesAPI = {}

function MovesAPI.callRestMethod()
end

function MovesAPI.getApiKeyAndSecret()
end

function MovesAPI.openAuthUrl()
    -- Request the frob that we need for authentication.
    local data = FlickrAPI.callRestMethod( nil, { method = 'flickr.auth.getFrob', skipAuthToken = true } )

    -- Get the frob from the response.
    local frob = assert( data.frob._value )

    -- Do the authentication. (This is not a standard REST call.)
    local apiKey = FlickrAPI.getApiKeyAndSecret()
    local authApiSig = FlickrAPI.makeApiSignature{ perms = 'delete', frob = frob }
    local authURL = string.format( 'http://flickr.com/services/auth/?api_key=%s&perms=delete&frob=%s&api_sig=%s',
    apiKey, frob, authApiSig )

    LrHttp.openUrlInBrowser( authURL )

    return frob
end
