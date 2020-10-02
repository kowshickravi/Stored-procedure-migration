IF	OBJECT_ID('dbo.ValidateWebUrl') IS NOT NULL
	DROP FUNCTION dbo.ValidateWebUrl
GO

CREATE FUNCTION [dbo].ValidateWebUrl(@Url nvarchar(max)) RETURNS nvarchar(max)
AS EXTERNAL NAME  URLValidationLib.URLValidator.ValidateURL
GO