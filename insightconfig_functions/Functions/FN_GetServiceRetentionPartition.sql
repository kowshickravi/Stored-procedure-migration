IF OBJECT_ID('FN_GetServiceRetentionPartition') IS NOT NULL
BEGIN
	DROP FUNCTION FN_GetServiceRetentionPartition
END
GO

CREATE FUNCTION FN_GetServiceRetentionPartition
(
	@iCustomerId	int,
	@dtStartDate	datetime,
	@dtEndDate		datetime,
	@vcServiceClass	varchar(255),
	@vcTableClass	varchar(255),
	@vcRetention	varchar(255)
)
RETURNS @tabPartition	TABLE
		(PartitionNumber	int)
AS
BEGIN
	INSERT
	INTO	@tabPartition
			(PartitionNumber)
	SELECT	SP.PartitionNumber
	FROM	dbo.ISCustomerServicePartition	CSP
	INNER JOIN
			dbo.ISServerPartition			SP
	ON	SP.ISServerPartitionId	= CSP.ISServerPartitionId
	INNER JOIN
			dbo.ISRetentionDefinition		RD
	ON	RD.ISRetentionDefinitionId	= SP.ISRetentionDefinitionId
	INNER JOIN
			dbo.ISServiceClass				SC
	ON	SC.ISServiceClassId	= SP.ISServiceClassId
	INNER JOIN
			dbo.ISTableClass				TC
	ON	SP.ISTableClassId	= TC.ISTableClassId
	WHERE	CSP.CustomerId	= @iCustomerId
	AND		CSP.StartDate	<= @dtEndDate
	AND		CSP.EndDate		> @dtStartDate
	AND		SC.Description	= @vcServiceClass
	AND		TC.Description	= @vcTableClass
	AND		RD.Description	= @vcRetention

RETURN
END
GO
