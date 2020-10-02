IF	OBJECT_ID(N'dbo.fn_insight_MEGetSubscriberPartnerSettings') IS NULL 
	EXEC ('CREATE FUNCTION dbo.fn_insight_MEGetSubscriberPartnerSettings() RETURNS @t TABLE(i int) AS BEGIN RETURN END')
GO

ALTER FUNCTION dbo.fn_insight_MEGetSubscriberPartnerSettings
(
	@iMode			int,
	@iCustomerId  		int = Null,
	@iPartnerId		int = Null,
	@iPartnerMEDomainId	int = Null,
	@iNominatedMEDomainId	int = Null
)
RETURNS @return TABLE
(
	[CustomerId] 				[int]					NULL ,
	[PartnerId] 				[int]					NULL ,
	[PartnerMEDomainId] 			[int]					NULL ,
	[NominatedMEDomainId] 			[int]					NULL ,
	[UseDefaultProtectionStrength] 		[bit]					NOT NULL ,
	[MinProtectionStrength] 		[int]					NULL ,
	[UseDefaultInboundAuthentication] 	[bit]					NOT NULL ,
	[InboundAuthentication] 		[bit]					NULL ,
	[UseDefaultContact] 			[bit]					NULL ,
	[ContactName] 				[varchar] (255) 			NULL ,
	[ContactEmail] 				[varchar] (255) 			NULL ,
	[Comments] 				[nvarchar] (1024) 			NULL ,

	UNIQUE
	(
		[CustomerId], [PartnerId], [PartnerMEDomainId], [NominatedMEDomainId]
	)
)
AS
-- $Id: fn_insight_MEGetSubscriberPartnerSettings.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: fn_insight_MEGetSubscriberPartnerSettings.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/3 2011/9/15 16:34:17
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/2 2011/9/15 15:37:17
-- No Comment
-- 
-- Revision v_16\.0_AccuRevSyncWithProduction_rsmart\/1 2011/8/25 14:32:10
-- No Comment
-- 
-- Revision IC01_Telstra_Build_dknight\/2 2007/10/25 13:52:26
-- Enabled version headers
-- 
-- $Header: /InsightConfig/Functions/fn_insight_MEGetSubscriberPartnerSettings.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
BEGIN
	--------------------------------------
	-- Data returned depends on the mode
	-- requested, valid modes are:
	--
	-- 1. Global settings
	-- 2. Subscriber level settings
	-- 3. Partner level settings for any partner of the subscriber
	-- 4. Domain level settings for any domain of any partner for the subscriber
	-- 5. Partner level settings for a particular partner of the subscriber
	-- 6. Domain level settings for all domains of a particular partner of the subscriber
	-- 7. Domain level settings for a particular partner domain of the subscriber
	-- 8. Nominated domain level settings for all or a single nominated domain for the subscriber
	--------------------------------------

	--------------------------------------
	-- Init
	--------------------------------------
   	DECLARE @dtMaxDate		datetime
	SELECT	@dtMaxDate 		= '9999.12.31 23:59:59'

	--------------------------------------
	-- Storage to work out the ME settings
	-- (need to resolve inheritance of settings)
	--------------------------------------
	DECLARE @driver TABLE
	(
		[SettingsLevel] 			[int]					NOT NULL ,
		[CustomerId] 				[int]					NULL ,
		[PartnerId] 				[int]					NULL ,
		[PartnerMEDomainId] 			[int]					NULL ,
		[NominatedMEDomainId] 			[int]					NULL ,
		[UseDefaultProtectionStrength] 		[bit]					NOT NULL ,
		[MinProtectionStrength] 		[int]					NULL ,
		[UseDefaultInboundAuthentication] 	[bit]					NOT NULL ,
		[InboundAuthentication] 		[bit]					NULL ,
		[UseDefaultContact] 			[bit]					NULL ,
		[ContactName] 				[varchar] (255) 			NULL ,
		[ContactEmail] 				[varchar] (255) 			NULL ,
		[Comments] 				[nvarchar] (1024) 			NULL ,

		UNIQUE
		(
			[CustomerId], [PartnerId], [PartnerMEDomainId], [NominatedMEDomainId]
		)
	)

	--------------------------------------
	-- Always get the global level settings
	--------------------------------------
	INSERT INTO @driver
	(
		SettingsLevel,
		CustomerId,
		PartnerId,
		PartnerMEDomainId,
		NominatedMEDomainId,
		UseDefaultProtectionStrength,
		MinProtectionStrength,
		UseDefaultInboundAuthentication,
		InboundAuthentication,
		UseDefaultContact,
		ContactName,
		ContactEmail,
		Comments
	)
	SELECT
		1,		-- Global level
		NULL,
		NULL,
		NULL,
		NULL,
		0,
		MinProtectionStrength,
		0,
		InboundAuthentication,
		NULL,
		NULL,
		NULL,
		NULL
	FROM
		ServiceMEGlobalSettings
	WHERE
		SettingsId = 1

	--------------------------------------
	-- Get the subscriber level settings
	-- unless only getting global
	--------------------------------------
	IF @iMode >= 2
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT
			2,					-- Subscriber level
			@iCustomerId,
			NULL,
			NULL,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			NULL,					-- Contacts inherit flag only applies to partner domain level
			NULL,
			NULL,
			NULL
		FROM
			ServiceMESubscriber S

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				S.CustomerId			= ME.CustomerId
				AND ME.PartnerId		IS NULL
				AND ME.PartnerMEDomainId	IS NULL
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			S.CustomerId				= @iCustomerId
			AND S.DateDeleted			= @dtMaxDate
	END

	--------------------------------------
	-- Get the partner level settings
	-- for any partner of the subscriber
	--------------------------------------
	IF @iMode = 3 OR @iMode = 4
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT DISTINCT
			3,					-- Partner level
			@iCustomerId,
			P.PartnerId,
			NULL,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication,1 ),
			InboundAuthentication,
			NULL,					-- Contacts inherit flag only applies to partner domain level
			ContactName,
			ContactEmail,
			Comments
		FROM
			ServiceMEPartner P

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= P.CustomerId		-- Subscriber
				AND ME.PartnerId		= P.PartnerId		-- Partner
				AND ME.PartnerMEDomainId	IS NULL			-- Partner level settings so exclude any domain settings
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			P.CustomerId				= @iCustomerId
			AND P.DateDeleted			= @dtMaxDate
	END


	--------------------------------------
	-- Get the domain level settings
	-- for any partner domain of the subscriber
	--------------------------------------
	IF @iMode = 4
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT DISTINCT
			4,					-- Domain level
			@iCustomerId,
			PD.PartnerId,
			PD.MEDomainId,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			IsNULL(UseDefaultContact, 1),
			ContactName,
			ContactEmail,
			Comments
		FROM
			ServiceMEPartnerDomain PD

				INNER JOIN ServiceMEPartner P
				ON
				PD.PartnerId 		= P.PartnerId

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= P.CustomerId		-- Subscriber
				AND ME.PartnerId		= P.PartnerId		-- Partner
				AND ME.PartnerMEDomainId	= PD.MEDomainId		-- Domain
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			P.CustomerId				= @iCustomerId
			AND PD.DateDeleted			= @dtMaxDate
			AND P.DateDeleted			= @dtMaxDate
	END


	--------------------------------------
	-- Get the partner level settings
	-- for the specified partner of the subscriber
	--------------------------------------
	IF @iMode = 5 OR @iMode = 6 OR @iMode = 7
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT DISTINCT
			3,							-- Partner level
			@iCustomerId,
			@iPartnerId,
			NULL,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			NULL,							-- Contacts inherit flag only applies to partner domain level
			ContactName,
			ContactEmail,
			Comments
		FROM
			ServiceMEPartner P

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= P.CustomerId		-- Subscriber
				AND ME.PartnerId		= P.PartnerId		-- Partner
				AND ME.PartnerMEDomainId	IS NULL			-- Partner level settings so exclude any domain settings
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			P.CustomerId				= @iCustomerId
			AND P.PartnerId				= @iPartnerId
			AND P.DateDeleted			= @dtMaxDate
	END


	--------------------------------------
	-- Get the domain level settings for any domain
	-- for the specified partner of the subscriber
	--------------------------------------
	IF @iMode = 6
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT DISTINCT
			4,							-- Domain level
			@iCustomerId,
			@iPartnerId,
			ME.PartnerMEDomainId,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			IsNULL(UseDefaultContact, 1),
			ContactName,
			ContactEmail,
			Comments
		FROM
			ServiceMEPartner P

				INNER JOIN ServiceMEPartnerDomain PD
				ON
				PD.PartnerId 			= P.PartnerId

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= P.CustomerId		-- Subscriber
				AND ME.PartnerId		= P.PartnerId		-- Partner
				AND ME.PartnerMEDomainId	IS NOT NULL		-- Domain level settings so exclude the partner settings
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			P.CustomerId				= @iCustomerId
			AND P.PartnerId				= @iPartnerId
			AND P.DateDeleted			= @dtMaxDate
			AND PD.DateDeleted			= @dtMaxDate
	END


	--------------------------------------
	-- Get the domain level settings for the specified
	-- domain for the specified partner of the subscriber
	--------------------------------------
	IF @iMode = 7
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT
			4,							-- Domain level
			@iCustomerId,
			@iPartnerId,
			@iPartnerMEDomainId,
			NULL,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			IsNULL(UseDefaultContact, 1),
			ContactName,
			ContactEmail,
			Comments
		FROM
			-- Use partner domains as link to find partners
			ServiceMEPartnerDomain PD

				INNER JOIN ServiceMEPartner P
				ON
				PD.PartnerId		= P.PartnerId

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= P.CustomerId		-- Subscriber
				AND ME.PartnerId		= P.PartnerId		-- Partner
				AND ME.PartnerMEDomainId	= PD.MEDomainId		-- Domain
				AND ME.NominatedMEDomainId	IS NULL
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			P.CustomerId				= @iCustomerId
			AND P.PartnerId				= @iPartnerId
			AND PD.MEDomainId			= @iPartnerMEDomainId
			AND PD.DateDeleted			= @dtMaxDate
			AND P.DateDeleted			= @dtMaxDate
	END


	--------------------------------------
	-- Get the nominated domain level settings for either
	-- all nominated domains or a specified domain for the
	-- subscriber.
	--------------------------------------
	IF @iMode = 8
	BEGIN
		INSERT INTO @driver
		(
			SettingsLevel,
			CustomerId,
			PartnerId,
			PartnerMEDomainId,
			NominatedMEDomainId,
			UseDefaultProtectionStrength,
			MinProtectionStrength,
			UseDefaultInboundAuthentication,
			InboundAuthentication,
			UseDefaultContact,
			ContactName,
			ContactEmail,
			Comments
		)
		SELECT
			5,							-- Nominated Domain level
			@iCustomerId,
			NULL,
			NULL,
			ND.MEDomainId,
			IsNULL(UseDefaultProtectionStrength, 1),
			MinProtectionStrength,
			IsNULL(UseDefaultInboundAuthentication, 1),
			InboundAuthentication,
			NULL,
			NULL,
			NULL,
			NULL
		FROM
			ServiceMENominatedDomain ND

				INNER JOIN ServiceMEDomain D
				ON
				ND.MEDomainId 		= D.MEDomainId

				LEFT OUTER JOIN ServiceMESettings ME
				ON
				ME.CustomerId			= D.CustomerId					-- Subscriber
				AND ME.NominatedMEDomainId	= D.MEDomainId					-- Nominated Domain
				AND ME.PartnerId		IS NULL						-- Partner
				AND ME.PartnerMEDomainId	IS NULL						-- Partner Domain
				AND ME.DateDeleted		= @dtMaxDate
		WHERE
			D.CustomerId				= @iCustomerId
			AND (ME.NominatedMEDomainId		= @iNominatedMEDomainId OR @iNominatedMEDomainId IS NULL)
			AND ND.DateDeleted			= @dtMaxDate
			AND D.DateDeleted			= @dtMaxDate
	END

	--------------------------------------
	-- Work out inheritance chains
	--------------------------------------


	--------------------------------------
	-- Apply global settings to any subscriber
	-- settings that require it
	--------------------------------------
	IF @iMode >= 2
	BEGIN
		UPDATE
			D2
		SET
			UseDefaultProtectionStrength	= IsNULL(D2.UseDefaultProtectionStrength, 1),
			UseDefaultInboundAuthentication	= IsNULL(D2.UseDefaultInboundAuthentication, 1),
			MinProtectionStrength 		= CASE WHEN IsNULL(D2.UseDefaultProtectionStrength, 1) = 1 THEN D1.MinProtectionStrength ELSE D2.MinProtectionStrength END,
			InboundAuthentication		= CASE WHEN IsNULL(D2.UseDefaultInboundAuthentication, 1) = 1 THEN D1.InboundAuthentication ELSE D2.InboundAuthentication END
		FROM
			@driver D2

				INNER JOIN @driver D1
				ON
				(D1.SettingsLevel + 1) = D2.SettingsLevel
		WHERE
			D2.SettingsLevel	= 2
			AND D1.SettingsLevel	= 1
	END


	IF @iMode >= 3 AND @iMode <= 7
	BEGIN
		--------------------------------------
		-- Apply subscriber settings to any partner
		-- settings that require it
		--------------------------------------
		UPDATE
			D3
		SET
			UseDefaultProtectionStrength	= IsNULL(D3.UseDefaultProtectionStrength, 1),
			UseDefaultInboundAuthentication	= IsNULL(D3.UseDefaultInboundAuthentication, 1),
			MinProtectionStrength 		= CASE WHEN IsNULL(D3.UseDefaultProtectionStrength, 1) = 1 THEN D2.MinProtectionStrength ELSE D3.MinProtectionStrength END,
			InboundAuthentication		= CASE WHEN IsNULL(D3.UseDefaultInboundAuthentication, 1) = 1 THEN D2.InboundAuthentication ELSE D3.InboundAuthentication END
		FROM
			@driver D3

				INNER JOIN @driver D2
				ON
				(D2.SettingsLevel + 1) 		= D3.SettingsLevel
				AND D2.CustomerId		= D3.CustomerId
				AND D2.PartnerId		IS NULL
				AND D3.PartnerId		IS NOT NULL
				AND D2.PartnerMEDomainId	IS NULL
				AND D3.PartnerMEDomainId	IS NULL
		WHERE
			D3.SettingsLevel	= 3
			AND D2.SettingsLevel	= 2

		IF @iMode IN (4, 6, 7)
		BEGIN
			--------------------------------------
			-- Apply partner settings to any partner
			-- domain settings that require it
			--------------------------------------
			UPDATE
				D4
			SET
				UseDefaultProtectionStrength	= IsNULL(D4.UseDefaultProtectionStrength, 1),
				UseDefaultInboundAuthentication	= IsNULL(D4.UseDefaultInboundAuthentication, 1),
				UseDefaultContact		= IsNULL(D4.UseDefaultContact, 1),
				MinProtectionStrength 		= CASE WHEN IsNULL(D4.UseDefaultProtectionStrength, 1) = 1 THEN D3.MinProtectionStrength ELSE D4.MinProtectionStrength END,
				InboundAuthentication		= CASE WHEN IsNULL(D4.UseDefaultInboundAuthentication, 1) = 1 THEN D3.InboundAuthentication ELSE D4.InboundAuthentication END,
				ContactName			= CASE WHEN IsNULL(D4.UseDefaultContact, 1) = 1 THEN D3.ContactName ELSE D4.ContactName END,
				ContactEmail			= CASE WHEN IsNULL(D4.UseDefaultContact, 1) = 1 THEN D3.ContactEmail ELSE D4.ContactEmail END
			FROM
				@driver D4

					INNER JOIN @driver D3
					ON
					(D3.SettingsLevel + 1) 		= D4.SettingsLevel
					AND D3.CustomerId		= D4.CustomerId
					AND D3.PartnerId		= D4.PartnerId
					AND D3.PartnerMEDomainId	IS NULL
					AND D4.PartnerMEDomainId	IS NOT NULL
			WHERE
				D4.SettingsLevel	= 4
				AND D3.SettingsLevel	= 3
		END
	END


	--------------------------------------
	-- Apply subscriber settings to any nominated
	-- domain settings that require it
	--------------------------------------
	IF @iMode = 8
	BEGIN
		UPDATE
			D5
		SET
			UseDefaultProtectionStrength	= IsNULL(D5.UseDefaultProtectionStrength, 1),
			UseDefaultInboundAuthentication	= IsNULL(D5.UseDefaultInboundAuthentication, 1),
			MinProtectionStrength 		= CASE WHEN IsNULL(D5.UseDefaultProtectionStrength, 1) = 1 THEN D2.MinProtectionStrength ELSE D5.MinProtectionStrength END,
			InboundAuthentication		= CASE WHEN IsNULL(D5.UseDefaultInboundAuthentication, 1) = 1 THEN D2.InboundAuthentication ELSE D5.InboundAuthentication END
		FROM
			@driver D5

				INNER JOIN @driver D2
				ON
				(D2.SettingsLevel + 3) 		= D5.SettingsLevel
				AND D2.CustomerId		= D5.CustomerId
				AND D2.PartnerId		IS NULL
				AND D5.PartnerId		IS NULL
				AND D2.PartnerMEDomainId	IS NULL
				AND D5.PartnerMEDomainId	IS NULL
				AND D2.NominatedMEDomainId	IS NULL
				AND D5.NominatedMEDomainId	IS NOT NULL

		WHERE
			D5.SettingsLevel	= 5
			AND D2.SettingsLevel	= 2
	END


	--------------------------------------
	-- Return resolved settings at the
	-- level requested
	--------------------------------------
	INSERT INTO @return
	(
		CustomerId,
		PartnerId,
		PartnerMEDomainId,
		NominatedMEDomainId,
		UseDefaultProtectionStrength,
		MinProtectionStrength,
		UseDefaultInboundAuthentication,
		InboundAuthentication,
		UseDefaultContact,
		ContactName,
		ContactEmail,
		Comments
	)
	SELECT
		CustomerId,
		PartnerId,
		PartnerMEDomainId,
		NominatedMEDomainId,
		UseDefaultProtectionStrength,
		MinProtectionStrength,
		UseDefaultInboundAuthentication,
		InboundAuthentication,
		UseDefaultContact,
		ContactName,
		ContactEmail,
		Comments
	FROM
		@driver
	WHERE
		SettingsLevel = CASE
					WHEN @iMode = 1 THEN 1
					WHEN @iMode = 2 THEN 2
					WHEN @iMode = 8 THEN 5
					WHEN @iMode IN (3, 5) THEN 3
					ELSE 4
				END

	RETURN
END
GO

GRANT SELECT ON dbo.fn_insight_MEGetSubscriberPartnerSettings TO R_InsightUser
GO