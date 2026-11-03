import { useEffect, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { Alert, Box, Button, CircularProgress, Paper, Stack, TextField, Typography } from "@mui/material";
import { useAuth } from "../auth/AuthContext";
import { getSetupStatus, passwordProblem, setup } from "../api/authApi";
import PasswordField from "../components/PasswordField";
import BrandMark from "../components/BrandMark";
import { colors } from "../theme";

export default function SignInPage() {
  const { user, signIn, signedIn } = useAuth();
  const navigate = useNavigate();
  const [mode, setMode] = useState("loading"); // loading | signin | setup
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({ userName: "", password: "" });
  const [admin, setAdmin] = useState({ name: "", employeeID: "", userName: "", password: "", confirm: "" });
  const [touched, setTouched] = useState(false);

  useEffect(() => {
    getSetupStatus()
      .then((s) => setMode(s.needsSetup ? "setup" : "signin"))
      .catch((e) => { setError(e.message); setMode("signin"); });
  }, []);

  if (user) return <Navigate to={user.mustChangePassword ? "/change-password" : "/dashboard"} replace />;

  const submit = async (e) => {
    e.preventDefault();
    setError("");
    if (!form.userName.trim() || !form.password) return setError("Enter your username and password.");
    setBusy(true);
    try {
      const res = await signIn(form.userName.trim(), form.password);
      navigate(res.mustChangePassword ? "/change-password" : "/dashboard", { replace: true });
    } catch (err) {
      setError(err.message);
      setForm((f) => ({ ...f, password: "" }));
      setBusy(false);
    }
  };

  const adminErrors = {
    name: !admin.name.trim() && "Enter your name.",
    employeeID: !admin.employeeID.trim() && "Enter your employee ID.",
    userName: !admin.userName.trim() && "Choose a username.",
    password: passwordProblem(admin.password, admin.userName),
    confirm: admin.confirm !== admin.password && "The passwords don't match.",
  };
  const createAdmin = async (e) => {
    e.preventDefault();
    setTouched(true);
    setError("");
    if (Object.values(adminErrors).some(Boolean)) return;
    setBusy(true);
    try {
      const res = await setup({ name: admin.name.trim(), employeeID: admin.employeeID.trim(), userName: admin.userName.trim(), password: admin.password });
      if (res.errorMessage) throw new Error(res.errorMessage);
      signedIn(res);
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  };
  const aErr = (k) => (touched ? adminErrors[k] : "");
  const setA = (k) => (e) => setAdmin({ ...admin, [k]: e.target.value });

  return (
    <Box sx={{ minHeight: "100vh", display: "grid", gridTemplateColumns: { xs: "1fr", md: "minmax(380px, 44%) 1fr" }, bgcolor: "#fff" }}>
      <Box sx={{
        display: { xs: "none", md: "flex" }, flexDirection: "column", justifyContent: "space-between", p: 6, color: "#fff",
        background: `radial-gradient(120% 80% at 0% 100%, rgba(44,197,184,0.22), transparent 60%), ${colors.navy}`,
      }}>
        <Box sx={{ display: "flex", alignItems: "center", gap: 1.5 }}>
          <BrandMark size={40} />
          <Typography sx={{ fontWeight: 700, fontSize: "1.125rem" }}>IAL QC Lab</Typography>
        </Box>
        <Box sx={{ maxWidth: 420 }}>
          <Typography sx={{ fontSize: "2.25rem", fontWeight: 700, lineHeight: 1.15, letterSpacing: "-0.02em", mb: 2 }}>
            Every SOP, at its current approved revision.
          </Typography>
          <Typography sx={{ color: colors.navyText, fontSize: "1.0625rem" }}>
            Lab documents reviewed by the supervisor, approved by the manager, and kept with their full history.
          </Typography>
        </Box>
        <Typography sx={{ color: "#6F8197", fontSize: "0.875rem" }}>Indian Additives Limited · QC Laboratory</Typography>
      </Box>

      <Box sx={{ display: "grid", placeItems: "center", px: 2, py: 6, bgcolor: { xs: colors.paper, md: "#fff" } }}>
      <Paper sx={{ width: "100%", maxWidth: 400, p: { xs: 3, sm: 4 }, boxShadow: { md: "none" }, border: { md: "none" } }}>
        <Box sx={{ display: { xs: "flex", md: "none" }, alignItems: "center", gap: 1.5, mb: 3 }}>
          <BrandMark size={36} />
          <Typography sx={{ fontWeight: 700, fontSize: "1.0625rem" }}>IAL QC Lab</Typography>
        </Box>
        <Typography variant="h1" sx={{ mb: 0.5 }}>{mode === "setup" ? "Set up the system" : "Sign in"}</Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>{mode === "setup" ? "Create the administrator account." : "Use your IAL QC Lab username and password."}</Typography>

        {error && <Alert severity="error" sx={{ mb: 2.5 }}>{error}</Alert>}

        {mode === "loading" && <Box sx={{ display: "grid", placeItems: "center", py: 4 }}><CircularProgress size={28} /></Box>}

        {mode === "signin" && (
          <Box component="form" onSubmit={submit} noValidate>
            <Stack spacing={2}>
              <TextField label="Username" autoFocus autoComplete="username" value={form.userName}
                onChange={(e) => setForm({ ...form, userName: e.target.value })} />
              <PasswordField label="Password" autoComplete="current-password" value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })} />
              <Button type="submit" variant="contained" size="large" disabled={busy}>Sign in</Button>
              <Typography variant="body2" color="text.secondary">
                Forgot your password? Ask the system administrator to reset it.
              </Typography>
            </Stack>
          </Box>
        )}

        {mode === "setup" && (
          <Box component="form" onSubmit={createAdmin} noValidate>
            <Stack spacing={2}>
              <Typography variant="body2" color="text.secondary">
                The system has no users yet. The administrator then adds everyone else from the Users page.
              </Typography>
              <TextField label="Full name" value={admin.name} onChange={setA("name")} error={!!aErr("name")} helperText={aErr("name")} />
              <Box sx={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 2 }}>
                <TextField label="Employee ID" value={admin.employeeID} onChange={setA("employeeID")} error={!!aErr("employeeID")} helperText={aErr("employeeID")} />
                <TextField label="Username" autoComplete="username" value={admin.userName} onChange={setA("userName")} error={!!aErr("userName")} helperText={aErr("userName")} />
              </Box>
              <PasswordField label="Password" autoComplete="new-password" value={admin.password} onChange={setA("password")}
                error={!!aErr("password")} helperText={aErr("password") || undefined} />
              <PasswordField label="Confirm password" autoComplete="new-password" value={admin.confirm} onChange={setA("confirm")}
                error={!!aErr("confirm")} helperText={aErr("confirm")} />
              <Button type="submit" variant="contained" size="large" disabled={busy}>Create administrator</Button>
            </Stack>
          </Box>
        )}
      </Paper>
      </Box>
    </Box>
  );
}
