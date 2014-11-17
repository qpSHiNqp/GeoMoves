--[[----------------------------------------------------------------------------

 Copyright 2014 S. Tanaka
 All Rights Reserved.

--------------------------------------------------------------------------------

Info.lua
Summary information for GeoMoves plug-in.

Adds two menu items to Lightroom.

------------------------------------------------------------------------------]]

return {

    LrSdkVersion = 3.0,
    LrSdkMinimumVersion = 1.3, -- minimum SDK version required by this plug-in

    LrToolkitIdentifier = 'com.qpshinqp.lightroom.sdk.geomoves',
    LrPluginName = LOC "$$$/GeoMoves/PluginName=GeoMoves",

    LrPluginInfoProvider = 'PluginInfoProvider.lua',

    -- Add the menu item to the Library menu.

    LrLibraryMenuItems = {
        {
            title = LOC "$$$/GeoMoves/MenuItems/AddGeotags=Add Geotags using Moves Trace",
            file = "AddGeotags.lua",
            enabledWhen = "photosAvailable",
        },
    },
    VERSION = { major=3, minor=0, revision=0, build=200000, },

}
