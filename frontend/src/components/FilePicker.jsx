import { useRef, useState } from "react";
import { Box, Button, Typography } from "@mui/material";
import UploadFileOutlined from "@mui/icons-material/UploadFileOutlined";
import { colors } from "../theme";
import { fmtSize } from "../format";

export const ACCEPTED = ".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx";
const MAX_MB = 25;

/** Drag-and-drop or click to choose one document file. */
export default function FilePicker({ file, onChange, error }) {
  const input = useRef(null);
  const [over, setOver] = useState(false);
  const [localError, setLocalError] = useState("");

  const pick = (f) => {
    if (!f) return;
    const ext = "." + f.name.split(".").pop().toLowerCase();
    if (!ACCEPTED.split(",").includes(ext)) return setLocalError("Choose a PDF, Word, Excel or PowerPoint file.");
    if (f.size > MAX_MB * 1024 * 1024) return setLocalError(`The file is larger than ${MAX_MB} MB.`);
    setLocalError("");
    onChange(f);
  };

  const shown = localError || error;
  return (
    <Box>
      <Box
        onDragOver={(e) => { e.preventDefault(); setOver(true); }}
        onDragLeave={() => setOver(false)}
        onDrop={(e) => { e.preventDefault(); setOver(false); pick(e.dataTransfer.files[0]); }}
        sx={{
          border: `1.5px dashed ${shown ? colors.red : over ? colors.teal : colors.line}`,
          bgcolor: over ? "rgba(15,110,106,0.05)" : "#fff",
          borderRadius: 1.5, p: 2.5, display: "flex", alignItems: "center", gap: 2, flexWrap: "wrap",
        }}
      >
        <UploadFileOutlined sx={{ color: colors.inkSoft }} />
        <Box sx={{ flexGrow: 1, minWidth: 180 }}>
          {file ? (
            <>
              <Typography sx={{ fontWeight: 500, wordBreak: "break-all" }}>{file.name}</Typography>
              <Typography variant="body2" color="text.secondary">{fmtSize(Math.ceil(file.size / 1024))}</Typography>
            </>
          ) : (
            <>
              <Typography sx={{ fontWeight: 500 }}>Drop the file here</Typography>
              <Typography variant="body2" color="text.secondary">PDF, Word, Excel or PowerPoint, up to {MAX_MB} MB</Typography>
            </>
          )}
        </Box>
        <Button variant="outlined" onClick={() => input.current?.click()}>{file ? "Choose another file" : "Choose file"}</Button>
        <input ref={input} type="file" hidden accept={ACCEPTED} onChange={(e) => { pick(e.target.files[0]); e.target.value = ""; }} />
      </Box>
      {shown && <Typography variant="body2" sx={{ color: colors.red, mt: 0.75 }}>{shown}</Typography>}
    </Box>
  );
}
