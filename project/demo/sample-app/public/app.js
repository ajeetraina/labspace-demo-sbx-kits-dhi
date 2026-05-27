async function loadDashboard() {
  const [scorecardResponse, servicesResponse] = await Promise.all([
    fetch("/api/scorecard"),
    fetch("/api/services")
  ]);

  const scorecard = await scorecardResponse.json();
  const catalog = await servicesResponse.json();

  document.querySelector("#service-count").textContent = scorecard.serviceCount;
  document.querySelector("#cve-count").textContent = scorecard.totalCves;
  document.querySelector("#risk-count").textContent = scorecard.highRiskServices.length;
  document.querySelector("#generated-at").textContent = new Date(
    scorecard.generatedAt
  ).toLocaleString();

  const services = document.querySelector("#services");
  services.replaceChildren(
    ...catalog.services.map((service) => {
      const card = document.createElement("article");
      card.className = "service-card";
      card.innerHTML = `
        <header>
          <div>
            <h3>${service.name}</h3>
            <p>${service.owner}</p>
          </div>
          <span class="pill ${service.status}">${service.status}</span>
        </header>
        <div class="facts">
          <div><span>Runtime</span><strong>${service.runtime}</strong></div>
          <div><span>Image</span><strong>${service.image}</strong></div>
          <div><span>P95 latency</span><strong>${service.p95LatencyMs} ms</strong></div>
          <div><span>Open CVEs</span><strong>${service.openCves}</strong></div>
        </div>
      `;
      return card;
    })
  );
}

loadDashboard().catch((error) => {
  console.error(error);
});
