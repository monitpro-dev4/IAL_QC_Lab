import { Box, Typography } from "@mui/material";
import CheckIcon from "@mui/icons-material/Check";
import CloseIcon from "@mui/icons-material/Close";
import { colors } from "../theme";

// The four steps every revision passes through, in order.
const STEPS = [
  { key: "Draft", label: "Draft", hint: "Chemist" },
  { key: "Submitted", label: "Submitted", hint: "Lab Supervisor reviews" },
  { key: "Supervisor Approved", label: "Supervisor approved", hint: "Lab Manager approves" },
  { key: "Approved", label: "Approved", hint: "Current version" },
];

/** status: the revision's status name. Rejected shows on the Draft step, as it goes back to the chemist. */
export default function ApprovalTrack({ status }) {
  const rejected = status === "Rejected";
  const current = rejected ? 0 : Math.max(0, STEPS.findIndex((s) => s.key === status));

  return (
    <Box
      component="ol"
      aria-label="Approval progress"
      sx={{ listStyle: "none", m: 0, p: 0, display: "grid", gridTemplateColumns: { xs: "1fr", sm: "repeat(4, 1fr)" }, gap: { xs: 1.5, sm: 0 } }}
    >
      {STEPS.map((s, i) => {
        const done = i < current || (status === "Approved" && i === current);
        const here = i === current && status !== "Approved";
        const bad = rejected && i === 0;
        const color = bad ? colors.red : done ? colors.green : here ? colors.amber : colors.line;
        return (
          <Box component="li" key={s.key} aria-current={here ? "step" : undefined} sx={{ position: "relative", display: "flex", flexDirection: { xs: "row", sm: "column" }, alignItems: { xs: "center", sm: "flex-start" }, gap: 1.25 }}>
            <Box sx={{ display: "flex", alignItems: "center", width: { sm: "100%" } }}>
              <Box sx={{
                width: 26, height: 26, borderRadius: "50%", flexShrink: 0, display: "grid", placeItems: "center",
                bgcolor: done || bad ? color : "#fff", border: `2px solid ${color}`, color: "#fff", fontSize: 13, fontWeight: 600,
              }}>
                {bad ? <CloseIcon sx={{ fontSize: 16 }} /> : done ? <CheckIcon sx={{ fontSize: 16 }} /> : <Box component="span" sx={{ color: here ? colors.amber : colors.inkSoft }}>{i + 1}</Box>}
              </Box>
              {i < STEPS.length - 1 && (
                <Box sx={{ display: { xs: "none", sm: "block" }, flexGrow: 1, height: 2, mx: 1, bgcolor: i < current || status === "Approved" ? colors.green : colors.line }} />
              )}
            </Box>
            <Box sx={{ pr: 1 }}>
              <Typography variant="body2" sx={{ fontWeight: here || bad ? 600 : 500, color: bad ? colors.red : colors.ink }}>
                {bad ? "Rejected — back to draft" : s.label}
              </Typography>
              <Typography variant="body2" color="text.secondary">{s.hint}</Typography>
            </Box>
          </Box>
        );
      })}
    </Box>
  );
}
