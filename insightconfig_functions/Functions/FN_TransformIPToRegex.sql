IF	OBJECT_ID('dbo.FN_TransformIPToRegex') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_TransformIPToRegex() RETURNS int AS BEGIN RETURN 0 END')
GO

GRANT EXECUTE ON dbo.FN_TransformIPToRegex  TO R_InsightUser
GO

ALTER FUNCTION	dbo.FN_TransformIPToRegex
(
	@vcInputIp		VARCHAR(20)
) 
RETURNS	VARCHAR(255)
AS
-- This function takes in an IP Address (regular and CIDR format) and converts into Regex taht can be processed by DLP Engine
BEGIN
	-- TODO Add data validation
	DECLARE		@vcStartingIP					VARCHAR(15),
				@vcEndingIP						VARCHAR(15),
				@vcRegex						VARCHAR(6000)	= '',
				@vcOctetRegex					VARCHAR(6000),
				@lBase      					BIGINT,
				@vcIpAddress 					VARCHAR(39),
				@iMask     						INT,
				@lPower      					BIGINT,
				@lLowRange   					BIGINT,
				@lHighRange 					BIGINT,
				@iStartingIPOctet				INT,
				@iEndingIPOctet					INT,
				@iCounter						INT				= 0,
				@bCallBackFlag					BIT				= 0,
				@iStartingIPOctet2				INT,
				@iEndingIPOctet2				INT
	
	IF 	CHARINDEX('/', @vcInputIp) > 0
	BEGIN
		--	The following section retrieves the starting and ending IP address from CIDR IP address
		SELECT		@lBase      		= 	CAST(4294967295 AS BIGINT),
					@vcIpAddress 		= 	LEFT(@vcInputIp, patindex('%/%' , @vcInputIp) - 1),
					@iMask     			= 	CAST(SUBSTRING(@vcInputIp, patindex('%/%' , @vcInputIp) + 1, 2) AS INT),
					@lPower      		= 	POWER(2.0, 32.0 - @iMask) - 1,
					@lLowRange   		= 	[dbo].[fn_web_ConvertIPToNumeric](@vcIpAddress) & (@lBase ^ @lPower),
					@lHighRange 		= 	@lLowRange + @lPower,
					@vcStartingIP		=	[dbo].[fn_web_ConvertNumericToIP](@lLowRange),
					@vcEndingIP			=	[dbo].[fn_web_ConvertNumericToIP](@lHighRange)
		
		SELECT 	@vcOctetRegex = ''
		
		IF 	@vcStartingIP = @vcEndingIP
		BEGIN
			SELECT	@vcRegex	= REPLACE(@vcStartingIP, '.', '\.')
		END
		ELSE
		BEGIN
			-- we will loop through the four octets of the starting IP  address and ending IP address to form a single regex
			WHILE @iCounter < 4
			BEGIN
				SELECT 	@vcOctetRegex = ''
				-- read the current octet
				SELECT		@iStartingIPOctet	=	CASE CHARINDEX('.', @vcStartingIP) WHEN 0 THEN CAST(@vcStartingIP AS INT) ELSE CAST(SUBSTRING(@vcStartingIP, 0, CHARINDEX('.', @vcStartingIP)) AS INT)END,
							@iEndingIPOctet		=	CASE CHARINDEX('.', @vcEndingIP) WHEN 0 THEN CAST(@vcEndingIP AS INT) ELSE CAST(SUBSTRING(@vcEndingIP, 0, CHARINDEX('.', @vcEndingIP)) AS INT) END
				-- remove the current octet from the current IP address
				SELECT		@vcStartingIP		=	SUBSTRING(@vcStartingIP, CHARINDEX('.', @vcStartingIP) + 1, LEN(@vcStartingIP) - CHARINDEX('.', @vcStartingIP)),
							@vcEndingIP			=	SUBSTRING(@vcEndingIP, CHARINDEX('.', @vcEndingIP) + 1, LEN(@vcEndingIP) - CHARINDEX('.', @vcEndingIP))
				
				
				IF	@iStartingIPOctet = @iEndingIPOctet
				BEGIN
					-- use case, if the two octets are the same, then add teh octet as a whole, no special regex needed
					SELECT	@vcOctetRegex = @vcOctetRegex + CAST(@iStartingIPOctet AS VARCHAR(3))
				END
				ELSE IF	LEN(@iStartingIPOctet) = LEN(@iEndingIPOctet) 		
				BEGIN
					-- use case, if the length of the two octects are the same
					IF	LEN(@iStartingIPOctet) = 1	
					BEGIN
						-- single digit number
						SELECT	@vcOctetRegex 	= @vcOctetRegex + '[' + CAST(@iStartingIPOctet AS VARCHAR(3)) + '-' + CAST(@iEndingIPOctet AS VARCHAR(3)) + ']'
					END
					ELSE IF	LEN(@iStartingIPOctet)	= 2 					
					BEGIN
						-- use case if both the octet is double digit number						
						GOTO 	EQUAL_LENGTH_DOUBLE_DIGIT_OCTETS
					END
					ELSE
					BEGIN
						-- use case if both the octet is triple digit number
						GOTO 	EQUAL_LENGTH_TRIPLE_DIGIT_OCTETS						
					END				
				END
				ELSE
				BEGIN
					-- the two octets are of different length
					IF	LEN(@iStartingIPOctet) = 1
					BEGIN
						-- if the starting octest single digit number
						SELECT	@vcOctetRegex	= @vcOctetRegex + CASE @iStartingIPOctet 
																	WHEN 9 THEN '9' 
																	ELSE '[' + CAST(@iStartingIPOctet AS VARCHAR(3)) + '-9]|' END
						
						IF	LEN(@iEndingIPOctet) = 2
						BEGIN
							-- after the single digit regex is formed, create regex for double digits
							SELECT	@iStartingIPOctet 	= 10						
							GOTO EQUAL_LENGTH_DOUBLE_DIGIT_OCTETS
						END
						ELSE
						BEGIN
							-- create regex for double digit
							SELECT	@vcOctetRegex	= @vcOctetRegex + '[1-9][0-9]|'
							
							-- after the single digit  & single digit regex is formed, create regex for double digits
							SELECT	@iStartingIPOctet 	= 100						
							GOTO 	EQUAL_LENGTH_TRIPLE_DIGIT_OCTETS
						END
					END
					ELSE
					BEGIN 
						-- by defualt the starting octet is double digit number here and ending octet is truple digit
						-- first form the regex for teh double digit cases
						IF	@iStartingIPOctet = 99
						BEGIN
							SELECT	@vcOctetRegex	= @vcOctetRegex + '99|'
						END
						ELSE IF	@iStartingIPOctet % 10 = 9
						BEGIN
							SELECT	@vcOctetRegex	= @vcOctetRegex + CAST(@iStartingIPOctet AS VARCHAR(3)) + '|' + CAST(@iStartingIPOctet / 10 +1 AS VARCHAR(3)) + '[0-9]|'
						END
						ELSE
						BEGIN
							SELECT	@vcOctetRegex	= @vcOctetRegex + CAST(@iStartingIPOctet / 10 AS VARCHAR(3)) + '[' + CAST(@iStartingIPOctet % 10 AS VARCHAR(3)) + '-9]|' + CASE @iStartingIPOctet / 10 WHEN 9 THEN '' ELSE CASE CAST(@iStartingIPOctet / 10 +1 AS VARCHAR(3)) WHEN 9 THEN '9' ELSE '[' + CAST(@iStartingIPOctet / 10 +1 AS VARCHAR(3)) + '-9]' END + '[0-9]|' END
						END
											
						SELECT	@iStartingIPOctet 	= 100
						
						-- after teh double digit regex is foned, create regex for triple digits
						GOTO 	EQUAL_LENGTH_TRIPLE_DIGIT_OCTETS
					END
				END
				
				GOTO 	END_LOOP
				
				EQUAL_LENGTH_TRIPLE_DIGIT_OCTETS:
					IF	(@iStartingIPOctet / 100) = (@iEndingIPOctet / 100)
					BEGIN
						SELECT	@vcOctetRegex		= @vcOctetRegex + CAST(@iStartingIPOctet / 100 AS VARCHAR(3)),
								@iStartingIPOctet 	= @iStartingIPOctet % 100,
								@iEndingIPOctet		= @iEndingIPOctet % 100
					END
					ELSE IF	@iStartingIPOctet	=	100
					BEGIN
						SELECT	@vcOctetRegex		= @vcOctetRegex + '1([0-9][0-9])|2',
								@iStartingIPOctet 	= 0,
								@iEndingIPOctet		= @iEndingIPOctet % 100
					END
					ELSE
					BEGIN
						SELECT	@iStartingIPOctet2	= @iStartingIPOctet % 100,
								@iEndingIPOctet2	= 99,
								@vcOctetRegex	= @vcOctetRegex + '1(',
								@iStartingIPOctet 	= 0,
								@iEndingIPOctet		= @iEndingIPOctet % 100
								
						IF	(@iStartingIPOctet2 / 10) = (@iEndingIPOctet2 / 10)
						BEGIN
							-- use case, the if the two octet are in the same range, for eg, both are in tens or twenties or thiries, etc
							SELECT	@vcOctetRegex	= @vcOctetRegex + CAST(@iStartingIPOctet2/10 AS VARCHAR(3)) + '[' + CAST(@iStartingIPOctet2 % 10 AS VARCHAR(3)) + '-' + CAST(@iEndingIPOctet2 % 10 AS VARCHAR(3)) + ']'
						END
						ELSE IF	(@iEndingIPOctet2 / 10) - (@iStartingIPOctet2 / 10) = 1
						BEGIN
							-- use case, the if the two octet are consecutive double digits, for eg,startin  octet is in 10s whereas ending octet is in 20s
							
							-- if the starting octet ends with 9 like 19 or 29, then teh we will hardcoded the number like 19 or 29
							-- if the starting octet ends with a number 0-8 then we need to form the regex. 15 will be 1[5-9]
							-- if the ending octet ends with 0 like 10 or 20, then teh we will hardcoded the number like 10 or 20
							-- if the ending octet ends with a number 1-9 then we need to form the regex. 15 will be 1[0-5]					
							SELECT	@vcOctetRegex	= @vcOctetRegex +
													  CAST(@iStartingIPOctet2/10 AS VARCHAR(3)) + CASE (@iStartingIPOctet2 % 10) 
																									WHEN 9 THEN '9' 
																									ELSE '[' + CAST(@iStartingIPOctet2 % 10 AS VARCHAR(3)) + '-9]' END +
													  '|' +
													  CAST(@iEndingIPOctet2/10 AS VARCHAR(3)) + CASE (@iEndingIPOctet2 % 10) 
																								WHEN 0 THEN '0' 
																								ELSE '[0-' + CAST(@iEndingIPOctet2 % 10 AS VARCHAR(3)) + ']' END
						END
						ELSE
						BEGIN
							-- use case, for any other double digit numbers	
							
							-- if the starting octet ends with 9 like 19 or 29, then teh we will hardcoded the number like 19 or 29
							-- if the starting octet ends with a number 1-8 then we need to form the regex. 15 will be 1[5-9]
							-- if the starting octet ends with 0 like 10 or 20, then no need to add any thing, the following section will take care of that
							SELECT	@vcOctetRegex	= @vcOctetRegex + 
														CASE 
															WHEN (@iStartingIPOctet2 % 10) = 9 THEN CAST(@iStartingIPOctet2 AS VARCHAR(3)) + '|' 
															WHEN (@iStartingIPOctet2 % 10) > 0 THEN CAST(@iStartingIPOctet2 / 10 AS VARCHAR(3)) + '[' + CAST(@iStartingIPOctet2 % 10 AS VARCHAR(3)) + '-9]|' 
															ELSE '' 
														END 
							
							-- if the starting octet ends with 0 like 10 and endOctet like 89, then the regex will be like [1-8][0-9]
							-- if the starting octet ends with 0 like 10 and endOctet like 86, then the regex will be like [1-7][0-9]
							-- if the starting octet ends with non zero like 12 and endOctet ike 89, then the regex will be like 1[2-9]|[2-8][0-9]
							-- if the starting octet ends with non zero like 12 and endOctet like 86, then the regex will be like 1[2-9]|[2-7][0-9]
							SELECT	@vcOctetRegex	= @vcOctetRegex + CASE @iStartingIPOctet2 % 10
																			WHEN 0 THEN '[' + CAST(@iStartingIPOctet2/10 AS VARCHAR(3)) + '-' + CAST(@iEndingIPOctet2/10 - 1 AS VARCHAR(3)) + ']'
																			ELSE
																			CASE 
																				WHEN (@iStartingIPOctet2/10 + 1) = (@iEndingIPOctet2/10 - 1) THEN CAST(@iStartingIPOctet2/10 + 1 AS VARCHAR(3)) 
																				ELSE '[' + CAST(@iStartingIPOctet2/10 + 1 AS VARCHAR(3)) + '-' +  CASE (@iEndingIPOctet2 % 10)
																																						WHEN 9	THEN CAST(@iEndingIPOctet2 / 10 AS VARCHAR(3))
																																						ELSE 	CAST(@iEndingIPOctet2 / 10 - 1 AS VARCHAR(3)) 
																																					END + ']' 
																			END	
																		END + '[0-9]'
																		
							-- if the endOctet ends with 9 then no need to add anything, the previos statemtn already accounted for that
							-- if the endOctet ends with 0, for eg., 80, then add |80
							-- if the endOctet ends with any number other than 9 or 0, for eg for 86, add |8[0-6]
							SELECT	@vcOctetRegex	= @vcOctetRegex + CASE (@iEndingIPOctet2 % 10)
																			WHEN 0 	THEN '|' + CAST(@iEndingIPOctet2 AS VARCHAR(3))
																			WHEN 9	THEN ''
																			ELSE 	'|'+ CAST(@iEndingIPOctet2 / 10 AS VARCHAR(3)) + '[0-' + CAST(@iEndingIPOctet2 % 10 AS VARCHAR(3)) + ']'
																		END
						END
						
						-- adding '2' at end to account for numbers in two-hundreds
						SELECT	@vcOctetRegex	= @vcOctetRegex + ')|2'
					END
					
					
					-- once the triple digile IP regex are formed, then form the double digit
					SELECT	@bCallBackFlag	= 1
					GOTO 	EQUAL_LENGTH_DOUBLE_DIGIT_OCTETS
				GOTO 	END_LOOP
				
				EQUAL_LENGTH_DOUBLE_DIGIT_OCTETS:
					IF 	@bCallBackFlag = 1
					BEGIN
						SELECT	@vcOctetRegex	= @vcOctetRegex + '('
					END
					
					IF	(@iStartingIPOctet / 10) = (@iEndingIPOctet / 10)
					BEGIN
						-- use case, the if the two octet are in the same range, for eg, both are in tens or twenties or thiries, etc
						SELECT	@vcOctetRegex	= @vcOctetRegex + CAST(@iStartingIPOctet/10 AS VARCHAR(3)) + '[' + CAST(@iStartingIPOctet % 10 AS VARCHAR(3)) + '-' + CAST(@iEndingIPOctet % 10 AS VARCHAR(3)) + ']'
					END
					ELSE IF	(@iEndingIPOctet / 10) - (@iStartingIPOctet / 10) = 1
					BEGIN
						-- use case, the if the two octet are consecutive double digits, for eg,startin  octet is in 10s whereas ending octet is in 20s
						
						-- if the starting octet ends with 9 like 19 or 29, then teh we will hardcoded the number like 19 or 29
						-- if the starting octet ends with a number 0-8 then we need to form the regex. 15 will be 1[5-9]
						-- if the ending octet ends with 0 like 10 or 20, then teh we will hardcoded the number like 10 or 20
						-- if the ending octet ends with a number 1-9 then we need to form the regex. 15 will be 1[0-5]
						SELECT	@vcOctetRegex	= @vcOctetRegex +
												  CAST(@iStartingIPOctet/10 AS VARCHAR(3)) + CASE (@iStartingIPOctet % 10) 
																								WHEN 9 THEN '9' 
																								ELSE '[' + CAST(@iStartingIPOctet % 10 AS VARCHAR(3)) + '-9]' END +
												  '|' +
												  CAST(@iEndingIPOctet/10 AS VARCHAR(3)) + CASE (@iEndingIPOctet % 10) 
																							WHEN 0 THEN '0' 
																							ELSE '[0-' + CAST(@iEndingIPOctet % 10 AS VARCHAR(3)) + ']' END
					END
					ELSE
					BEGIN
						-- use case, for any other double digit numbers
						
						-- if the starting octet ends with 9 like 19 or 29, then teh we will hardcoded the number like 19 or 29
						-- if the starting octet ends with a number 1-8 then we need to form the regex. 15 will be 1[5-9]
						-- if the starting octet ends with 0 like 10 or 20, then no need to add any thing, the following section will take care of that
						SELECT	@vcOctetRegex	= @vcOctetRegex + 
												  CASE 
														WHEN (@iStartingIPOctet % 10) = 9 THEN CAST(@iStartingIPOctet AS VARCHAR(3)) + '|' 
														WHEN (@iStartingIPOctet % 10) > 0 THEN CAST(@iStartingIPOctet / 10 AS VARCHAR(3)) + '[' + CAST(@iStartingIPOctet % 10 AS VARCHAR(3)) + '-9]|' 
														ELSE '' 
													END
												
						-- if the starting octet ends with 0 like 10 and endOctet octet like 89, then the regex will be like [1-8][0-9]
						-- if the starting octet ends with 0 like 10 and endOctet octet like 86, then the regex will be like [1-7][0-9]
						-- if the starting octet ends with non zero like 12 and endOctet like 89, then the regex will be like 1[2-9]|[2-8][0-9]
						-- if the starting octet ends with non zero like 12 and endOctet like 86, then the regex will be like 1[2-9]|[2-7][0-9]										
						SELECT	@vcOctetRegex	= @vcOctetRegex + 							
													CASE @iStartingIPOctet % 10
														WHEN 0 THEN '[' + CAST(@iStartingIPOctet/10 AS VARCHAR(3)) + '-' + CAST(@iEndingIPOctet/10 - 1 AS VARCHAR(3)) + ']'
														ELSE
														CASE 
															WHEN (@iStartingIPOctet/10 + 1) = (@iEndingIPOctet/10 - 1) THEN CAST(@iStartingIPOctet/10 + 1 AS VARCHAR(3)) 
															ELSE '[' + CAST(@iStartingIPOctet/10 + 1 AS VARCHAR(3)) + '-' +  CASE (@iEndingIPOctet % 10)
																																	WHEN 9	THEN CAST(@iEndingIPOctet / 10 AS VARCHAR(3))
																																	ELSE 	CAST(@iEndingIPOctet / 10 - 1 AS VARCHAR(3)) 
																																END + ']' 
														END	
													END + '[0-9]'
													
						-- if the endOctet ends with 9 then no need to add anything, the previos statemtn already accounted for that
						-- if the endOctet ends with 0, for eg., 80, then add |80
						-- if the endOctet ends with any number other than 9 or 0, for eg for 86, add |8[0-6]
						SELECT	@vcOctetRegex	= @vcOctetRegex + 
													CASE (@iEndingIPOctet % 10)
														WHEN 0 	THEN '|' + CAST(@iEndingIPOctet AS VARCHAR(3))
														WHEN 9	THEN ''
														ELSE 	'|'+ CAST(@iEndingIPOctet / 10 AS VARCHAR(3)) + '[0-' + CAST(@iEndingIPOctet % 10 AS VARCHAR(3)) + ']'
													END
					END
					IF 	@bCallBackFlag = 1
					BEGIN
						SELECT	@vcOctetRegex	= @vcOctetRegex + ')'
						SELECT	@bCallBackFlag 	= 0
					END
				GOTO 	END_LOOP
							
				
				END_LOOP:
				SELECT	@vcRegex	= @vcRegex + CASE CHARINDEX('[',@vcOctetRegex) WHEN 0 THEN @vcOctetRegex ELSE '(' + @vcOctetRegex + ')' END
				
				IF	@iCounter < 3
				BEGIN
					SELECT	@vcRegex	= @vcRegex + '\.'
				END				
				
				SELECT 	@iCounter	= @iCounter + 1				
			END
		END
	END
	ELSE
	BEGIN
		SELECT	@vcRegex	= REPLACE(@vcInputIp, '.', '\.')
	END
	
	RETURN	'\b' + @vcRegex + '\b'
END
GO
