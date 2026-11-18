/* =============================================================
   Script   : 004_PlantAreaMaster_Seed.sql
   Purpose  : Starting plants / areas (sample data - adjust to IAL's list).
              Adds only the ones that are missing.
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

MERGE dbo.PlantAreaMaster AS t
USING (VALUES
    ('QC Laboratory', 1), ('Product Development Lab', 2), ('Additive Plant - Reactor Section', 3),
    ('Blending Plant', 4), ('Tank Farm', 5), ('Drum Filling Area', 6), ('Raw Material Store', 7),
    ('Finished Goods Warehouse', 8), ('Utilities (Boiler & Cooling Tower)', 9),
    ('Effluent Treatment Plant (ETP)', 10), ('Maintenance Workshop', 11), ('Admin Building', 12)
) AS s (PlantAreaName, SortOrder)
ON t.PlantAreaName = s.PlantAreaName
WHEN NOT MATCHED THEN INSERT (PlantAreaName, SortOrder) VALUES (s.PlantAreaName, s.SortOrder);
PRINT 'PlantAreaMaster seed done.';
GO
