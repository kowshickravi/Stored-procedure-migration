IF	OBJECT_ID(N'dbo.up_FN_CheckLocale') IS NULL 
	EXEC ('CREATE FUNCTION dbo.up_FN_CheckLocale() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.up_FN_CheckLocale
(
	@vcLocaleId	VARCHAR(20)
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @vcLocale VARCHAR(20)

	IF (LOWER(@vcLocaleId) <> 'none') AND (LOWER(@vcLocaleId) <> 'all') AND (LTRIM(RTRIM(@vcLocaleId)) <> '')	-- 'All' and 'None' are preserved, everything else will be defaulted to 'en-US'
	BEGIN
		SELECT @vcLocale = LocaleId
		FROM Locale (NOLOCK)
		WHERE LocaleId = COALESCE(@vcLocaleId, 'en-US')
		
		IF @@ROWCOUNT = 0	-- check partial existance, and find the best match based on the first two letters
			SELECT TOP 1 @vcLocale = LocaleId
			FROM Locale (NOLOCK)
			WHERE SUBSTRING(LocaleId, 1, 2) = SUBSTRING(@vcLocaleId, 1, 2)
			ORDER BY LocaleId	-- return the alphabetically first record if more than one matching records in table (i.e. 'zh-CN', 'zh-TW')
	END
	ELSE
		SET @vcLocale = CASE WHEN LTRIM(RTRIM(@vcLocaleId)) = '' THEN NULL ELSE @vcLocaleId END -- if the input locale is empty string, then default it to 'en-US'

	RETURN COALESCE(@vcLocale, 'en-US') -- If not exist or "nearly" exist, then default it to 'en-US'
END
