/* =============================================================
   Script   : 003_UserRoles.sql
   Purpose  : Links users to roles (one user can have many roles)
   Depends  : 001_RoleMaster.sql, 002_UserMaster.sql
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.UserRoles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRoles
    (
        ID          BIGINT IDENTITY(1,1) NOT NULL,
        UserID      INT      NOT NULL,
        RoleID      INT      NOT NULL,
        AssignedBy  INT      NULL,
        AssignedOn  DATETIME NOT NULL CONSTRAINT DF_UserRoles_AssignedOn DEFAULT (GETDATE()),
        CONSTRAINT PK_UserRoles             PRIMARY KEY (ID),
        CONSTRAINT UQ_UserRoles_UserRole    UNIQUE (UserID, RoleID),
        CONSTRAINT FK_UserRoles_UserMaster  FOREIGN KEY (UserID) REFERENCES dbo.UserMaster (UserID),
        CONSTRAINT FK_UserRoles_RoleMaster  FOREIGN KEY (RoleID) REFERENCES dbo.RoleMaster (RoleID)
    );
    PRINT 'Table UserRoles created.';
END
ELSE
    PRINT 'Table UserRoles already exists - nothing changed.';
GO
