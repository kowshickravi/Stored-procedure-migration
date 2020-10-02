IF OBJECT_ID('dbo.fn_ACSGetIngestionEmailAddress') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_ACSGetIngestionEmailAddress () RETURNS int as begin RETURN 0 end ')
GO

ALTER FUNCTION dbo.fn_ACSGetIngestionEmailAddress  
(
	@iCustomerId	int,
	@vcService		varchar(20)= ''
)  
RETURNS	varchar(255) 
-- $Id: fn_ACSGetIngestionEmailAddress.sql v_25\.1_WIA_eharper\/5 2012/7/27 11:56:13 eharper $
-- $Log: fn_ACSGetIngestionEmailAddress.sql $
-- Revision v_25\.1_WIA_eharper\/5 2012/7/27 11:56:13
-- remove customer id from ingestion address domain
-- 
-- $Header: /InsightConfig/Functions/fn_ACSGetIngestionEmailAddress.sql v_25\.1_WIA_eharper\/5 2012/7/27 11:56:13 eharper $
AS  
BEGIN

	DECLARE @vcIngestionEmailAddress		nvarchar(255)


	SELECT @vcIngestionEmailAddress = null
	SELECT @vcService = LTRIM(RTRIM(@vcService))

	-- email address format is :
	-- <custid>@<servicetype>.<groupname>.<region>.<acsdomain.com>
	-- or null if customer not provisioned

	-- check if the customer has any of the Shs services?
	IF EXISTS ( SELECT 1 
				FROM	dbo.CustomerService		AS cs	WITH (NOLOCK)
				JOIN	dbo.CustomerServiceType	AS cst	WITH (NOLOCK) 
				ON		cs.ServiceTypeid = cst.Typeid
				WHERE	cst.Typeid		= 22
				AND		cst.DateDeleted	= '9999-12-31 23:59:59' 
				AND		cs.CustomerID	= @iCustomerID 
				AND		cs.[Enabled]	= 'Y'
				AND		cs.DateDeleted	= '9999-12-31 23:59:59'  
				AND		@vcService		IN ( 'imss', 'wss', '', '*') 
			  )	
	OR EXISTS ( SELECT 1 
				FROM	dbo.ACSCustomerArchivingService	AS cas WITH (NOLOCK)
				JOIN	dbo.CustomerServiceType			AS cst WITH (NOLOCK) 
				ON		cas.ServiceTypeid = cst.Typeid
				WHERE	cst.Typeid		= 21 -- imss
				AND		cst.DateDeleted	= '9999-12-31 23:59:59' 
				AND		cas.CustomerID	= @iCustomerID 
				AND		@vcService		= 'imss' 
			  )
	OR EXISTS ( SELECT 1 
				FROM	dbo.ACSCustomerArchivingService	AS cas WITH	(NOLOCK)
				JOIN	dbo.CustomerServiceType			AS cst WITH	(NOLOCK) 
				ON		cas.ServiceTypeid = cst.Typeid
				WHERE	cst.Typeid		= 14 -- wss
				AND		cst.DateDeleted	= '9999-12-31 23:59:59' 
				AND		cas.CustomerID	= @iCustomerID 
				AND		@vcService		= 'wss' 
			  )

	BEGIN
	
		-- get the email address for customer/service provided
		SELECT @vcIngestionEmailAddress = c.IngestionAddressSuffixOverride	
		FROM dbo.ACSCustomer as c (NOLOCK)
		WHERE c.CustomerId = @iCustomerId

		-- if a service was provided, return the full format of the email 
		-- otherwise we return only the suffix portion  (IngestionAddressSuffixOverride)
		IF @vcService = '*'
			SELECT @vcIngestionEmailAddress =	@vcService + '.' +
												@vcIngestionEmailAddress  

		ELSE IF @vcService <> ''
			SELECT @vcIngestionEmailAddress =	CONVERT(varchar, @iCustomerId) + '@' +
												@vcService + '.' +
												@vcIngestionEmailAddress  
	END

	RETURN(@vcIngestionEmailAddress)

END
GO

GRANT EXECUTE ON dbo.fn_ACSGetIngestionEmailAddress to r_InsightUser
GO

