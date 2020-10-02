IF OBJECT_ID('dbo.fn_insight_split2') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_insight_split2 () RETURNS @Limits TABLE (CustomerId int) AS BEGIN RETURN END')	
GO

ALTER FUNCTION [dbo].[fn_insight_split2]
(
	@RowData varchar(max),
	@SplitOn nvarchar(5)
)  
RETURNS @RtnValue table 
(
	Id int identity(1,1),
	Data nvarchar(2000)
) 
AS  
BEGIN 
	Declare @Cnt int
	Set @Cnt = 1

	While (Charindex(@SplitOn,@RowData)>0)
	Begin
		Insert Into @RtnValue (data)
		Select 
			Data = ltrim(rtrim(Substring(@RowData,1,Charindex(@SplitOn,@RowData)-1)))

		Set @RowData = Substring(@RowData,Charindex(@SplitOn,@RowData)+len(@SplitOn),len(@RowData))
		Set @Cnt = @Cnt + 1
	End
	
	Insert Into @RtnValue (data)
	Select Data = ltrim(rtrim(@RowData))

	Return
END
	