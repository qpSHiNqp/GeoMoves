require 'PluginInit.lua'
require 'OAuth.lua'

local function sectionsForTopOfDialog( f, _ )
    return {
        -- Section for the top of the dialog.
        {
            title = LOC "$$$/GeoMoves/PluginManager/Title=Plugin Settings",
            f:row {
                spacing = f:control_spacing(),

                f:static_text {
                    title = LOC "$$$/GeoMoves/PluginManager/NeedSignin=Sign-in to Moves to use this plugin.",
                    fill_horizontal = 1,
                },

                f:push_button {
                    width = 150,
                    title = LOC "$$$/GeoMoves/PluginManager/ButtonTitle=Connect to Moves",
                    enabled = true,
                    action = OAuth.authenticate,
                },
            },
        },

    }
end

return {
    sectionsForTopOfDialog = sectionsForTopOfDialog,
}
