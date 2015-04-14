USE [test1]
GO

/****** Object:  Table [Data].[Numbers]    Script Date: 4/14/2015 11:04:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Data].[Numbers](
	[Number] [int] NULL
) ON [PRIMARY]

GO

USE [test1]
GO

/****** Object:  Table [Data].[Numbers]    Script Date: 4/14/2015 11:03:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Data].[Numbers](
	[Number] [int] NULL
) ON [PRIMARY]

GO

USE [test1]
GO

/****** Object:  StoredProcedure [dbo].[UpdateTest1]    Script Date: 4/14/2015 11:05:47 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateTest1]
  @i1 INT,
  @addToI2 INT,
  @addToToggle1 INT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  UPDATE Data.Test
      SET toggle1 = toggle1 + @addToToggle1,
-- modifies i2 so that the other non clustered index is also modified
            i2 = i2 + @addToI2
      WHERE i1 = @i1;
END;

GO


USE [test1]
GO


/****** Object:  StoredProcedure [dbo].[UpdateTest2]    Script Date: 4/14/2015 11:08:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateTest2]
  @i2 INT,
  @addToI1 INT,
  @addToToggle2 INT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  UPDATE Data.Test
      SET toggle2 = toggle2 + @addToToggle2,
-- modifies i1 so that the other non clustered index is also modified
            i1 = i1 + @addToI1
      WHERE i2 = @i2;
END;

GO

USE [test1]
GO

/****** Object:  StoredProcedure [dbo].[SelectTest2]    Script Date: 4/14/2015 11:09:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SelectTest2]
  @i2 INT,
  @toggle2 INT OUT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
  SELECT @toggle2=toggle2 FROM Data.Test
      WHERE i2 = @i2;
END;

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SelectTestHandled

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
			DECLARE @RetryCounter INT
		SET @RetryCounter = 1
		RETRY: -- Label RETRY
		BEGIN TRY

DECLARE @i INT, @j INT, @toggle2 INT;
SET NOCOUNT ON;
SELECT @i=0, @j = 0, @toggle2 = 0;
WHILE (@i<100000) BEGIN
    EXEC dbo.SelectTest2 @i2 = 999000, @toggle2 = 0
  SET @i = @i + 1;
END;
END TRY
		BEGIN CATCH
			DECLARE @DoRetry bit;
			DECLARE @ErrorMessage varchar(500)
			SET @doRetry = 0;
			SET @ErrorMessage = ERROR_MESSAGE()
			IF ERROR_NUMBER() = 1205 -- Deadlock Error Number
			BEGIN
				SET @doRetry = 1; -- Set @doRetry to 1 only for Deadlock
			END
			IF @DoRetry = 1
			BEGIN
				SET @RetryCounter = @RetryCounter + 1 -- Increment Retry Counter By one
				IF (@RetryCounter > 3) -- Check whether Retry Counter reached to 3
				BEGIN
					RAISERROR(@ErrorMessage, 18, 1) -- Raise Error Message if 
						-- still deadlock occurred after three retries
				END
				ELSE
				BEGIN
					WAITFOR DELAY '00:00:10' -- Wait for 10s
					GOTO RETRY	-- Go to Label RETRY
				END
			END
			ELSE
			BEGIN
				RAISERROR(@ErrorMessage, 18, 1)
			END
		END CATCH
END
GO
