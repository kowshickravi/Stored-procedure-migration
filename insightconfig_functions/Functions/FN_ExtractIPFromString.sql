IF	OBJECT_ID('dbo.FN_ExtractIPFromString') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_ExtractIPFromString() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION	dbo.FN_ExtractIPFromString
(
	@vcString	varchar(500)
) 
RETURNS	varchar(15)
AS
/*
   this function returns IP address extracted from a free-format string
*/

-- $Id: FN_ExtractIPFromString.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 15:57:46 dfisher $
-- $Log: FN_ExtractIPFromString.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 15:57:46
-- No Comment
-- 
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v9\.5_Turntide_performance_dfisher\/2 2010/5/14 10:22:37
-- Corrected comments
-- 
-- $Header: /InsightConfig/Functions/FN_ExtractIPFromString.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 15:57:46 dfisher $

BEGIN
	DECLARE	@iStringLength	int,
			@iCurPos 		int,
			@iCurText		varchar(15),
			@idotCount		int,
			@vcReturnIP		varchar(15)
		
	SELECT	@iCurPos		= PATINDEX('%[.0-9]%', @vcString),
			@idotCount		= 0,
			@iStringLength	= LEN(@vcString),
			@vcReturnIp		= ''
	
	WHILE	@iStringLength <> @iCurPos - 1
		AND	@iCurPos > 0
	BEGIN
		IF SUBSTRING(@vcString, @iCurPos, 1 ) LIKE '[.0-9]'
		BEGIN
			SELECT	@vcReturnIP = @vcReturnIP + SUBSTRING(@vcString, @iCurPos, 1)
			IF SUBSTRING(@vcString, @iCurPos, 1) = '.'
				SET	@idotCount = @idotCount + 1
		END
		ELSE
			IF @idotCount	=	3 
				RETURN	@vcReturnIP
			ELSE
				SELECT	@vcReturnIP	= '',
						@idotCount = 0		
			
		SET	@iCurPos = @iCurPos + 1
	END

	RETURN	@vcReturnIP
END
GO
