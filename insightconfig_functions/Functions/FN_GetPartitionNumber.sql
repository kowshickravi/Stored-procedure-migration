IF	OBJECT_ID('dbo.FN_GetPartitionNumber') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_GetPartitionNumber() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.FN_GetPartitionNumber
(
	@iCustomerId	int,
	@dtStartDate	datetime,
	@vcServiceClass	varchar(255),
	@vcTableClass	varchar(255)
)
RETURNS	int
AS
BEGIN
DECLARE	@iPartitionNumber	int

	SELECT	@iPartitionNumber = SP.PartitionNumber
	FROM	dbo.ISCustomerServicePartition	CSP
	INNER JOIN
			dbo.ISServerPartition			SP
	ON	SP.ISServerPartitionId	= CSP.ISServerPartitionId
	INNER JOIN
			dbo.ISServiceClass				SC
	ON	SC.ISServiceClassId	= SP.ISServiceClassId
	INNER JOIN
			dbo.ISTableClass				TC
	ON	TC.ISTableClassId	= SP.ISTableClassId
	WHERE	CSP.CustomerId	=  @iCustomerId
	AND		SC.Description	=  @vcServiceClass
	AND		TC.Description	=  @vcTableClass
	AND		CSP.StartDate	<= @dtStartDate
	AND		CSP.EndDate		>  @dtStartDate

RETURN @iPartitionNumber
END
GO
