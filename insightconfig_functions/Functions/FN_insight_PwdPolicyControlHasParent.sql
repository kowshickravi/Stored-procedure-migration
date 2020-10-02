IF OBJECT_ID('dbo.FN_insight_PwdPolicyControlHasParent') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_insight_PwdPolicyControlHasParent() RETURNS bit AS BEGIN RETURN 0 END')
GO
ALTER FUNCTION dbo.FN_insight_PwdPolicyControlHasParent
(
@iOwnerId			int,
@tiOwnerTypeId		tinyint
)
RETURNS bit
AS
-- $Id: FN_insight_PwdPolicyControlHasParent.sql v_23\.4_ECCR_Orb5055v2_crayer\/1 2012/4/25 8:34:58 crayer $
-- $Log: FN_insight_PwdPolicyControlHasParent.sql $
-- Revision v_23\.4_ECCR_Orb5055v2_crayer\/1 2012/4/25 8:34:58
-- ECCR 5055 v2
-- 
-- $Header: /InsightConfig/Functions/FN_insight_PwdPolicyControlHasParent.sql v_23\.4_ECCR_Orb5055v2_crayer\/1 2012/4/25 8:34:58 crayer $
BEGIN

	declare @bParentExists bit;

		IF @tiOwnerTypeId = 3 AND EXISTS 
			(	
		   SELECT   
				p1.OwnerId  
		   FROM dbo.AllDomains d WITH (NOLOCK)   
		   JOIN dbo.PwdPolicyControl p1 WITH (NOLOCK) ON d.CustomerId=p1.OwnerId AND p1.OwnerTypeId=2  
		   WHERE d.DomainId = @iOwnerId  	
			)
			SET @bParentExists=1
		ELSE
			SET @bParentExists=0

	RETURN @bParentExists;
	
END
GO
