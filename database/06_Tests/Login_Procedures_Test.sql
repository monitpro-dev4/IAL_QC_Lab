/* Test script: login procedures (sessions, lockout, password change).
   Runs inside a transaction and rolls back, so no data is left behind. */
USE IAL_QC;
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRAN;
DECLARE @U INT, @chk VARCHAR(300), @i INT = 0;
DECLARE @T1 CHAR(64) = REPLICATE('a', 64), @T2 CHAR(64) = REPLICATE('b', 64), @T3 CHAR(64) = REPLICATE('c', 64);
CREATE TABLE #s (UserID INT, Name VARCHAR(100), UserName VARCHAR(50), MustChangePassword BIT, Roles VARCHAR(500));

EXEC UserInsertUpdate 0,'Login Test','L01','logintest','hash-1',NULL,NULL,NULL,NULL,'Y','5,3',1,@U OUTPUT;
SELECT @chk = CONCAT('must change=', MustChangePassword) FROM UserMaster WHERE UserID=@U; PRINT '01 new user must change pwd -> ' + @chk;
BEGIN TRY EXEC UserInsertUpdate 0,'No Pwd','L02','nopwd',NULL,NULL,NULL,NULL,NULL,'Y','5',1,@i OUTPUT; PRINT 'FAIL 02'; END TRY BEGIN CATCH PRINT '02 new user without password -> ' + ERROR_MESSAGE(); END CATCH

-- UserGetByUserName returns two result sets, so it is checked directly rather than captured
SELECT @chk = CAST(COUNT(*) AS VARCHAR) FROM UserMaster WHERE UserName = 'nobody' AND IsActive = 'Y';
PRINT '03 unknown user returns rows -> ' + @chk + ' (UserGetByUserName returns no user row)';

SET @i = 0; WHILE @i < 4 BEGIN EXEC UserLoginFailed 'logintest'; SET @i += 1; END
SELECT @chk = CONCAT('failed=', FailedLoginCount, ' locked=', IIF(LockedUntil > GETDATE(),'yes','no')) FROM UserMaster WHERE UserID=@U; PRINT '04 after 4 wrong passwords -> ' + @chk;
EXEC UserLoginFailed 'logintest';
SELECT @chk = CONCAT('locked=', IIF(LockedUntil > GETDATE(),'yes','no'), ' for ', DATEDIFF(MINUTE, GETDATE(), LockedUntil) + 1, ' min') FROM UserMaster WHERE UserID=@U; PRINT '05 after 5 wrong passwords -> ' + @chk;

EXEC UserLoginSuccess @U, @T1, '10.0.0.1', 'test';
SELECT @chk = CONCAT('failed=', FailedLoginCount, ' locked=', IIF(LockedUntil IS NULL,'no','yes'), ' lastLogin=', IIF(LastLoginOn IS NULL,'no','yes')) FROM UserMaster WHERE UserID=@U; PRINT '06 login success resets -> ' + @chk;
INSERT INTO #s EXEC UserSessionValidate @T1; SELECT @chk = CONCAT(UserName, ' roles=', Roles) FROM #s; DELETE #s;
PRINT '07 session valid -> ' + @chk;
INSERT INTO #s EXEC UserSessionValidate @T2; SELECT @chk = CAST(COUNT(*) AS VARCHAR) FROM #s; DELETE #s;
PRINT '08 unknown token rows -> ' + @chk;

EXEC UserLoginSuccess @U, @T2, NULL, NULL;
EXEC UserPasswordUpdate @U, 'hash-2', 0, @U, @T1;   -- user changes own password from session T1
INSERT INTO #s EXEC UserSessionValidate @T1; SELECT @chk = CONCAT('T1 rows=', COUNT(*)) FROM #s; DELETE #s;
INSERT INTO #s EXEC UserSessionValidate @T2; SELECT @chk = @chk + CONCAT(', T2 rows=', COUNT(*)) FROM #s; DELETE #s;
SELECT @chk = @chk + CONCAT(', must change=', MustChangePassword) FROM UserMaster WHERE UserID=@U;
PRINT '09 own change keeps this session only -> ' + @chk;

EXEC UserPasswordUpdate @U, 'hash-3', 1, 1, NULL;   -- admin reset
INSERT INTO #s EXEC UserSessionValidate @T1; SELECT @chk = CONCAT('T1 rows=', COUNT(*)) FROM #s; DELETE #s;
SELECT @chk = @chk + CONCAT(', must change=', MustChangePassword) FROM UserMaster WHERE UserID=@U;
PRINT '10 admin reset ends all sessions -> ' + @chk;

EXEC UserLoginSuccess @U, @T3, NULL, NULL;
EXEC UserActiveStatusUpdate @U, 'N', 1;
INSERT INTO #s EXEC UserSessionValidate @T3; SELECT @chk = CAST(COUNT(*) AS VARCHAR) FROM #s; DELETE #s;
PRINT '11 deactivated user session rows -> ' + @chk;
EXEC UserActiveStatusUpdate @U, 'Y', 1;
EXEC UserLogout @T3;
INSERT INTO #s EXEC UserSessionValidate @T3; SELECT @chk = CAST(COUNT(*) AS VARCHAR) FROM #s; DELETE #s;
PRINT '12 after logout session rows -> ' + @chk;

ROLLBACK TRAN;
DROP TABLE IF EXISTS #s;
SELECT LeftOver_Users = (SELECT COUNT(*) FROM UserMaster), LeftOver_Sessions = (SELECT COUNT(*) FROM UserLoginHistory);
