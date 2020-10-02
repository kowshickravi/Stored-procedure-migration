IF	OBJECT_ID('dbo.FN_Config_DomainToTowerMapping') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_Config_DomainToTowerMapping() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.FN_Config_DomainToTowerMapping
(
	@iCustomerId	int,
	@iDomainId	int
)
RETURNS varchar(1000)
AS
-- $Id: FN_Config_DomainToTowerMapping.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: FN_Config_DomainToTowerMapping.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision IC01_Telstra_Build_dknight\/2 2007/10/25 13:52:26
-- Enabled version headers
-- 
-- $Header: /InsightConfig/Functions/FN_Config_DomainToTowerMapping.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
BEGIN

	DECLARE @vcTowerRole varchar(1000)

	DECLARE @ClusterInfo TABLE
	(
		ServerName	varchar(100), 
		Priority	tinyint
	)

	INSERT INTO @ClusterInfo
	SELECT 	CS.ServerName,
		CASE DomainRole
			WHEN 'Primary' THEN 1
			WHEN 'Merged Primary' THEN 1
			WHEN 'Failover' THEN 2
			WHEN 'Merged FailOver' THEN 2
			WHEN 'FailOver1' THEN 3
			WHEN 'Merged FailOver1' THEN 3
			WHEN 'FailOver2' THEN 4
		END
	FROM ClusterServerConfig CSC (NOLOCK) JOIN ClusterServer CS (NOLOCK)
	ON	CSC.ServerId 	= CS.ServerId
	WHERE 	CSC.CustomerId 	= @iCustomerId
	AND	CSC.DomainId	= @iDomainId
	AND	CSC.DateDeleted	= '99991231 23:59:59.000'
	ORDER BY 2
	
	SELECT 	@vcTowerRole =	COALESCE(@vcTowerRole + ';', '') 
		+ CAST(Priority AS char(1)) + ':' + ServerName
	FROM 	@ClusterInfo		

	RETURN @vcTowerRole
END
GO
