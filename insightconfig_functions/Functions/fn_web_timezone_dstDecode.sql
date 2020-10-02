IF	OBJECT_ID('dbo.fn_web_timezone_dstDecode') IS NULL
	EXEC ('CREATE FUNCTION dbo.fn_web_timezone_dstDecode() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.fn_web_timezone_dstDecode 
(  @vcDSTDateFormat varchar(10) )
RETURNS datetime

BEGIN

	DECLARE @iYear		int
	DECLARE @dtStart	datetime
	DECLARE @dtEnd		datetime

	DECLARE @iWeekNo	int
	DECLARE	@iMonthNo	int
	DECLARE	@iDayNo		int
	DECLARE @dtFindStartDate	datetime

	DECLARE @dtDSTDate	datetime
	

	-------------------------------------------------
	-- Calculate the week numbers for each month
	-------------------------------------------------

	DECLARE @tmpWeeksofMonth table( FromMonthDayYear datetime, ToMonthDayYear datetime, WeekNo int)

	SELECT @iYear = DATEPART(year, getdate())
	SELECT @dtStart = CONVERT(datetime, 'Jan 1 ' + CONVERT(varchar, @iYear))
	SELECT @dtEnd = CONVERT(datetime, 'Dec 31 ' + CONVERT(varchar, @iYear))

	WHILE @dtStart <= @dtEnd AND NOT EXISTS (	SELECT 1 FROM  @tmpWeeksofMonth 
												WHERE FromMonthDayYear = @dtStart )
	BEGIN
		IF DATEPART(month, DATEADD(day, 6, @dtStart)) = DATEPART(month, @dtStart) 
		BEGIN
			INSERT @tmpWeeksofMonth (FromMonthDayYear, ToMonthDayYear, WeekNo)
			SELECT @dtStart, 
			DATEADD(day, 6, @dtStart), 
			CASE WHEN DATEPART(month, DATEADD(day, 6, @dtStart)) != DATEPART(month, DATEADD(day, 7, @dtStart)) 
				 THEN -1  -- end of the current month
				 ELSE DATEDIFF(week,(@dtStart-DATEPART(dd,@dtStart)+1),@dtStart)+1 
			END

			SELECT @dtStart = DATEADD(day, 7, @dtStart)
		END

		ELSE 
		BEGIN
			IF DATEPART(year, DATEADD(day, 6, @dtStart)) = DATEPART(year, @dtStart) 
			BEGIN
				INSERT @tmpWeeksofMonth (FromMonthDayYear, ToMonthDayYear, WeekNo)
				SELECT @dtStart, 
				DATEADD(day, -1, CONVERT (datetime,CONVERT(varchar,DATEPART(month, DATEADD(day, 6, @dtStart))) + '/01/' + CONVERT(varchar,@iYear))),
				-1 -- end of the current month

				SELECT @dtStart = CONVERT (datetime,CONVERT(varchar,DATEPART(month, DATEADD(day, 6, @dtStart))) + '/01/' + CONVERT(varchar,@iYear))
			END
			ELSE
			BEGIN
				INSERT @tmpWeeksofMonth (FromMonthDayYear, ToMonthDayYear, WeekNo)
				SELECT @dtStart, 
				DATEADD(day, -1, CONVERT (datetime,CONVERT(varchar,DATEPART(month, DATEADD(day, 6, @dtStart))) + '/01/' + CONVERT(varchar,@iYear+1))),
				-1 -- end of the current month

				SELECT @dtStart = CONVERT (datetime,CONVERT(varchar,DATEPART(month, DATEADD(day, 6, @dtStart))) + '/01/' + CONVERT(varchar,@iYear+1))
			END

		END
	END


	-------------------------------------------------
	-- Now lets take the elements of the wacky format and process them 
	-- so they become a real date!
	-------------------------------------------------
	
	-- @vcDSTDateFormat is of the format: X;Y;Z

	-- X is the week of the month, can be -1, or in the range 1 to 5. (-1 means “last”, 1 means 1st, 2 means 2nd, etc)
	-- Y is the day of the week, in the range 0 to 6, where 0 = Sunday
	-- Z is the month of the year, in the range 1 to 12, where 1 = January
	-- E.g. “1;0;5” for “1st Sunday in May”, “-1;6;4” for “last Saturday in April”
	
	-- lets take the month first
	DECLARE @tmpFormatSplit TABLE( Seq int, Placeholder int)

	INSERT @tmpFormatSplit
	SELECT * 
	FROM dbo.fn_insight_split( @vcDSTDateFormat, ';' )

	SELECT @iWeekNo = Placeholder FROM @tmpFormatSplit where Seq = 1
	SELECT @iDayNo = Placeholder + 1 FROM @tmpFormatSplit where Seq = 2 -- sql offset is 1
	SELECT @iMonthNo = Placeholder FROM @tmpFormatSplit where Seq = 3

	SELECT @dtFindStartDate = convert(datetime, convert(varchar,@iMonthNo) + '/01/' + convert(varchar,@iYear))

	SELECT @dtDSTDate =
 		   CASE WHEN datepart(dw, FromMonthDayYear) = @iDayNo THEN FromMonthDayYear
				WHEN datepart(dw, dateadd(day, 1, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 1, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 1, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, 2, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 2, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 2, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, 3, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 3, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 3, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, 4, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 4, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 4, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, 5, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 5, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 5, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, 6, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, 6, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, 6, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -1, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -1, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -1, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -2, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -2, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -2, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -3, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -3, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -3, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -4, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -4, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -4, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -5, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -5, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -5, FromMonthDayYear)
				WHEN datepart(dw, dateadd(day, -6, FromMonthDayYear)) = @iDayNo and datepart(month, dateadd(day, -6, FromMonthDayYear)) = @iMonthNo THEN  dateadd(day, -6, FromMonthDayYear)
				END
	FROM @tmpWeeksofMonth  
	WHERE WeekNo = @iWeekNo
	AND FromMonthDayYear >= @dtFindStartDate
	AND ToMonthDayYear <= dateadd(day, -1, dateadd(month, 1, @dtFindStartDate))


	RETURN @dtDSTDate 
END