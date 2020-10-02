IF OBJECT_ID('FN_ViewStatsForAllAVDomains') IS NULL
BEGIN
	EXEC ('CREATE FUNCTION dbo.FN_ViewStatsForAllAVDomains (@x int) RETURNS int AS BEGIN RETURN 0 END')
END
GO

ALTER FUNCTION dbo.FN_ViewStatsForAllAVDomains
(
	@iUserId		int,
	@iCustomerId	int
)
RETURNS	bit
AS
BEGIN
DECLARE	@bAllDomains		bit,
			@iAVDomainCount		int,
			@iUserAVDomainCount	int

DECLARE	@tabDomains TABLE
			(DomainId int)

DECLARE	@tabRoleServiceDomains TABLE
			(DomainId	int)

	SET @bAllDomains = 0

	INSERT
	INTO	@tabDomains
			(DomainId)
	SELECT	AD.DomainId
	FROM	dbo.AllDomains	AD
	INNER JOIN
			dbo.CustomerConfig	CC
	ON	AD.DomainId				= CC.DomainId
	AND	CC.CheckUs_CheckVirus	= 'Y'
	WHERE	AD.CustomerId	= @iCustomerId
	AND		AD.DateDeleted	IS NULL

	SET @iAVDomainCount = @@ROWCOUNT

	INSERT
	INTO	@tabRoleServiceDomains
			(DomainId)
	SELECT	DomainId
	FROM	(SELECT	AD.DomainId,
						MAX(CASE	WHEN RSD.CustomerServiceTypeId IS NOT NULL	AND DomainInclusionState = 0 THEN 4  
									WHEN RSD.CustomerServiceTypeId IS NOT NULL	AND DomainInclusionState = 1 THEN 3  
									WHEN RSD.CustomerServiceTypeId IS NULL			AND DomainInclusionState = 0 THEN 2  
									WHEN RSD.CustomerServiceTypeId IS NULL			AND DomainInclusionState = 1 THEN 1
							END) Rank  
			FROM	dbo.AllDomains		AD
			INNER JOIN
					dbo.CustomerConfig	CC
			ON	AD.DomainId				= CC.DomainId
			AND	CC.CheckUs_CheckVirus	= 'Y'
			INNER JOIN  
				   dbo.AuthorisedUserRoleServiceDomain	RSD
			ON	AD.Customerid				= @iCustomerId
			AND RSD.UserId					= @iUserId
			AND RSD.RoleId					= 2
			AND	(RSD.DomainId				= ad.DomainId
			OR	RSD.DomainId				IS NULL)
			AND (RSD.CustomerServiceTypeId	= 2
			OR	RSD.CustomerServiceTypeId	IS NULL)
			AND	AD.DateDeleted				IS NULL
			GROUP BY AD.DomainId) AS A
	WHERE A.Rank IN (1,3)
 
	SET @iUserAVDomainCount = @@ROWCOUNT

	IF @iUserAVDomainCount	= @iAVDomainCount
	AND	@iAVDomainCount		> 0
	BEGIN
		SET @bAllDomains = 1
	END

RETURN @bAllDomains
END
GO
