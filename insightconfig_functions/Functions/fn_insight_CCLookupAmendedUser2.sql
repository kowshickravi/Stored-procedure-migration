IF OBJECT_ID('dbo.fn_insight_CCLookupAmendedUser2') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_CCLookupAmendedUser2() RETURNS int AS BEGIN RETURN 0 end ')
GO

ALTER FUNCTION dbo.fn_insight_CCLookupAmendedUser2 
(
	@vcAmendedBy		varchar(255)
)
RETURNS varchar(255)
AS
BEGIN
	--------------------------------------
	-- The WhoAmended_nt_username field is 
	-- populated with data of the format
	-- User=1 when modifications take place
	-- by Insight2 stored procs. This function
	-- extracts the id after the = and looks
	-- up the full name and username in the AuthorisedUser
	-- table and returns 'full name (user name)'.
	-- If the passed in data is not in 
	-- the Insight2 format then the passed in
	-- data is simply returned as 'System User'
	--------------------------------------

	DECLARE	@vcUserId	varchar(255), 
			@iUserId	int


	-- Get rid of any leading or trailing spaces
	SELECT @vcAmendedBy 	= Ltrim(Rtrim(@vcAmendedBy))

	IF LEFT(@vcAmendedBy, 5) = 'User='
	BEGIN

		-- Extract the user id part
		SELECT @vcUserId = Substring(@vcAmendedBy, 6, Len(@vcAmendedBy))

		SELECT @vcAmendedBy  = 'System User'

		-- Check that we're left with only numbers
		IF IsNumeric(@vcUserId) = 1
		BEGIN
			-- Convert to int
			SELECT @iUserId = CAST(@vcUserId AS int)

			-- If not any of the generic and hardocoded user, show the actual user, otherwise show 'System User' defined above
			IF @iUserId NOT IN (-1, 1, 185915)	-- 185915 - hardcoded user for API; 1 - generic STA145 user; -1 - generic Insight 1.8 system access User
			BEGIN
				-- Lookup user details
				SELECT @vcAmendedBy = ISNULL( (FullName + ' (' + Username + ')') , 'System User')
				FROM dbo.AuthorisedUser
				WHERE UserId = @iUserId
			END
		END

	END
	ELSE
		SELECT @vcAmendedBy  = 'System User'
	
	-- Return looked up details or the passed in data if we didn't get to the lookup
	RETURN @vcAmendedBy
END

