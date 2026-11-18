import { get, http, post, postForm, toError } from "./client";

export const getDocuments = ({ search, categoryId = 0, approvedOnly = true, isActive = "Y" } = {}) =>
  get("/Document/DocumentList", { search, categoryId, approvedOnly, isActive });
export const getDocument = (documentId) => get("/Document/DocumentGetById", { documentId });
export const getHistory = (documentId) => get("/Document/DocumentHistory", { documentId });
export const getPendingApprovals = () => get("/Document/DocumentPendingApprovals");

export const createDocument = (fields) => postForm("/Document/DocumentCreate", fields);
export const createRevision = (fields) => postForm("/Document/DocumentVersionCreate", fields);
export const updateRevision = (fields) => postForm("/Document/DocumentVersionUpdate", fields);

/** Event fired after anything that changes someone's "Waiting for me" list. */
export const PENDING_CHANGED = "ialqc:pending-changed";
const notifyPending = (result) => { window.dispatchEvent(new Event(PENDING_CHANGED)); return result; };

export const submitRevision = (versionID, userID, comments) =>
  post("/Document/DocumentVersionSubmit", { versionID, userID, comments }).then(notifyPending);
export const decideRevision = (versionID, action, userID, comments) =>
  post("/Document/DocumentVersionApprove", { versionID, action, userID, comments }).then(notifyPending);
/** Lab Manager: action = "Cancel", "Archive" or "Restore". */
export const changeDocumentStatus = (versionID, action, comments) =>
  post("/Document/DocumentStatusChange", { versionID, action, userID: 0, comments }).then(notifyPending);
export const setDocumentActive = (documentID, isActive, userID) =>
  post("/Document/DocumentActiveStatusUpdate", { documentID, isActive, userID });

/**
 * Opens a revision's file in a new tab (PDF) or downloads it (Word, Excel, ...).
 * Files need the login token, so they are fetched here rather than linked directly.
 */
export async function openFile(versionId, fileName, download = false) {
  const showInTab = !download && /\.pdf$/i.test(fileName || "");
  const tab = showInTab ? window.open("", "_blank") : null; // opened now, so pop-up blockers allow it
  try {
    const res = await http.get("/Document/DocumentDownload", { params: { versionId, inline: showInTab }, responseType: "blob" });
    const url = URL.createObjectURL(res.data);
    if (tab) {
      tab.location.href = url;
    } else {
      const a = document.createElement("a");
      a.href = url;
      a.download = fileName || "document";
      a.click();
    }
    setTimeout(() => URL.revokeObjectURL(url), 60000);
  } catch (err) {
    tab?.close();
    throw await toError(err);
  }
}
