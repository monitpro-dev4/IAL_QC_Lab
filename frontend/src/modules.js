// The three QMEX modules from the technical proposal, in display order.
// "ready: false" modules open a placeholder page until they are built.
export const MODULES = [
  {
    key: "samples",
    name: "Sample Request",
    description: "Register plant samples with a unique ID and label, track results, resamples and approvals.",
    path: "/sample-register",
    ready: false,
    tone: "amber",
  },
  {
    key: "calibration",
    name: "Calibration & PM",
    description: "Lab equipment calibration and preventive maintenance schedules, due-date alerts and escalation.",
    path: "/calibration",
    ready: false,
    tone: "blue",
  },
  {
    key: "documents",
    name: "Document Management",
    description: "SOPs and ISO documents with two-step approval, the current approved version, and full revision history.",
    path: "/dashboard",
    ready: true,
    tone: "teal",
  },
];
