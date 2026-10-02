const BOOKS = [
  { id: "aws", name: "AWS book", price: 22, logo: "logos/amazonwebservices.svg" },
  { id: "terraform", name: "Terraform book", price: 19, logo: "logos/terraform.svg" },
  { id: "kubernetes", name: "Kubernetes book", price: 24, logo: "logos/kubernetes.svg" },
  { id: "docker", name: "Docker book", price: 16, logo: "logos/docker.svg" },
  { id: "ansible", name: "Ansible book", price: 17, logo: "logos/ansible.svg" },
  { id: "github", name: "GitHub Actions", price: 18, logo: "logos/githubactions.svg" },
  { id: "jenkins", name: "Jenkins book", price: 15, logo: "logos/jenkins.svg" },
  { id: "git", name: "Git book", price: 14, logo: "logos/git.svg" },
  { id: "python", name: "Python book", price: 20, logo: "logos/python.svg" },
  { id: "linux", name: "Linux book", price: 16, logo: "logos/linux.svg" },
  { id: "prometheus", name: "Prometheus book", price: 21, logo: "logos/prometheus.svg" },
  { id: "grafana", name: "Grafana book", price: 21, logo: "logos/grafana.svg" },
  { id: "otel", name: "OpenTelemetry", price: 19, logo: "logos/opentelemetry.svg" },
  { id: "argo", name: "Argo CD book", price: 20, logo: "logos/argo.svg" },
  { id: "helm", name: "Helm book", price: 18, logo: "logos/helm.svg" },
  { id: "istio", name: "Istio book", price: 20, logo: "logos/istio.svg" },
  { id: "opensearch", name: "OpenSearch book", price: 19, logo: "logos/opensearch.svg" },
  { id: "elasticsearch", name: "Elasticsearch", price: 19, logo: "logos/elasticsearch.svg" },
  { id: "kibana", name: "Kibana book", price: 18, logo: "logos/kibana.svg" },
  { id: "mlflow", name: "MLflow book", price: 21, logo: "logos/mlflow.svg" },
  { id: "tensorflow", name: "TensorFlow book", price: 22, logo: "logos/tensorflow.svg" },
  { id: "pytorch", name: "PyTorch book", price: 22, logo: "logos/pytorch.svg" },
  { id: "mongodb", name: "MongoDB book", price: 18, logo: "logos/mongodb.svg" },
  { id: "postgresql", name: "PostgreSQL book", price: 18, logo: "logos/postgresql.svg" },
  { id: "redis", name: "Redis book", price: 16, logo: "logos/redis.svg" },
  { id: "nginx", name: "Nginx book", price: 15, logo: "logos/nginx.svg" },
  { id: "mlops", name: "MLOps book", price: 23, logo: "logos/mlflow.svg" },
  { id: "security", name: "Security book", price: 22, logo: "logos/amazonwebservices.svg" },
  { id: "exam", name: "Exam pack", price: 25, logo: "logos/github.svg" },
];

function session() {
  return JSON.parse(localStorage.getItem("coa_user") || "null");
}
function saveSession(user) {
  if (user) localStorage.setItem("coa_user", JSON.stringify({ name: user.name, email: user.email }));
  else localStorage.removeItem("coa_user");
  paintAuth();
}
function paintAuth() {
  const slot = document.getElementById("auth-slot");
  if (!slot) return;
  const user = session();
  if (user) {
    slot.innerHTML = `<span class="who">${user.name}</span><button type="button" class="btn ghost" id="logout-btn">Log out</button>`;
    const out = document.getElementById("logout-btn");
    if (out) out.onclick = () => saveSession(null);
  } else {
    slot.innerHTML = `<a class="btn ghost" href="login.html">Login</a><a class="btn plum" href="signup.html">Sign up</a>`;
  }
}
paintAuth();

const signupForm = document.getElementById("signup-form");
if (signupForm) {
  signupForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const res = await fetch("/api/signup", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        name: signupForm.name.value.trim(),
        email: signupForm.email.value.trim(),
        password: signupForm.password.value,
      }),
    });
    const body = await res.json();
    const note = document.getElementById("signup-note");
    if (!res.ok) {
      note.className = "fail";
      note.textContent = body.message || "Sign up failed.";
      return;
    }
    saveSession(body);
    window.location.href = "index.html";
  });
}

