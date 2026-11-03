/* =============================================================
   Change   : 2026-10-09_001
   Table    : UserMaster
   Purpose  : Columns for username / password login:
              MustChangePassword - 1 after the admin sets or resets a
                                   password; the user must change it
              FailedLoginCount   - wrong passwords in a row
              LockedUntil        - set for 15 minutes after 5 wrong passwords
              LastLoginOn        - last successful login
   Safe to run again: each column is added only if missing.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.UserMaster', 'MustChangePassword') IS NULL
    ALTER TABLE dbo.UserMaster ADD MustChangePassword BIT NOT NULL CONSTRAINT DF_UserMaster_MustChangePassword DEFAULT (0);
IF COL_LENGTH('dbo.UserMaster', 'FailedLoginCount') IS NULL
    ALTER TABLE dbo.UserMaster ADD FailedLoginCount INT NOT NULL CONSTRAINT DF_UserMaster_FailedLoginCount DEFAULT (0);
IF COL_LENGTH('dbo.UserMaster', 'LockedUntil') IS NULL
    ALTER TABLE dbo.UserMaster ADD LockedUntil DATETIME NULL;
IF COL_LENGTH('dbo.UserMaster', 'LastLoginOn') IS NULL
    ALTER TABLE dbo.UserMaster ADD LastLoginOn DATETIME NULL;
PRINT 'UserMaster login columns in place.';
GO
