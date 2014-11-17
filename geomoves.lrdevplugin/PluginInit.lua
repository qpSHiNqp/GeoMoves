require 'URLEncoder.lua'

PluginInit = {
    pluginID = "com.qpshinqp.lightroom.sdk.geomoves",
    clientID = "Ea9sQ7zu5qzw0mZzyYoBIyt5on4zg2RX",
    --clientSecret = "3cha6FgCyly86fh4XPR8BI8Icbk2K2NWPlEbMip3B3rvNYwH11hO0xj177A3ZC17",
    scope    = "location",
    oAuthURL = function(clientID, scope)
        return "https://api.moves-app.com/oauth/v1/authorize?response_type=code" ..
        "&client_id=" .. clientID .. 
        "&scope=" .. URLEncoder.encode(scope)
    end,
}
