IF OBJECT_ID('dbo.fn_insight_DLPLimitOverrideGet') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_DLPLimitOverrideGet () RETURNS @Limits TABLE (CustomerId int) AS BEGIN RETURN END')	
GO

ALTER FUNCTION [dbo].fn_insight_DLPLimitOverrideGet
(
	@iCustomerId	INT
)
RETURNS @Limits TABLE
(
	EntryLimit	INT,
	ListLimit	INT,
	PolicyLimit	INT,
	SuperListLimit INT,
	PolicyListLimit INT,
	CustomerListLimit INT
)
AS
BEGIN
 
    DECLARE	@iEntryLimit		INT,
			@iListLimit			INT,
			@iPolicyLimit		INT,
			@iSuperListLimit	INT,
			@iPolicyListLimit	INT,
			@iCustomerListLimit	INT 

	SELECT	@iEntryLimit	= CAST(COALESCE(ParameterValue, '2000') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumEntriesPerList'

	SELECT	@iListLimit		= CAST(COALESCE(ParameterValue, '500') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumLists'

	SELECT @iPolicyLimit	= CAST(COALESCE(ParameterValue, '500') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumPolicy'

	SELECT @iSuperListLimit	= CAST(COALESCE(ParameterValue, '26500') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumEntriesPerSuperList'

	SELECT @iPolicyListLimit	= CAST(COALESCE(ParameterValue, '30000') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumEntriesPerPolicy'

	SELECT @iCustomerListLimit	= CAST(COALESCE(ParameterValue, '37600') AS INT)
	FROM SystemParameter WITH (NOLOCK)
	WHERE ParameterName = 'DLPMaxNumEntriesPerAllPolicies'
	

	INSERT INTO @Limits
	SELECT	TOP 1							-- this is just in case, otherwise should be one entry per customer ...
		COALESCE(EntryLimit,  @iEntryLimit)					AS EntryLimit,
		COALESCE(ListLimit,   @iListLimit)					AS ListLimit,
		COALESCE(PolicyLimit, @iPolicyLimit)				AS PolicyLimit,
		COALESCE(SuperListLimit, @iSuperListLimit)			AS SuperListLimit,
		COALESCE(PolicyListLimit, @iPolicyListLimit)		AS PolicyListLimit,
		COALESCE(CustomerListLimit, @iCustomerListLimit)	AS CustomerListLimit
	FROM	dbo.DLPLimitOverride (NOLOCK)
	WHERE	CustomerId = @iCustomerId
	IF @@ROWCOUNT = 0
		INSERT INTO @Limits
		SELECT 
			@iEntryLimit		AS EntryLimit, 
			@iListLimit			AS ListLimit,
			@iPolicyLimit		AS PolicyLimit,
			@iSuperListLimit	AS  SuperListLimit,
			@iPolicyListLimit	AS PolicyListLimit,
			@iCustomerListLimit AS CustomerListLimit

	RETURN
END