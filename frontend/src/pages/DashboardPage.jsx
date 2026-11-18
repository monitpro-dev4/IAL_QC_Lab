import { useSearchParams } from "react-router-dom";
import { Box, Button, Paper, Typography } from "@mui/material";
import { useAuth } from "../auth/AuthContext";
import { MODULES } from "../modules";
import ModuleIcon from "../components/ModuleIcon";
import DocumentDashboard from "../components/DocumentDashboard";
import { fmtDate } from "../format";

const greeting = () => {
  const h = new Date().getHours();
  return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
};
const weekday = new Intl.DateTimeFormat("en-GB", { weekday: "long" });

// Dashboard tabs, one per module. Modules still being built show a short message;
// Document Management shows its charts dashboard.
const TABS = MODULES;

/** Dashboard tab for a module that is not built yet. */
function ModuleComingSoon({ module }) {
  return (
    <Paper sx={{ p: { xs: 3, md: 4 }, display: "flex", gap: 2.5, alignItems: "center", flexWrap: "wrap" }}>
      <ModuleIcon moduleKey={module.key} tone={module.tone} size={52} />
      <Box sx={{ flex: 1, minWidth: 240 }}>
        <Typography variant="h2" sx={{ mb: 0.5 }}>{module.name} is being built</Typography>
        <Typography color="text.secondary">This module is under development. Its dashboard will appear here once it's ready.</Typography>
      </Box>
    </Paper>
  );
}

export default function DashboardPage() {
  const { user } = useAuth();
  const [params, setParams] = useSearchParams();
  const tab = TABS.some((m) => m.key === params.get("tab")) ? params.get("tab") : TABS[0].key;
  const module = TABS.find((m) => m.key === tab);
  const firstName = user.name.split(/\s+/)[0];

  // On large screens the dashboard fits the window (no page scroll)
  return (
    <Box sx={{ display: { lg: "flex" }, flexDirection: "column", height: { lg: "calc(100vh - 48px)" } }}>
      <Box sx={{ display: "flex", alignItems: { xs: "flex-start", sm: "flex-end" }, gap: 2, mb: 2, flexWrap: "wrap", flexShrink: 0 }}>
        <Box sx={{ flexGrow: 1 }}>
          <Typography color="text.secondary" sx={{ mb: 0.5 }}>{weekday.format(new Date())}, {fmtDate(new Date())}</Typography>
          <Typography variant="h1" sx={{ fontSize: { xs: "1.625rem", md: "2rem" } }}>{greeting()}, {firstName}</Typography>
        </Box>
      </Box>

      <Paper sx={{ display: "flex", alignItems: "center", gap: 1, p: 1.25, mb: 2, flexWrap: "wrap", flexShrink: 0 }}>
        <Box role="tablist" aria-label="Dashboards" sx={{ display: "flex", gap: 1, flexWrap: "wrap" }}>
          {TABS.map((m) => (
            <Button key={m.key} role="tab" aria-selected={tab === m.key}
              variant={tab === m.key ? "contained" : "text"} color={tab === m.key ? "primary" : "inherit"}
              onClick={() => setParams(m.key === TABS[0].key ? {} : { tab: m.key }, { replace: true })}
              sx={{ borderRadius: 2, px: 2, fontWeight: 600, color: tab === m.key ? undefined : "text.secondary" }}>
              {m.name}
            </Button>
          ))}
        </Box>
      </Paper>

      {module && !module.ready && <ModuleComingSoon module={module} />}
      {tab === "documents" && <DocumentDashboard />}
    </Box>
  );
}
