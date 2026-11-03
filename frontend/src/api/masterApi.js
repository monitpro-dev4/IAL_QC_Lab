import { get, post } from "./client";

export const getRoles = (isActive = "Y") => get("/Master/RoleMasterGet", { isActive });
export const saveRole = (role) => post("/Master/RoleMasterInsertUpdate", role);

export const getCategories = (isActive = "Y") => get("/Master/DocumentCategoryGet", { isActive });
export const saveCategory = (category) => post("/Master/DocumentCategoryInsertUpdate", category);
