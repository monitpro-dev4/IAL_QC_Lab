/* =============================================================
   Script   : 001_RoleMaster.sql
   Purpose  : Master list of user roles (safe to run again)
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.RoleMaster', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RoleMaster
    (
        RoleID      INT IDENTITY(1,1) NOT NULL,
        RoleName    VARCHAR(50)  NOT NULL,
        RoleDesc    VARCHAR(250) NULL,
        IsActive    CHAR(1)      NOT NULL CONSTRAINT DF_RoleMaster_IsActive  DEFAULT ('Y'),
        CreatedBy   INT          NULL,
        CreatedOn   DATETIME     NOT NULL CONSTRAINT DF_RoleMaster_CreatedOn DEFAULT (GETDATE()),
        ModifiedBy  INT          NULL,
        ModifiedOn  DATETIME     NULL,
        CONSTRAINT PK_RoleMaster          PRIMARY KEY (RoleID),
        CONSTRAINT UQ_RoleMaster_RoleName UNIQUE (RoleName),
        CONSTRAINT CK_RoleMaster_IsActive CHECK (IsActive IN ('Y','N'))
    );
    PRINT 'Table RoleMaster created.';
END
ELSE
    PRINT 'Table RoleMaster already exists - nothing changed.';
GO
