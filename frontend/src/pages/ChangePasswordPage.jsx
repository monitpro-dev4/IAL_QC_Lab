import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Alert, Box, Button, Paper, Stack, Typography } from "@mui/material";
import { useSnackbar } from "notistack";
import { useAuth } from "../auth/AuthContext";
import { changePassword, passwordProblem } from "../api/authApi";
import PasswordField from "../components/PasswordField";
import PageHeader from "../components/PageHeader";

export default function ChangePasswordPage() {
  const { user, passwordChanged, signOut } = useAuth();
  const navigate = useNavigate();
  const { enqueueSnackbar } = useSnackbar();
  const [f, setF] = useState({ current: "", next: "", confirm: "" });
  const [touched, setTouched] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const forced = user.mustChangePassword;

  const errors = {
    current: !f.current && "Enter your current password.",
    next: passwordProblem(f.next, user.userName) || (f.next && f.next === f.current && "Choose a new password, not the current one."),
    confirm: f.confirm !== f.next && "The passwords don't match.",
  };

  const save = async (e) => {
    e.preventDefault();
    setTouched(true);
    setError("");
    if (Object.values(errors).some(Boolean)) return;
    setBusy(true);
    try {
      await changePassword(f.current, f.next);
      passwordChanged();
      enqueueSnackbar("Password changed", { variant: "success" });
      navigate("/dashboard", { replace: true });
    } catch (err) {
      setError(err.message);
      setBusy(false);
    }
  };

  const err = (k) => (touched ? errors[k] : "");
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });

  return (
    <>
      <PageHeader title="Change password" subtitle={forced ? undefined : "Your other devices will be signed out."} />
      {forced && (
        <Alert severity="info" sx={{ mb: 3, maxWidth: 520 }}>
          You signed in with a temporary password. Choose your own password to continue.
        </Alert>
      )}
      <Paper sx={{ p: { xs: 2, sm: 3 }, maxWidth: 520 }}>
        <Box component="form" onSubmit={save} noValidate>
          <Stack spacing={2.25}>
            {error && <Alert severity="error">{error}</Alert>}
            <PasswordField label={forced ? "Temporary password" : "Current password"} autoComplete="current-password"
              value={f.current} onChange={set("current")} error={!!err("current")} helperText={err("current")} />
            <PasswordField label="New password" autoComplete="new-password" value={f.next} onChange={set("next")}
              error={!!err("next")} helperText={err("next") || undefined} />
            <PasswordField label="Confirm new password" autoComplete="new-password" value={f.confirm} onChange={set("confirm")}
              error={!!err("confirm")} helperText={err("confirm")} />
            <Box sx={{ display: "flex", gap: 1 }}>
              <Button type="submit" variant="contained" disabled={busy}>Change password</Button>
              {forced ? (
                <Button onClick={async () => { await signOut(); navigate("/signin"); }}>Sign out</Button>
              ) : (
                <Button onClick={() => navigate(-1)}>Cancel</Button>
              )}
            </Box>
          </Stack>
        </Box>
      </Paper>
      <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
        Signed in as {user.name} ({user.userName}).
      </Typography>
    </>
  );
}
