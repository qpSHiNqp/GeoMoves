MovesUser = {}

function MovesUser.login( propertyTable )

    MovesAPI.getApiKeyAndSecret()

    local frob = MovesAPI.openAuthUrl()

    local waitForAuthDialogResult = LrDialogs.confirm(
    LOC "$$$/GeoMoves/WaitForAuthDialog/Message=Return to this window once you've authorized Lightroom on Moves.",
    LOC "$$$/GeoMoves/WaitForAuthDialog/HelpText=Once you've granted permission for Lightroom (in your web browser), click the Done button below.",
    LOC "$$$/GeoMoves/WaitForAuthDialog/DoneButtonText=Done",
    LOC "$$$/LrDialogs/Cancel=Cancel" )

    if waitForAuthDialogResult == 'cancel' then
        return
    end

    -- User has OK'd authentication. Get the user info.

    propertyTable.accountStatus = LOC "$$$/GeoMoves/AccountStatus/WaitingForMoves=Waiting for response from Moves..."

    local data = MovesAPI.callRestMethod( propertyTable, { method = 'moves.auth.getToken', frob = frob, suppressError = true, skipAuthToken = true } )

    local auth = data.auth

    if not auth then
        return
    end
end
