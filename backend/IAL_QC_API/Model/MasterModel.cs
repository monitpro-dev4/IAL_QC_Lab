namespace IAL_QC_API.Model
{
    //=========================== Roles ===========================

    public class RoleModel
    {
        public int RoleID { get; set; }
        public string RoleName { get; set; }
        public string RoleDesc { get; set; }
        public string IsActive { get; set; } = "Y";
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }

    //=========================== Document categories ===========================

    /// <summary>Department dropdown item.</summary>
    public class DepartmentModel
    {
        public int DepartmentID { get; set; }
        public string DepartmentName { get; set; }
        public string IsActive { get; set; } = "Y";
    }

    /// <summary>Plant / Area dropdown item.</summary>
    public class PlantAreaModel
    {
        public int PlantAreaID { get; set; }
        public string PlantAreaName { get; set; }
        public string IsActive { get; set; } = "Y";
    }

    public class DocumentCategoryModel
    {
        public int CategoryID { get; set; }
        public string CategoryCode { get; set; }
        public string CategoryName { get; set; }
        public string CategoryDesc { get; set; }
        public string IsActive { get; set; } = "Y";
        public int? CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }
}
