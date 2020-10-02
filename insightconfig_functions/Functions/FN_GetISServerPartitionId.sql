IF	OBJECT_ID('dbo.FN_GetISServerPartitionId') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_GetISServerPartitionId() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.FN_GetISServerPartitionId
(
	@iCustomerId		int,
	@dtStartDate		datetime,
	@vcServiceClass		varchar(255),
	@vcTableClass		varchar(255)
)
RETURNS	int
AS
BEGIN
DECLARE	@iISServerPartitionId	int

	SELECT	@iISServerPartitionId = SP.ISServerPartitionId
	FROM	dbo.ISServerPartition			SP
	INNER JOIN
			dbo.ISCustomerServicePartition	CSP
	ON	CSP.ISServerPartitionId	= SP.ISServerPartitionId
	INNER JOIN
			dbo.ISServiceClass				SC
	ON	SC.ISServiceClassId	= SP.ISServiceClassId
	INNER JOIN
			dbo.ISTableClass				TC
	ON	TC.ISTableClassId	= SP.ISTableClassId
	INNER JOIN
			dbo.ISServerCode				CO
	ON	CO.ISServerCodeId	= SP.ISServerCodeId
	INNER JOIN
			dbo.ISRetentionDefinition	RD
	ON	RD.ISRetentionDefinitionId	= SP.ISRetentionDefinitionId
	AND	RD.ISTableClassId			= TC.ISTableClassId
	WHERE	CSP.CustomerId		=  @iCustomerid
	AND		SC.Description		=  @vcServiceClass
	AND		TC.Description		=  @vcTableClass
	AND		CSP.StartDate		<= @dtStartDate
	AND		CSP.EndDate			>  @dtStartDate

RETURN @iISServerPartitionId
END

GO


