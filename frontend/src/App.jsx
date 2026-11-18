import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { Box, CircularProgress } from "@mui/material";
import { useAuth } from "./auth/AuthContext";
import Layout from "./components/Layout";
import SignInPage from "./pages/SignInPage";
import ChangePasswordPage from "./pages/ChangePasswordPage";
import DashboardPage from "./pages/DashboardPage";
import ComingSoonPage from "./pages/ComingSoonPage";
import DocumentListPage from "./pages/DocumentListPage";
import DocumentDetailPage from "./pages/DocumentDetailPage";
import UsersPage from "./pages/UsersPage";
import CategoriesPage from "./pages/CategoriesPage";
import NotFoundPage from "./pages/NotFoundPage";

/** Signed in, and (unless on the change-password page) no temporary password pending. */
function RequireUser({ children }) {
  const { user, checking } = useAuth();
  const location = useLocation();
  if (checking) return <Box sx={{ minHeight: "100vh", display: "grid", placeItems: "center" }}><CircularProgress /></Box>;
  if (!user) return <Navigate to="/signin" replace />;
  if (user.mustChangePassword && location.pathname !== "/change-password") return <Navigate to="/change-password" replace />;
  return children;
}

function RequireRole({ allowed, children }) {
  return allowed ? children : <Navigate to="/dashboard" replace />;
}

export default function App() {
  const { isAdmin } = useAuth();
  return (
    <Routes>
      <Route path="/signin" element={<SignInPage />} />
      <Route element={<RequireUser><Layout /></RequireUser>}>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/modules" element={<Navigate to="/dashboard" replace />} />
        <Route path="/sample-register" element={<ComingSoonPage moduleKey="samples" />} />
        <Route path="/calibration" element={<ComingSoonPage moduleKey="calibration" />} />
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/change-password" element={<ChangePasswordPage />} />
        <Route path="/documents" element={<DocumentListPage />} />
        <Route path="/archived" element={<Navigate to="/documents?tab=archived" replace />} />
        <Route path="/documents/new" element={<Navigate to="/documents" replace />} />
        <Route path="/documents/:id" element={<DocumentDetailPage />} />
        <Route path="/approvals" element={<Navigate to="/documents" replace />} />
        <Route path="/users" element={<RequireRole allowed={isAdmin}><UsersPage /></RequireRole>} />
        <Route path="/categories" element={<RequireRole allowed={isAdmin}><CategoriesPage /></RequireRole>} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
