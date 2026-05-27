export type Service = {
  id: string;
  name: string;
  owner: string;
  runtime: "node" | "python" | "go" | "postgres";
  status: "healthy" | "degraded" | "investigating";
  image: string;
  requestsPerMinute: number;
  p95LatencyMs: number;
  openCves: number;
  lastDeploy: string;
};

export const services: Service[] = [
  {
    id: "checkout-api",
    name: "Checkout API",
    owner: "payments",
    runtime: "node",
    status: "healthy",
    image: "node:24-trixie-slim",
    requestsPerMinute: 1840,
    p95LatencyMs: 91,
    openCves: 8,
    lastDeploy: "2026-05-21T10:14:00Z"
  },
  {
    id: "orders-worker",
    name: "Orders Worker",
    owner: "fulfillment",
    runtime: "node",
    status: "degraded",
    image: "node:24-trixie-slim",
    requestsPerMinute: 620,
    p95LatencyMs: 244,
    openCves: 12,
    lastDeploy: "2026-05-20T15:42:00Z"
  },
  {
    id: "catalog-sync",
    name: "Catalog Sync",
    owner: "catalog",
    runtime: "go",
    status: "healthy",
    image: "golang:1.24-bookworm",
    requestsPerMinute: 320,
    p95LatencyMs: 54,
    openCves: 5,
    lastDeploy: "2026-05-19T08:30:00Z"
  },
  {
    id: "customer-notify",
    name: "Customer Notify",
    owner: "engagement",
    runtime: "node",
    status: "investigating",
    image: "node:24-trixie-slim",
    requestsPerMinute: 410,
    p95LatencyMs: 388,
    openCves: 16,
    lastDeploy: "2026-05-18T17:05:00Z"
  },
  {
    id: "analytics-db",
    name: "Analytics DB",
    owner: "data",
    runtime: "postgres",
    status: "healthy",
    image: "postgres:17-bookworm",
    requestsPerMinute: 275,
    p95LatencyMs: 31,
    openCves: 7,
    lastDeploy: "2026-05-17T12:22:00Z"
  }
];
