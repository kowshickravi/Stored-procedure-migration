IF	OBJECT_ID('dbo.fn_insight_CCLookupAmendedUser') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_CCLookupAmendedUser() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_insight_CCLookupAmendedUser
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
	-- up the full name in the AuthorisedUser
	-- table. If the passed in data is not in 
	-- the Insight2 format then the passed in
	-- data is simply returned as is.
	--------------------------------------
	DECLARE	@vcUserId	varchar(255), 
			@iUserId	int


	-- Get rid of any leading or trailing spaces
	SELECT @vcAmendedBy 	= Ltrim(Rtrim(@vcAmendedBy))

	IF LEFT(@vcAmendedBy, 5) = 'User='
	BEGIN
		-- Extract the user id part
		SELECT @vcUserId = Substring(@vcAmendedBy, 6, Len(@vcAmendedBy))
	END
	ELSE 
	IF LEFT(@vcAmendedBy, 7) = 'UserId='
	BEGIN
		-- Extract the user id part
		SELECT @vcUserId = Substring(@vcAmendedBy, 8, Len(@vcAmendedBy))
	END


		-- Check that we're left with only numbers
	IF @vcUserId IS NOT NULL AND IsNumeric(@vcUserId) = 1
	BEGIN
		-- Convert to int
		SELECT @iUserId = CAST(@vcUserId AS int)

		-- Lookup user details
		SELECT
			@vcAmendedBy = FullName
		FROM
			AuthorisedUser
		WHERE
			UserId = @iUserId
	END

	
	-- Return looked up details or the passed in data if we didn't get to the lookup
	RETURN @vcAmendedBy
END
GO

GRANT EXECUTE ON dbo.fn_insight_CCLookupAmendedUser TO R_InsightUser
GO

