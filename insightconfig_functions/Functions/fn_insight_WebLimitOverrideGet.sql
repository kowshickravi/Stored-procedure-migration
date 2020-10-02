IF OBJECT_ID('dbo.fn_insight_WebLimitOverrideGet') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_WebLimitOverrideGet () RETURNS @Limits TABLE (CustomerId int) AS BEGIN RETURN END')	
GO

ALTER FUNCTION [dbo].fn_insight_WebLimitOverrideGet
(
	@iCustomerId	INT
)
RETURNS @Limits TABLE
(
	ByPassDomainLimit	INT,
	CertErrDomainLimit	INT
)
AS
BEGIN
-- $Id: fn_insight_WebLimitOverrideGet.sql WSS_v3\.63\.1_IC_WSS_Support_For_HTTPS_zcvetanovski\/4 2012/8/1 19:09:11 zcvetanovski $
-- $Log: fn_insight_WebLimitOverrideGet.sql $
-- Revision WSS_v3\.63\.1_IC_WSS_Support_For_HTTPS_zcvetanovski\/4 2012/8/1 19:09:11
-- v3.63 - WSS Support for HTTPS/SSL Inspection - bug fixes
-- 
-- Revision WSS_v3\.63_IC_WSS_Support_For_HTTPS_zcvetanovski\/3 2012/7/23 14:57:29
-- v3.63 - WSS Support for HTTPS/SSL Inspection
-- 
-- Revision WSS_v3\.63_IC_WSS_Support_For_HTTPS_zcvetanovski\/2 2012/7/12 18:17:49
-- v3.63 - WSS Support for HTTPS/SSL Inspection - Draft
-- 
-- $Header: /InsightConfig/Functions/fn_insight_WebLimitOverrideGet.sql WSS_v3\.63\.1_IC_WSS_Support_For_HTTPS_zcvetanovski\/4 2012/8/1 19:09:11 zcvetanovski $
    DECLARE	@iByPassDomainLimit	INT,
			@iCertErrDomainLimit	INT

	SELECT	@iByPassDomainLimit	= CAST(COALESCE(ParameterValue, '1000') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'WebByPassDomainLimit'

	SELECT	@iCertErrDomainLimit	= CAST(COALESCE(ParameterValue, '1000') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'WebCertErrDomainLimit'

	INSERT INTO @Limits
	SELECT	TOP 1							-- this is just in case, otherwise should be one entry per customer ...
		COALESCE(ByPassDomainLimit,  @iByPassDomainLimit)	AS ByPassDomainLimit,
		COALESCE(CertErrDomainLimit, @iCertErrDomainLimit)	AS CertErrDomainLimit
	FROM	dbo.WebLimitOverride (NOLOCK)
	WHERE	CustomerId = @iCustomerId
	IF @@ROWCOUNT = 0
		INSERT INTO @Limits
		SELECT 
			@iByPassDomainLimit		AS ByPassDomainLimit, 
			@iCertErrDomainLimit	AS CertErrDomainLimit
	RETURN
END