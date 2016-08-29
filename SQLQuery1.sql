
Create table QuesDifficult
(
	ques_no INT NOT NULL,
	difficulty_level INT
)
select * from QuesDifficult

INSERT INTO QuesDifficult  ( [ques_no],[difficulty_level] ) VALUES (1,1);

CREATE TABLE UserAttempts
(
	UserID INT  NOT NULL,
	attemptCount INT
)
select * from UserAttempts

CREATE TABLE UserMarks
(
UserID INT  NOT NULL,
marks INT,
attempt INT,
letterID INT NOT NULL,
letterResult SMALLINT NOT NULL,
attempt_date datetime NOT NULL DEFAULT GETDATE()
PRIMARY KEY (UserID,attempt,letterID,attempt_date)
);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,3,1,1,1),(1,3,1,2,0),(1,3,1,3,1),(1,3,1,4,0),(1,3,1,5,1);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,4,2,4,1),(1,4,2,2,1),(1,4,2,3,1),(1,3,2,5,0),(1,3,2,10,1);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,5,3,5,1),(1,5,3,1,1),(1,5,3,4,1),(1,5,3,5,1),(1,5,3,9,1);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,0,4,6,0),(1,0,4,7,0),(1,0,4,8,0),(1,0,4,2,0),(1,0,4,1,0);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,3,5,6,1),(1,3,5,7,0),(1,3,5,8,1),(1,3,5,2,1),(1,3,5,1,0);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (1,4,6,7,1),(1,4,6,1,1),(1,4,6,3,1),(1,4,6,5,1),(1,4,6,4,0);

insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (2,2,1,2,0),(2,2,1,1,1),(2,2,1,5,0),(2,2,1,7,1),(2,2,1,4,0);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (2,4,2,5,1),(2,4,2,4,1),(2,4,2,2,0),(2,4,2,3,1),(2,4,2,6,0);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (2,3,3,2,1),(2,3,3,6,1),(2,3,3,8,0),(2,3,3,10,0),(2,3,3,7,1);

insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (3,4,1,2,1),(3,4,1,4,0),(3,4,1,1,1),(3,4,1,8,1),(3,4,1,6,1);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (3,3,2,4,0),(3,3,2,10,1),(3,3,2,3,0),(3,3,2,4,1),(3,3,2,2,1);
insert into UserMarks (UserID,marks,attempt,letterID,letterResult) values (3,3,3,4,1),(3,3,3,3,1),(3,3,3,4,0),(3,3,3,1,0),(3,3,3,7,1);




select * from UserMarks

--------------------------------------------------sp------------------------------------------------------------

USE [CheckMateDB]
GO
/****** Object:  StoredProcedure [dbo].[usp_getNextPaper]    Script Date: 8/29/2016 4:19:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-----------------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[usp_getNextPaper] @UserID INT
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY

		CREATE TABLE #userMarksWithRecentAttempt(
			attempt INT,
			letterID INT NOT NULL,
			letterResult SMALLINT NOT NULL
		) 

		--INSERT INTO #userMarksWithRecentAttempt
		--SELECT um.attempt, um.letterID, um.letterResult
		--FROM [dbo].[UserMarks] um		 
		--INNER JOIN
		--	(SELECT letterID, MAX(attempt) AS MaxAttempt
		--	FROM [dbo].[UserMarks]
		--	GROUP BY letterID) groupedum 
		--ON um.letterID = groupedum.letterID 
		--AND um.attempt = groupedum.MaxAttempt
		--where um.UserID = @UserID

		INSERT INTO #userMarksWithRecentAttempt
		SELECT 
			um.attempt,
			um.letterID, 
			letterResult = CASE WHEN um.letterResult = 1 THEN -10
				ELSE 10
				END
		FROM [dbo].[UserMarks] um		 
		where um.UserID = @UserID

		DECLARE @userMarksWithDefficultyLevel TABLE (
			letterID INT,
			attempt INT,
			letterResult SMALLINT,
			difficultyLevel INT,
			attemptScore INT
		)

		INSERT INTO @userMarksWithDefficultyLevel
		SELECT 
			qd.ID,
			umra.attempt,
			umra.letterResult,
			qd.difficult_level,
			attemptScore = CASE WHEN umra.attempt IS NULL AND umra.letterResult IS NULL THEN qd.difficult_level*20 
				ELSE qd.difficult_level*umra.attempt*umra.letterResult
				END
		FROM #userMarksWithRecentAttempt umra  
		FULL OUTER JOIN [dbo].[QuesDifficult] qd 
		ON umra.letterID = qd.ID
		 
		SELECT TOP 5 letterID FROM @userMarksWithDefficultyLevel GROUP BY letterID ORDER BY SUM(attemptScore) DESC

	END TRY
	
	BEGIN CATCH
		-- Raise an error with the details of the exception
	    DECLARE @ErrMsg       VARCHAR(4000)
	           ,@ErrSeverity  INT
	    
	    SELECT @ErrMsg = ERROR_MESSAGE(),
	    	   @ErrSeverity = ERROR_SEVERITY()	    
	    RAISERROR(@ErrMsg, @ErrSeverity, 1);
	END CATCH
END
---------------------------------------Execute stored procedure-------------------------------------------------------------------------

USE [CheckMateDB]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[usp_getNextPaper]
		@UserID = 1

SELECT	'Return Value' = @return_value

GO
[dbo].[usp_getNextPaper]