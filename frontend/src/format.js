const dateFmt = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" });
const dateTimeFmt = new Intl.DateTimeFormat("en-GB", {
  day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit",
});

export const fmtDate = (v) => (v ? dateFmt.format(new Date(v)) : "");
export const fmtDateTime = (v) => (v ? dateTimeFmt.format(new Date(v)) : "");
export const fmtSize = (kb) => (kb == null ? "" : kb >= 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${kb} KB`);

/**
 * Name for the "Approved by" column: the Lab Supervisor once they approve
 * (waiting for the manager), then the Lab Manager after final approval.
 * Nothing while it is still waiting for the supervisor or was rejected.
 */
export const approvedByName = (status, approvedBy, reviewedBy) =>
  status === "Approved" || status === "Superseded" ? approvedBy || ""
    : status === "Supervisor Approved" ? reviewedBy || ""
    : "";
