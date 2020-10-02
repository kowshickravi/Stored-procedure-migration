------------------------------------------------------------------------------------
--	Project:       	Insight1 Internationalisation Drop3
--
--	File:			fn_isite_GetWebAlertTextLanguages.sql
--
--	Description:	Function to build a string of the languages a WebAlert is defined in.
--
--	Developed by:   Electrum Multimedia Limited,
--                  58-59 Timber Bush,
--                  Edinburgh EH6 6QH
--                  United Kingdom.
--                  www.electrum.co.uk
--
------------------------------------------------------------------------------------
-- $Id: fn_isite_GetWebAlertTextLanguages.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: fn_isite_GetWebAlertTextLanguages.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/2 2011/9/15 15:37:17
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/1 2011/8/25 14:32:10
-- No Comment
-- 
-- Revision IC36_Insight1_Internationalisation_Drop3_phemsted\/2 2009/6/12 11:22:04
-- Updated existence check.
-- 
-- $Header: /InsightConfig/Functions/fn_isite_GetWebAlertTextLanguages.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
------------------------------------------------------------------------------------
IF	OBJECT_ID('dbo.fn_isite_GetWebAlertTextLanguages') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_isite_GetWebAlertTextLanguages() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_isite_GetWebAlertTextLanguages
(
	@WebAlertRowId			int
)
RETURNS varchar(1000)
AS
BEGIN
	--------------------------------------
	-- Get locale text details for the 
	-- supplied id and look up the language
	-- name for each locale.
	--------------------------------------
	DECLARE @return varchar(1000)

	SELECT 
		@return = Coalesce(@return + ',', '') + LOC.LocaleName
	FROM 
		WebAlertText WAT
	
			INNER JOIN Locale LOC
			ON
			WAT.LocaleId = LOC.LocaleId
	WHERE 
		WAT.WebAlertRowId = @WebAlertRowId
	ORDER BY 
		CASE
			-- Always order en-US as the first entry then alphabetically by LocaleName 
			WHEN LOC.LocaleId = 'en-US' THEN 'AAAAAAA'
			ELSE LOC.LocaleName
		END

	-- Return 
	RETURN @return
END
GO

GRANT EXECUTE ON dbo.fn_isite_GetWebAlertTextLanguages TO R_StarAdmin
GO