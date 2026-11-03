import { createTheme } from "@mui/material/styles";

// Dark navy sidebar, light content, white rounded cards with soft shadows.
// One colour per meaning: teal = actions, amber = in progress,
// green = approved, red = rejected.
export const colors = {
  ink: "#0F172A",
  inkSoft: "#5B6475",
  inkMuted: "#8A93A3",
  paper: "#F3F5F9",
  line: "#E6E9EF",
  navy: "#0D1B2A",
  navySoft: "#16273A",
  navyText: "#A9B6C7",
  teal: "#0E7C76",
  tealBright: "#2CC5B8",
  tealTint: "#E3F4F2",
  amber: "#B7791F",
  amberTint: "#FBF1E1",
  green: "#2F7D4F",
  greenTint: "#E4F3EA",
  red: "#B3261E",
  redTint: "#FBE8E6",
};

export const shadow = {
  card: "0 1px 2px rgba(15, 23, 42, 0.04), 0 2px 8px rgba(15, 23, 42, 0.05)",
  raised: "0 8px 24px rgba(15, 23, 42, 0.10)",
};

const font = '"Plus Jakarta Sans", system-ui, -apple-system, "Segoe UI", sans-serif';

const theme = createTheme({
  palette: {
    primary: { main: colors.teal, contrastText: "#fff" },
    warning: { main: colors.amber },
    success: { main: colors.green },
    error: { main: colors.red },
    text: { primary: colors.ink, secondary: colors.inkSoft },
    background: { default: colors.paper, paper: "#FFFFFF" },
    divider: colors.line,
  },
  typography: {
    fontFamily: font,
    h1: { fontSize: "1.625rem", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.25 },
    h2: { fontSize: "1.125rem", fontWeight: 700, letterSpacing: "-0.01em" },
    h3: { fontSize: "1rem", fontWeight: 600 },
    body1: { fontSize: "0.9375rem", lineHeight: 1.6 },
    body2: { fontSize: "0.875rem", lineHeight: 1.55 },
    button: { textTransform: "none", fontWeight: 600, letterSpacing: 0 },
  },
  shape: { borderRadius: 10 },
  components: {
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: { borderRadius: 10, paddingInline: 16 },
        sizeSmall: { borderRadius: 8, paddingInline: 10 },
        sizeLarge: { paddingBlock: 10 },
      },
    },
    MuiPaper: {
      defaultProps: { elevation: 0 },
      styleOverrides: { root: { borderRadius: 14, boxShadow: shadow.card, border: `1px solid ${colors.line}` } },
    },
    MuiDialog: { styleOverrides: { paper: { borderRadius: 16, boxShadow: shadow.raised, border: "none" } } },
    MuiMenu: { styleOverrides: { paper: { borderRadius: 12, boxShadow: shadow.raised } } },
    MuiOutlinedInput: {
      styleOverrides: {
        root: { borderRadius: 10, backgroundColor: "#fff" },
        notchedOutline: { borderColor: "#D9DEE7" },
      },
    },
    MuiTextField: { defaultProps: { size: "small" } },
    MuiSelect: { defaultProps: { size: "small" } },
    MuiChip: { styleOverrides: { root: { fontWeight: 600, borderRadius: 8 } } },
    MuiTab: { styleOverrides: { root: { textTransform: "none", fontWeight: 600, minHeight: 48 } } },
    MuiAlert: { styleOverrides: { root: { borderRadius: 12 } } },
    MuiDataGrid: {
      styleOverrides: {
        root: {
          border: "none",
          "--DataGrid-containerBackground": "#F8FAFC",
          "& .MuiDataGrid-columnHeaderTitle": { fontWeight: 700, color: colors.inkSoft, fontSize: "0.8125rem" },
          "& .MuiDataGrid-row:hover": { backgroundColor: "#F6FAFA" },
          "& .MuiDataGrid-cell:focus, & .MuiDataGrid-cell:focus-within, & .MuiDataGrid-columnHeader:focus": { outline: "none" },
        },
      },
    },
  },
});

export default theme;
