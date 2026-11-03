import axios from "axios";

// All API calls go through here.
// - The login token is sent on every request ("Authorization: Bearer ...").
// - The backend returns { errorMessage } when a request is refused; that message
//   is thrown as an Error so pages can show it as is.
// - A 401 (session ended) signs the user out everywhere in the app.
export const API_URL = import.meta.env.VITE_API_URL;
export const TOKEN_KEY = "ialqc_token";
export const SIGNED_OUT = "ialqc:signed-out";

export const http = axios.create({ baseURL: API_URL });

http.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

http.interceptors.response.use(
  (res) => res,
  (err) => {
    const isLogin = err.config?.url?.includes("/Auth/Login");
    if (err.response?.status === 401 && !isLogin) window.dispatchEvent(new Event(SIGNED_OUT));
    return Promise.reject(err);
  }
);

export async function toError(err) {
  let data = err.response?.data;
  if (data instanceof Blob) {
    try { data = JSON.parse(await data.text()); } catch { data = null; }
  }
  if (data?.errorMessage) return new Error(data.errorMessage);
  if (err.response) return new Error(`The server returned an error (${err.response.status}).`);
  return new Error("Can't reach the server. Check that the API is running.");
}

export async function get(url, params) {
  try {
    const res = await http.get(url, { params });
    return res.data;
  } catch (err) {
    throw await toError(err);
  }
}

export async function post(url, body) {
  let res;
  try {
    res = await http.post(url, body);
  } catch (err) {
    throw await toError(err);
  }
  if (res.data?.errorMessage) throw new Error(res.data.errorMessage);
  return res.data;
}

/** multipart/form-data post (file uploads). Null / undefined fields are left out. */
export async function postForm(url, fields) {
  const form = new FormData();
  Object.entries(fields).forEach(([key, value]) => {
    if (value !== null && value !== undefined && value !== "") form.append(key, value);
  });
  return post(url, form);
}