const loginForm = document.getElementById("login-form");
if (loginForm) {
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const res = await fetch("/api/login", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        email: loginForm.email.value.trim(),
        password: loginForm.password.value,
      }),
    });
    const body = await res.json();
    const note = document.getElementById("login-note");
    if (!res.ok) {
      note.className = "fail";
      note.textContent = body.message || "Login failed.";
      return;
    }
    saveSession(body);
    window.location.href = "index.html";
  });
}

function cart() {
  return JSON.parse(localStorage.getItem("coa_cart") || "[]");
}
function saveCart(items) {
  localStorage.setItem("coa_cart", JSON.stringify(items));
  const el = document.getElementById("cart-count");
  if (el) el.textContent = items.reduce((n, i) => n + i.qty, 0);
}
function addCart(id) {
  const items = cart();
  const hit = items.find((i) => i.id === id);
  if (hit) hit.qty += 1;
  else items.push({ id, qty: 1 });
  saveCart(items);
}
function buyNow(id) {
  addCart(id);
  window.location.href = "cart.html";
}

const wall = document.getElementById("book-wall");
if (wall) {
  wall.innerHTML = BOOKS.map(
    (b) => `<div class="tile">
      <span class="ico"><img src="${b.logo}" alt="${b.name}"></span>
      <b>${b.name}</b>
      <div class="mini">
        <button type="button" data-add="${b.id}">Add to cart</button>
        <button type="button" class="buy" data-buy="${b.id}">Buy $${b.price}</button>
      </div>
    </div>`
  ).join("");
  wall.addEventListener("click", (e) => {
    const add = e.target.dataset.add;
    const buy = e.target.dataset.buy;
    if (add) addCart(add);
    if (buy) buyNow(buy);
  });
}
saveCart(cart());

function book(id) {
  return BOOKS.find((b) => b.id === id);
}

const list = document.getElementById("cart-list");
if (list) {
  const items = cart();
  if (!items.length) list.innerHTML = "<p>Cart is empty. Add a book from the round icons.</p>";
  else {
    list.innerHTML = items
      .map((i) => {
        const b = book(i.id);
        return `<tr><td>${b.name}</td><td>${i.qty}</td><td>$${b.price * i.qty}</td></tr>`;
      })
      .join("");
  }
}

const buyForm = document.getElementById("buy-form");
if (buyForm) {
  const user = session();
  if (user) {
    if (buyForm.name) buyForm.name.value = user.name;
    if (buyForm.email) buyForm.email.value = user.email;
  }
  buyForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = buyForm.email.value.trim();
    const name = buyForm.name.value.trim();
    const items = cart();
    if (!items.length) return;
    const res = await fetch("/api/buy", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ email, name, items }),
    });
    const body = await res.json();
    saveCart([]);
    const note = document.getElementById("buy-note");
    note.style.display = "block";
    note.textContent = body.message || "Purchased.";
    setTimeout(() => (window.location.href = "exam.html"), 800);
  });
}

const examForm = document.getElementById("exam-form");
if (examForm) {
  const user = session();
  if (user && examForm.email) examForm.email.value = user.email;
  const sel = examForm.book_id;
  BOOKS.forEach((b) => {
    const o = document.createElement("option");
    o.value = b.id;
    o.textContent = b.name;
    sel.appendChild(o);
  });
  examForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const score = Number(examForm.score.value);
    const res = await fetch("/api/exam", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        name: user ? user.name : "",
        email: examForm.email.value.trim(),
        book_id: examForm.book_id.value,
        score,
      }),
    });
    const body = await res.json();
    document.getElementById("exam-note").innerHTML = body.passed
      ? `<span class="pass">PASS ${body.score} — certificate ${body.certificate ? body.certificate.id : ""} for ${body.book}</span>`
      : `<span class="fail">FAIL ${body.score} — sit ${body.book} again</span>`;
  });
}

