IF	OBJECT_ID('dbo.FN_TransformUserNameToRegex') IS NULL
	EXEC ('CREATE FUNCTION dbo.FN_TransformUserNameToRegex() RETURNS int AS BEGIN RETURN 0 END')
GO

GRANT EXECUTE ON dbo.FN_TransformUserNameToRegex  TO R_InsightUser
GO

ALTER FUNCTION	dbo.FN_TransformUserNameToRegex
(
	@nvcInputUserName		NVARCHAR(2000)
) 
RETURNS	NVARCHAR(2000)
AS
-- This function takes in an User Name, and returns a regex that can be used to match against email header
BEGIN
	DECLARE 	@iIndex 					INT,
				@nvcChar 					NVARCHAR(200),
				@binChar 					VARBINARY(200),
				@nvcLhs 					NVARCHAR(2000),
				@nvcRhs 					NVARCHAR(2000),
				@bHasComma					BIT,
				@nvcToken0					NVARCHAR(2000),
				@nvcToken1					NVARCHAR(2000),
				@nvcToken2					NVARCHAR(2000),
				@iNumberTokens				INT,
				@nvcCanonicalizedInput		NVARCHAR(2000),
				@nvcToken0Initial 			NVARCHAR(200),
				@nvcToken1Initial			NVARCHAR(200),
				@nvcToken2Initial			NVARCHAR(200),
				@nvcToken0Remainder			NVARCHAR(2000),
				@nvcToken1Remainder			NVARCHAR(2000),
				@nvcToken2Remainder			NVARCHAR(2000),
				@nvcRegex					NVARCHAR(2000),
				@iToken0InitialLen			INT,
				@iToken1InitialLen			INT,
				@iToken2InitialLen			INT
	
	-- Interpret punctuation and canonicalize the string
	SET	@nvcInputUserName	= LOWER(@nvcInputUserName)
	SET @iIndex 			= 0
	SET @nvcChar 			= ''
	SET @nvcLhs 			= ''
	SET @nvcRhs 			= ''
	SET @bHasComma 			= 0
	
	WHILE @iIndex < LEN(@nvcInputUserName)
	BEGIN
		SET @iIndex 	= @iIndex + 1
		SET @nvcChar 	= SUBSTRING(@nvcInputUserName, @iIndex, 1)
		SET @binChar 	= CAST(@nvcChar AS VARBINARY(200))

		IF @nvcChar	 = '.'
		BEGIN
			SET @nvcChar	= ' '
		END

		IF @nvcChar	= ','
			SET @bHasComma	= 1
		ELSE
		BEGIN
			IF @nvcChar <> '[' AND @nvcChar <> ']'
			BEGIN
				IF @nvcChar = '-' 				SET @nvcChar = '\-?'
				ELSE IF @binChar = 0xFB01 		SET @nvcChar = N'[ǻa]'
				ELSE IF @binChar = 0xFD01 		SET @nvcChar = N'[ǽa]'
				ELSE IF @binChar = 0xE301 		SET @nvcChar = N'[ǣa]'
				ELSE IF @binChar = 0x0D1E 		SET @nvcChar = N'[ḍd]'
				ELSE IF @binChar = 0xBD1E 		SET @nvcChar = N'[ẽe]'
				ELSE IF @binChar = 0xB91E 		SET @nvcChar = N'[ẹe]'
				ELSE IF @binChar = 0x251E 		SET @nvcChar = N'[ḥh]'
				ELSE IF @binChar = 0xCB1E 		SET @nvcChar = N'[ịi]'
				ELSE IF @binChar = 0x4001 		SET @nvcChar = N'[ŀl]'
				ELSE IF @binChar = 0x4901 		SET @nvcChar = N'[ŉn]'
				ELSE IF @binChar = 0x6E000803 		SET @nvcChar = N'[n̈n]'
				ELSE IF @binChar = 0xCD1E 		SET @nvcChar = N'[ọo]'
				ELSE IF @binChar = 0xFF01 		SET @nvcChar = N'[ǿo]'
				ELSE IF @binChar = 0x1902 		SET @nvcChar = N'[șs]'
				ELSE IF @binChar = 0x631E 		SET @nvcChar = N'[ṣs]'
				ELSE IF @binChar = 0x1B02 		SET @nvcChar = N'[țt]'
				ELSE IF @binChar = 0x6D1E 		SET @nvcChar = N'[ṭt]'
				ELSE IF @binChar = 0xE51E 		SET @nvcChar = N'[ụu]'
				ELSE IF @binChar = 0x831E 		SET @nvcChar = N'[ẃw]'
				ELSE IF @binChar = 0x811E 		SET @nvcChar = N'[ẁw]'
				ELSE IF @binChar = 0x851E 		SET @nvcChar = N'[ẅw]'
				ELSE IF @binChar = 0xF31E 		SET @nvcChar = N'[ỳy]'
				ELSE IF @binChar = 0x3302 		SET @nvcChar = N'[ȳy]'
				ELSE IF @binChar = 0xF91E 		SET @nvcChar = N'[ỹy]'
				ELSE IF @binChar = 0x931E 		SET @nvcChar = N'[ẓz]'
				ELSE IF @binChar = 0xEF01 		SET @nvcChar = N'[ǯz]'
				ELSE
				IF @nvcChar <> CAST(@nvcChar AS VARCHAR(32)) COLLATE SQL_Latin1_General_Cp1251_CS_AS
				BEGIN
					SET @nvcChar = '[' + @nvcChar + CAST(@nvcChar AS VARCHAR(32)) COLLATE SQL_Latin1_General_Cp1251_CS_AS + ']'
				END

				IF @bHasComma = 0
					SET @nvcLhs = @nvcLhs + @nvcChar
				ELSE
					SET @nvcRhs = @nvcRhs + @nvcChar 
			END
		END
	END
	SET @nvcCanonicalizedInput = ''
	IF @bHasComma = 1
		BEGIN
		SET @nvcCanonicalizedInput	= @nvcRhs + ' ' + @nvcLhs
		SET @nvcCanonicalizedInput 	= REPLACE(@nvcCanonicalizedInput, '  ', ' ')
		END
	ELSE
		SET @nvcCanonicalizedInput 	= @nvcLhs + @nvcRhs

	-- Eliminate duplicate spaces up to a point. More canonicalization.
	SET @nvcCanonicalizedInput 	= REPLACE(@nvcCanonicalizedInput, '  ', ' ')
	SET @nvcCanonicalizedInput 	= RTRIM(LTRIM(@nvcCanonicalizedInput))

	-- Tokenize up to three name tokens
	SET @nvcToken0		= ''
	SET @nvcToken1 		= ''
	SET @nvcToken2 		= ''
	SET @iNumberTokens 	= 0
	SET @iIndex 		= 0

	WHILE @iIndex < LEN(@nvcCanonicalizedInput)
	BEGIN
		SET @iIndex 	= @iIndex + 1
		SET @nvcChar 	= SUBSTRING(@nvcCanonicalizedInput, @iIndex, 1)
		SET @binChar 	= CAST(@nvcChar AS VARBINARY(200))

		IF @binChar = 0x20
			BEGIN
				SET @iNumberTokens = @iNumberTokens + 1
				IF @iNumberTokens > 2
				BEGIN
					SET @nvcToken1 = @nvcToken1 + ' '
					SET @nvcToken1 = @nvcToken1 + @nvcToken2
					SET @nvcToken2 = ''
				END
			END
		ELSE
			BEGIN
				IF @iNumberTokens = 0 
				SET @nvcToken0 = @nvcToken0 + @nvcChar
				ELSE
				BEGIN
					IF @iNumberTokens = 1 
						SET @nvcToken1 = @nvcToken1 + @nvcChar
					ELSE
						SET @nvcToken2 = @nvcToken2 + @nvcChar
				END
			END
	END
	SET @nvcToken0 	= RTRIM(LTRIM(@nvcToken0))
	SET @nvcToken1 	= RTRIM(LTRIM(@nvcToken1))
	SET @nvcToken2 	= RTRIM(LTRIM(@nvcToken2))
	
	IF @nvcToken0 <> '' AND @nvcToken1 <> '' AND @nvcToken2 <> '' 
		SET @iNumberTokens = 3
	ELSE
	BEGIN
		IF @nvcToken0 <> '' AND @nvcToken1 <> '' 
			SET @iNumberTokens = 2
		ELSE
			IF @nvcToken0 <> '' 
				SET @iNumberTokens = 1
			ELSE
				SET @iNumberTokens = 0
	END

	-- Create tokens for replacement
	SET @nvcToken0Initial 		= ''
	SET @nvcToken1Initial 		= ''
	SET @nvcToken2Initial 		= ''
	SET @nvcToken0Remainder 	= ''
	SET @nvcToken1Remainder 	= ''
	SET @nvcToken2Remainder 	= ''
	SET @iToken0InitialLen 		= 1
	SET @iToken1InitialLen 		= 1
	SET @iToken2InitialLen 		= 1
	
	IF SUBSTRING(@nvcToken0, 1, 1) = '[' SET @iToken0InitialLen = 4
	IF SUBSTRING(@nvcToken1, 1, 1) = '[' SET @iToken1InitialLen = 4
	IF SUBSTRING(@nvcToken2, 1, 1) = '[' SET @iToken2InitialLen = 4
	
	IF @iNumberTokens 	> 0 SET @nvcToken0Initial 		= SUBSTRING(@nvcToken0, 1, @iToken0InitialLen)
	IF @iNumberTokens 	> 1 SET @nvcToken1Initial 		= SUBSTRING(@nvcToken1, 1, @iToken1InitialLen)
	IF @iNumberTokens 	> 2 SET @nvcToken2Initial 		= SUBSTRING(@nvcToken2, 1, @iToken2InitialLen)
	IF LEN(@nvcToken0) 	> 1 SET @nvcToken0Remainder 	= RIGHT(@nvcToken0, LEN(@nvcToken0) - @iToken0InitialLen)
	IF LEN(@nvcToken1) 	> 1 SET @nvcToken1Remainder 	= RIGHT(@nvcToken1, LEN(@nvcToken1) - @iToken1InitialLen)
	IF LEN(@nvcToken2) 	> 1 SET @nvcToken2Remainder 	= RIGHT(@nvcToken2, LEN(@nvcToken2) - @iToken2InitialLen)

	-- Create regex
	SET @nvcRegex = ''
	IF @iNumberTokens = 1
		SET @nvcRegex = '^(from:.*?(?:[''?“"” ,.-](\b[first]\b(?:(?:\p{Punct}?[ ]|\p{Punct}(?<!\/|\\)\p{L}{1,}?\p{Punct}?[ ])|[''“"”]?<[^\s]+?@[\w.-]+?>$)|(?<=[''“"”<\( :])[first][0-9]{0,1}@).*))'
	ELSE
	BEGIN
		IF @iNumberTokens = 2
		BEGIN
			SET @nvcRegex 	= @nvcRegex + '^(from:.*?(?:[''?“"” ,.-]('
			SET @nvcRegex 	= @nvcRegex + '\b[first](?:\b.*?\b|\p{Punct})?[second]\b|\b[second](?:\b.*?\b|\p{Punct})?[first]\b|\b[firstinit](?:\b.*?\b|\p{Punct})?[second]\b|\b[secondinit](?:\b.*?\b|\p{Punct})?[first]\b'
			SET @nvcRegex 	= @nvcRegex + '|\b[first](?:\b.*?\b|\p{Punct})?[secondinit]\b|\b[second](?:\b.*?\b|\p{Punct})?[firstinit]\b)(?:(?:\p{Punct}?[ ]|\p{Punct}(?<!\/|\\)\p{L}{1,}?\p{Punct}?[ ])|[''“"”]?<[^\s]+?@[\w.-]+?>$)|(?<=[''“"”<\( :])(?:'
			SET @nvcRegex 	= @nvcRegex + '[first]\p{Punct}{0,3}[second]|[second]\p{Punct}{0,3}[first]|[firstinit]\p{Punct}{0,3}[second]|[secondinit]\p{Punct}{0,3}[first]|[first]\p{Punct}{0,3}[secondinit]|[second]\p{Punct}{0,3}[firstinit]'
			SET @nvcRegex 	= @nvcRegex + ')[0-9]{0,1}@).*)'
		END
		ELSE
		IF @iNumberTokens = 3
		BEGIN
			SET @nvcRegex = @nvcRegex + '^(from:.*?(?:[''?“"” ,.-]('
			SET @nvcRegex = @nvcRegex + '\b[first](?:\b.*?\b|\p{Punct})?[third]\b|\b[third](?:\b.*?\b|\p{Punct})?[first]\b|\b[firstinit](?:\b.*?\b|\p{Punct})?[third]\b|\b[thirdinit](?:\b.*?\b|\p{Punct})?[first]\b|\b[first](?:\b.*?\b|\p{Punct})?[thirdinit]\b|\b[third](?:\b.*?\b|\p{Punct})?[firstinit]\b'
			SET @nvcRegex = @nvcRegex + ')(?:(?:\p{Punct}?[ ]|\p{Punct}(?<!\/|\\)\p{L}{1,}?\p{Punct}?[ ])|[''“"”]?<[^\s]+?@[\w.-]+?>$)|(?<=[''“"”<\( :])(?:'
			SET @nvcRegex = @nvcRegex + '[firstinit](?:[firstremainder])?\p{Punct}{0,3}[secondinit](?:[secondremainder])?\p{Punct}{0,3}[third]|[thirdinit](?:[thirdremainder])?\p{Punct}{0,3}[secondinit](?:[secondremainder])?\p{Punct}{0,3}[first]|[thirdinit](?:[thirdremainder])?\p{Punct}{0,3}[firstinit](?:[firstremainder])?\p{Punct}{0,3}[second]|[firstinit](?:[firstremainder])?\p{Punct}{0,3}[third]|[firstinit](?:[firstremainder])?\p{Punct}{0,3}[second]|[thirdinit](?:[thirdremainder])?\p{Punct}{0,3}[first]|[first]\p{Punct}{0,3}[thirdinit]|[first]\p{Punct}{0,3}[secondinit]|[third]\p{Punct}{0,3}[firstinit]'
			SET @nvcRegex = @nvcRegex + ')[0-9]{0,1}@).*)'
		END
	END

    -- Replacements
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[first]', @nvcToken0)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[firstinit]', @nvcToken0Initial)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[firstremainder]', @nvcToken0Remainder)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[second]', @nvcToken1)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[secondinit]', @nvcToken1Initial)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[secondremainder]', @nvcToken1Remainder)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[third]', @nvcToken2)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[thirdinit]', @nvcToken2Initial)
	SET @nvcRegex 	= REPLACE(@nvcRegex, '[thirdremainder]', @nvcToken2Remainder)	
	RETURN @nvcRegex

END
GO