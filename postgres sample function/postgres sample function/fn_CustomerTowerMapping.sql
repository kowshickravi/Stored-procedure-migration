CREATE OR REPLACE FUNCTION dbo."fn_CustomerTowerMapping"(
    IN  pi_ClusterId INTEGER ,
    IN  pi_ServerId  INTEGER
)
    RETURNS TABLE
                (
                    "ClusterId" INTEGER ,
                    "ServerId"  INTEGER
                )
    LANGUAGE plpgsql
AS
$BODY$
-- ========================================================================================================
-- Description : 
--             :
-- Author      : 
-- --------------------------------------------------------------------------------------------------------
-- [Change History]
-- --------------------------------------------------------------------------------------------------------
-- Date (yyyy-mm-dd)  Changed By                 Build               Etrack/Jira     Change Description
--
-- 2020-06-08          Jayaprakash(k1)           20_02_RobsonDB                      Migrated from SQL Server
-- ========================================================================================================
-- ------------------------------------------------------------------------------------------------------------
-- [COPYIGHT NOTICE]
-- ------------------------------------------------------------------------------------------------------------
-- Copyright © 2020 Broadcom. All rights reserved.
-- The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.
--
-- This software and all information contained therein is confidential and proprietary and shall not be
-- duplicated, used, disclosed or disseminated in any way except as authorized by the applicable license agreement,
-- without the express written permission of Broadcom. All authorized reproductions must be marked with this language.
--
-- EXCEPT AS SET FORTH IN THE APPLICABLE LICENSE AGREEMENT, TO THE EXTENT PERMITTED BY APPLICABLE LAW OR
-- AS AGREED BY BROADCOM IN ITS APPLICABLE LICENSE AGREEMENT, BROADCOM PROVIDES THIS DOCUMENTATION “AS IS”
-- WITHOUT WARRANTY OF ANY KIND, INCLUDING WITHOUT LIMITATION, ANY IMPLIED WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE, OR NONINFRINGEMENT. IN NO EVENT WILL BROADCOM BE LIABLE TO THE END USER OR
-- ANY THIRD PARTY FOR ANY LOSS OR DAMAGE, DIRECT OR INDIRECT, FROM THE USE OF THIS DOCUMENTATION,
-- INCLUDING WITHOUT LIMITATION, LOST PROFITS, LOST INVESTMENT, BUSINESS INTERRUPTION, GOODWILL, OR LOST DATA,
-- EVEN IF BROADCOM IS EXPRESSLY ADVISED IN ADVANCE OF THE POSSIBILITY OF SUCH LOSS OR DAMAGE
-- ========================================================================================================
BEGIN
    RETURN QUERY (
                     SELECT "MasterServer_ClusterId" AS "ClusterId",
                            "MasterServer_ServerId"  AS "ServerId"
                       FROM dbo."ClusterSuperServer" ss
                      WHERE ss."MasterServer_ClusterId" = pi_ClusterId
                        AND ss."MasterServer_ServerId"  = pi_ServerId
                      UNION
                     SELECT "Clone_ClusterId" AS "ClusterId",
                            "Clone_ServerId"  AS "ServerId"
                       FROM dbo."ClusterSuperServer" ss
                      WHERE ss."MasterServer_ClusterId" = pi_ClusterId
                        AND ss."MasterServer_ServerId"  = pi_ServerId
                      UNION
                     SELECT pi_ClusterId AS "ClusterId", -- For any stand alone servers in Prod streams
                            pi_ServerId  AS "ServerId"
                 );
END;
$BODY$;