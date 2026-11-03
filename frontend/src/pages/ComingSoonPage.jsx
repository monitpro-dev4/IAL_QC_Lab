import { Link as RouterLink } from "react-router-dom";
import { Box, Button, Paper, Typography } from "@mui/material";
import { MODULES } from "../modules";
import ModuleIcon from "../components/ModuleIcon";

/** Placeholder for a module that is not built yet. */
export default function ComingSoonPage({ moduleKey }) {
  const m = MODULES.find((x) => x.key === moduleKey);
  return (
    <Paper sx={{ p: { xs: 3, md: 5 }, maxWidth: 720 }}>
      <ModuleIcon moduleKey={m.key} tone={m.tone} size={60} />
      <Typography variant="h1" sx={{ mt: 3, mb: 1 }}>{m.name}</Typography>
      <Typography color="text.secondary" sx={{ mb: 3 }}>{m.description}</Typography>
      <Box sx={{ p: 2.5, borderRadius: 3, bgcolor: "#F6F8FA" }}>
        <Typography sx={{ fontWeight: 600, mb: 0.5 }}>This module is being built</Typography>
        <Typography variant="body2" color="text.secondary">
          It will appear here once it's ready. Document Management is available now.
        </Typography>
      </Box>
      <Button variant="contained" component={RouterLink} to="/dashboard" sx={{ mt: 3 }}>Open Document Management</Button>
    </Paper>
  );
}
