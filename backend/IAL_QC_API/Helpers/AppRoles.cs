namespace IAL_QC_API
{
    /// <summary>Role names exactly as in RoleMaster. Used with [Authorize(Roles = ...)].</summary>
    public static class AppRoles
    {
        public const string Admin = "Administrator";
        public const string LabManager = "Lab Manager";
        public const string LabSupervisor = "Lab Supervisor";
        public const string QAManager = "QA Manager";
        public const string LabChemist = "Lab Chemist";
        public const string Employee = "Employee";

        /// <summary>Can add and revise documents.</summary>
        public static readonly string[] DocumentEditors = { LabChemist, LabSupervisor, LabManager, Admin };

        /// <summary>Can open revisions that are not approved yet (drafts, in review).</summary>
        public static readonly string[] DraftViewers = { LabChemist, LabSupervisor, LabManager, QAManager, Admin };
    }
}
