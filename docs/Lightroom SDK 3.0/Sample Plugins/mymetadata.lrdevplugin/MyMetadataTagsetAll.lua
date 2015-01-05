--[[----------------------------------------------------------------------------

MyMetadataTagsetAll.lua
MyMetadata.lrplugin

--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2008-2010 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]


--------------------------------------------------------------------------------

 -- NOTE to developers reading this sample code: This file is used to generate
 -- the documentation for the "metadata tagset provider" section of the API
 -- reference material. This means it's more verbose than it would otherwise
 -- be, but also means that you can match up the documentation with an actual
 -- working example. It is not necessary for you to preserve any of the
 -- documentation comments in your own code.


--===========================================================================--
--[[ @sdk
--- The <i>metadata-tagset provider</i> is a Lua file that returns a tagset 
 -- definition for filtering metadata displayed in the Library module's Metadata
 -- panel.  Tagset defintions available to Lightroom are selected using the 
 -- drop-down menu at the top left of the Metadata panel. 
 -- <p>First supported in version 2.0 of the Lightroom SDK.</p>
 -- @module_type Plug-in provided

	module 'SDK - Metadata tagset provider' -- not actually executed, but suffices to trick LuaDocs

--]]


--============================================================================--

return {

--------------------------------------------------------------------------------
--- (string, required) This table member defines the localizable display name of
 -- the tagset, which appears in the popup menu for the Metadata panel.
	-- @name title
	-- @class property

	title = "EXIF and IPTC and Extensions",
	
--------------------------------------------------------------------------------
--- (string, required) This table member defines an identifier for this tagset
 -- that is unique within this plug-in. The name must conform to the same naming
 -- conventions as Lua variables; that is, it must start with a letter, followed
 -- by letters or numbers. Case is significant.
	-- @name id
	-- @class property

	id = 'MyMetadataTagsetAll',
	
--------------------------------------------------------------------------------
--- (table, required) This table member defines an array of metadata fields that
 -- appear in this tagset, in order of appearance.  Each entry in the items array
 -- identifies a field to be included in the Metadata menu. It can be a simple
 -- string specifying the field name, or an array that specifies the field name
 -- and additional information about that field.
 -- <p>If present, it should be a table containing the following elements:
	-- <ul>
		-- <li>(string) The first element in the array is the unique identifying
			-- name of the field, or one of the special values described below.</li>
		-- <li><b>height_in_lines</b>: (number) (optional) For text-entry fields,
			-- the number of lines of text for the field.</li>
		-- <li><b>label</b>: (string, optional) When the field name is the special
			-- value 'com.adobe.label', this is the localizable string to use as the section label.</li>
	-- </ul></p>
 -- <p>The field names accepted within tagsets are as follows:
	-- <ul>
		-- <li><b>com.adobe.filename</b>: The leaf name of the file
			-- (for example, "myFile.jpg").</li>
		-- <li><b>com.adobe.originalFilename.ifDiffers</b>: The leaf
			-- name of the file (for example, "myFile.jpg") prior to renaming.
			-- Only displayed if differs from the current file name.</li>			
		-- <li><b>com.adobe.sidecars</b>: If any "sidecar" files are
			-- associated with this file (for instance, .xmp or .thm files),
			-- this item will list the extensions of those files.</li>
		-- <li><b>com.adobe.copyname</b>: The name associated with this copy.</li>			
		-- <li><b>com.adobe.folder</b>: The name of the folder the file is in.</li>
		-- <li><b>com.adobe.filesize</b>: The formatted size of the file
			-- (for example, "6.01 MB")</li>
		-- <li><b>com.adobe.fileFormat</b>: The user-visible file type
			-- (DNG, RAW, etc.).</li>
		-- <li><b>com.adobe.metadataStatus</b>: The status of the metadata
			-- in the file, as compared to the metadata in the Lightroom catalog.
			-- Typical values (in English) are "Up to date", "Has been changed",
			-- or "Conflict exists". (This list is not exhaustive.)</li>
		-- <li><b>com.adobe.metadataDate</b>: Date/time when Lightroom last
			-- updated metadata in this file.</li>
		-- <li><b>com.adobe.audioAnnotation</b>: If an audio file (typically .wav file)
			-- is associated with this photo, this will contain the name of that
			-- file. Only displayed if there is an audio file.</li>
		-- <li><b>com.adobe.separator</b>: Inserts a dividing line.</li>
		-- <li><b>com.adobe.rating</b>: The user rating of the file (number of stars).</li>
		-- <li><b>com.adobe.colorLabels</b>: The name of assigned color label. Despite
			-- the plural name, only one color label can be assigned to a photo.</li>
		-- <li><b>com.adobe.title</b>: The title of photo.</li>
		-- <li><b>com.adobe.caption</b>: The caption for photo.</li>
		-- <li><b>com.adobe.label</b>: This entry allows you to insert a custom
			-- label describing the items that follow it.</li>
		-- <li><b>com.adobe.imageFileDimensions</b>: The original dimensions of
			-- the file (for example, "3072 x 2304").</li>
		-- <li><b>com.adobe.imageCroppedDimensions</b>: The cropped dimensions of
			-- file (for example, "3072 x 2304").</li>
		-- <li><b>com.adobe.exposure</b>: The exposure summary (for example, "1/60 sec at f/2.8")</li>
			-- exposureTime?
		-- <li><b>com.adobe.shutterSpeedValue</b>: The shutter speed (for example, "1/60 sec")</li>
		-- <li><b>com.adobe.apertureValue</b>: The aperture (for example, "f/2.8")</li>
		-- <li><b>com.adobe.brightnessValue</b>: The brightness value</li>
		-- <li><b>com.adobe.exposureBiasValue</b>: The exposure bias/compensation (for example, "-2/3 EV")</li>
		-- <li><b>com.adobe.flash</b>: Whether the flash fired or not (for example, "Did fire")</li>
		-- <li><b>com.adobe.exposureProgram</b>: The exposure program (for example, "Aperture priority")</li>
		-- <li><b>com.adobe.meteringMode</b>: The metering mode (for example, "Pattern")</li>
		-- <li><b>com.adobe.ISOSpeedRating</b>: The ISO speed rating (for example, "ISO 200")</li>
		-- <li><b>com.adobe.focalLength</b>: The focal length of lens as shot (for example, "132 mm")</li>
		-- <li><b>com.adobe.focalLength35mm</b>: The focal length as 35mm equivalent (for example, "211 mm")</li>
		-- <li><b>com.adobe.lens</b>: The lens (for example, "28.0-135.0 mm")</li>
		-- <li><b>com.adobe.subjectDistance</b>: The subject distance (for example, "3.98 m")</li>
		-- <li><b>com.adobe.dateTimeOriginal</b>: The date and time of capture (for example, "09/15/2005 17:32:50")
			-- Formatting can vary based on the user's localization settings</li>
		-- <li><b>com.adobe.dateTimeDigitized</b>: The date and time of scanning (for example, "09/15/2005 17:32:50")
			-- Formatting can vary based on the user's localization settings</li>
		-- <li><b>com.adobe.dateTime</b>: Adjusted date and time (for example, "09/15/2005 17:32:50")
			-- Formatting can vary based on the user's localization settings</li>
		-- <li><b>com.adobe.make</b>: The camera manufacturer</li>
		-- <li><b>com.adobe.model</b>: The camera model</li>
		-- <li><b>com.adobe.serialNumber</b>: The camera serial number</li>
		-- <li><b>com.adobe.artist</b>: The artist's name</li>
		-- <li><b>com.adobe.software</b>: The software used to process/create photo</li>
		-- <li><b>com.adobe.GPS</b>: The location of this photo (for example, "37&deg;56'10" N 27&deg;20'42" E")</li>
		-- <li><b>com.adobe.GPSAltitude</b>: The GPS altitude for this photo (for example, "82.3 m")</li>
		-- <li><b>com.adobe.creator</b>: The name of the person that created this image</li>
		-- <li><b>com.adobe.creatorJobTitle</b>: The job title of the person that created this image</li>
		-- <li><b>com.adobe.creatorAddress</b>: The address for the person that created this image</li>
		-- <li><b>com.adobe.creatorCity</b>: The city for the person that created this image</li>
		-- <li><b>com.adobe.creatorState</b>: The state or city for the person that created this image</li>
		-- <li><b>com.adobe.creatorZip</b>: The postal code for the person that created this image</li>
		-- <li><b>com.adobe.creatorCountry</b>: The country for the person that created this image</li>
		-- <li><b>com.adobe.creatorWorkPhone</b>: The phone number for the person that created this image</li>
		-- <li><b>com.adobe.creatorWorkEmail</b>: The email address for the person that created this image</li>
		-- <li><b>com.adobe.creatorWorkWebsite</b>: The web URL for the person that created this image</li>
		-- <li><b>com.adobe.headline</b>: A brief, publishable synopsis or summary of the contents of this image</li>
		-- <li><b>com.adobe.iptcSubjectCode</b>: Values from the IPTC Subject NewsCode Controlled Vocabulary (see: http://www.newscodes.org/)</li>
		-- <li><b>com.adobe.descriptionWriter</b>: The name of the person involved in writing, editing or correcting the description of the image </li>
		-- <li><b>com.adobe.category</b>: Deprecated field; included for transferring legacy metadata</li>
		-- <li><b>com.adobe.supplementalCategories</b>: Deprecated field; included for transferring legacy metadata</li>
		-- <li><b>com.adobe.dateCreated</b>: The IPTC-formatted creation date (for example, "2005-09-20T15:10:55Z")</li>
		-- <li><b>com.adobe.intellectualGenre</b>: A term to describe the nature of the image in terms of its intellectual or journalistic characteristics, such as daybook, or feature (examples at: http://www.newscodes.org/)</li>
		-- <li><b>com.adobe.scene</b>: Values from the IPTC Scene NewsCodes Controlled Vocabulary (see: http://www.newscodes.org/)</li>
		-- <li><b>com.adobe.location</b>: Details about a location which is shown in this image</li>
		-- <li><b>com.adobe.city</b>: The name of the city pictured in this image</li>
		-- <li><b>com.adobe.state</b>: The name of the state pictured in this image </li>
		-- <li><b>com.adobe.country</b>: The name of the country pictured in this image</li>
		-- <li><b>com.adobe.isoCountryCode</b>: The 2 or 3 letter ISO 3166 Country Code of the country pictured in this image</li>
		-- <li><b>com.adobe.jobIdentifier</b>: A number or identifier needed for workflow control or tracking</li>
		-- <li><b>com.adobe.instructions</b>: Information about embargoes, or other restrictions not covered by the Rights Usage field</li>
		-- <li><b>com.adobe.provider</b>: Name of person who should be credited when this image is published</li>
		-- <li><b>com.adobe.source</b>: The original owner of the copyright of this image</li>
		-- <li><b>com.adobe.copyright</b>: The copyright text for this image</li>
		-- <li><b>com.adobe.rightsUsageTerms</b>: Instructions on how this image can legally be used</li>
		-- <li><b>com.adobe.copyrightInfoURL</b></li>
		-- <li><b>com.adobe.allPluginMetadata</b>: All metadata defined by plug-ins.</li>
		-- <li><b><i>(plugin ID)</i>.*</b>: All metadata defined by the plug-in with the given ID.</li>
		-- <li><b><i>(plugin ID)</i>.<i>(field ID)</i></b>: A specific plug-in provided metadata field.</li>
	-- </ul>	
		-- <p>The following items are first supported in version 3.0 of the Lightroom SDK.</p>
	-- <ul>	
		-- <li><b>com.adobe.personInImage</b>: Name of a person shown in the image</li>
		-- <li><b>com.adobe.locationCreated</b>: The Location the photo was taken. Each element in the return table is a table which is a structure named LocationDetails as defined in the IPTC Extension spec. Definition details can be found at http://www.iptc.org/std/photometadata/2008/specification/. </li>
		-- <li><b>com.adobe.locationShown</b>: The Location shown in the image. Each element in the return table is a table which is a structure named LocationDetails as defined in the IPTC Extension spec. Definition details can be found at http://www.iptc.org/std/photometadata/2008/specification/. </li>
		-- <li><b>com.adobe.organisationInImageName</b>: Name of the organization or company which is featured in the image</li>
		-- <li><b>com.adobe.organisationInImageCode</b>: Code from a controlled vocabulary for identifying the organization or company which is featured in the image</li>
		-- <li><b>com.adobe.event</b>: Names or describes the specific event at which the photo was taken</li>
		-- <li><b>com.adobe.artworkOrObject</b>: A set of metadata about artwork or an object in the image. Each element in the return table is a table which is a structure named ArtworkOrObjectDetails as defined in the IPTC Extension spec. Definition details can be found at http://www.iptc.org/std/photometadata/2008/specification/. </li>
		-- <li><b>com.adobe.additionalModelInfo</b>: Information about the ethnicity and other facets of model(s) in a model-released image</li>
		-- <li><b>com.adobe.modelAge</b>: Age of human model(s) at the time this image was taken in a model released image</li>
		-- <li><b>com.adobe.minorModelAgeDisclosure</b>: Age of the youngest model pictured in the image, at the time that the image was made.</li>
		-- <li><b>com.adobe.modelReleaseStatus</b>: Summarizes the availability and scope of model releases authorizing usage of the likenesses of persons appearing in the photograph.</li>
		-- <li><b>com.adobe.modelReleaseID</b>: A PLUS-ID identifying each Model Release</li>
		-- <li><b>com.adobe.imageSupplier</b>: Identifies the most recent supplier of item, who is not necessarily its owner or creator. Each element in the return table is a table which is a structure named ImageSupplierDetail defined in PLUS. Definition details can be found at http://ns.useplus.org/LDF/ldf-XMPReference. </li>
		-- <li><b>com.adobe.registryId</b>: Both a Registry Item Id and a Registry Organization Id to record any registration of this item with a registry. Each element in the return table is a table which is a structure named RegistryEntryDetail as defined in the IPTC Extension spec. Definition details can be found at http://www.iptc.org/std/photometadata/2008/specification/. </li>
		-- <li><b>com.adobe.maxAvailWidth</b>: The maximum available width in pixels of the original photo from which this photo has been derived by downsizing</li>
		-- <li><b>com.adobe.maxAvailHeight</b>: The maximum available height in pixels of the original photo from which this photo has been derived by downsizing</li>
		-- <li><b>com.adobe.digitalSourceType</b>: The type of the source of this digital image, selected from a controlled vocabulary</li>
		-- <li><b>com.adobe.imageCreator</b>: Creator or creators of the image. Each element in the return table is a table which is a structure named ImageCreatorDetail defined in PLUS. Definition details can be found at http://ns.useplus.org/LDF/ldf-XMPReference. </li>
		-- <li><b>com.adobe.copyrightOwner</b>: Owner or owners of the copyright in the licensed image. Each element in the return table is a table which is a structure named CopyrightOwnerDetail defined in PLUS. Definition details can be found at http://ns.useplus.org/LDF/ldf-XMPReference. </li>
		-- <li><b>com.adobe.licensor</b>: A person or company that should be contacted to obtain a license for using the item or who has licensed the item. Each element in the return table is a table which is a structure named LicensorDetail defined in PLUS. Definition details can be found at http://ns.useplus.org/LDF/ldf-XMPReference. </li>
		-- <li><b>com.adobe.propertyReleaseID</b>: A PLUS-ID identifying each Property Release</li>
		-- <li><b>com.adobe.propertyReleaseStatus</b>: Summarizes the availability and scope of property releases authorizing usage of the likenesses of persons appearing in the photograph.</li>
		-- <li><b>com.adobe.digImageGUID</b>: Globally unique identifier for the item, created and applied by the creator of the item at the time of its creation</li>
		-- <li><b>com.adobe.plusVersion</b>: The version number of the PLUS standards in place at the time of the transaction</li>			
	-- </ul>
	-- @name items
	-- @class property

	items = {

"com.adobe.separator",
{
	formatter = "com.adobe.label",
	label = "keywordTags",
},

"com.adobe.keywordTags", -- does this work?

"com.adobe.separator",
{
	formatter = "com.adobe.label",
	label = "kwTagsForExport",
},

"com.adobe.keywordTagsForExport", -- does this work?

"com.adobe.separator",

		"com.adobe.filename",		
		"com.adobe.originalFilename.ifDiffers",
		"com.adobe.sidecars",
		"com.adobe.copyname",
		"com.adobe.folder",
		"com.adobe.filesize",
		"com.adobe.fileFormat",
		"com.adobe.metadataStatus",
		"com.adobe.metadataDate",
		"com.adobe.audioAnnotation",
		
		"com.adobe.separator",
		
		"com.adobe.rating",
		
		"com.adobe.separator",
		
		"com.adobe.colorLabels",
		
		"com.adobe.separator",
		
		"com.adobe.title",
	  {	"com.adobe.caption", height_in_lines = 3 },

		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "EXIF",
		},

		"com.adobe.imageFileDimensions",		-- dimensions
		"com.adobe.imageCroppedDimensions",

		"com.adobe.exposure",					-- exposure factors
		"com.adobe.brightnessValue",
		"com.adobe.exposureBiasValue",
		"com.adobe.flash",
		"com.adobe.exposureProgram",
		"com.adobe.meteringMode",
		"com.adobe.ISOSpeedRating",
		
		"com.adobe.focalLength",				-- lens info
		"com.adobe.focalLength35mm",
		"com.adobe.lens",
		"com.adobe.subjectDistance",

		"com.adobe.dateTimeOriginal",
		"com.adobe.dateTimeDigitized",
		"com.adobe.dateTime",

		"com.adobe.make",						-- camera
		"com.adobe.model",
		"com.adobe.serialNumber",

		"com.adobe.artist",
		"com.adobe.software",

		"com.adobe.GPS",						-- gps
		"com.adobe.GPSAltitude",

		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Contact",
		},
		
		"com.adobe.creator",
		{ formatter = "com.adobe.creatorJobTitle", form = "short_title" },
		{ formatter = "com.adobe.creatorAddress", form = "short_title" },
		{ formatter = "com.adobe.creatorCity", form = "short_title" },
		{ formatter = "com.adobe.creatorState", form = "short_title" },
		{ formatter = "com.adobe.creatorZip", form = "short_title" },
		{ formatter = "com.adobe.creatorCountry", form = "short_title" },
		{ formatter = "com.adobe.creatorWorkPhone", form = "short_title" },
		{ formatter = "com.adobe.creatorWorkEmail", form = "short_title" },
		{ formatter = "com.adobe.creatorWorkWebsite", form = "short_title" },
		
		"com.adobe.separator",
		{ formatter = "com.adobe.label",
			label = "IPTC",
		},

		"com.adobe.headline",
		"com.adobe.iptcSubjectCode",
		"com.adobe.descriptionWriter",
		"com.adobe.category",
		"com.adobe.supplementalCategories",
		
		{
			formatter = "com.adobe.label",
			label = "Image",
		},
		"com.adobe.dateCreated",
		"com.adobe.intellectualGenre",
		"com.adobe.scene",
		"com.adobe.location",
		"com.adobe.city",
		"com.adobe.state",
		"com.adobe.country",
		"com.adobe.isoCountryCode",
		{
			formatter = "com.adobe.label",
			label = "Workflow",
		},
		"com.adobe.jobIdentifier",
		"com.adobe.instructions",
		"com.adobe.provider",
		"com.adobe.source",
		{
			formatter = "com.adobe.label",
			label = "Copyright",
		},
	  { "com.adobe.copyrightState", pruneRedundantFields = false },
		"com.adobe.copyright",
		"com.adobe.rightsUsageTerms",
		"com.adobe.copyrightInfoURL",

		"com.adobe.separator",
		{ formatter = "com.adobe.label",
			label = "IPTC Extension",
		},
		
		-- might want to enable this if the user can ever do anything useful with it
		-- for example, he might want to look the photo up in a global db of some sort
		"com.adobe.digImageGUID",
		
		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Description",
		},
		
		{ formatter = "com.adobe.personInImage", form = "short_title" },
		
		{ formatter = "com.adobe.locationCreated", form = "short_title" },
		{ formatter = "com.adobe.locationShown", form = "short_title" },
		
		{ formatter = "com.adobe.organisationInImageName", form = "short_title" },
		{ formatter = "com.adobe.organisationInImageCode", form = "short_title" },
		"com.adobe.event",
		
		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Artworks",
		},
		
		{ formatter = "com.adobe.artworkOrObject", form = "short_title" },
		
		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Models",
		},
		
		{ formatter = "com.adobe.additionalModelInfo", form = "short_title" },
		"com.adobe.modelAge",
		{ formatter = "com.adobe.minorModelAgeDisclosure", form = "short_title" },
		"com.adobe.modelReleaseStatus",
		"com.adobe.modelReleaseID",

		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Admin",
		},
		
		"com.adobe.imageSupplier",
		"com.adobe.registryId",
		"com.adobe.maxAvailHeight",
		"com.adobe.maxAvailWidth",
		{ formatter = "com.adobe.digitalSourceType", form = "short_title" },
		
		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Rights",
		},
		
		"com.adobe.imageCreator",
		"com.adobe.copyrightOwner",
		"com.adobe.licensor",
		{ formatter = "com.adobe.propertyReleaseID", form = "short_title" },
		{ formatter = "com.adobe.propertyReleaseStatus", form = "short_title" },
		
		"com.adobe.separator",
		{
			formatter = "com.adobe.label",
			label = "Others",
		},
			
		"com.adobe.plusVersion",	
		
		"com.adobe.allPluginMetadata",
			-- separator and label will be added automatically for each plug-in
	},

}
