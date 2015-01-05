local LrApplication     = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding         = import 'LrBinding'
local LrView            = import 'LrView'
local LrDialogs         = import 'LrDialogs'
local LrLogger          = import 'LrLogger'
local catalog           = LrApplication.activeCatalog()

CMMenuItem = {}

local ACTION_TYPE = {}
ACTION_TYPE.NONE      = ""
ACTION_TYPE.OVERWRITE = "ok"
ACTION_TYPE.SKIP      = "cancel"
ACTION_TYPE.ABORT     = "other"
CMMenuItem.defaultAction = ACTION_TYPE.NONE

function CMMenuItem.scanAndUpdateGPS ()
    local catPhotos = catalog:getTargetPhotos()
    local logger = LrLogger('GeoMoves:GPSUpdater')
    logger:enable("logfile")
    local action = ACTION_TYPE.NONE

    logger:trace("=== start to scan ===")
    for _, photo in ipairs( catPhotos ) do
        logger:trace("processing: " .. photo:getRawMetadata('path'))

        local dateTime = photo:getRawMetadata('dateTime')
        if (dateTime == nil) then
            dateTime = photo:getRawMetadata('dateTimeOriginal')
        end
        logger:trace("\tdatetime: " .. dateTime)

        local gps      = photo:getRawMetadata('gps')

        if (dateTime ~= nil) then -- dateTime acquired
            if (gps ~= nil) then -- this photo already has a gps metainfo.
                logger:trace("\tGPS latitude  = " .. gps.latitude)
                logger:trace("\tGPS longitude = " .. gps.longitude)

                action = CMMenuItem.defaultAction -- use default action
                if (action == ACTION_TYPE.NONE or action == nil) then
                    action = CMMenuItem.showModalDialog(photo) -- confirm to overwrite
                end
            else
                action = ACTION_TYPE.OVERWRITE
            end

            if (action == ACTION_TYPE.OVERWRITE) then
                -- TODO acquire GPS info from Moves and set it to photo
                -- lat, lng = MovesAdapter.getLatLng(dateTime)
                logger:trace("\twriting gps info")
                -- photo.setRawMetadata('gps', {
                --     latitude  = lat,
                --     longitude = lng,
                -- })
            elseif (action == ACTION_TYPE.ABORT) then
                -- aborting
                return
            end
        end
    end
end

function CMMenuItem.showModalDialog(photo)
    local bind = LrView.bind

    return LrFunctionContext.callWithContext('showConflictSolverDialog',
    function(context)
        -- [[ prepare viewFactories ]]
        local f     = LrView.osFactory()
        local props = LrBinding.makePropertyTable ( context )
        props.isChecked = false

        -- [[ prepare view contents ]]
        -- TODO: Layouting
        local c = f:column {
            bind_to_object = props,
            f:row {
                f:static_text {
                    title = LOC "$$$/GeoMoves/CMMenuItem/ConflictOccurredMessage=This item already has a GPS info. Overwrite it?",
                }
            },
            f:row {
                spacing = f:control_spacing(),
                f:picture {
                    value = photo:getRawMetadata('path')
                },
                f:checkbox {
                    title     = LOC "$$$/GeoMoves/CMMenuItem/ApplyToAll=Apply To All",
                    value     = bind 'isChecked',
                    alignment = "right",
                }
            }
        }

        -- [[ finally display the dialog box ]]
        local verb  = LrDialogs.presentModalDialog {
            title = LOC "$$$/GeoMoves/CMMenuItem/ConflictOccurredTitle=GPS Conflict Occurred",
            contents = c,
            actionVerb = LOC "$$$/GeoMoves/CMMenuItem/ActionVerb=Overwrite",
            cancelVerb = LOC "$$$/GeoMoves/CMMenuItem/CancelVerb=Skip",
            otherVerb  = LOC "$$$/GeoMoves/CMMenuItem/OtherVerb=Abort",
        }

        if props.isChecked == true then
            if verb == 'ok' then
                CMMenuItem.defaultAction = ACTION_TYPE.OVERWRITE
            elseif verb == 'cancel' then
                CMMenuItem.defaultAction = ACTION_TYPE.SKIP
            end
        end
        return verb
    end)
end

import 'LrTasks'.startAsyncTask( CMMenuItem.scanAndUpdateGPS )
