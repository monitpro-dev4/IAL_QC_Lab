/* =============================================================
   Table    : PlantAreaMaster
   Purpose  : Plants / areas of IAL Manali shown in the Plant / Area dropdown
   Added    : 2026-11-13
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.PlantAreaMaster', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PlantAreaMaster
    (
        PlantAreaID    INT IDENTITY(1,1) NOT NULL,
        PlantAreaName  VARCHAR(100) NOT NULL,
        SortOrder      INT          NULL,
        IsActive       CHAR(1)      NOT NULL CONSTRAINT DF_PlantAreaMaster_IsActive  DEFAULT ('Y'),
        CreatedOn      DATETIME     NOT NULL CONSTRAINT DF_PlantAreaMaster_CreatedOn DEFAULT (GETDATE()),
        ModifiedOn     DATETIME     NULL,
        CONSTRAINT PK_PlantAreaMaster          PRIMARY KEY (PlantAreaID),
        CONSTRAINT UQ_PlantAreaMaster_Name   UNIQUE (PlantAreaName),
        CONSTRAINT CK_PlantAreaMaster_Active CHECK (IsActive IN ('Y','N'))
    );
    PRINT 'Table PlantAreaMaster created.';
END
ELSE
    PRINT 'Table PlantAreaMaster already exists - nothing changed.';
GO
