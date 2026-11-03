/* =============================================================
   Script   : 001_Create_Database.sql
   Purpose  : Create the IAL_QC database (safe to run again)
   Run in   : SSMS, connected to the SQL Server instance (master)
   ============================================================= */
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = N'IAL_QC')
BEGIN
    CREATE DATABASE IAL_QC;
    PRINT 'Database IAL_QC created.';
END
ELSE
    PRINT 'Database IAL_QC already exists - nothing changed.';
GO

ALTER DATABASE IAL_QC SET RECOVERY FULL;
GO
