IF 	OBJECT_ID('FN_ReplRegionGet') IS NOT NULL
BEGIN
	DROP FUNCTION FN_ReplRegionGet
END
GO

CREATE FUNCTION FN_ReplRegionGet
(
	@iCustomerId	int,
	@iDomainId		int = NULL
)
RETURNS smallint
AS
BEGIN
	
	DECLARE	@siRegion 		smallint = 3;		-- All Region- Explicit Value Assignment
	DECLARE	@vcRegionCode	varchar(10)= 'ALL';
	DECLARE	@iCount 		int = 0;

	DECLARE	@tabRegion	TABLE
		(
		CustomerId		int,
		CDSRegionCode	varchar(10)
		)
	
	IF	@iCustomerId = 11209	-- 11209 is always 3; early exit
		RETURN @siRegion
	
	IF	@iDomainId IS NULL
	BEGIN
		INSERT	INTO @tabRegion
				(
				CustomerId,
				CDSRegionCode
				)
		SELECT	DISTINCT csc.CustomerId, cm.CDSRegionCode
		FROM	dbo.ClusterServerConfig csc
		JOIN	dbo.CDSRegionClusterMap cm
		ON		csc.ClusterId	= cm.ClusterId
		WHERE	csc.CustomerId 	= @iCustomerId
		AND		csc.DateDeleted = '9999-12-31 23:59:59.000'
	END
	ELSE
	BEGIN
		INSERT	INTO @tabRegion
				(
				CustomerId,
				CDSRegionCode
				)
		SELECT	DISTINCT csc.CustomerId, cm.CDSRegionCode
		FROM	dbo.ClusterServerConfig csc
		JOIN	dbo.CDSRegionClusterMap cm
		ON		csc.ClusterId 	= cm.ClusterId
		WHERE	csc.CustomerId	= @iCustomerId						
		AND		csc.DomainId	= @iDomainId
		AND		csc.DateDeleted = '9999-12-31 23:59:59.000'
	END

	SELECT @iCount = COUNT(*) FROM @tabRegion;
	IF	@iCount 	= 1
	BEGIN
		SELECT @vcRegionCode = CDSRegionCode FROM @tabRegion;
	END
	ELSE IF @iCount < 1
	BEGIN
		SELECT @vcRegionCode = 'WSS';	-- If there is no record in ClusterServerConfig we assume it is WSS Customer
	END
	ELSE
	BEGIN
		SELECT @vcRegionCode = 'ALL';
	END
	
	SELECT	@siRegion = ReplRegionId 
	FROM 	dbo.ReplRegion
	WHERE	RegionCode = @vcRegionCode;
	
RETURN @siRegion
END
GO

GRANT EXECUTE ON FN_ReplRegionGet TO R_ARUser

GO
