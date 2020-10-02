IF	OBJECT_ID('dbo.fn_insight_IMAccountNameNormalize') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_IMAccountNameNormalize() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_insight_IMAccountNameNormalize 

( @iProviderID int, 
  @nvcAccountName nvarchar(255) )

RETURNS nvarchar(255)

AS  
BEGIN 
	DECLARE @vcProviderName nvarchar(50)
	DECLARE @nvcAccountNameNormalized nvarchar(255)

	SELECT @vcProviderName = Providername 
	FROM dbo.IMProvider
	WHERE ProviderID = @iProviderID


	-----------------------------------------------------------
	-- AIM -- 
	-- Remove spaces, convert to lowercase
	-----------------------------------------------------------
	IF @vcProviderName = 'AIM' 
	BEGIN
		SELECT @nvcAccountNameNormalized = lower(replace(@nvcAccountName,' ', ''))
	END


	-----------------------------------------------------------
	-- MSN -- 
	-- Lowercase
	-----------------------------------------------------------
	IF @vcProviderName = 'MSN' 
	BEGIN
		SELECT @nvcAccountNameNormalized = lower(@nvcAccountName)
	END


	-----------------------------------------------------------
	-- OCS -- 
	-- Lowercase
	-----------------------------------------------------------
	IF @vcProviderName = 'OCS' 
	BEGIN
		SELECT @nvcAccountNameNormalized = lower(@nvcAccountName)
	END


	-----------------------------------------------------------
	-- YAHOO -- 
	-- Lowercase. If no domain is present, append @yahoo.com.
	-----------------------------------------------------------
	IF @vcProviderName = 'YHO' 
	BEGIN
		SELECT @nvcAccountNameNormalized = lower(@nvcAccountName)
		IF charindex('@',@nvcAccountNameNormalized) = 0
			SELECT @nvcAccountNameNormalized = @nvcAccountNameNormalized + '@yahoo.com'
	END


	RETURN @nvcAccountNameNormalized
END
Go



