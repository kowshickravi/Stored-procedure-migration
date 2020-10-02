IF OBJECT_ID(N'[dbo].[FN_TooBigDefaultEmailSize]') IS NULL
      EXEC ('CREATE FUNCTION dbo.FN_TooBigDefaultEmailSize() RETURNS int AS BEGIN RETURN 0 END')	
GO

GRANT  EXECUTE  ON dbo.FN_TooBigDefaultEmailSize  TO R_InsightUser
GO

ALTER FUNCTION	[dbo].[FN_TooBigDefaultEmailSize]
(
	@bIsDefaultSize smallint = 1
)
RETURNS int
AS
/*
	call: SELECT dbo.FN_TooBigDefaultEmailSize(1)
	Size is in Kb
*/
BEGIN
	DECLARE @iResult int

	SET @iResult	=	CASE
							WHEN @bIsDefaultSize = 0	THEN 1000		-- Minimum allowed CheckUs_maxEmailSize (in Kb)
							WHEN @bIsDefaultSize = 2	THEN 1000000	-- Maximum allowed CheckUs_maxEmailSize (in Kb)
							ELSE 50000									-- Default CheckUs_maxEmailSize         (in Kb)
						END

	RETURN @iResult
END

