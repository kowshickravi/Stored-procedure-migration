IF	OBJECT_ID('dbo.fn_web_ConvertNumericToIP') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_web_ConvertNumericToIP() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_web_ConvertNumericToIP
(
	@IPAddress bigint
)  
RETURNS varchar(15) 
AS  
BEGIN

-- $Id: fn_web_ConvertNumericToIP.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/3/26 13:03:53 dfisher $
-- $Log: fn_web_ConvertNumericToIP.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/2 2012/3/26 13:03:53
-- changed from unicode
-- 
-- $Header: /InsightConfig/Functions/fn_web_ConvertNumericToIP.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/3/26 13:03:53 dfisher $

DECLARE	@biOctetA 	bigint,
	@biOctetB	bigint,
	@biOctetC	bigint,
	@biOctetD	bigint,
	@bIp 		bigint,
	@iError		int,
	@cIp		varchar(15)
        
    	SET @bIp = CONVERT(bigint, @IPAddress)
        SET @biOctetA = (@bIp & 0x00000000FF000000) / 256 / 256 / 256
        SET @biOctetB = (@bIp & 0x0000000000FF0000) / 256 / 256
        SET @biOctetC = (@bIp & 0x000000000000FF00) / 256
        SET @biOctetD = (@bIp & 0x00000000000000FF)
        
	-- Verify IP Range is correct.
	IF @biOctetD > 255 or @biOctetD < 0 SELECT @iError = 1
	IF @biOctetC > 255 or @biOctetC < 0 SELECT @iError = 1
	IF @biOctetB > 255 or @biOctetB < 0 SELECT @iError = 1
	IF @biOctetA > 255 or @biOctetA < 0 SELECT @iError = 1
	IF @iError = 1
		BEGIN
			--SELECT @vc255ErrorMessage = ' **>>ERROR(UP_isite_GetIPNumberToString): IP Out of Range' 
	                	--RAISERROR 99205 @vc255ErrorMessage
	                RETURN 1
		END
        SELECT @cIp = 	CONVERT(varchar(4), @biOctetA) + '.' +
                	CONVERT(varchar(4), @biOctetB) + '.' +
                	CONVERT(varchar(4), @biOctetC) + '.' +
                	CONVERT(varchar(4), @biOctetD)
	Return(@cIp)
END
