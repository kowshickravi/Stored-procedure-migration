IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_util_IPAddressBinaryToString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_util_IPAddressBinaryToString]
GO


CREATE FUNCTION dbo.fn_util_IPAddressBinaryToString(@bIPAddressBinary BINARY(16))
RETURNS NVARCHAR(39) WITH EXECUTE AS CALLER
/*
This function is a wrapper for a CLR assembly which converts BINARY(16) to an IPAddress string
*/

-- $Id: fn_util_IPAddressBinaryToString.sql v_15\.1_ANZ_IP_Restriction_eharper\/3 2011/2/10 8:59:41 eharper $
-- $Log: fn_util_IPAddressBinaryToString.sql $
-- Revision v_15\.1_ANZ_IP_Restriction_eharper\/3 2011/2/10 8:59:41
-- CLR code review changes
-- 
-- Revision v_15\.1_ANZ_IP_Restriction_eharper\/2 2011/2/4 15:51:52
-- fix typo
-- 
-- $Header: /InsightConfig/Functions/fn_util_IPAddressBinaryToString.sql v_15\.1_ANZ_IP_Restriction_eharper\/3 2011/2/10 8:59:41 eharper $

AS EXTERNAL NAME IPAddressHandler.[Symantec.SaaS.SqlServer.Utils.IPFunctions].BinaryToIp

