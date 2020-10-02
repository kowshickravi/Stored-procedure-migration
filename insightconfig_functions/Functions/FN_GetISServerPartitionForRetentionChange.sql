IF	OBJECT_ID('dbo.FN_GetISServerPartitionForRetentionChange') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_GetISServerPartitionForRetentionChange() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.FN_GetISServerPartitionForRetentionChange
(
	@iCustomerId		int,
	@dtStartDate		datetime,
	@vcServiceClass		varchar(255),
	@vcTableClass		varchar(255),
	@iRetentionSpan		int,
	@iISServerCodeId	int
)
RETURNS	int
AS
BEGIN
DECLARE	@iISServerPartitionId	int

	SELECT	TOP 1
			@iISServerPartitionId = SP.ISServerPartitionId + (@iCustomerId % RD.NumberOfTablesDefault)
	FROM	dbo.ISServerPartition			SP
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
	WHERE	SC.Description		=  @vcServiceClass
	AND		TC.Description		=  @vcTableClass
	AND		RD.UnitsBack		=  @iRetentionSpan
	AND		CO.ISServerCodeId	=  @iISServerCodeId
	ORDER BY SP.ISServerPartitionId

RETURN @iISServerPartitionId
END

GO

