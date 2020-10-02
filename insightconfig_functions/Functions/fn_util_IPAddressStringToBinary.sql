IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_util_IPAddressStringToBinary]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[fn_util_IPAddressStringToBinary]
GO

CREATE FUNCTION dbo.fn_util_IPAddressStringToBinary(@nvcIPAddressString NVARCHAR(45))
RETURNS BINARY(16) WITH EXECUTE AS CALLER
/*
This function is a wrapper for a CLR assembly which converts IPAddress strings to BINARY(16)
*/

-- $Id: fn_util_IPAddressStringToBinary.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $
-- $Log: fn_util_IPAddressStringToBinary.sql $
-- Revision v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51
-- No Comment
-- 
-- Revision v_15\.1_ANZ_IP_Restriction_eharper\/3 2011/2/10 8:59:41
-- CLR code review changes
-- 
-- Revision v_15\.1_ANZ_IP_Restriction_eharper\/2 2011/2/4 15:51:52
-- fix typo
-- 
-- $Header: /InsightConfig/Functions/fn_util_IPAddressStringToBinary.sql v_20\.1_ESS_for_GCF_dfisher\/1 2012/2/7 11:38:51 dfisher $

AS EXTERNAL NAME IPAddressHandler.[Symantec.SaaS.SqlServer.Utils.IPFunctions].IpToBinary

