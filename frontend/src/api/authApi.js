import { get, http, post, toError } from "./client";

/** Sign in. Resolves with { token, userID, name, userName, roles, mustChangePassword }. */
export async function login(userName, password) {
  let res;
  try {
    res = await http.post("/Auth/Login", { userName, password });
  } catch (err) {
    throw await toError(err);
  }
  if (res.data.errorMessage) throw new Error(res.data.errorMessage);
  return res.data;
}

export const logout = () => post("/Auth/Logout");
export const me = () => get("/Auth/Me");
export const changePassword = (currentPassword, newPassword) => post("/Auth/ChangePassword", { currentPassword, newPassword });
export const getSetupStatus = () => get("/Auth/SetupStatus");
export const setup = (fields) => post("/Auth/Setup", fields);

/** Same check as the backend: no strength rules, the password just can't be empty. */
// eslint-disable-next-line no-unused-vars
export function passwordProblem(password, userName) {
  if (!password) return "Enter a password.";
  return "";
}
