IF	OBJECT_ID('dbo.CalculateMd5') IS NOT NULL
	DROP FUNCTION dbo.CalculateMd5
GO

CREATE FUNCTION dbo.CalculateMd5(@userName [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [ClrStoredProcedures].[UserDefinedFunctions].[CalculateMd5]
GO

GRANT EXECUTE ON dbo.CalculateMd5 TO R_InsightUser
GO
