IF	OBJECT_ID(N'dbo.up_FN_InitCap') IS NULL 
	EXEC ('CREATE FUNCTION dbo.up_FN_InitCap() RETURNS int AS BEGIN RETURN 0 END')
GO

ALTER FUNCTION dbo.up_FN_InitCap ( @InputString nvarchar(MAX) ) 
RETURNS NVARCHAR(MAX)
AS
BEGIN
-- This function will capitalize the first leter of the word within the @inputString argument
-- i.e. 'THIS IS STRING' will output to 'This Is String'
DECLARE @Index          INT
DECLARE @Char           NCHAR(1)
DECLARE @PrevChar       NCHAR(1)
DECLARE @OutputString   NVARCHAR(MAX)

SET @OutputString = LOWER(@InputString)
SET @Index = 1

WHILE @Index <= LEN(@InputString)
BEGIN
    SET @Char     = SUBSTRING(@InputString, @Index, 1)
    SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                         ELSE SUBSTRING(@InputString, @Index - 1, 1)
                    END

    IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
    BEGIN
        IF @PrevChar != '''' OR UPPER(@Char) != 'S'
            SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char))
    END

    SET @Index = @Index + 1
END

RETURN @OutputString

END