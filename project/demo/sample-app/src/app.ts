import compression from "compression";
import express, { type Request, type Response } from "express";
import helmet from "helmet";
import morgan from "morgan";
import path from "node:path";
import { z } from "zod";
import { services, type Service } from "./data";

const assessmentSchema = z.object({
  serviceId: z.string().min(3),
  proposedImage: z.string().min(3),
  requestedBy: z.string().email()
});

export function createApp() {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(compression());
  app.use(express.json({ limit: "64kb" }));
  app.use(morgan("tiny"));
  app.use(express.static(path.join(process.cwd(), "public")));

  app.get("/healthz", (_req: Request, res: Response) => {
    res.json({
      ok: true,
      service: "leaddev-platform-radar",
      version: process.env.npm_package_version ?? "0.2.0",
      uptimeSeconds: Math.round(process.uptime())
    });
  });

  app.get("/readyz", (_req: Request, res: Response) => {
    res.json({
      ready: services.length > 0,
      checks: {
        serviceCatalog: "ok",
        policyBundle: "ok"
      }
    });
  });

  app.get("/api/services", (req: Request, res: Response) => {
    const status = req.query.status?.toString();
    const filtered = status
      ? services.filter((service) => service.status === status)
      : services;

    res.json({ count: filtered.length, services: filtered });
  });

  app.get("/api/services/:id", (req: Request, res: Response) => {
    const service = services.find((candidate) => candidate.id === req.params.id);
    if (!service) {
      res.status(404).json({ error: "service not found" });
      return;
    }

    res.json(service);
  });

  app.get("/api/scorecard", (_req: Request, res: Response) => {
    const totalCves = services.reduce((sum, service) => sum + service.openCves, 0);
    const runtimeBreakdown = summarizeByRuntime(services);
    const highRiskServices = services
      .filter((service) => service.openCves >= 10 || service.status !== "healthy")
      .map(({ id, name, owner, status, openCves }) => ({
        id,
        name,
        owner,
        status,
        openCves
      }));

    res.json({
      generatedAt: new Date().toISOString(),
      serviceCount: services.length,
      totalCves,
      runtimeBreakdown,
      highRiskServices
    });
  });

  app.get("/metrics", (_req: Request, res: Response) => {
    const lines = [
      "# HELP platform_radar_services Services tracked by the demo app",
      "# TYPE platform_radar_services gauge",
      `platform_radar_services ${services.length}`,
      "# HELP platform_radar_open_cves Open CVEs across tracked services",
      "# TYPE platform_radar_open_cves gauge",
      `platform_radar_open_cves ${services.reduce((sum, service) => sum + service.openCves, 0)}`
    ];

    for (const service of services) {
      lines.push(
        `platform_radar_service_latency_p95_ms{service="${service.id}"} ${service.p95LatencyMs}`
      );
    }

    res.type("text/plain").send(`${lines.join("\n")}\n`);
  });

  app.post("/api/assessments", (req: Request, res: Response) => {
    const parsed = assessmentSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: "invalid assessment", details: parsed.error.flatten() });
      return;
    }

    const service = services.find((candidate) => candidate.id === parsed.data.serviceId);
    if (!service) {
      res.status(404).json({ error: "service not found" });
      return;
    }

    res.status(202).json({
      id: `assessment-${Date.now()}`,
      serviceId: service.id,
      currentImage: service.image,
      proposedImage: parsed.data.proposedImage,
      policy: "queued",
      next: "Review the pushed image in Docker Hub before rolling out the Dockerfile change."
    });
  });

  return app;
}

function summarizeByRuntime(catalog: Service[]) {
  return catalog.reduce<Record<Service["runtime"], number>>(
    (summary, service) => {
      summary[service.runtime] += 1;
      return summary;
    },
    { node: 0, python: 0, go: 0, postgres: 0 }
  );
}
