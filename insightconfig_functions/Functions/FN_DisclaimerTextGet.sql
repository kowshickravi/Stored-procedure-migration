IF	OBJECT_ID(N'dbo.FN_DisclaimerTextGet') IS NULL 
	EXEC ('CREATE FUNCTION dbo.FN_DisclaimerTextGet() RETURNS @t TABLE(i int) AS BEGIN RETURN END')
GO

ALTER FUNCTION dbo.FN_DisclaimerTextGet
(
 @iDisclaimerId int,
 @iDisclaimerTextTypeId int
)
RETURNS @tResult TABLE
(
 CustomerID int,
 ParentResellerId int,
 DisclaimerId int,
 [Level] int,
 CustomTextContentId uniqueidentifier,
 ForUseByChildren tinyint,
 [State] int,
 CustomTextTypeId int,
 CustomTextId uniqueidentifier
)
AS 
-- $Id: FN_DisclaimerTextGet.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: FN_DisclaimerTextGet.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_bflanaghan\/3 2011/3/30 9:58:29
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_bflanaghan\/2 2011/2/22 16:31:29
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_bflanaghan\/1 2011/1/18 14:28:55
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_1_aphillips\/4 2010/10/29 8:24:43
-- No Comment
-- 
-- Revision v_10\.0_DisclaimersManagement_1_aphillips\/3 2010/10/29 8:20:42
-- $Header: /InsightConfig/Functions/FN_DisclaimerTextGet.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
BEGIN
    -- note this function only works for default disclaimers
    -- this function is only called by up_insight_DisclaimerTextGet (and the initial disclaimers migration script)
    
    DECLARE @iCount int
    DECLARE @iMaxCount int 
    DECLARE @uiCustomTextContentId uniqueidentifier ;
    
	-- insert inheritance hierarchy
    WITH    cte
              AS (SELECT    c.CustomerID,
                            c.ParentResellerId,
                            d.DisclaimerId,
                            0 'Level'
                  FROM      dbo.Customers c (NOLOCK)
                  JOIN      dbo.Disclaimer d
                  ON        d.CustomerId = c.CustomerID
                            AND d.isDefault = 1
                            AND d.DisclaimerId = @iDisclaimerId
                  UNION ALL
                  SELECT    c.CustomerID,
                            c.ParentResellerId,
                            d.DisclaimerId,
                            [Level] + 1
                  FROM      dbo.Customers c (NOLOCK)
                  JOIN      dbo.Disclaimer d
                  ON        d.CustomerId = c.CustomerID
                            AND d.DisclaimerName = 'Default'
                  JOIN      cte
                  ON        cte.ParentResellerId = c.CustomerID
                  WHERE     cte.CustomerID <> dbo.FN_RootCustomer()
                            AND c.DateDeleted = '9999-12-31 23:59:59')
        INSERT  INTO @tResult
        (
         CustomerID,
         ParentResellerId,
         DisclaimerId,
         [Level],
         CustomTextTypeId,
         ForUseByChildren
        )       
				SELECT  CustomerID,
                        ParentResellerId,
                        DisclaimerId,
                        ROW_NUMBER() OVER (ORDER BY Level DESC),
                        @iDisclaimerTextTypeId,
                        1
                FROM    cte
                                
	-- insert initial customer level default disclaimer record
    INSERT  INTO @tResult
    (
     CustomerID,
     ParentResellerId,
     DisclaimerId,
     [Level],
     CustomTextTypeId,
     ForUseByChildren
    )       
	SELECT  c.CustomerID,
            c.ParentResellerId,
            d.DisclaimerId,
            (SELECT MAX([Level]) FROM @tResult) + 1 AS [Level],
            @iDisclaimerTextTypeId,
            0
	FROM    dbo.Customers c WITH (NOLOCK) INNER JOIN
	        dbo.Disclaimer d ON d.CustomerId = c.CustomerID
    WHERE   DisclaimerId = @iDisclaimerId



    SELECT  @iMaxCount = MAX([Level])
    FROM    @tResult

    SELECT  @iCount = 1            
    WHILE @iCount <= @iMaxCount
        BEGIN           
        
            UPDATE  r1
            SET     CustomTextContentId = cth.CustomTextContentId,
                    State = cth.State,
                    CustomTextId = cth.CustomTextId
            FROM    @tResult r1 INNER JOIN
                    dbo.CustomTextHierarchy cth ON cth.ownerid = r1.DisclaimerId
					                            AND cth.ownertypeid = 3
					                            AND cth.CustomTextTypeId = r1.CustomTextTypeId
					                            AND cth.ForUseByChildren = r1.ForUseByChildren
            WHERE     r1.[Level] = @iCount     
        
            SET @iCount = @iCount + 1
        END 
    RETURN
END
GO
 
