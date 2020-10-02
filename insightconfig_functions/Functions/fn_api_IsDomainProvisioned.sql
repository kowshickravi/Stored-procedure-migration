IF OBJECT_ID('dbo.fn_api_IsDomainProvisioned') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_api_IsDomainProvisioned (@i int) RETURNS TABLE AS RETURN (SELECT @i AS a)')
GO

ALTER FUNCTION dbo.fn_api_IsDomainProvisioned
( @vcDomainName	varchar(255) )
RETURNS TABLE
AS
RETURN
(	
	WITH recCTE
	AS
	(
		SELECT @vcDomainName AS dom, charindex('.',@vcDomainName) + 1 as cx, 1 as ix
		
		UNION ALL
		
		SELECT substring(dom,cx,255) as dom, charindex('.',substring(dom,cx,255)) + 1 as cx, ix + 1 as ix
		FROM recCTE
		WHERE cx > 1
	)
	SELECT	TOP 1
			d.CustomerID,
			d.DomainId,
			d.Domain,
			ISNULL(a1.smtproutes_wildcard,0)	AS	smtproutes_wildcard
	FROM	dbo.AllDomains		AS	d	WITH (NOLOCK)
	LEFT 
	JOIN	dbo.CustomerConfig	AS	a1	WITH (NOLOCK)
	ON		a1.DomainId		=	d.DomainId
	AND		a1.DateDeleted	=	'9999-12-31 23:59:59'
	WHERE	EXISTS	(	SELECT	*
						FROM	recCTE AS r
						WHERE	d.Domain = r.dom
					)
	ORDER
	BY		LEN(d.Domain) DESC
)

GO