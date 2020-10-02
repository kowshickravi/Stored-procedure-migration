IF OBJECT_ID('dbo.fn_api_CustomerSuppressSecurityQuestions') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_api_CustomerSuppressSecurityQuestions (@i int) RETURNS TABLE AS RETURN (SELECT @i AS a)')
GO

ALTER FUNCTION dbo.fn_api_CustomerSuppressSecurityQuestions
( @iCustomerId	int )

-- $Id: fn_api_CustomerSuppressSecurityQuestions.sql v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40 eharper $
-- $Log: fn_api_CustomerSuppressSecurityQuestions.sql $
-- Revision v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40
-- update version header
-- 
-- $Header: /InsightConfig/Functions/fn_api_CustomerSuppressSecurityQuestions.sql v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40 eharper $

RETURNS TABLE
AS
RETURN
(	
	SELECT	CustomerId
	FROM	dbo.fn_api_CustomerParentHierarchy (@iCustomerId)
	INTERSECT
	SELECT	CustomerId
	FROM	dbo.CustomerSuppressSecurityQuestions
	WHERE	CustomerId = @iCustomerId
)
GO
