import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { SIGNED_OUT, TOKEN_KEY } from "../api/client";
import { login as apiLogin, logout as apiLogout, me } from "../api/authApi";

// Signed-in user. The login token is kept in localStorage; on start-up it is
// checked with the server (Auth/Me), so a session that was ended elsewhere
// (sign out, password reset, user deactivated) does not linger in the browser.

export const ROLES = {
  ADMIN: "Administrator",
  MANAGER: "Lab Manager",
  SUPERVISOR: "Lab Supervisor",
  QA: "QA Manager",
  CHEMIST: "Lab Chemist",
  EMPLOYEE: "Employee",
};
const EDITOR_ROLES = [ROLES.CHEMIST, ROLES.SUPERVISOR, ROLES.MANAGER, ROLES.ADMIN];
const DRAFT_VIEWER_ROLES = [...EDITOR_ROLES, ROLES.QA];

const AuthContext = createContext(null);

const toUser = (r) => ({ userID: r.userID, name: r.name, userName: r.userName, roles: r.roles || [], mustChangePassword: !!r.mustChangePassword });

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(() => !!localStorage.getItem(TOKEN_KEY));

  const clear = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setUser(null);
  }, []);

  // Check a saved token once on start-up
  useEffect(() => {
    if (!localStorage.getItem(TOKEN_KEY)) return;
    me().then((r) => setUser(toUser(r))).catch(clear).finally(() => setChecking(false));
  }, [clear]);

  // Any 401 from the API (session ended) signs out here too
  useEffect(() => {
    window.addEventListener(SIGNED_OUT, clear);
    return () => window.removeEventListener(SIGNED_OUT, clear);
  }, [clear]);

  const value = useMemo(() => {
    const roles = user?.roles || [];
    const has = (...names) => names.some((n) => roles.includes(n));
    return {
      user,
      checking,
      /** Accepts a login (or setup) response. */
      signedIn: (res) => {
        localStorage.setItem(TOKEN_KEY, res.token);
        setUser(toUser(res));
      },
      signIn: async (userName, password) => {
        const res = await apiLogin(userName, password);
        localStorage.setItem(TOKEN_KEY, res.token);
        setUser(toUser(res));
        return res;
      },
      signOut: async () => {
        try { await apiLogout(); } catch { /* already signed out */ }
        clear();
      },
      passwordChanged: () => setUser((u) => ({ ...u, mustChangePassword: false })),
      has,
      canEditDocuments: has(...EDITOR_ROLES),
      canViewDrafts: has(...DRAFT_VIEWER_ROLES),
      isSupervisor: has(ROLES.SUPERVISOR),
      isManager: has(ROLES.MANAGER),
      isAdmin: has(ROLES.ADMIN),
      canChangeDocumentStatus: has(ROLES.MANAGER, ROLES.ADMIN),
    };
  }, [user, checking, clear]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
