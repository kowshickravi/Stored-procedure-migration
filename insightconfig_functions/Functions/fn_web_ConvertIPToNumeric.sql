IF	OBJECT_ID('dbo.fn_web_ConvertIPToNumeric') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_web_ConvertIPToNumeric() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_web_ConvertIPToNumeric (@cIPAddress char(15))  
RETURNS bigint  
/**  
** Name: fn_web_ConvertIPToNumeric  
** =================================  
$Revision: 1 $  
$Modtime: 28/02/06 8:56 $  
$Author: Scott McLean $  
** =================================  
**  
** PURPOSE:   
** Returns numeric IP from display format  
**   
** PROCEDURE CALLS  
** Called From:  
** Calls:   None  
**  
** TABLES:   
**  
** PARAMETERS:  
** @cIPAddress     
**  
** RETURNS:   
** @iIPNumeric  
**                
** COMMENT:   
**    
**/  
AS  
BEGIN  
DECLARE @iOct   int,                     
 @iOct1           int,  
 @iOct2           int,  
 @iOct3           int,  
 @iOct4           int,  
 @iIPOct1         int,  
 @iIPOct2         int,  
 @iIPOct3         int,  
 @iIPOct4        int,  
 @iActiveOct     int,  
 @iActiveIPOct   int,  
 @iActiveOctNo    int,  
 @iEndPos         int,  
 @iLoop           int,  
 @iRangeStart     int,  
 @iRangeEnd       int,  
 @iRowId          int,   
 @iFini           int,  
 @iIPNumeric   bigint,  
 @vc16IPString   varchar(16)  
  
 /* Get the IP Octets */  
    
 SELECT @iLoop          = 1  
    
 SELECT @vc16IPString = @cIPAddress + '.'  
    
 WHILE @iLoop <= 4  
 BEGIN  
  SELECT @iEndPos      = CHARINDEX('.',@vc16IPString)  
  SELECT @iOct         = CONVERT(int,SUBSTRING(@vc16IPString,1,(@iEndPos-1)))  
  SELECT @vc16IPString = SUBSTRING(@vc16IPString,(@iEndPos + 1),LEN(@vc16IPString))   
    
  IF @iLoop = @iActiveOctNo  
   SELECT @iActiveIPOct   = @iOct  
     
  IF @iLoop = 1  
   SELECT @iIPOct1 = @iOct  
  ELSE IF @iLoop = 2  
     SELECT @iIPOct2 = @iOct   
    ELSE IF @iLoop = 3  
       SELECT @iIPOct3 = @iOct   
      ELSE  
       SELECT @iIPOct4 = @iOct   
      
  SELECT @iLoop = @iLoop + 1  
 END  
   
 IF @iActiveOctNo = 1  
  RETURN 0  
  
 SELECT @iIPNumeric = 16777216.0 * @iIPOct1 + 65536.0 * @iIPOct2 + 256.0 * @iIPOct3 + @iIPOct4  
 RETURN @iIPNumeric  
END  
  
  