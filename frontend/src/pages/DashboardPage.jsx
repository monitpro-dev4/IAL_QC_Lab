import { useEffect, useState } from "react";
import { Link as RouterLink, useNavigate } from "react-router-dom";
import { Alert, Box, Button, ButtonBase, Paper, Skeleton, Tooltip, Typography } from "@mui/material";
import DescriptionOutlined from "@mui/icons-material/DescriptionOutlined";
import FactCheckOutlined from "@mui/icons-material/FactCheckOutlined";
import HourglassTopOutlined from "@mui/icons-material/HourglassTopOutlined";
import ReplayOutlined from "@mui/icons-material/ReplayOutlined";
import EditNoteOutlined from "@mui/icons-material/EditNoteOutlined";
import VerifiedOutlined from "@mui/icons-material/VerifiedOutlined";
import AddIcon from "@mui/icons-material/Add";
import ArrowForward from "@mui/icons-material/ArrowForward";
import { useAuth } from "../auth/AuthContext";
import { getDashboard } from "../api/dashboardApi";
import { MODULES } from "../modules";
import ModuleIcon from "../components/ModuleIcon";
import AddDocumentDialog from "../components/AddDocumentDialog";
import { fmtDateTime } from "../format";
import { colors } from "../theme";

const greeting = () => {
  const h = new Date().getHours();
  return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
};
const today = new Intl.DateTimeFormat("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" });

/** A number the user can act on; clicking goes to the matching list. */
function StatCard({ label, value, hint, icon, tone, to }) {
  const navigate = useNavigate();
  return (
    <Paper sx={{ p: 0, overflow: "hidden" }}>
      <ButtonBase
        onClick={() => navigate(to)}
        sx={{ width: "100%", p: 2.5, display: "flex", alignItems: "flex-start", gap: 2, textAlign: "left", justifyContent: "flex-start",
          "&:hover": { bgcolor: "#FAFBFC" } }}
      >
        <Box sx={{ width: 44, height: 44, borderRadius: 3, bgcolor: tone.bg, color: tone.fg, display: "grid", placeItems: "center", flexShrink: 0 }}>
          {icon}
        </Box>
        <Box sx={{ minWidth: 0 }}>
          <Typography sx={{ fontSize: "1.875rem", fontWeight: 700, lineHeight: 1.1, letterSpacing: "-0.02em" }}>{value}</Typography>
          <Typography sx={{ fontWeight: 600, mt: 0.5 }}>{label}</Typography>
          {hint && <Typography variant="body2" color="text.secondary">{hint}</Typography>}
        </Box>
      </ButtonBase>
    </Paper>
  );
}

/** One tile per module: its headline number, or "Being built". */
function ModuleTile({ module, line, value }) {
  const navigate = useNavigate();
  return (
    <Paper sx={{ p: 0, overflow: "hidden" }}>
      <ButtonBase
        onClick={() => navigate(module.path)}
        aria-label={`Open ${module.name}`}
        sx={{ width: "100%", p: 2.25, display: "flex", alignItems: "center", gap: 2, textAlign: "left", justifyContent: "flex-start", "&:hover": { bgcolor: "#FAFBFC" } }}
      >
        <ModuleIcon moduleKey={module.key} tone={module.tone} size={44} />
        <Box sx={{ minWidth: 0, flexGrow: 1 }}>
          <Typography sx={{ fontWeight: 700 }}>{module.name}</Typography>
          <Typography variant="body2" color="text.secondary" noWrap>
            {module.ready ? line : "Being built"}
          </Typography>
        </Box>
        {module.ready && value != null && (
          <Typography sx={{ fontSize: "1.5rem", fontWeight: 700, letterSpacing: "-0.02em" }}>{value}</Typography>
        )}
        <ArrowForward sx={{ fontSize: 18, color: module.ready ? colors.teal : colors.inkMuted }} />
      </ButtonBase>
    </Paper>
  );
}

