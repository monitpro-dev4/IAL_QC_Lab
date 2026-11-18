/* =============================================================
   Table    : DepartmentMaster
   Purpose  : Departments shown in the Department dropdown (Document Management and later modules)
   Added    : 2026-11-13
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.DepartmentMaster', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DepartmentMaster
    (
        DepartmentID    INT IDENTITY(1,1) NOT NULL,
        DepartmentName  VARCHAR(100) NOT NULL,
        SortOrder      INT          NULL,
        IsActive       CHAR(1)      NOT NULL CONSTRAINT DF_DepartmentMaster_IsActive  DEFAULT ('Y'),
        CreatedOn      DATETIME     NOT NULL CONSTRAINT DF_DepartmentMaster_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn     DATETIME     NULL,
        CONSTRAINT PK_DepartmentMaster          PRIMARY KEY (DepartmentID),
        CONSTRAINT UQ_DepartmentMaster_Name   UNIQUE (DepartmentName),
        CONSTRAINT CK_DepartmentMaster_Active CHECK (IsActive IN ('Y','N'))
    );
    PRINT 'Table DepartmentMaster created.';
END
ELSE
    PRINT 'Table DepartmentMaster already exists - nothing changed.';
GO
