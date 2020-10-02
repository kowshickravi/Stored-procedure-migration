IF OBJECT_ID('dbo.fn_insight_DLPDataLimits') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_DLPDataLimits () RETURNS @Limits TABLE (CustomerId int) AS BEGIN RETURN END')	
GO

ALTER FUNCTION [dbo].fn_insight_DLPDataLimits
(
	@iCustomerId	INT,
	@iPolicyId		INT
)
RETURNS @Counts TABLE
(
	CustomerListCount INT,
	PolicyListCount INT
)
AS
BEGIN
 
DECLARE		@iPolicyListCount	INT,
			@iCustomerListCount	INT,
			@iLevel INT 

SET @iLevel = 0

	DECLARE @tableListCount TABLE ( PolicyId INT,
									    ParentConditionGroupId INT,
									    ConditionGroupId INT, 
									    ExclusionFlag BIT,
									    InsertedLevel INT )
									    
	INSERT @tableListCount
	SELECT DISTINCT p.policyid, gp.ConditionGroupId as ParentConditionGroupId, gp.ConditionGroupId, 0 as ExclusionFlag, @iLevel as InsertedLevel
	FROM dbo.DLPPolicy p (NOLOCK)
	JOIN dbo.DLPRule r (NOLOCK) on p.policyid = r.policyid
	JOIN dbo.DLPCondition c (NOLOCK) on r.ruleid = c.ruleid
	JOIN dbo.DLPConditionGroupParam gp (NOLOCK) on c.conditionId = gp.ConditionId
    WHERE p.customerid = @iCustomerid
 
	WHILE @@ROWCOUNT > 0 
	BEGIN
		SET @iLevel = @iLevel + 1
		-- super group items to breakdown
		INSERT @tableListCount ( PolicyId, ParentConditionGroupId, ConditionGroupId, ExclusionFlag, InsertedLevel  )
		SELECT tmp.PolicyId, tmp.ParentConditionGroupId, sg.SuperConditionGroupDataId, sg.ExclusionFlag, @iLevel
		FROM DLPSuperConditionGroup sg (NOLOCK)
		JOIN @tableListCount tmp on tmp.ConditionGroupId = sg.SuperconditionGroupid
		WHERE tmp.InsertedLevel = @iLevel - 1
	END
 
	-- check currently selected policy limits
	DECLARE @tableListCountPolicy TABLE ( PolicyTotalEntryCount INT)
	
	INSERT @tableListCountPolicy
	SELECT COALESCE(( SELECT COUNT(gd.ConditionGroupDataId)
					 FROM DLPConditionGroupData	gd	(NOLOCK)
					 JOIN DLPCOnditionGroup g (NOLOCK) on gd.conditionGroupid = g.conditionGroupid and g.isSuper = 0					 
					 WHERE g.ConditionGroupId = tmp.ConditionGroupId and tmp.ExclusionFlag = 0),0) 	 
		   - 
		   COALESCE(( SELECT COUNT(gd.ConditionGroupDataId)
					 FROM DLPConditionGroupData	gd	(NOLOCK)
					 JOIN DLPCOnditionGroup g (NOLOCK) on gd.conditionGroupid = g.conditionGroupid and g.isSuper = 0					 
					 WHERE g.ConditionGroupId = tmp.ConditionGroupId and tmp.ExclusionFlag = 1),0)  As   PolicyTotalEntryCount
	FROM @tableListCount tmp
	WHERE tmp.policyid = @iPolicyId

	SELECT @iPolicyListCount = SUM(PolicyTotalEntryCount) 
	FROM @tableListCountPolicy 

	-- just in case we exclude more than we have...
	IF @iPolicyListCount < 0
	   SET @iPolicyListCount = 0 


	-- check all policies limits	
	DECLARE @tableListCountTot TABLE ( ParentConditionGroupId INT,
										PolicyTotalEntryCount INT)
	
	INSERT @tableListCountTot
	SELECT  DISTINCT tmp.ParentConditionGroupId,
			COALESCE(( SELECT COUNT(gd.ConditionGroupDataId)
					 FROM DLPConditionGroupData	gd	(NOLOCK)
					 JOIN DLPCOnditionGroup g (NOLOCK) on gd.conditionGroupid = g.conditionGroupid and g.isSuper = 0
					 JOIN @tableListCount tmp2 on g.conditionGroupid = tmp2.ConditionGroupId and tmp2.ExclusionFlag = 0
					 WHERE tmp2.ParentConditionGroupId = tmp.ConditionGroupId),0)  
			-		 
		  COALESCE(( SELECT COUNT(gd.ConditionGroupDataId)
					 FROM DLPConditionGroupData	gd	(NOLOCK)
					 JOIN DLPCOnditionGroup g (NOLOCK) on gd.conditionGroupid = g.conditionGroupid and g.isSuper = 0
					 JOIN @tableListCount tmp2 on g.conditionGroupid = tmp2.ConditionGroupId and tmp2.ExclusionFlag = 1
					 WHERE tmp2.ParentConditionGroupId = tmp.ConditionGroupId),0) As   PolicyTotalEntryCount
	FROM @tableListCount tmp

	SELECT @iCustomerListCount = SUM(PolicyTotalEntryCount) 
	FROM @tableListCountTot 
	
	IF @iCustomerListCount < 0
	   SET @iCustomerListCount = 0 


	INSERT INTO @Counts  
	SELECT @iCustomerListCount, @iPolicyListCount

	RETURN
END