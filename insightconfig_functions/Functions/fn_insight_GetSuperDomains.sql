IF	OBJECT_ID('dbo.fn_insight_GetSuperDomains') IS NULL
      EXEC ('CREATE FUNCTION dbo.fn_insight_GetSuperDomains() RETURNS @retTable TABLE (i int) AS BEGIN RETURN END')	
GO

ALTER FUNCTION dbo.fn_insight_GetSuperDomains
(
	@vcEmailOrDomain varchar(255) 
)
RETURNS @retTable TABLE
(
	Domain varchar(255),
	[level] int
)
AS
-- $Id: fn_insight_GetSuperDomains.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: fn_insight_GetSuperDomains.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_bflanaghan\/2 2011/10/25 14:03:44
-- No Comment
-- 
-- $Header: /InsightConfig/Functions/fn_insight_GetSuperDomains.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
BEGIN

	DECLARE @iLevel int
	SET @iLevel = 1
	
	IF CHARINDEX('@', @vcEmailOrDomain) > 0
		SET @vcEmailOrDomain = REVERSE(LEFT(REVERSE(@vcEmailOrDomain), CHARINDEX('@', REVERSE(@vcEmailOrDomain))-1))

	WHILE CHARINDEX('.', @vcEmailOrDomain) > 0
	BEGIN
		INSERT @retTable VALUES (@vcEmailOrDomain, @iLevel)
		
		SET @iLevel = @iLevel + 1
		SET @vcEmailOrDomain = RIGHT(@vcEmailOrDomain, LEN(@vcEmailOrDomain) - CHARINDEX('.', @vcEmailOrDomain))
	END

	RETURN
END
GO
 