const orders = document.getElementById("orders");
if (orders) {
  Promise.all([fetch("/api/orders").then((r) => r.json()), fetch("/api/exams").then((r) => r.json())]).then(
    ([bought, exams]) => {
      orders.innerHTML = bought
        .map((o) => `<tr><td>${o.name}</td><td>${o.email}</td><td>${o.books}</td><td>${o.when}</td></tr>`)
        .join("");
      document.getElementById("exams").innerHTML = exams
        .map(
          (x) =>
            `<tr><td>${x.email}</td><td>${x.book}</td><td>${x.score}</td><td class="${x.passed ? "pass" : "fail"}">${x.passed ? "PASS" : "FAIL"}</td></tr>`
        )
        .join("");
    }
  );
}

const certs = document.getElementById("certs");
if (certs) {
  fetch("/api/certificates")
    .then((r) => r.json())
    .then((rows) => {
      certs.innerHTML = rows.length
        ? rows
            .map((c) => {
              const raw = c.name || (c.email || "").split("@")[0] || "Learner";
              const who = String(raw).replace(/[a-zA-Z]+/g, (w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase());
              const issued = (c.when || "").slice(0, 10);
              let until = c.valid_until;
              if (!until && issued) {
                const d = new Date(issued);
                if (!Number.isNaN(d.getTime())) {
                  d.setFullYear(d.getFullYear() + 1);
                  until = d.toISOString().slice(0, 10);
                }
              }
              until = until || "1 year from issue";
              const pretty = (value) => {
                const d = new Date(value);
                if (Number.isNaN(d.getTime())) return value;
                return d.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
              };
              const issuedPretty = pretty(issued);
              const untilPretty = pretty(until);
              return `<article class="cert">
                <div class="cert-frame" aria-hidden="true"></div>
                <div class="cert-rays" aria-hidden="true"></div>
                <div class="cert-banner">CLOUD AND DEVOPS · ONE YEAR AWARD</div>
                <p class="cert-brand"><i>Cloud</i> and <em>DevOps</em></p>
                <h2 class="cert-title">CERTIFICATE<span>OF ACHIEVEMENT</span></h2>
                <div class="cert-seal"><i></i><b>1 YEAR</b>AWARD</div>
                <p class="cert-given">PROUDLY PRESENTED TO</p>
                <p class="cert-name">${who}</p>
                <p class="cert-why">This certifies that <em>${who}</em> has successfully passed <em>${c.book}</em> with a score of <em>${c.score}</em>. This award is valid for <em>one year</em>, from ${issuedPretty} to ${untilPretty}.</p>
                <p class="cert-wish">All the best for the year ahead.</p>
                <div class="cert-foot">
                  <span><em>${issuedPretty}</em>DATE</span>
                  <span><em>${untilPretty}</em>VALID UNTIL</span>
                  <span><em class="sign">Cloud and DevOps</em>SIGNATURE</span>
                </div>
                <p class="cert-serial">Certificate No. ${c.id}</p>
              </article>`;
            })
            .join("")
        : "<p>No certificates yet. Pass an exam first.</p>";
    });
}

const board = document.getElementById("board");
if (board) {
  fetch("/api/leaderboard")
    .then((r) => r.json())
    .then((rows) => {
      board.innerHTML = rows
        .map(
          (x, i) =>
            `<tr><td>${i + 1}</td><td>${x.email}</td><td>${x.book}</td><td>${x.score}</td><td class="${x.passed ? "pass" : "fail"}">${x.passed ? "PASS" : "FAIL"}</td></tr>`
        )
        .join("");
    });
}

const threadForm = document.getElementById("thread-form");
if (threadForm) {
  const user = session();
  if (user && threadForm.name) threadForm.name.value = user.name;
  const list = document.getElementById("threads");
  const draw = (rows) => {
    list.innerHTML = rows
      .map((t) => `<article class="thread"><b>${t.title}</b><p>${t.body}</p><small>${t.name} · ${t.when}</small></article>`)
      .join("") || "<p>No questions yet.</p>";
  };
  fetch("/api/community").then((r) => r.json()).then(draw);
  threadForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const res = await fetch("/api/community", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        name: threadForm.name.value.trim(),
        title: threadForm.title.value.trim(),
        body: threadForm.body.value.trim(),
      }),
    });
    const body = await res.json();
    const note = document.getElementById("thread-note");
    if (!res.ok) {
      note.className = "fail";
      note.textContent = body.message || "Post failed.";
      return;
    }
    threadForm.title.value = "";
    threadForm.body.value = "";
    fetch("/api/community").then((r) => r.json()).then(draw);
  });
}
