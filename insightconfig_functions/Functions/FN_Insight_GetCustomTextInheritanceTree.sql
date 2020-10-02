IF	OBJECT_ID(N'dbo.FN_Insight_GetCustomTextInheritanceTree') IS NULL 
	EXEC ('CREATE FUNCTION dbo.FN_Insight_GetCustomTextInheritanceTree() RETURNS @t TABLE(i int) AS BEGIN RETURN END')
GO

ALTER FUNCTION dbo.FN_Insight_GetCustomTextInheritanceTree
( @guidCustomTextId	uniqueidentifier )
RETURNS
	@retInheritingDomains TABLE
	(	CustomerId	int,
		DomainId	int	)
AS

-- $Id: $
-- $Log: $
-- $Header: $

BEGIN	
	DECLARE
		@iCustomerId		int,
		@iDomainId			int,
		@iOwnerId			int,
		@tiOwnerTypeId		tinyint,
		@tiForUseByChildren	tinyint,
		@tiCustomTextTypeId	tinyint

	SELECT
		@iOwnerId			=	OwnerId,
		@tiOwnerTypeId		=	OwnertypeId,
		@tiForUseByChildren	=	ForUseByChildren,
		@tiCustomTextTypeId =	CustomTextTypeId
	FROM CustomTextHierarchy
	WHERE CustomTextId = @guidCustomTextId

	IF @tiOwnerTypeId = 0 SET @iCustomerId	= @iOwnerId
	IF @tiOwnerTypeId = 1 SET @iDomainId	= @iOwnerId

	IF 	@tiOwnerTypeId		=	1	-- Domain
	BEGIN
		INSERT	@retInheritingDomains
		( CustomerId,	DomainId	)
		SELECT	ad.CustomerId, ad.DomainId
		FROM	AllDomains			ad 
		WHERE	DomainId	=	@iDomainId
		
		RETURN
	END

	IF 	@tiOwnerTypeId		=	0	-- Customer
	AND	@tiForUseByChildren	=	0   -- not used by children
	BEGIN							-- only need to raise changes for inheriting domains
		INSERT	@retInheritingDomains
		( CustomerId,	DomainId	)
		SELECT	ad.CustomerId, ad.DomainId
		FROM	AllDomains			ad
		JOIN	CustomTextHierarchy	cth
		  ON	cth.OwnerId				=	ad.DomainId
		 AND	cth.OwnerTypeId			=	1
		 AND	cth.CustomTextTypeId	=	@tiCustomTextTypeId
		WHERE	cth.State		=	2				-- state 3 inherits from reseller (level above)
		  AND	ad.CustomerId	=	@iCustomerId
		  
		RETURN
	END
		
	IF 	@tiOwnerTypeId		=	0	-- Customer
	AND	@tiForUseByChildren	=	1   -- used by children
	BEGIN							-- need to raise changes for inheriting customer/reseller nodes and all associated inheriting domains
		;WITH
			detail	AS
			(
				SELECT	c.CustomerId, c.ParentResellerId, ct.State
				FROM	Customers			c
				JOIN	CustomTextHierarchy	ct
				  ON	c.CustomerId		=	ct.OwnerId
				 AND	ct.ownertypeid		=	0
				 AND	ct.customtexttypeid	=	@tiCustomTexttypeId
				 AND	ct.forusebychildren	=	@tiForUseByChildren
				WHERE	c.datedeleted		= '9999-12-31 23:59:59.000'
			),
			hier	AS
			(
				SELECT	a.CustomerId, a.ParentResellerId, a.State,	CAST(0 as tinyint) as parentstate	--, 0 as hierachylevel
				FROM	detail	a
				WHERE	a.CustomerId		=	@iCustomerId											-- customer passed in
				UNION	ALL
				SELECT	b.CustomerId, b.parentresellerid, b.State,	hier.state as parentstate			--, hier.hierachylevel +1 as hierachylevel
				FROM	hier
				JOIN	detail	b
				  ON	b.ParentResellerId		=	hier.CustomerId
				 AND	b.CustomerId			<>	hier.CustomerId
			)
			INSERT	@retInheritingDomains
			( CustomerId,	DomainId	)
			SELECT	ad.CustomerId, ad.DomainId
			FROM	Hier				h
			JOIN	AllDomains			ad
			  ON	ad.CustomerId		=	h.CustomerId
			JOIN	CustomTextHierarchy	cth
			  ON	cth.OwnerId			=	ad.DomainId
			 AND	cth.OwnerTypeId		=	1
			WHERE	ad.DateDeleted			IS	NULL
			  AND	cth.customtexttypeid	=	@tiCustomTexttypeId
			  AND	cth.State				IN	(2,3)				-- domains inheriting from customer
			  AND	h.State					NOT	IN	(0,1)		-- stop lookup at customers with custom text or none
			  AND	ad.CustomerId			<>	@iCustomerId	-- for use by children, so given customer is not relevant
			UNION
			SELECT	ad.CustomerId, ad.DomainId
			FROM	Hier				h
			JOIN	AllDomains			ad
			  ON	ad.CustomerId		=	h.CustomerId
			JOIN	CustomTextHierarchy	cth
			  ON	cth.OwnerId			=	ad.DomainId
			 AND	cth.OwnerTypeId		=	1
			WHERE	ad.DateDeleted			IS	NULL
			  AND	cth.customtexttypeid	=	@tiCustomTexttypeId
			  AND	cth.State				=	3				-- domains inheriting from reseller
			  AND	( h.ParentState			NOT	IN	(0,1)		-- stop lookup at customers with custom text or the parent exists in the chain	
					OR	exists( select h2.CustomerId from Hier h2 where h2.customerid = h.ParentResellerId )) 
			
		RETURN
	END 
	RETURN
END
GO