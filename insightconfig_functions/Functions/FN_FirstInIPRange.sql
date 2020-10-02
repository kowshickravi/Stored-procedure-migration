IF	OBJECT_ID('dbo.FN_FirstInIPRange') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_FirstInIPRange() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION	dbo.FN_FirstInIPRange
(
	@vcHostIPAddress	varchar(15),
	@vcHostSubNet		varchar(15)
) 
RETURNS	varchar(15)
AS
/*
   this function returns the first IP address in an IPRange given an IP and sub net mask
*/

-- $Id: FN_FirstInIPRange.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: FN_FirstInIPRange.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- $Header: /InsightConfig/Functions/FN_FirstInIPRange.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $

BEGIN
	DECLARE	@iSubOct1		int,
			@iSubOct2		int,
			@iSubOct3		int,
			@iSubOct4		int,
			@iIPOct1		int,
			@iIPOct2		int,
			@iIPOct3		int,
			@iIPOct4		int,
			@vcReturnIP		varchar(15)

	-- Split each Ip and Subnet into its octet
	SELECT	@iIPOct1	= ISNULL(PARSENAME(@vcHostIPAddress, 4), ''),
			@iIPOct2	= ISNULL(PARSENAME(@vcHostIPAddress, 3), ''),
			@iIPOct3	= ISNULL(PARSENAME(@vcHostIPAddress, 2), ''),
			@iIPOct4	= ISNULL(PARSENAME(@vcHostIPAddress, 1), ''),
			@iSubOct1	= ISNULL(PARSENAME(@vcHostSubNet, 4), ''),
			@iSubOct2	= ISNULL(PARSENAME(@vcHostSubNet, 3), ''),
			@iSubOct3	= ISNULL(PARSENAME(@vcHostSubNet, 2), ''),
			@iSubOct4	= ISNULL(PARSENAME(@vcHostSubNet, 1), '')
	
	-- Calculate First IP by bitwise comparisson of IP address and Subnet
	SET	@vcReturnIP		= CONVERT(varchar(3), (@iIPOct1 & @iSubOct1)) + '.'
						+ CONVERT(varchar(3), (@iIPOct2 & @iSubOct2)) + '.' 
						+ CONVERT(varchar(3), (@iIPOct3 & @iSubOct3)) + '.'
						+ CONVERT(varchar(3), (@iIPOct4 & @iSubOct4))

	RETURN @vcReturnIP
END
GO
