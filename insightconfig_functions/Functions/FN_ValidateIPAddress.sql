IF	OBJECT_ID('dbo.FN_ValidateIPAddress') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_ValidateIPAddress() RETURNS bit AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION	dbo.FN_ValidateIPAddress
(
	@vcIPAddress	varchar(50)
) 
RETURNS	bit
AS
/*
   this function returns 1 if the ip address is valid otherwise returns 0
*/
BEGIN
	DECLARE	@IP0	int,
			@IP1 	int,
			@IP2	varchar(15),
			@IP3	int

  -- characters other than digits and dots
  IF @vcIPAddress LIKE '%[^.0-9]%'
    RETURN 0
  
  -- different number of dots then 3
  IF LEN(@vcIPAddress) - LEN(REPLACE(@vcIPAddress, '.', '')) <> 3
    RETURN 0
  
  -- missing octets
  IF @vcIPAddress NOT LIKE '%_%.%_%.%_%.%_%'
    RETURN 0
  
  -- first octet between 0 and 255
  SELECT @IP3=LEFT(@vcIPAddress, CHARINDEX('.',@vcIPAddress) - 1)
  IF @IP3 NOT BETWEEN 0 AND 255
    RETURN 0
  
  -- second octet between 0 and 255
  SELECT @IP2=SUBSTRING(@vcIPAddress, CHARINDEX('.', @vcIPAddress) + 1,
                 CHARINDEX('.', @vcIPAddress, CHARINDEX('.', @vcIPAddress) + 1)
                 - CHARINDEX('.', @vcIPAddress) - 1)
  IF @IP2 NOT BETWEEN 0 AND 255
    RETURN 0
  
  -- third octet between 0 and 255
  SELECT @IP1=SUBSTRING(@vcIPAddress, CHARINDEX('.', @vcIPAddress,
                 CHARINDEX('.', @vcIPAddress) + 1) + 1, (LEN(@vcIPAddress)
                 - CHARINDEX('.', REVERSE(@vcIPAddress)) + 1)
                 - (CHARINDEX('.', @vcIPAddress, CHARINDEX('.',@vcIPAddress) + 1)) - 1)
  IF @IP1 NOT BETWEEN 0 AND 255
    RETURN 0
  
  -- fourth octet between 0 and 255
  SELECT @IP0=RIGHT(@vcIPAddress, LEN(@vcIPAddress) - (LEN(@vcIPAddress) - CHARINDEX('.',
                 REVERSE(@vcIPAddress)) + 1))
  IF @IP0 NOT BETWEEN 0 AND 255
    RETURN 0

  RETURN 1

END
GO
