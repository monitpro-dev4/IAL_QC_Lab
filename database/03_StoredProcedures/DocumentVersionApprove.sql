/* =============================================================
   Procedure : DocumentVersionApprove
   Module    : Document Management
   Purpose   : Approve or reject a submitted revision.
               The level comes from the revision's status:
                 Submitted           -> level 1, Lab Supervisor
                 Supervisor Approved -> level 2, Lab Manager
               Level 2 approval makes this the current version:
                 the old Approved revision -> Superseded (history),
                 Document.CurrentVersionID -> this revision,
                 IssuedDate = today.
   Rules     : - Only the right role can act at each level
               - A Supervisor / Manager may approve or reject a revision they
                 uploaded themselves (allowed since 2026-10-29)
               - Comments are required when rejecting
   Params    : @Action  'Approved' or 'Rejected'
   Example   : EXEC DocumentVersionApprove 1, 'Approved', 'Looks good', 3;
   ============================================================= */
USE IAL_QC;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.DocumentVersionApprove
    @VersionID  INT,
    @Action     VARCHAR(20),
    @Comments   VARCHAR(1000) = NULL,
    @UserID     INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OwnTran BIT = 0, @StatusID TINYINT, @DocumentID INT, @EditedBy INT,
            @RevisionNo INT, @Level TINYINT, @NewStatusID TINYINT, @OldApprovedID INT,
            @RequiredRole VARCHAR(50);

    IF LTRIM(RTRIM(@Comments)) IN ('', 'null') SET @Comments = NULL;
    SET @Action = LTRIM(RTRIM(@Action));

    BEGIN TRY
        IF @Action NOT IN ('Approved', 'Rejected')
        BEGIN
            RAISERROR ('Action Must Be Approved Or Rejected', 11, 1);
            RETURN;
        END

        IF @Action = 'Rejected' AND @Comments IS NULL
        BEGIN
            RAISERROR ('Comments Are Required When Rejecting', 11, 1);
            RETURN;
        END

        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @OwnTran = 1; END

        SELECT @StatusID = v.StatusID, @DocumentID = v.DocumentID,
               @EditedBy = v.EditedBy, @RevisionNo = v.RevisionNo
        FROM dbo.DocumentVersion v WITH (UPDLOCK, HOLDLOCK)
        WHERE v.VersionID = @VersionID;

        IF @StatusID IS NULL
        BEGIN
            RAISERROR ('Document Version Not Found', 11, 1);
            RETURN;
        END

        IF @StatusID = 2      SELECT @Level = 1, @RequiredRole = 'Lab Supervisor';
        ELSE IF @StatusID = 3 SELECT @Level = 2, @RequiredRole = 'Lab Manager';
        ELSE
        BEGIN
            RAISERROR ('This Revision Is Not Waiting For Approval', 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.UserRoles ur
                       JOIN dbo.RoleMaster rm ON rm.RoleID = ur.RoleID AND rm.IsActive = 'Y'
                       JOIN dbo.UserMaster u  ON u.UserID  = ur.UserID AND u.IsActive  = 'Y'
                       WHERE ur.UserID = @UserID AND rm.RoleName = @RequiredRole)
        BEGIN
            DECLARE @Msg VARCHAR(200) = 'Only The ' + @RequiredRole + ' Can Act At Approval Level ' + CAST(@Level AS VARCHAR(1));
            RAISERROR (@Msg, 11, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.Document WHERE DocumentID = @DocumentID AND IsActive = 'Y')
        BEGIN
            RAISERROR ('Document Is Inactive', 11, 1);
            RETURN;
        END

        IF @Action = 'Rejected'
        BEGIN
            SET @NewStatusID = 5;
            UPDATE dbo.DocumentVersion
            SET StatusID   = 5,
                ReviewedBy = CASE WHEN @Level = 1 THEN @UserID    ELSE ReviewedBy END,
                ReviewedOn = CASE WHEN @Level = 1 THEN GETDATE() ELSE ReviewedOn END,
                ModifiedBy = @UserID,
                ModifiedOn = GETDATE()
            WHERE VersionID = @VersionID;
        END
        ELSE IF @Level = 1
        BEGIN
            SET @NewStatusID = 3;
            UPDATE dbo.DocumentVersion
            SET StatusID = 3, ReviewedBy = @UserID, ReviewedOn = GETDATE(),
                ModifiedBy = @UserID, ModifiedOn = GETDATE()
            WHERE VersionID = @VersionID;
        END
        ELSE
        BEGIN
            SET @NewStatusID = 4;

            -- 1. Old approved revision goes to history
            SELECT @OldApprovedID = VersionID
            FROM dbo.DocumentVersion WITH (UPDLOCK, HOLDLOCK)
            WHERE DocumentID = @DocumentID AND StatusID = 4;

            IF @OldApprovedID IS NOT NULL
            BEGIN
                UPDATE dbo.DocumentVersion
                SET StatusID = 6, ModifiedBy = @UserID, ModifiedOn = GETDATE()
                WHERE VersionID = @OldApprovedID;

                INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
                VALUES (@OldApprovedID, 'Superseded', NULL, 4, 6,
                        'Replaced by revision ' + CAST(@RevisionNo AS VARCHAR(10)), @UserID, GETDATE());
            END

            -- 2. This revision becomes the approved one
            UPDATE dbo.DocumentVersion
            SET StatusID = 4, ApprovedBy = @UserID, ApprovedOn = GETDATE(),
                IssuedDate = CAST(GETDATE() AS DATE),
                ModifiedBy = @UserID, ModifiedOn = GETDATE()
            WHERE VersionID = @VersionID;

            -- 3. Point the document at it
            UPDATE dbo.Document
            SET CurrentVersionID = @VersionID, ModifiedBy = @UserID, ModifiedOn = GETDATE()
            WHERE DocumentID = @DocumentID;
        END

        INSERT INTO dbo.DocumentApprovalLog (VersionID, ActionType, ApprovalLevel, FromStatusID, ToStatusID, Comments, ActionBy, ActionOn)
        VALUES (@VersionID, @Action, @Level, @StatusID, @NewStatusID, @Comments, @UserID, GETDATE());

        IF @OwnTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 11, 1);
    END CATCH;
END
GO
