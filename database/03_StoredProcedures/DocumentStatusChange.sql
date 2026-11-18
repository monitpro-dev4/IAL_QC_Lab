/* =============================================================
   Procedure : DocumentStatusChange
   Module    : Document Management
   Purpose   : Lab Manager actions on a document's revision:
                 Cancel  - Under Review / Under Approval / Rejected -> Cancelled (final;
                           an older approved revision, if any, stays current)
                 Archive - an Under Approval revision, or the current Approved revision,
                           -> Archived (retired: hidden from employees; an archived
                           approved document gets no new revisions)
                 Restore - an Archived revision -> back to the status it had before
                           (Under Approval or Approved)
   Params    : @Action  'Cancel', 'Archive' or 'Restore'
   Who       : Lab Manager only
   Example   : EXEC DocumentStatusChange 12, 'Archive', 'No longer used', 4;
   Added     : 2026-11-11 (Archive from Under Approval added the same day)
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentStatusChange
    @VersionID  INT,
    @Action     VARCHAR(20),
    @Comments   VARCHAR(1000) = NULL,
    @UserID     INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0, @StatusID TINYINT, @DocumentID INT, @NewStatusID TINYINT,
            @LogAction VARCHAR(20), @IsCurrent BIT, @PrevStatusID TINYINT;

    IF LTRIM(RTRIM(@Comments)) IN ('', 'null') SET @Comments = NULL;
    SET @Action = LTRIM(RTRIM(@Action));

    BEGIN TRY
        IF @Action NOT IN ('Cancel', 'Archive', 'Restore')
        BEGIN
            RAISERROR ('Action Must Be Cancel, Archive Or Restore', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID AND rm.RoleName = 'Lab Manager')
        BEGIN
            RAISERROR ('Only The Lab Manager Can Cancel, Archive Or Restore Documents', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        SELECT @StatusID = v.StatusID, @DocumentID = v.DocumentID,
               @IsCurrent = CASE WHEN d.CurrentVersionID = v.VersionID THEN 1 ELSE 0 END
        FROM dbo.DocumentVersion v WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.Document d ON d.DocumentID = v.DocumentID AND d.IsActive = 'Y'
        WHERE v.VersionID = @VersionID;

        IF @StatusID IS NULL
        BEGIN
            RAISERROR ('Document Version Not Found', 11, 1);
            RETURN;
        END

        IF @Action = 'Cancel'
        BEGIN
            IF @StatusID NOT IN (2, 3, 5)
            BEGIN
                RAISERROR ('Only A Revision Under Review, Under Approval Or Rejected Can Be Cancelled', 11, 1);
                RETURN;
            END
            SELECT @NewStatusID = 7, @LogAction = 'Cancelled';
        END
        ELSE IF @Action = 'Archive'
        BEGIN
            IF @StatusID = 3
                SELECT @NewStatusID = 8, @LogAction = 'Archived';      -- Under Approval
            ELSE IF @StatusID = 4 AND @IsCurrent = 1
            BEGIN
                IF EXISTS (SELECT 1 FROM dbo.DocumentVersion WHERE DocumentID = @DocumentID AND StatusID IN (1, 2, 3, 5))
                BEGIN
                    RAISERROR ('This Document Has A Revision In Progress - Cancel Or Approve It First', 11, 1);
                    RETURN;
                END
                SELECT @NewStatusID = 8, @LogAction = 'Archived';      -- Approved
            END
            ELSE
            BEGIN
                RAISERROR ('Only An Under Approval Or Approved Document Can Be Archived', 11, 1);
                RETURN;
            END
        END
        ELSE
        BEGIN
            IF @StatusID <> 8
            BEGIN
                RAISERROR ('Only An Archived Document Can Be Restored', 11, 1);
                RETURN;
            END
            -- Back to the status it had when it was archived
            SELECT TOP 1 @PrevStatusID = FromStatusID FROM dbo.DocumentApprovalLog
            WHERE VersionID = @VersionID AND ActionType = 'Archived' ORDER BY LogID DESC;
            SET @PrevStatusID = ISNULL(@PrevStatusID, 4);

            IF @PrevStatusID = 4 AND @IsCurrent = 0
            BEGIN
                RAISERROR ('This Revision Is No Longer The Current Version And Cannot Be Restored', 11, 1);
                RETURN;
            END
            IF @PrevStatusID = 3 AND EXISTS (SELECT 1 FROM dbo.DocumentVersion
                                             WHERE DocumentID = @DocumentID AND StatusID IN (1, 2, 3) AND VersionID <> @VersionID)
            BEGIN
                RAISERROR ('Another Revision Of This Document Is In Progress - It Cannot Be Restored', 11, 1);
                RETURN;
            END
            SELECT @NewStatusID = @PrevStatusID, @LogAction = 'Restored';
        END

        UPDATE dbo.DocumentVersion
        SET StatusID = @NewStatusID, ModifiedBy = @UserID, ModifiedOn = GETDATE()
        WHERE VersionID = @VersionID;

        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        VALUES (@VersionID, @LogAction, NULL, @StatusID, @NewStatusID, @Comments, @UserID, GETDATE());

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
