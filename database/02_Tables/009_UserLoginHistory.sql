/* =============================================================
   Script   : 009_UserLoginHistory.sql
   Purpose  : One row per login session. The login token itself is
              never stored, only its SHA-256 hash, so a copy of this
              table cannot be used to sign in. A session ends when
              LogoutTime is set (sign out, password change, reset).
   Depends  : 002_UserMaster.sql
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.UserLoginHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserLoginHistory
    (
        ID          BIGINT IDENTITY(1,1) NOT NULL,
        UserID      INT          NOT NULL,
        TokenHash   CHAR(64)     NOT NULL,
        LoginTime   DATETIME     NOT NULL CONSTRAINT DF_UserLoginHistory_LoginTime DEFAULT (GETDATE()),
        LogoutTime  DATETIME     NULL,
        IPAddress   VARCHAR(50)  NULL,
        UserAgent   VARCHAR(300) NULL,
        CONSTRAINT PK_UserLoginHistory            PRIMARY KEY (ID),
        CONSTRAINT UQ_UserLoginHistory_TokenHash  UNIQUE (TokenHash),
        CONSTRAINT FK_UserLoginHistory_UserMaster FOREIGN KEY (UserID) REFERENCES dbo.UserMaster (UserID)
    );
    CREATE INDEX IX_UserLoginHistory_UserID ON dbo.UserLoginHistory (UserID) WHERE LogoutTime IS NULL;
    PRINT 'Table UserLoginHistory created.';
END
ELSE
    PRINT 'Table UserLoginHistory already exists - nothing changed.';
GO
