import { createApp } from "./app";

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";

const server = createApp().listen(port, host, () => {
  console.log(`leaddev platform radar listening on http://${host}:${port}`);
});

process.on("SIGTERM", () => {
  server.close(() => {
    console.log("server closed");
  });
});
