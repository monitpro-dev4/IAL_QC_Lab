import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Alert, Box, ButtonBase, Paper, Skeleton, Typography } from "@mui/material";
import { PieChart } from "@mui/x-charts/PieChart";
import { BarChart } from "@mui/x-charts/BarChart";
import { LineChart } from "@mui/x-charts/LineChart";
import { useAuth } from "../auth/AuthContext";
import { getDocuments } from "../api/documentApi";
import { getDashboard } from "../api/dashboardApi";
import { colors } from "../theme";

/*
 * Document Management dashboard, built from the workflow:
 *   Upload (Lab Chemist) -> Under Review (Lab Supervisor) -> Under Approval (Lab Manager) -> Approved
 *   (+ Rejected, Archived, Cancelled)
 * Document staff see every document; employees see approved documents only.
 * On large screens it fits one screen (no page scroll).
 */

const BLUE = "#2F5FA7";
const GREY = "#7C8798";
const LIGHT_GREY = "#B8C0CC";
const STATUS = [
  { key: "Approved", label: "Approved", color: colors.green },
  { key: "Submitted", label: "Under Review", color: colors.amber },
  { key: "Supervisor Approved", label: "Under Approval", color: BLUE },
  { key: "Rejected", label: "Rejected", color: colors.red },
  { key: "Archived", label: "Archived", color: GREY },
  { key: "Cancelled", label: "Cancelled", color: LIGHT_GREY },
];
const PIE_COLORS = [colors.teal, BLUE, colors.amber, colors.green, "#8E5CB5", "#C2563A", "#3A9BB0", "#7A8B2E", GREY, "#B0477A", "#5E6AD2", LIGHT_GREY];
const INACTIVE = ["Archived", "Cancelled"];

const short = (s, n = 18) => (s && s.length > n ? `${s.slice(0, n - 1)}…` : s);

/** Count rows by a field, largest first; empty values grouped as "Not set". */
const groupBy = (rows, key) => {
  const map = new Map();
  rows.forEach((r) => { const k = r[key] || "Not set"; map.set(k, (map.get(k) || 0) + 1); });
  return [...map.entries()].map(([label, value]) => ({ label, value })).sort((a, b) => b.value - a.value);
};

/** Measures the space a chart can fill. */
function useSize() {
  const ref = useRef(null);
  const [size, setSize] = useState({ width: 0, height: 0 });
  useLayoutEffect(() => {
    const ro = new ResizeObserver(([e]) => setSize({ width: Math.floor(e.contentRect.width), height: Math.floor(e.contentRect.height) }));
    ro.observe(ref.current);
    return () => ro.disconnect();
  }, []);
  return [ref, size];
}

/** Small legend: coloured dot, label and (optionally) the value. */
function Legend({ items, vertical }) {
  return (
    <Box sx={{ display: "flex", flexDirection: vertical ? "column" : "row", flexWrap: vertical ? "nowrap" : "wrap", columnGap: 1.5, rowGap: vertical ? 0.75 : 0.25, minWidth: 0 }}>
      {items.map((i) => (
        <Box key={i.label} title={i.label} sx={{ display: "flex", alignItems: "center", gap: 0.75, minWidth: 0 }}>
          <Box sx={{ width: 9, height: 9, borderRadius: "50%", bgcolor: i.color, flexShrink: 0 }} />
          <Typography variant="caption" noWrap sx={{ color: "text.secondary", flexGrow: vertical ? 1 : 0, minWidth: 0 }}>{i.label}</Typography>
          {i.value != null && <Typography variant="caption" sx={{ fontWeight: 700 }}>{i.value}</Typography>}
        </Box>
      ))}
    </Box>
  );
}

function ChartPanel({ title, subtitle, legend, empty, children }) {
  const [ref, size] = useSize();
  return (
    <Paper sx={{ p: 2, display: "flex", flexDirection: "column", minHeight: 0, minWidth: 0 }}>
      <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 0.75, minWidth: 0 }}>
        <Typography noWrap sx={{ fontWeight: 700, fontSize: "0.9375rem", flexShrink: 0 }}>{title}</Typography>
        {subtitle && <Typography variant="caption" color="text.secondary" noWrap sx={{ flexGrow: 1, minWidth: 0 }}>{subtitle}</Typography>}
      </Box>
      {legend && <Box sx={{ mt: -0.25, mb: 0.75 }}><Legend items={legend} /></Box>}
      {/* The chart is drawn inside an absolutely positioned box, so its size never feeds back into the measured space */}
      <Box ref={ref} sx={{ flex: 1, minHeight: 0, height: { xs: 220, lg: "auto" }, position: "relative" }}>
        <Box sx={{ position: "absolute", inset: 0, overflow: "hidden" }}>
          {empty ? (
            <Typography variant="body2" color="text.secondary" sx={{ height: "100%", display: "grid", placeItems: "center" }}>
              No data yet
            </Typography>
          ) : size.height > 40 && size.width > 40 && children(size)}
        </Box>
      </Box>
    </Paper>
  );
}

