IF OBJECT_ID('dbo.FN_ReadFeatureCodesForCustomer') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_ReadFeatureCodesForCustomer () RETURNS @ProvisionedFeatures TABLE (CustomerId int) AS BEGIN RETURN END')
GO

ALTER FUNCTION dbo.FN_ReadFeatureCodesForCustomer 
(
	@iCustomerId as INT
)
RETURNS 
@ProvisionedFeatures TABLE 
(
	FeatureCode varchar(56), 
	NumberUsers int
)
AS
BEGIN
	insert into @ProvisionedFeatures  
	select fs.featurecode, c.ActualNumberUsers from 
	(
		select CustomerId, ServiceTypeId from customerservice (NOLOCK)
		where customerid = @iCustomerId AND Enabled = 'Y' AND DateDeleted = '9999-12-31 23:59:59.000'
	UNION
		select @iCustomerId, 2 from CustomerConfig (NOLOCK)
		where customerid = @iCustomerId AND CheckUs_CheckVirus = 'Y' AND DateDeleted = '9999-12-31 23:59:59.000'
	UNION
		select @iCustomerId, 4 from ServiceSpam (NOLOCK)
		where customerid = @iCustomerId AND DateDeleted = '9999-12-31 23:59:59.000'
	) cs
	inner join featureservice fs on cs.servicetypeid = fs.serviceid 
	inner join customers c on cs.customerid = c.customerid
	WHERE	(fs.featurecode <> 'ESS_EMAIL_SAFEGUARD' OR fs.serviceid NOT IN (2, 4)) -- ignores AV/AS for Safeguard
			AND (fs.FeatureCode <> 'ESS_ETI_STANDALONE') -- remove ETI standalone
	GROUP BY fs.featurecode, c.ActualNumberUsers

	-- if PROTECT isn't provisioned and ESS_ETI_ADDON is then switch it for ESS_ETI_STANDALONE
	IF NOT EXISTS(SELECT 1 from @ProvisionedFeatures where FeatureCode IN ('ESS_EMAIL_PROTECT', 'ESS_EMAIL_SAFEGUARD'))
	BEGIN
		UPDATE @ProvisionedFeatures SET FeatureCode = 'ESS_ETI_STANDALONE' WHERE FeatureCode = 'ESS_ETI_ADDON'
	END
	-- if SAFEGAURD is being provisioned then remove PROTECT 
	IF EXISTS(SELECT 1 from @ProvisionedFeatures where FeatureCode = 'ESS_EMAIL_SAFEGUARD')
	BEGIN 
		DELETE FROM @ProvisionedFeatures where FeatureCode = 'ESS_EMAIL_PROTECT'
	END

	RETURN 
END

