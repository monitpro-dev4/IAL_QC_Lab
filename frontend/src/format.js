// One date format across the application: dd/mm/yyyy (time as 24-hour HH:mm)
const pad = (n) => String(n).padStart(2, "0");
const toDate = (v) => { const d = v instanceof Date ? v : new Date(v); return isNaN(d) ? null : d; };

/** dd/mm/yyyy */
export const fmtDate = (v) => {
  const d = v ? toDate(v) : null;
  return d ? `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}` : "";
};
/** dd/mm/yyyy HH:mm */
export const fmtDateTime = (v) => {
  const d = v ? toDate(v) : null;
  return d ? `${fmtDate(d)} ${pad(d.getHours())}:${pad(d.getMinutes())}` : "";
};
export const fmtSize = (kb) => (kb == null ? "" : kb >= 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${kb} KB`);

// A revision counts as approved once the Lab Manager signed it off (it may be Superseded later)
const wasApproved = (status, approvedBy) =>
  status === "Approved" || status === "Archived" || (status === "Superseded" && !!approvedBy);

/** "Reviewed by": the Lab Supervisor who approved it at step 1 (Under Approval, Approved). */
export const reviewedByName = (status, reviewedBy, approvedBy) =>
  status === "Supervisor Approved" || wasApproved(status, approvedBy) ? reviewedBy || "" : "";

/** "Reviewed date": when the Lab Supervisor approved it (same rule as "Reviewed by"). */
export const reviewedDate = (status, approvedBy, date) =>
  status === "Supervisor Approved" || wasApproved(status, approvedBy) ? fmtDate(date) : "";

/** "Approved by": the Lab Manager who gave the final approval. */
export const approvedByName = (status, approvedBy) => (wasApproved(status, approvedBy) ? approvedBy || "" : "");

/** "Approved date": when the Lab Manager gave the final approval. */
export const approvedDate = (status, approvedBy, date) => (wasApproved(status, approvedBy) ? fmtDate(date) : "");
