local LrHttp = import "LrHttp"

OAuth = {
    authenticate = function()
        LrHttp.openUrlInBrowser(
            PluginInit.oAuthURL(PluginInit.clientID, PluginInit.scope)
        )
    end
}
