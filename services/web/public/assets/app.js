const steps = [
  { t: "Beginner", n: "Linux, Git, and how the cloud is billed." },
  { t: "AWS", n: "VPC, IAM, EC2, S3 — the four blocks every app sits on." },
  { t: "DevOps", n: "Pipelines that test, approve, then ship." },
  { t: "Kubernetes", n: "EKS, Helm, and a rollout you can watch." },
  { t: "Platform Engineering", n: "Golden paths. One platform, many teams." },
  { t: "MLOps", n: "Train, register, deploy, then watch drift." },
  { t: "AI Infrastructure", n: "Endpoints, GPUs, and cost you can explain." },
];
const box = document.getElementById("steps");
const panel = document.getElementById("step-panel");
function showStep(i) {
  [...box.children].forEach((el, idx) => {
    if (el.tagName === "BUTTON") el.classList.toggle("on", idx / 2 === i || (el.dataset.i === String(i)));
  });
  [...box.querySelectorAll("button")].forEach((b) => b.classList.toggle("on", b.dataset.i === String(i)));
  panel.innerHTML = `<p class="kicker">Stage ${i + 1}</p><h3 class="big">${steps[i].t}</h3><p>${steps[i].n}</p>`;
}
steps.forEach((s, i) => {
  const b = document.createElement("button");
  b.className = "chip";
  b.dataset.i = String(i);
  b.textContent = s.t;
  b.onclick = () => showStep(i);
  box.appendChild(b);
  if (i < steps.length - 1) {
    const a = document.createElement("span");
    a.textContent = "↓";
    a.style.fontSize = "22px";
    a.style.color = "#714b67";
    box.appendChild(a);
  }
});
showStep(0);

const nodes = [
  { name: "Route53", x: 10, y: 20, n: "DNS for the academy and every lab hostname." },
  { name: "CloudFront", x: 30, y: 14, n: "Edge cache in front of the site." },
  { name: "ALB", x: 50, y: 22, n: "Splits web, API, and lab ingress." },
  { name: "EKS", x: 72, y: 16, n: "Auth, cart, catalog, labs as Deployments." },
  { name: "RDS", x: 28, y: 62, n: "PostgreSQL for users, orders, enrollments." },
  { name: "Redis", x: 50, y: 66, n: "Session and rate limits." },
  { name: "Prometheus", x: 72, y: 58, n: "Scrapes /metrics from shop and labs." },
  { name: "Grafana", x: 88, y: 44, n: "The board students learn to read." },
];
const arch = document.getElementById("arch");
const tip = document.createElement("div");
tip.className = "tip";
arch.appendChild(tip);
function setTip(node) {
  tip.innerHTML = `<b style="color:#ffc107">${node.name}</b><p style="margin:6px 0 0">${node.n}</p>`;
}
nodes.forEach((node) => {
  const el = document.createElement("button");
  el.className = "node";
  el.style.left = node.x + "%";
  el.style.top = node.y + "%";
  el.textContent = node.name;
  el.onmouseenter = () => setTip(node);
  arch.appendChild(el);
});
setTip(nodes[3]);

const stats = [
  ["Students", 28400],
  ["Courses", 86],
  ["Labs", 140],
  ["Books", 48],
  ["Deployments", 12000],
];
const nums = document.getElementById("nums");
stats.forEach(([label, to]) => {
  const d = document.createElement("div");
  d.innerHTML = `<strong data-to="${to}">0</strong><span>${label}</span>`;
  nums.appendChild(d);
});
const io = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    entry.target.querySelectorAll("strong").forEach((el) => {
      const to = Number(el.dataset.to);
      const start = performance.now();
      const tick = (now) => {
        const p = Math.min(1, (now - start) / 1400);
        el.textContent = Math.round(to * (1 - (1 - p) ** 3)).toLocaleString();
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    });
    io.disconnect();
  });
});
io.observe(nums);