function Card({ label, value, hint, color, to }) {
  const navigate = useNavigate();
  return (
    <Paper sx={{ p: 0, overflow: "hidden", borderTop: `3px solid ${color}` }}>
      <ButtonBase onClick={to ? () => navigate(to) : undefined} disabled={!to} aria-label={`${label}: ${value}`}
        sx={{ width: "100%", px: 2, py: 1.5, display: "block", textAlign: "left", "&:hover": { bgcolor: to ? "#FAFBFC" : undefined } }}>
        <Typography sx={{ fontSize: "0.75rem", fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase", color: "text.secondary" }}>{label}</Typography>
        <Typography sx={{ fontSize: "1.875rem", fontWeight: 700, lineHeight: 1.2, letterSpacing: "-0.02em" }}>{value}</Typography>
        <Typography variant="body2" color="text.secondary" noWrap>{hint}</Typography>
      </ButtonBase>
    </Paper>
  );
}

/** Donut on the left, its legend (label + count) on the right. */
function Donut({ data, size }) {
  const items = data.map((d, i) => ({ ...d, color: d.color || PIE_COLORS[i % PIE_COLORS.length] }));
  const d = Math.min(size.height, Math.floor(size.width * 0.5));
  return (
    <Box sx={{ display: "flex", alignItems: "center", gap: 2, height: "100%" }}>
      <PieChart
        width={d}
        height={d}
        hideLegend
        margin={{ top: 2, bottom: 2, left: 2, right: 2 }}
        series={[{
          data: items.filter((x) => x.value).map((x) => ({ id: x.label, label: x.label, value: x.value, color: x.color })),
          innerRadius: d * 0.27, outerRadius: d / 2 - 4, paddingAngle: 1.5, cornerRadius: 3,
          highlightScope: { fade: "global", highlight: "item" },
        }]}
      />
      <Box sx={{ flex: 1, minWidth: 0, maxHeight: "100%", overflowY: "auto", pr: 0.5 }}>
        <Legend vertical items={items} />
      </Box>
    </Box>
  );
}

function HorizontalBars({ data, color, size }) {
  return (
    <BarChart
      layout="horizontal"
      width={size.width}
      height={size.height}
      dataset={data}
      yAxis={[{ scaleType: "band", dataKey: "label", width: 120, valueFormatter: (v) => short(v), tickLabelStyle: { fontSize: 11 } }]}
      xAxis={[{ tickMinStep: 1, tickLabelStyle: { fontSize: 11 } }]}
      series={[{ dataKey: "value", label: "Documents", color }]}
      hideLegend
      borderRadius={4}
      margin={{ top: 4, bottom: 0, left: 0, right: 12 }}
      grid={{ vertical: true }}
    />
  );
}

export default function DocumentDashboard() {
  const { canEditDocuments } = useAuth();
  const [rows, setRows] = useState(null);
  const [summary, setSummary] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    Promise.all([getDocuments({ approvedOnly: !canEditDocuments }), getDashboard()])
      .then(([list, dash]) => { setRows(list); setSummary(dash); })
      .catch((e) => setError(e.message));
  }, [canEditDocuments]);

  if (error) return <Alert severity="error">{error}</Alert>;
  const loading = !rows || !summary;
  const all = rows || [];
  const active = all.filter((r) => !INACTIVE.includes(r.versionStatus));
  const count = (...s) => all.filter((r) => s.includes(r.versionStatus)).length;
  const review = count("Submitted"), approval = count("Supervisor Approved"), rejected = count("Rejected");
  const months = (summary?.months || []).map((m) => ({ ...m, label: new Date(m.monthStart).toLocaleString("en-GB", { month: "short" }) }));
  const thisMonth = months.length ? months[months.length - 1].approved : 0;

  const cards = canEditDocuments ? [
    // Total = every document; the other four cards add up to it
    { key: "total", label: "Total documents", value: all.length, color: colors.teal, to: "/documents",
      hint: "All statuses" },
    { key: "pending", label: "Pending approval", value: review + approval, color: colors.amber, to: "/documents",
      hint: `Review ${review} · Approval ${approval}` },
    { key: "approved", label: "Approved", value: count("Approved"), color: colors.green, to: "/documents?status=Approved",
      hint: `${thisMonth} approved this month` },
    { key: "rejected", label: "Rejected", value: rejected, color: colors.red, to: "/documents?status=Rejected",
      hint: "Sent back for revision" },
    { key: "archived", label: "Archived / Cancelled", value: count("Archived", "Cancelled"), color: GREY, to: "/documents?tab=archived",
      hint: `${count("Archived")} archived · ${count("Cancelled")} cancelled` },
  ] : [
    { key: "approved", label: "Approved documents", value: all.length, color: colors.green, to: "/documents", hint: "Current versions in use" },
    { key: "month", label: "Approved this month", value: thisMonth, color: colors.teal, to: "/documents", hint: "Newly issued or revised" },
    { key: "cats", label: "Categories", value: new Set(all.map((r) => r.categoryName).filter(Boolean)).size, color: colors.amber, hint: "With approved documents" },
    { key: "depts", label: "Departments", value: new Set(all.map((r) => r.department).filter(Boolean)).size, color: BLUE, hint: "With approved documents" },
  ];

  // Every status is listed (0 included); only non-zero ones get a slice
  const statusData = STATUS.map((s) => ({ ...s, value: count(s.key) }));
  const pipeline = [
    { label: "Under Review", sub: "Lab Supervisor", value: review, color: colors.amber },
    { label: "Under Approval", sub: "Lab Manager", value: approval, color: BLUE },
    { label: "Rejected", sub: "Back to chemist", value: rejected, color: colors.red },
  ];
  const byCategory = groupBy(active, "categoryName");
  const byDepartment = groupBy(active, "department");
  const byPlant = groupBy(active, "plantArea");

  const trendSeries = [
    ...(canEditDocuments ? [{ key: "uploaded", label: "Uploaded", color: colors.teal }] : []),
    { key: "approved", label: "Approved", color: colors.green },
    ...(canEditDocuments ? [{ key: "rejected", label: "Rejected", color: colors.red }] : []),
  ];
  const trend = (
    <ChartPanel key="trend" title="Monthly activity" subtitle="Last 6 months" legend={trendSeries} empty={!months.length}>
      {(size) => (
        <LineChart
          width={size.width}
          height={size.height}
          xAxis={[{ scaleType: "point", data: months.map((m) => m.label), tickLabelStyle: { fontSize: 11 } }]}
          yAxis={[{ tickMinStep: 1, width: 28, tickLabelStyle: { fontSize: 11 } }]}
          series={trendSeries.map((s) => ({ data: months.map((m) => m[s.key]), label: s.label, color: s.color, curve: "linear", showMark: true }))}
          hideLegend
          margin={{ top: 8, bottom: 0, left: 0, right: 12 }}
          grid={{ horizontal: true }}
        />
      )}
    </ChartPanel>
  );
  const category = (
    <ChartPanel key="cat" title="By category" empty={!byCategory.length}>
      {(size) => <HorizontalBars data={byCategory} color={colors.teal} size={size} />}
    </ChartPanel>
  );
  const department = (
    <ChartPanel key="dept" title="By department" empty={!byDepartment.length}>
      {(size) => <HorizontalBars data={byDepartment} color={BLUE} size={size} />}
    </ChartPanel>
  );
  const plant = (
    <ChartPanel key="plant" title="By plant / area" empty={!byPlant.length}>
      {(size) => <Donut data={byPlant} size={size} />}
    </ChartPanel>
  );

  const charts = canEditDocuments ? [
    <ChartPanel key="status" title="Documents by status" empty={!all.length}>
      {(size) => <Donut data={statusData} size={size} />}
    </ChartPanel>,
    <ChartPanel key="pipeline" title="Approval pipeline" subtitle="Where documents are waiting">
      {(size) => (
        <BarChart
          width={size.width}
          height={size.height}
          dataset={pipeline}
          xAxis={[{ scaleType: "band", dataKey: "label", tickLabelStyle: { fontSize: 11 },
            colorMap: { type: "ordinal", values: pipeline.map((p) => p.label), colors: pipeline.map((p) => p.color) } }]}
          yAxis={[{ tickMinStep: 1, width: 28, tickLabelStyle: { fontSize: 11 } }]}
          series={[{ dataKey: "value", label: "Documents", valueFormatter: (v, { dataIndex }) => `${v} (${pipeline[dataIndex].sub})` }]}
          hideLegend
          borderRadius={6}
          margin={{ top: 8, bottom: 0, left: 0, right: 8 }}
          grid={{ horizontal: true }}
        />
      )}
    </ChartPanel>,
    category,
    trend,
    department,
    plant,
  ] : [category, department, plant, trend];

  return (
    <Box sx={{ display: { lg: "flex" }, flexDirection: "column", flex: 1, minHeight: 0 }}>
      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr", md: "repeat(3, 1fr)", lg: `repeat(${cards.length || 4}, 1fr)` }, gap: 2, mb: 2, flexShrink: 0 }}>
        {loading
          ? [0, 1, 2, 3].map((i) => <Skeleton key={i} variant="rounded" height={92} sx={{ borderRadius: 3.5 }} />)
          : cards.map(({ key, ...c }) => <Card key={key} {...c} />)}
      </Box>
      <Box sx={{ display: "grid", gap: 2, flex: 1, minHeight: 0,
        gridTemplateColumns: { xs: "1fr", md: "1fr 1fr", lg: canEditDocuments ? "repeat(3, 1fr)" : "repeat(2, 1fr)" },
        gridTemplateRows: { lg: "repeat(2, minmax(0, 1fr))" } }}>
        {loading
          ? Array.from({ length: canEditDocuments ? 6 : 4 }, (_, i) => <Skeleton key={i} variant="rounded" sx={{ borderRadius: 3.5, height: { xs: 260, lg: "100%" } }} />)
          : charts}
      </Box>
    </Box>
  );
}
