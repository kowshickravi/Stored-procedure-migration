IF OBJECT_ID('dbo.fn_api_CustomerParentHierarchy') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_api_CustomerParentHierarchy (@i int) RETURNS TABLE AS RETURN (SELECT @i AS a)')
GO

ALTER FUNCTION dbo.fn_api_CustomerParentHierarchy
( @iCustomerId	int )

-- $Id: fn_api_CustomerParentHierarchy.sql v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40 eharper $
-- $Log: fn_api_CustomerParentHierarchy.sql $
-- Revision v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40
-- update version header
-- 
-- $Header: /InsightConfig/Functions/fn_api_CustomerParentHierarchy.sql v_23\.1_ClientNet_Authentication_Strategic_P1_eharper\/2 2012/5/25 8:16:40 eharper $

RETURNS TABLE
AS
RETURN
(	WITH	cteCustomerTree
	AS
	(	SELECT	CustomerId,ParentResellerId
		FROM	dbo.Customers		WITH (NOLOCK)
		WHERE	CustomerId = @iCustomerId
		UNION ALL
		SELECT	c.CustomerId,c.ParentResellerId
		FROM	dbo.Customers	c	WITH (NOLOCK)
		JOIN	cteCustomerTree	t	
		ON		c.CustomerId	=	t.ParentResellerId
		AND		c.CustomerID	<>	t.CustomerID
	)
	SELECT CustomerId
	FROM	cteCustomerTree
)

GO