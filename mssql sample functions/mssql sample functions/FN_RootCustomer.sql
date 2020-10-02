IF	OBJECT_ID('dbo.FN_RootCustomer') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_RootCustomer() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION	dbo.FN_RootCustomer()
RETURNS int
AS
BEGIN
	RETURN (	SELECT	CustomerId
				FROM	dbo.Customers	WITH (NOLOCK)
				WHERE	CustomerId = ParentResellerId
			)
END
GO
