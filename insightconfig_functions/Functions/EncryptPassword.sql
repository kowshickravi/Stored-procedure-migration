IF	OBJECT_ID('dbo.EncryptPassword') IS NOT NULL
	DROP FUNCTION dbo.EncryptPassword
GO

CREATE FUNCTION dbo.EncryptPassword(@userName [nvarchar](4000), @password [nvarchar](4000))
RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [PasswordHash].[UserDefinedFunctions].[EncryptPassword]
GO


