import { get, post } from "./client";

export const getUsers = ({ search, roleId = 0, isActive } = {}) =>
  get("/User/UsersGet", { search, roleId, isActive });
export const getUser = (userId) => get("/User/UserGet", { userId });
export const saveUser = (user) => post("/User/UserInsertUpdate", user);
export const setUserActive = (userID, isActive) => post("/User/UserActiveStatusUpdate", { userID, isActive });
export const resetPassword = (userID, newPassword) => post("/User/UserPasswordReset", { userID, newPassword });
