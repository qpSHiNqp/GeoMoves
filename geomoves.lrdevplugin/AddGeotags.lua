local LrApplication = import 'LrApplication'
local LrBinding     = import 'LrBinding'
local LrView        = import 'LrView'
local LrDialogs     = import 'LrDialogs'
local LrLogger      = import 'LrLogger'
local catalog       = LrApplication.activeCatalog()

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
    local action = ACTION_TYPE.NONE

    logger:trace("=== start to scan ===")
    for _, photo in ipairs( catPhotos ) do
        logger:enable("logfile")
        local dateTime = photo:getRawMetadata('dateTime')
        if (dateTime == nil) then
            dateTime = photo:getRawMetadata('dateTimeOriginal')
        end
        local gps      = photo:getRawMetadata('gps')
        logger:trace("processing:\t" .. photo:getRawMetadata('path'))
        logger:trace("\tdatetime:\t" .. dateTime)
        logger:trace("\tgps:\t" .. ((gps ~= nil) and gps or "(blank)"))

        if (dateTime ~= nil) then -- dateTime acquired
            if (gps ~= nil) then -- this photo already has a gps metainfo.
                action = CMMenuItem.defaultSolution -- use default action
                if (action == solution.NONE) then
                    action = CMMenuItem.showModalDialog(photo) -- confirm to overwrite
                end
            else
                action = ACTION_TYPE.OVERWRITE
            end

            if (action == ACTION_TYPE.OVERWRITE) then
                -- TODO acquire GPS info from Moves and set it to photo
                logger:trace("\twriting gps info")
                -- photo.setRawMetadata('gps', gps)
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

        -- [[ prepare thumbnail ]]
        local thumbView
        local thumb, err = cat:getPreview( photo, nil, nil, 4 )
        if thumb then
            thumbView = f:picture {
                value = thumb
            }
        else
            thumbView = {}
        end

        -- [[ prepare view contents ]]
        local c = f:column {
            bind_to_object = props,
            f:row {
                f:static_text {
                    title = LOC "$$$/GeoMoves/CMMenuItem/ConflictOccurredMessage=This item already has a GPS info. Overwrite it?",
                }
            },
            f:row {
                thumbView,
                f:checkbox {
                    title = LOC "$$$/GeoMoves/CMMenuItem/ApplyToAll=Apply To All",
                    value = bind 'isChecked',
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
                CMMenuItem.defaultSolution = solution.OVERWRITE
            elseif verb == 'cancel' then
                CMMenuItem.defaultSolution = solution.SKIP
            end
        end
        return verb
    end)
end

import 'LrTasks'.startAsyncTask( CMMenuItem.scanAndUpdateGPS )
