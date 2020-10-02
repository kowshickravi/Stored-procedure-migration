IF	OBJECT_ID('dbo.fn_insight_MEConvertSMTPRoutesDeliveryAddress') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_MEConvertSMTPRoutesDeliveryAddress() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_insight_MEConvertSMTPRoutesDeliveryAddress
(
	@iRequestMode			int,		-- IP = 1, Hostname = 2
	@vcDeliveryAddress		varchar(255)
)
RETURNS varchar(255)
AS
-- $Id: fn_insight_MEConvertSMTPRoutesDeliveryAddress.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 16:30:21 dfisher $
-- $Log: fn_insight_MEConvertSMTPRoutesDeliveryAddress.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 16:30:21
-- No Comment
-- 
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/2 2011/9/15 15:37:17
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/1 2011/8/25 14:32:10
-- No Comment
-- 
-- Revision IC01_Telstra_Build_dknight\/2 2007/10/25 13:52:26
-- Enabled version headers
-- 
-- $Header: /InsightConfig/Functions/fn_insight_MEConvertSMTPRoutesDeliveryAddress.sql v_20\.1_ESS_for_GCF_dfisher\/2 2012/2/7 16:30:21 dfisher $
BEGIN
	--------------------------------------
	-- The SMTPRoutes delivery address can
	-- either be an IP or a hostname. The
	-- mode param determines if the delivery
	-- address is returned or if NULL is returned.
	-- If an IP address is requested and the
	-- delivery address is an IP, then the enclosing
	-- brackets are removed before the IP is returned.
	--------------------------------------
	DECLARE @bIsIPAddress		bit,
		@vcCheckIP		varchar(255)


	--------------------------------------
	-- Get rid of any leading or trailing spaces
	--------------------------------------
	SELECT @vcDeliveryAddress 	= Ltrim(Rtrim(@vcDeliveryAddress))
	SELECT @vcCheckIP		= Replace(Replace(@vcDeliveryAddress, '[' , ''), ']' , '')
	SELECT @vcCheckIP 		= Ltrim(Rtrim(@vcCheckIP))


	--------------------------------------
	-- Determine if the delivery address is
	-- an IP by removing any . and then checking
	-- that all remaining chars are numbers.
	-- Use table so we can use a LIKE clause
	-- to check the value.
	--------------------------------------
	DECLARE @ipCheck TABLE
	(
		[CheckAddress]		[varchar](255)	NULL
	)

	INSERT INTO @ipCheck(CheckAddress)
	SELECT Replace(@vcCheckIP, '.', '')

	IF Exists(SELECT 1 FROM @ipCheck WHERE CheckAddress LIKE '%[^0-9]%')
	BEGIN
		-- Found a non-number character in the address, so the address cannot be an IP
		SELECT @bIsIPAddress = 0
	END
	ELSE
	BEGIN
		-- All numbers, so must be an IP
		SELECT @bIsIPAddress = 1
	END



	--------------------------------------
	-- Set value to return based on what
	-- was asked for and what type of data
	-- the delivery address is.
	--------------------------------------
	SELECT
		@vcDeliveryAddress = CASE
					WHEN @iRequestMode = 1 THEN
						-- Asked for IP
						CASE
							WHEN @bIsIPAddress = 1 THEN @vcCheckIP		-- Return processed IP
							ELSE NULL					-- Not IP
						END
					ELSE
						-- Asked for hostname
						CASE
							WHEN @bIsIPAddress = 1 THEN NULL		-- Not hostname
							ELSE @vcDeliveryAddress				-- Return original delivery address
						END
					END

	RETURN @vcDeliveryAddress
END
GO
GRANT EXECUTE ON dbo.fn_insight_MEConvertSMTPRoutesDeliveryAddress TO R_InsightUser
GO
