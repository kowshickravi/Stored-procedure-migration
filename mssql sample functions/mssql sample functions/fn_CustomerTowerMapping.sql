IF OBJECT_ID('dbo.fn_CustomerTowerMapping') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_CustomerTowerMapping (@i int) RETURNS TABLE AS RETURN (SELECT @i AS a)')
GO

ALTER FUNCTION dbo.fn_CustomerTowerMapping
( @iClusterId	int,
  @iServerId	int)

RETURNS TABLE
AS
RETURN
(	
		SELECT	MasterServer_ClusterId as Clusterid,
				MasterServer_ServerId  as Serverid
		FROM    dbo.ClusterSuperServer	ss
		WHERE 	ss.MasterServer_ClusterId 		= @iClusterId
		AND 	ss.MasterServer_ServerId  		= @iServerId
		UNION 
		SELECT	Clone_ClusterId		   as Clusterid,
				Clone_ServerId		   as Serverid
		FROM    dbo.ClusterSuperServer	ss
		WHERE 	ss.MasterServer_ClusterId 		= @iClusterId
		AND 	ss.MasterServer_ServerId  		= @iServerId
		UNION
		SELECT  @iClusterId as Clusterid, -- For any stand alone servers in Prod streams
				@iServerId  as Serverid
	
)
GO