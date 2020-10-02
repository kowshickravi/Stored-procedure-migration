IF	OBJECT_ID('dbo.FN_AuthorisedRoleServiceIdGet') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_AuthorisedRoleServiceIdGet() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.FN_AuthorisedRoleServiceIdGet
(
	@iCustomerServiceTypeId int,
	@iUserId int,
	@iRoleId int,
	@iCustomerId int,
	@iDomainId int
)
RETURNS int 
AS
-- $Id: FN_AuthorisedRoleServiceIdGet.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: FN_AuthorisedRoleServiceIdGet.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_bflanaghan\/1 2011/2/22 16:31:29
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_1_aphillips\/2 2010/9/20 12:39:51
-- No Comment
-- 
-- $Header: /InsightConfig/Functions/FN_AuthorisedRoleServiceIdGet.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
BEGIN
	DECLARE @iUserServiceId int

	DECLARE @tServiceType TABLE (TypeId int)

	;WITH Email_cte
	AS 
	(
		SELECT	TypeId
		FROM    dbo.CustomerServiceType
		WHERE   TypeId = @iCustomerServiceTypeId
		AND		DateDeleted = '9999-12-31 23:59:59.000'
		UNION ALL
		SELECT  cst.TypeId
		FROM    dbo.CustomerServiceType cst
		JOIN    Email_cte cte
		ON      cst.ParentTypeId = cte.TypeId
		WHERE   cst.TypeId <> @iCustomerServiceTypeId
		AND		cst.DateDeleted = '9999-12-31 23:59:59.000'
	)
	INSERT INTO @tServiceType
	SELECT TypeId 
	FROM Email_cte
		
	SELECT TOP 1 @iUserServiceId = CustomerServiceTypeId 
	FROM dbo.AuthorisedUserRoleServiceDomain au
	WHERE UserId = @iUserId
	AND RoleId = @iRoleId
	AND (
			CustomerServiceTypeId IN (SELECT TypeId FROM @tServiceType)
			OR CustomerServiceTypeId IS NULL 
		) 	
	AND ISNULL(DomainId, -1) = ISNULL(@iDomainId, -1)
	AND EXISTS (SELECT 1 FROM AuthorisedUserRole WHERE RoleId = au.RoleId AND UserId = au.UserId)
	
	RETURN ISNULL(@iUserServiceId, @iCustomerServiceTypeId)
END
GO 
