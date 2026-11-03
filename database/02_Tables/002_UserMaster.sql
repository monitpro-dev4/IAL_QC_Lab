/* =============================================================
   Script   : 002_UserMaster.sql
   Purpose  : Application users (safe to run again)
   Note     : PasswordHash is NULL when the user signs in with
              the IAL Windows / LDAP login.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.UserMaster', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserMaster
    (
        UserID        INT IDENTITY(1,1) NOT NULL,
        Name          VARCHAR(100) NOT NULL,
        EmployeeID    VARCHAR(50)  NOT NULL,
        UserName      VARCHAR(50)  NOT NULL,
        PasswordHash  NVARCHAR(256) NULL,
        EmailAddress  VARCHAR(100) NULL,
        MobileNo      VARCHAR(15)  NULL,
        Designation   VARCHAR(100) NULL,
        UserImage     VARCHAR(200) NULL,
        IsActive      CHAR(1)      NOT NULL CONSTRAINT DF_UserMaster_IsActive  DEFAULT ('Y'),
        CreatedBy     INT          NULL,
        CreatedOn     DATETIME     NOT NULL CONSTRAINT DF_UserMaster_CreatedOn DEFAULT (GETDATE()),
        ModifiedBy    INT          NULL,
        ModifiedOn    DATETIME     NULL,
        CONSTRAINT PK_UserMaster            PRIMARY KEY (UserID),
        CONSTRAINT UQ_UserMaster_UserName   UNIQUE (UserName),
        CONSTRAINT UQ_UserMaster_EmployeeID UNIQUE (EmployeeID),
        CONSTRAINT CK_UserMaster_IsActive   CHECK (IsActive IN ('Y','N'))
    );
    PRINT 'Table UserMaster created.';
END
ELSE
    PRINT 'Table UserMaster already exists - nothing changed.';
GO