const ACTION_TEXT = (a) => {
  if (a.actionType === "Approved") return a.approvalLevel === 2 ? "approved and issued" : "approved as supervisor";
  return { Created: "added", Updated: "revised", Submitted: "sent for approval", Rejected: "rejected", Superseded: "replaced" }[a.actionType] || a.actionType.toLowerCase();
};
const ACTION_TONE = (a) =>
  a.actionType === "Rejected" ? colors.red
    : a.actionType === "Approved" && a.approvalLevel === 2 ? colors.green
    : a.actionType === "Approved" || a.actionType === "Submitted" ? colors.amber
    : colors.inkMuted;

export default function DashboardPage() {
  const { user, canEditDocuments, canViewDrafts, isSupervisor, isManager } = useAuth();
  const [data, setData] = useState(null);
  const [error, setError] = useState("");
  const [adding, setAdding] = useState(false);
  const navigate = useNavigate();
  const approver = isSupervisor || isManager;

  useEffect(() => { getDashboard().then(setData).catch((e) => setError(e.message)); }, []);

  const c = data?.counts;
  const firstName = user.name.split(/\s+/)[0];
  const maxCat = Math.max(1, ...(data?.categories || []).map((x) => x.documents));

  const cards = !c ? [] : [
    { key: "approved", label: "Approved documents", value: c.approvedDocuments, hint: `${c.approvedLast30Days} issued in the last 30 days`,
      icon: <DescriptionOutlined />, tone: { fg: colors.green, bg: colors.greenTint }, to: "/documents", show: true },
    { key: "waiting", label: "Waiting for you", value: c.waitingForMe, hint: c.waitingForMe ? "Needs your review" : "You're all caught up",
      icon: <FactCheckOutlined />, tone: { fg: colors.amber, bg: colors.amberTint }, to: "/documents", show: approver },
    { key: "mine", label: "My open revisions", value: c.myOpenRevisions, hint: c.myRejected ? `${c.myRejected} sent back to you` : "Drafts and in review",
      icon: <EditNoteOutlined />, tone: { fg: colors.teal, bg: colors.tealTint }, to: "/documents", show: canEditDocuments && !approver },
    { key: "review", label: "In review", value: c.inReview, hint: `${c.drafts} more in draft`,
      icon: <HourglassTopOutlined />, tone: { fg: colors.amber, bg: colors.amberTint }, to: "/documents", show: canViewDrafts },
    { key: "rejected", label: "Sent back", value: c.rejected, hint: "Rejected, waiting for revision",
      icon: <ReplayOutlined />, tone: { fg: colors.red, bg: colors.redTint }, to: "/documents", show: canViewDrafts },
    { key: "recent", label: "Issued this month", value: c.approvedLast30Days, hint: "Approved in the last 30 days",
      icon: <VerifiedOutlined />, tone: { fg: colors.teal, bg: colors.tealTint }, to: "/documents", show: !canViewDrafts },
  ].filter((x) => x.show).slice(0, 4);

  return (
    <>
      <Box sx={{ display: "flex", alignItems: { xs: "flex-start", sm: "flex-end" }, gap: 2, mb: 3.5, flexWrap: "wrap" }}>
        <Box sx={{ flexGrow: 1 }}>
          <Typography color="text.secondary" sx={{ mb: 0.5 }}>{today.format(new Date())}</Typography>
          <Typography variant="h1" sx={{ fontSize: { xs: "1.625rem", md: "2rem" } }}>{greeting()}, {firstName}</Typography>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", md: "repeat(3, 1fr)" }, gap: 2, mb: 4.5 }}>
        {MODULES.map((m) => (
          <ModuleTile
            key={m.key}
            module={m}
            value={m.key === "documents" ? c?.approvedDocuments : null}
            line={m.key === "documents" ? (c ? "Approved documents" : "Loading") : ""}
          />
        ))}
      </Box>

      <Box sx={{ display: "flex", alignItems: "center", gap: 1.5, mb: 2 }}>
        <ModuleIcon moduleKey="documents" tone="teal" size={32} />
        <Typography variant="h2" sx={{ flexGrow: 1 }}>Document Management</Typography>
        <Button size="small" component={RouterLink} to="/documents" endIcon={<ArrowForward />}>Open documents</Button>
        {canEditDocuments && (
          <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => setAdding(true)}>Add document</Button>
        )}
      </Box>

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr", lg: `repeat(${Math.max(cards.length, 2)}, 1fr)` }, gap: 2, mb: 3 }}>
        {!c && [0, 1, 2, 3].map((i) => <Skeleton key={i} variant="rounded" height={112} sx={{ borderRadius: 3.5 }} />)}
        {cards.map(({ key, ...card }) => <StatCard key={key} {...card} />)}
      </Box>

      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", lg: "1.6fr 1fr" }, gap: 2, alignItems: "start" }}>
        <Paper sx={{ p: { xs: 2, sm: 3 } }}>
          <Box sx={{ display: "flex", alignItems: "center", mb: 2 }}>
            <Typography variant="h2" sx={{ flexGrow: 1 }}>Recent activity</Typography>
            <Button size="small" component={RouterLink} to="/documents">All documents</Button>
          </Box>
          {!data && [0, 1, 2, 3].map((i) => <Skeleton key={i} height={48} />)}
          {data && data.activity.length === 0 && (
            <Typography color="text.secondary" sx={{ py: 4, textAlign: "center" }}>
              Nothing yet. Activity appears here as documents are added and approved.
            </Typography>
          )}
          <Box component="ol" sx={{ listStyle: "none", m: 0, p: 0 }}>
            {data?.activity.map((a, i) => (
              <Box component="li" key={a.logID} sx={{ display: "flex", gap: 1.75, position: "relative", pb: i < data.activity.length - 1 ? 2.25 : 0 }}>
                <Box sx={{ position: "relative", flexShrink: 0, width: 12, display: "flex", justifyContent: "center" }}>
                  <Box sx={{ width: 10, height: 10, borderRadius: "50%", bgcolor: ACTION_TONE(a), mt: 0.75, zIndex: 1, boxShadow: "0 0 0 4px #fff" }} />
                  {i < data.activity.length - 1 && <Box sx={{ position: "absolute", top: 14, bottom: -6, width: 2, bgcolor: colors.line }} />}
                </Box>
                <Box sx={{ minWidth: 0 }}>
                  <Typography variant="body2">
                    <strong>{a.actionBy}</strong> {ACTION_TEXT(a)}{" "}
                    <Box component={RouterLink} to={`/documents/${a.documentID}`} sx={{ color: colors.teal, fontWeight: 600, textDecoration: "none", "&:hover": { textDecoration: "underline" } }}>
                      {a.documentNumber}
                    </Box>{" "}
                    rev {a.revisionNo}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" noWrap>{a.title}, {fmtDateTime(a.actionOn)}</Typography>
                </Box>
              </Box>
            ))}
          </Box>
        </Paper>

        <Paper sx={{ p: { xs: 2, sm: 3 } }}>
          <Typography variant="h2" sx={{ mb: 0.5 }}>Approved documents by category</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2.5 }}>Current versions only</Typography>
          {!data && [0, 1, 2, 3].map((i) => <Skeleton key={i} height={36} />)}
          <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
            {data?.categories.map((cat) => (
              <Tooltip key={cat.categoryID} title={`${cat.categoryName}: ${cat.documents} approved`} placement="top" arrow>
                <Box sx={{ display: "block" }}>
                  <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.75 }}>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>{cat.categoryName}</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>{cat.documents}</Typography>
                  </Box>
                  <Box sx={{ height: 8, borderRadius: 4, bgcolor: "#EEF1F5", overflow: "hidden" }}>
                    <Box className="bar" sx={{ height: "100%", width: `${(cat.documents / maxCat) * 100}%`, minWidth: cat.documents ? 8 : 0, bgcolor: colors.teal, borderRadius: 4 }} />
                  </Box>
                </Box>
              </Tooltip>
            ))}
          </Box>
        </Paper>
      </Box>
      <AddDocumentDialog open={adding} onClose={() => setAdding(false)} onAdded={() => navigate("/documents")} />
    </>
  );
}
