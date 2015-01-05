--
-- Sending Twitter Tweets from a Lightroom Plugin
-- Latest version: http://regex.info/blog/lua/twitter
--
-- Copyright 2009-2013 Jeffrey Friedl
-- (jfriedl@yahoo.com)
-- http://regex.info/blog/
--
-- This code is released under a Creative Commons CC-BY "Attribution" License:
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
--
-- It can be used for any purpose so long as the copyright notice and
-- web-page links above are maintained. Enjoy.
--
-- Version 6 (Jan 13, 2011)
-- (version history follows at the end of this file)
--
--
-- Twitter docs: https://dev.twitter.com/docs
--
-- This requires my sha1.lua package (http://regex.info/blog/lua/sha1)
-- This requires my JSON.lua package (http://regex.info/blog/lua/json)
--
-- This exposes two public functions:
--
--    Twitter_AuthenticateNewCredentials()
--    Twitter_SendTweet(credential_bundle, status_text)
--
-- The first leads the user through the procedure to grant your application
-- permission to send tweets on their behalf. It returns a "credential
-- bundle" (a Lua table) that can be cached locally (such as in the plugin
-- preferences -- see LrPrefs) and used for sending subsequent tweets
-- forever, or until the user  un-permissions your application at Twitter.
--
-- For example, if you have 'TWITTER_CREDENTIALS' in your
-- exportPresetFields list (with its default set to nil) and 'P' is the
-- local copy of the property table for the plugin (e.g. as passed to
-- sectionsForBottomOfDialog, you might have:
--
--
--|     f:view {
--|        bind_to_object = P,
--|        place = 'overlapping',
--|        fill_horizontal = 1,
--|     
--|        f:static_text {
--|           fill_horizontal = 1,
--|           visible = LrBinding.keyIsNotNil 'TWITTER_CREDENTIALS',
--|           LrView.bind {
--|              key = 'TWITTER_CREDENTIALS',
--|              transform = function(credentials)
--|                             return LOC("$$$/xxx=Authenticated to Twitter as @^1",
--|                                        credentials.screen_name)
--|                          end
--|           },
--|        },
--|        f:push_button {
--|           visible = LrBinding.keyIsNil 'TWITTER_CREDENTIALS',
--|           enabled = LrBinding.keyIsNotNil '_authenticating_at_twitter',
--|           title   = "Authenticate at Twitter",
--|           action  = function()
--|                        LrFunctionContext.postAsyncTaskWithContext("authenticate at twitter",
--|                           function(context)
--|                              context:addFailureHandler(function(status, error)
--|                                                           LrDialogs.message("INTERNAL ERROR", error, "critical")
--|                                                        end)
--|                              context:addCleanupHandler(function()
--|                                                           _authenticating_at_twitter = nil
--|                                                        end)
--|                              _authenticating_at_twitter = true
--|                              P.TWITTER_CREDENTIALS = Twitter_AuthenticateNewCredentials()
--|                           end)
--|                     end
--|        }
--|     }
--
--
-- and then later during export...
--
--
--|     local P = exportContext.propertyTable
--|     
--|     if P.TWITTER_CREDENTIALS then
--|        local result = Twitter_SendTweet(P.TWITTER_CREDENTIALS,
--|                                         "I just did something with Lightroom!")
--|        if result == nil then
--|           -- user has revoked permission, so we'll uncache the credential bundle
--|           P.TWITTER_CREDENTIALS = nil
--|        end
--|     end
--|     
--
--
-- LOCAL CONFIGURATION
--
-- Modify these two functions so that each returns a string, the "Consumer Key"
-- and "Consumer Secret", respectively, that Twitter generated for your specific
-- application when you registered it at Twitter (at http://twitter.com/oauth_clients/new)
--
-- THE KEY/SECRET PAIR SHOULD BE HIDDEN FROM THE PUBLIC. BE SURE TO COMPILE THIS MODULE,
-- AND CONSIDER OBFUSCATING THE VALUES HERE, e.g. INSTEAD OF
--     return "jhjg6x89jajah2"
-- DO
--     return "j".."h".."j".."g".."6".."x".."8".."9".."j".."a".."j".."a".."h".."2"
-- AT THE VERY LEAST.
--
local function consumer_secret()   return plugin.twitter_secret()          end
local function consumer_key()      return plugin.twitter_key()             end

--
-- Have this function return something unique to your application, such as a
-- hostname or reversed hostname, e.g. I use "regex.info/flickr" for my
-- upload-to-Flickr plugin. This is used only for generating a unique random
-- string, so the user will never see it.
--
local function string_unique_to_this_ap()   return "regex.info/" .. plugin.version_tag() end

local JSON = RemoteJSON()

--
-- Like URL-encoding, but following OAuth's specific semantics
--
--  https://dev.twitter.com/docs/auth/percent-encoding-parameters
--
local function oauth_percent_encode(val)
   return tostring(val:gsub('[^-._~0-9A-Za-z]', function(letter)
                                                   return string.format("%%%02x", letter:byte()):upper()
                                                end))
   --
   -- The wrapping tostring() above is to ensure that only one item is returned (it's easy to
   -- forget that gsub() returns multiple items). The same effect can be achieved by wrapping
   -- the return arg with parens, but tostring() is more explicit.
   --
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local LrMD5             = import 'LrMD5'
local LrXml             = import 'LrXml'
local LrDate            = import 'LrDate'
local LrDialogs         = import 'LrDialogs'
local LrHttp            = import 'LrHttp'
local LrStringUtils     = import 'LrStringUtils'
local LrFunctionContext = import 'LrFunctionContext'

local TwitterRequestTokenURL = 'https://api.twitter.com/oauth/request_token'
local TwitterAuthorizeURL    = 'https://api.twitter.com/oauth/authorize'
local TwitterAccessTokenURL  = 'https://api.twitter.com/oauth/access_token'

local nonce_counter = 0

local function generate_nonce()
   nonce_counter = nonce_counter + 1
   return tostring(nonce_counter) .. LrMD5.digest(string_unique_to_this_ap() .. tostring(math.random()) .. tostring(LrDate.currentTime()))
end


-- UnixTime of 978307200 is a CocoaTime of 0
local CocoTimeShift = 978307200

--
-- Returns the current time as a Unix timestamp.
--
local function current_unix_timestamp()
   return tostring(CocoTimeShift + math.floor(LrDate.currentTime() + 0.5))
end

local key_belongs_in_oauth_header = {
   oauth_verifier                 = true, -- https://dev.twitter.com/discussions/16443#comment-36618
   oauth_callback                 = true,
   oauth_consumer_key             = true,
   oauth_nonce                    = true,
   oauth_signature                = true,
   oauth_signature_method         = true,
   oauth_timestamp                = true,
   oauth_token                    = true,
   oauth_version                  = true,
}

--
-- Supply dummy debug-logging functions for when not used in Jeffrey's build environment
if not LogNote then
   function LogNote() end
   function DumpLog() end
end

--
-- Given the fodder for a request, add an authentication field to the request headers,
-- remove the relevant items from the query string parameters, and return any other parameters
-- as a fully-formed query string.
--
-- https://dev.twitter.com/docs/auth/creating-signature
--
local function prep_oauth_request(request_url, request_method, request_headers, query_string_args)

   Assert(isString(request_url))
   Assert(not request_url:match("[?#]"))
   Assert(request_method == "GET" or request_method == "POST")
   Assert(isTable(request_headers))
   Assert(isTable(query_string_args))

   local consumer_secret = consumer_secret()
   local token_secret    = query_string_args.oauth_token_secret or ""

   --
   -- Remove the token_secret from the query_string_args, 'cause we neither send nor sign it.
   -- (we use it for signing which is why we need it in the first place)
   --
   query_string_args.oauth_token_secret = nil

   -- Twitter does only HMAC-SHA1
   query_string_args.oauth_signature_method = 'HMAC-SHA1'


   --
   -- Prepare the signature
   --
   do
      --
      -- oauth-encode each key and value, and get them set up for a Lua table sort.
      -- http://tools.ietf.org/html/rfc5849#section-3.4.1.3.2
      --
      local encoded_args_data = { }
      for key, val in pairs(query_string_args) do
         table.insert(encoded_args_data, {
                         encoded_key = oauth_percent_encode(key),
                         encoded_val = oauth_percent_encode(val)
                      })
      end

      --
      -- Sort by key first, then value. You can't just combine them with '=' and then sort on that
      -- because that could break when one key is a prefix for another, e.g. "test" and "test1".
      --
      table.sort(encoded_args_data, function(a,b)
                                       if a.encoded_key < b.encoded_key then
                                          return true
                                       elseif a.encoded_key > b.encoded_key then
                                          return false
                                       else
                                          return a.encoded_val < b.encoded_val
                                       end
                                    end)
    
      --
      -- Now combine key and value into key=value
      --
      local parameter_pairs = { }
      for _, rec in ipairs(encoded_args_data) do
         table.insert(parameter_pairs, rec.encoded_key .. "=" .. rec.encoded_val)
      end

      --
      -- Now we have the query string we use for signing, and, after we add the
      -- signature, for the final as well.
      --
      local parameter_string = table.concat(parameter_pairs, "&")

      --
      -- Don't need it for Twitter, but if this routine is ever adapted for
      -- general OAuth signing, we may need to massage a version of the request_url to
      -- remove query elements, as described in http://oauth.net/core/1.0#rfc.section.9.1.2
      --
      -- More on signing:
      --   http://www.hueniverse.com/hueniverse/2008/10/beginners-gui-1.html
      --
      local signature_base_string = request_method .. '&' .. oauth_percent_encode(request_url) .. '&' .. oauth_percent_encode(parameter_string)


      -- http://tools.ietf.org/html/rfc5849#section-3.4.2
      local signing_key = oauth_percent_encode(consumer_secret) .. '&' .. oauth_percent_encode(token_secret)

      --
      -- Now have our text and key for HMAC-SHA1 signing
      --
      local hmac_binary = hmac_sha1_binary(signing_key, signature_base_string)

      --
      -- Base64 encode it
      --
      query_string_args.oauth_signature = LrStringUtils.encodeBase64(hmac_binary)

   end

   local header_pairs = { }
   local query_pairs = { }
   for key, value in pairs(query_string_args) do
      if key_belongs_in_oauth_header[key] then
         table.insert(header_pairs, sprintf('%s="%s"', oauth_percent_encode(key), oauth_percent_encode(value)))
         query_string_args.key = nil
      else
         table.insert(query_pairs, sprintf('%s=%s', oauth_percent_encode(key), oauth_percent_encode(value)))
      end
   end

   table.sort(header_pairs)
   table.insert(request_headers, {
                   field = "Authorization",
                   value = "OAuth " .. table.concat(header_pairs, ", ")
                })

   table.sort(query_pairs)
   local query_string = table.concat(query_pairs, "&")
   return query_string
end

--
-- Given a url endpoint, a GET/POST method, and a table of key/value args, build
-- the query string and sign it, returning the query string (in the case of a
-- POST) or, for a GET, the final url.
--
-- The args should also contain an 'oauth_token_secret' item, except for the
-- initial token request.

--
-- Show a dialog to the user inviting them to enter the 6-digit PIN that
-- the twitter page should have shown them after they granted this
-- application permission for access.
--
-- We return the PIN (as a string) if they provide it, nil otherwise.
--
local function GetUserPIN(context)

   LogNote("in GetUserPIN()")

   local PropertyTable = LrBinding.makePropertyTable(context)
   PropertyTable.PIN = ""

   local v = LrView.osFactory()
   local result = LrDialogs.presentModalDialog {
      title = LOC("$$$/xxx=Twitter Authentication PIN"),
      contents = v:view {
         bind_to_object = PropertyTable,
         v:static_text {
            title = LOC("$$$/xxx=After you have granted this application access at Twitter, enter the seven-digit PIN they provided:")
         },
         v:view {
            margin_top    = 30,
            margin_bottom = 30,
            place_horizontal = 0.5,
            place = 'horizontal',
            v:static_text {
               title = LOC("$$$/xxx=PIN"),
               font = {
                  name = "<system/default>",
                  size = 40, -- this is big, to match the way Twitter presents the PIN to the user
               }
            },
            v:spacer { width = 30 },
            v:edit_field {
               width_in_digits = 9, -- make a bit bigger than needed so the PIN will never "wrap" in the little box
               wraps = false,
               alignment = 'center',
               value = LrView.bind 'PIN',
               font = {
                  name = "<system/default>",
                  size = 40,
               },
               validate = function(view, value)
                             -- strip all whitespace, just in case some came over with a cut-n-paste
                             value = value:gsub('%s+', '')
                             if value:match('^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$') then
                                return true, value
                             else
                                return false, value, LOC("$$$/xxx=A Twitter authentication PIN is a seven-digit number")
                             end
                          end
            }
         }
      }
   }

   if result == "ok" and PropertyTable.PIN:match("^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$") then
      LogNote("PIN IS [" .. PropertyTable.PIN .. "]");
      return PropertyTable.PIN
   else
      LogNote("no pin")
      return nil
   end
end


--
-- If an HTTP request returns nothing, check the headers and return some kind of reasonable
-- error message.
--
local function error_from_header(reply, headers)

   if notTable(headers) then
      return LOC("$$$/xxx=couldn't connect to twitter --- Internet connection down?")
   elseif not headers.status then
      return LOC("$$$/xxx=couldn't connect to twitter -- Internet connection down?")
   end

   local note = LOC("$$$/xxx=Unexpected error reply (HTTP code #^1) from Twitter's servers", headers.status)

   if isString(reply) then
      -- https://dev.twitter.com/blog/making-api-responses-match-request-content-type
      local error = reply:match('"message":"([^"]+)",') or reply:match("<error[^>]*>(.-)</error>")
      if error then
         note = note .. ": " .. error
      end
   end

   return note
end

--
-- Start a sequence that allows the user to authenticate their Twitter account
-- to the plugin. This can't be run on the main LR task, so be sure it's downwind
-- of a LrTask.startAsyncTask() or LrFunctionContext.postAsyncTaskWithContext().
--
-- On failure, it returns nil and an error message.
--
-- On success, it returns a "credential bundle" table along the lines of:
--       
--       {
--          oauth_token        = "jahdhYHajdkajaeh"
--          oauth_token_secret = "GFWFGN$7gIN9Nf8huN&G^G#736nx7N&ZY#SyZz",
--          user_id            = "14235768",
--          screen_name        = "jfriedl",
--       }
--
-- You should cache this credential-bundle table somewhere (e.g. in the
-- Lightroom Prefs) and use it for subsequent interaction with Twitter on behalf
-- of the user, forever, unless attempting to use it results in an error
-- (at which point you probably want to uncache it).
-- 
function Twitter_AuthenticateNewCredentials()
   --
   -- First ping Twitter to get a request token.
   --
   local token
   local token_secret

   do
      local RequestHeaders = {}
      prep_oauth_request(TwitterRequestTokenURL, "GET", RequestHeaders, {
                            oauth_consumer_key = consumer_key(), --KEY(oauth_consumer_key)
                            oauth_timestamp    = current_unix_timestamp(), --KEY(oauth_timestamp)
                            oauth_version      = '1.0', --KEY(oauth_version)
                            oauth_callback     = "oob", --KEY(oauth_callback)
                            oauth_nonce        = generate_nonce(), --KEY(oauth_nonce)
                         })

      local result, headers = LrHttp.get(TwitterRequestTokenURL, RequestHeaders)

      if not result or headers.status ~= 200 then
         return nil, error_from_header(result, headers)
      end

      token        = result:match('oauth_token=([^&]+)')
      token_secret = result:match('oauth_token_secret=([^&]+)')

      if not token then
         DumpLog {
            resultBody    = result,
            resultHeaders = headers,
         }

         return nil, LOC("$$$/xxx=couldn't get request token from Twitter")
      end
   end

   --
   -- Tell the user that they'll have to permission their account to allow this
   -- app to have access, and give them a chance to bail.
   --
   do
      local url = TwitterAuthorizeURL .. '?oauth_token=' .. oauth_percent_encode(token)

      local result = LrDialogs.confirm(LOC("$$$/xxx=For this plugin to update your status at Twitter, you must grant it permission. Jump to the authentication page at Twitter?"),
                                    LOC("$$$/xxx=If you are currently logged into Twitter with your browser, you will authenticate under that login."),
                                    LOC("$$$/xxx=View authentication page at Twitter"))
      if result ~= "ok" then
         return nil, "Canceled"
      end


      --
      -- Now have the user visit the authorize url (with that token) to log in to Twitter
      -- and permission their account for your application.
      --
      LrHttp.openUrlInBrowser(url)

      LrTasks.sleep(1) -- give the browser a chance to open
   end

   --
   -- Now must get PIN from user
   --
   local PIN -- will be filled in by next call.... if NIL, then bail because user canceled

   LrFunctionContext.callWithContext("Twitter authentication PIN",
              function(context)
                 --
                 -- Set up a failure handle, just in case there's a programming bug in
                 -- this code. (my standard practice after creating a new context)
                 --
                 context:addFailureHandler(function(status, error)
                                              LrDialogs.message(LOC("$$$/xxx=INTERNAL ERROR"),
                                                                error,
                                                                "critical")
                                           end)

                 PIN = GetUserPIN(context)
              end)

   if not PIN then
      return nil, "Canceled"
   end


   --
   -- Now that your app should have permission, go to Twitter and get the
   -- authentication token that will let you interact with Twitter on behalf of the
   -- user.
   --
   do
      local RequestHeaders = {}
      local post_body = prep_oauth_request(TwitterAccessTokenURL, "POST", RequestHeaders, {
                                              oauth_consumer_key = consumer_key(), --KEY(oauth_consumer_key)
                                              oauth_timestamp    = current_unix_timestamp(), --KEY(oauth_timestamp)
                                              oauth_version      = '1.0', --KEY(oauth_version)
                                              oauth_callback     = "oob", --KEY(oauth_callback)
                                              oauth_nonce        = generate_nonce(), --KEY(oauth_nonce)
                                              oauth_token        = token, --KEY(oauth_token)
                                              oauth_token_secret = token_secret, --KEY(oauth_token_secret)
                                              oauth_verifier     = PIN, --KEY(oauth_verifier)
                                           })

      DumpLog(post_body, "post body to send PIN back")
      local result, headers = LrHttp.post(TwitterAccessTokenURL, post_body, RequestHeaders)


      if isTable(headers) and isNumber(headers.status) and headers.status == 401 then
         return nil, "Wrong PIN"
      end

      if not result or headers.status ~= 200 then
         return nil, error_from_header(result, headers)
      end

      local oauth_token        = result:match(       'oauth_token=([^&]+)')
      local oauth_token_secret = result:match('oauth_token_secret=([^&]+)')
      local user_id            = result:match(           'user_id=([^&]+)')
      local screen_name        = result:match(       'screen_name=([^&]+)')

      if oauth_token and oauth_token_secret and user_id and screen_name then
         --
         -- Got it
         --
         return {
            oauth_token        = oauth_token,
            oauth_token_secret = oauth_token_secret,
            user_id            = user_id,
            screen_name        = screen_name,
         }

      end

      return nil, LOC("$$$/xxx=Unexpected reply from Twitter: ^1",  result)
   end

end

--
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0verify_credentials
--
function Twitter_VerifyCredentials(credential_bundle)

   Assert(isTable(credential_bundle))
   Assert(isString(credential_bundle.oauth_token))
   Assert(isString(credential_bundle.oauth_token_secret))

   -- https://dev.twitter.com/docs/api/1.1/get/account/verify_credentials
   local url = "https://api.twitter.com/1.1/account/verify_credentials.json"

   local RequestHeaders = {}
   prep_oauth_request(url, "GET", RequestHeaders, {
                         oauth_consumer_key = consumer_key(), --KEY(oauth_consumer_key)
                         oauth_timestamp    = current_unix_timestamp(), --KEY(oauth_timestamp)
                         oauth_version      = '1.0', --KEY(oauth_version)
                         oauth_callback     = "oob", --KEY(oauth_callback)
                         oauth_nonce        = generate_nonce(), --KEY(oauth_nonce)
                         oauth_token        = credential_bundle.oauth_token, --KEY(oauth_token)
                         oauth_token_secret = credential_bundle.oauth_token_secret, --KEY(oauth_token_secret)
                      })
   local json = JSON:decode(LrHttp.get(url, RequestHeaders))

   --| {
   --|    contributors_enabled = false
   --|    created_at = "Thu May 28 04:09:04 +0000 2009"
   --|    default_profile = true
   --|    default_profile_image = true
   --|    description = ""
   --|    favourites_count = 0
   --|    follow_request_sent = false
   --|    followers_count = 1
   --|    following = false
   --|    friends_count = 1
   --|    geo_enabled = true
   --|    id = 43044196
   --|    id_str = "43044196"
   --|    is_translator = false
   --|    lang = "en"
   --|    listed_count = 0
   --|    location = ""
   --|    name = "just testing"
   --|    notifications = false
   --|    profile_background_color = "C0DEED"
   --|    profile_background_image_url = "http://a0.twimg.com/images/themes/theme1/bg.png"
   --|    profile_background_image_url_https = "https://si0.twimg.com/images/themes/theme1/bg.png"
   --|    profile_background_tile = false
   --|    profile_image_url = "http://a1.twimg.com/sticky/default_profile_images/default_profile_6_normal.png"
   --|    profile_image_url_https = "https://si0.twimg.com/sticky/default_profile_images/default_profile_6_normal.png"
   --|    profile_link_color = "0084B4"
   --|    profile_sidebar_border_color = "C0DEED"
   --|    profile_sidebar_fill_color = "DDEEF6"
   --|    profile_text_color = "333333"
   --|    profile_use_background_image = true
   --|    protected = true
   --|    screen_name = "jftest"
   --|    show_all_inline_media = false
   --|    status = table: 0x12a93b6b0:
   --|       | created_at = "Wed Aug 17 17:07:16 +0000 2011"
   --|       | favorited = false
   --|       | id = 1.0387555469611e+17
   --|       | id_str = "103875554696105984"
   --|       | retweet_count = 0
   --|       | retweeted = false
   --|       | source = "<a href="http://regex.info/blog/lightroom-goodies/zenfolio" rel="nofollow">Jeffrey's Export-to-Zenfolio Lightroom Plugin</a>"
   --|       | text = "test 5"
   --|       | truncated = false
   --|    statuses_count = 91
   --|    time_zone = "Tokyo"
   --|    utc_offset = 32400
   --|    verified = false
   --| }

   return json
end

--
--don't think I need this any more
--
--|    function Twitter_CurrentStatusID(credential_bundle)
--|       local result = Twitter_VerifyCredentials(credential_bundle) -- a side effect is that this'll return the current status
--|       return result.status.id_str
--|    end


--
-- Twitter_SendTweet(credential_bundle, status_text)
--
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update
--
-- Given a credential bundle (as returned by Twitter_AuthenticateNewCredentials),
-- and the text of a new tweet, send it.
--
-- Returns true on success, nil if the user has revoked permission for your app
-- (and thus the credential bundle should be discarded and no longer cached),
-- and false on other failure (e.g. network is down)
--
-- ARGS is an optional table of key/value pairs, with keys from among:
--     lat
--     long
--
function Twitter_SendTweet(credential_bundle, status_text, ARGS)

   Assert(isString(status_text))
   Assert(isTable(credential_bundle))
   Assert(isString(credential_bundle.oauth_token))
   Assert(isString(credential_bundle.oauth_token_secret))

   local withMedia = false
   if ARGS.image then
      withMedia = true
   end


   -- https://dev.twitter.com/docs/api/1.1/post/statuses/update
   local url = "https://api.twitter.com/1.1/statuses/update.json"

   local QUERY = {
      oauth_consumer_key = consumer_key(),
      oauth_timestamp    = current_unix_timestamp(),
      oauth_version      = '1.0',
      oauth_nonce        = generate_nonce(),
      oauth_token        = credential_bundle.oauth_token,
      oauth_token_secret = credential_bundle.oauth_token_secret,
   }

   local RequestHeaders = { }

   if withMedia then
      -- https://dev.twitter.com/docs/api/1.1/post/statuses/update_with_media
      url = "https://api.twitter.com/1.1/statuses/update_with_media.json"

      -- As per https://dev.twitter.com/docs/api/1/post/statuses/update_with_media, when sending media,
      -- generate the signature using only oauth_* fields.
      prep_oauth_request(url, "POST", RequestHeaders, QUERY)

      --
      -- Now that we've created the Authorization header, we flush the QUERY, leaving it
      -- empty to later accept the things we'll actually pass as multipart elements.
      --
      QUERY = {}

      if ARGS.possibly_sensitive then
         QUERY.possibly_sensitive = ARGS.possibly_sensitive
      end
   end

   QUERY.status = status_text

   if ARGS and ARGS.lat and ARGS.long then
      -- the next bit lops each value off at 8 digits (as per the API), but gets rid of trailing zeros to keep it tidy
      local lat = tonumber(ARGS.lat)
      local lon = tonumber(ARGS.long)
      -- don't add if it's 0,0.... sorry to those on a boat off Africa
      if lat and lon and (lat ~= 0 or lon ~= 0) then
         -- https://dev.twitter.com/comment/reply/1059/2139
         QUERY.lat  = sprintf("%.8f", lat):gsub('0+$', ''):gsub('.$', '')
         QUERY.long = sprintf("%.8f", lon):gsub('0+$', ''):gsub('.$', '')
      end
   end

   local resultText, headers

   if withMedia then
      local content = { }
      for key, value in pairs(QUERY) do
         table.insert(content, { name = key, value = value })
      end
      table.insert(content, {
                      name        = "media",
                      filePath    = ARGS.image,
                      fileName    = LrPathUtils.leafName(ARGS.image),
                      contentType = image_mime_type(ARGS.image),
                   })
 
      resultText, headers = LrHttp.postMultipart(url, content, RequestHeaders)

      if isTable(headers) and isNumber(headers.status) and headers.status == 413 then
         return false, LOC("$$$/xxx=The tweet could not be sent because the photo was too large.")
      end


   else

      local query_string = prep_oauth_request(url, "POST", RequestHeaders, QUERY)

      table.insert(RequestHeaders, {
                      field = 'Content-Type',
                      value = 'application/x-www-form-urlencoded',
                   })
      table.insert(RequestHeaders, {
                      field = 'Content-Length',
                      value = tostring(#query_string)
                   })

      --
      -- Twitter requires the Content-Type and Content-Length be set, or they refuse the authentication.
      --
      resultText, headers = LrHttp.post(url, query_string, RequestHeaders)
   end

   if not resultText or (isString(resultText) and resultText:match("^%s*$")) then
      return nil, error_from_header(headers)
   end

   -- Maybe can check JSON result after Feb 2012:  https://dev.twitter.com/blog/making-api-responses-match-request-content-type
   if resultText:match("Failed to validate") then -- should probably check result.error after the json decode
      LogNote("user revoked permission")
      return nil -- user revoked permission
   end

   local result = JSON:decode(resultText)

   -- https://dev.twitter.com/comment/reply/1059/2139
   if isTable(result.errors) and isTable(result.errors[1]) and isString(result.errors[1].message) then
      result.error = result.errors[1].message
   end

   if isString(result.error) then
      DumpLog {
         resultText = resultText,
         ERROR = result.error
      }
      LrDialogs.message(LOC("$$$/xxx=Tweet Rejected"),
                        LOC("$$$/xxx=Twitter rejected the tweet with this error: ^1", result.error),
                        "critical")
      return false, LOC("$$$/xxx=Tweet rejected by Twitter")
   end

   local ID = result.id_str --KEYS(id_str)

   if notString(ID) then
      DumpLog({
                 resultText = resultText,
              }, "No ID")

      LrDialogs.message(LOC("$$$/xxx=The tweet was rejected by Twitter"),
                        LOC("$$$/xxx=They don't say why... it may have been too long, a repeat of a recent tweet, or something else."),
                        "warning")
      return false, LOC("$$$/xxx=Tweet rejected by Twitter")
   end

   result.jfriedl_added_tweet_url = result.expanded_url or sprintf("https://twitter.com/#!/%s/status/%s", result.user.screen_name, ID)

   local VisitTweetView = LrView.osFactory():push_button {
      title = "Visit tweet at Twitter",
      action = function()
                  LrHttp.openUrlInBrowser(result.jfriedl_added_tweet_url)
               end
   }

   if withMedia then
      local resets_when = popupmenu_item_from_key(headers, 'field', "X-Mediaratelimit-Reset",     'value') --BAREOK(field)
      local count_left  = popupmenu_item_from_key(headers, 'field', "X-Mediaratelimit-Remaining", 'value')
      local full_quota  = popupmenu_item_from_key(headers, 'field', "X-Mediaratelimit-Limit",     'value')

      if isString(resets_when)  and isString(count_left) then
         local diff = tonumber(resets_when) - current_unix_timestamp()
         if diff > 0 then
            local time_remaining = timespan_description(diff)
            local note
            if count_left == "0" then
               note = LOC("$$$/xxx=With this tweet you've exhausted your photo-tweet limit until it resets to ^1 in ^2.", full_quota, time_remaining)
            else
               local photo_s = count_left == "1" and "photo" or "photos"
               note = LOC("$$$/xxx=You may now tweet up to ^1 more ^2 in the next ^3, after which your Twitter-photo quota resets to ^4.",
                          count_left,
                          photo_s,
                          time_remaining,
                          full_quota)
            end

            -- have not seen result.truncated ever turned on, but just in case....
            if result.truncated then
               note = note .. " " .. "However, the tweet text was apparently too long for some reason, and it was truncated by Twitter; you may wish to visit the tweet at Twitter to investigate."
            end
            
            LrDialogs.message("Photo Tweet Successful", note, "info", { accessoryView = VisitTweetView })
         end
      end

   elseif result.truncated then
      -- have not seen result.truncated ever turned on, but just in case....

      LrDialogs.message(LOC("$$$/xxx=Note: the tweet was truncated by Twitter"),
                        LOC("$$$/xxx=It was apparently too long; you may wish to visit the tweet at Twitter to investigate."),
                        "warning",
                        { accessoryView = VisitTweetView })
   end

   return true, result

end



--[[---------------------------------------------------------------------------------------------------

Version History

Version 1 (May 29, 2009)
      Initial public release

Version 2 (June 14, 2009)

      Sigh, it seems Twitter suddenly changed OAuth versions in a way that
      unilaterally breaks all prior applications, without notice.
      This version supports OAuth 1.0a, and provides better error detection
      and reporting, for the next time they pull a stunt like this.

Version 3 (Feb 2, 2010)

      Geotagging support.
      Also returns the full result from Twitter as a 2nd return value for Twitter_SendTweet.
      Added Twitter_VerifyCredentials()

Version 4 (Mar 22, 2010)

      Added a tostring() oauth_percent_encode() to ensure that it returns a single item, just to be safe
      in the future.

Version 5 (Dec 17, 2010)

      Updated Twitter urls as per
      http://groups.google.com/group/twitter-api-announce/browse_thread/thread/46ca6fcb9ea7eb49/34b013f4d092737f?show_docid=34b013f4d092737f&pli=1

Version 6 (Jan 13, 2011)

      Moved over to request-header authentication, and moved to all HTTPS requests.
      Twitters docs are a heck of a lot better now than they were a couple of years ago... thanks Twitter.


--]]---------------------------------------------------------------------------------------------------
