const STORAGE_KEY = "startup_x_products";
const DEMO_KEY = "startup_x_demo_steps";
const PAGE_SIZE = 5;

function createId() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }
  return `id-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
}

const defaults = [
  { id: createId(), name: "iPhone 16 Pro", price: 1299, color: "Titanium", description: "Visible text for CI/CD demo change.", imageUrl: "assets/images/placeholder.svg" },
  { id: createId(), name: "MacBook Air M3", price: 1199, color: "Midnight", description: "Lightweight laptop for deployment demo.", imageUrl: "assets/images/placeholder.svg" },
  { id: createId(), name: "Apple Watch Series 10", price: 429, color: "Jet Black", description: "Great sample item for UI update verification.", imageUrl: "assets/images/placeholder.svg" },
  { id: createId(), name: "AirPods Pro 2", price: 249, color: "White", description: "Supports quick CRUD demonstrations.", imageUrl: "assets/images/placeholder.svg" },
  { id: createId(), name: "iPad Air", price: 699, color: "Blue", description: "Useful for pagination and search checks.", imageUrl: "assets/images/placeholder.svg" },
  { id: createId(), name: "HomePod mini", price: 99, color: "Orange", description: "Small but visible catalog item.", imageUrl: "assets/images/placeholder.svg" }
];

const state = { items: loadItems(), page: 1, search: "", color: "" };
const rows = document.getElementById("productRows");
const cards = document.getElementById("mobileCards");
const pageInfo = document.getElementById("pageInfo");
const prevPage = document.getElementById("prevPage");
const nextPage = document.getElementById("nextPage");
const searchInput = document.getElementById("searchInput");
const colorFilter = document.getElementById("colorFilter");
const modalEl = document.getElementById("productModal");
const modal = {
  show() {
    if (!modalEl) return;
    modalEl.classList.add("open");
    modalEl.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";
  },
  hide() {
    if (!modalEl) return;
    modalEl.classList.remove("open");
    modalEl.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
  }
};

const productForm = document.getElementById("productForm");
const productId = document.getElementById("productId");
const modalTitle = document.getElementById("modalTitle");
const nameInput = document.getElementById("name");
const priceInput = document.getElementById("price");
const colorInput = document.getElementById("color");
const descriptionInput = document.getElementById("description");
const imageInput = document.getElementById("imageFile");
const previewImage = document.getElementById("previewImage");
const appLoader = document.getElementById("appLoader");
const contentShell = document.getElementById("contentShell");
const tableSkeleton = document.getElementById("tableSkeleton");
const runAddress = document.getElementById("runAddress");
const dataSource = document.getElementById("dataSource");
const tierName = document.getElementById("tierName");
const stackName = document.getElementById("stackName");
const envBadge = document.getElementById("envBadge");
const appVersionEl = document.getElementById("appVersion");
const totalProductsEl = document.getElementById("totalProducts");
const averagePriceEl = document.getElementById("averagePrice");
const storageModeEl = document.getElementById("storageMode");
const confirmModalEl = document.getElementById("confirmModal");
const confirmTextEl = document.getElementById("confirmText");
const confirmDeleteBtn = document.getElementById("confirmDeleteBtn");
const toastRoot = document.getElementById("toastRoot");

let pendingDeleteId = null;
let pendingAnimation = "";
const RUNTIME_ENV_KEY = "startup_x_runtime_env";
const TIER_CONTEXT_KEY = "startup_x_selected_tier";

const TIER_CONFIG = [
  {
    key: "tier1-systemd",
    label: "Tier 1",
    stack: "Systemd or PM2"
  },
  {
    key: "tier2-docker-compose",
    label: "Tier 2",
    stack: "Docker Compose"
  },
  {
    key: "tier3-multi-server-lb",
    label: "Tier 3",
    stack: "Multi-server Load Balancer"
  },
  {
    key: "tier4-docker-swarm",
    label: "Tier 4",
    stack: "Docker Swarm"
  },
  {
    key: "tier5-kubernetes",
    label: "Tier 5",
    stack: "Kubernetes"
  }
];

function showToast(type, title, message) {
  if (!toastRoot) return;
  const toast = document.createElement("article");
  toast.className = `toast-item toast-${type}`;
  toast.innerHTML = `<div class="toast-title">${title}</div><div class="toast-message">${message}</div>`;
  toastRoot.appendChild(toast);

  window.setTimeout(() => {
    toast.classList.add("hide");
    window.setTimeout(() => {
      toast.remove();
    }, 250);
  }, 2200);
}

function animateRenderedItems(type) {
  if (!type) return;
  const tableItems = Array.from(document.querySelectorAll("#productRows tr"));
  const cardItems = Array.from(document.querySelectorAll("#mobileCards .card-mobile"));
  const className = `anim-${type}`;
  [...tableItems, ...cardItems].forEach((node, index) => {
    node.classList.remove("anim-add", "anim-edit", "anim-remove");
    node.style.animationDelay = `${Math.min(index * 24, 140)}ms`;
    node.classList.add(className);
  });
}

function animateDeleteBeforeRemove(id, done) {
  const targets = document.querySelectorAll(`[data-product-id="${id}"]`);
  if (!targets.length) {
    done();
    return;
  }
  targets.forEach((node) => {
    node.classList.add("anim-remove");
  });
  window.setTimeout(done, 220);
}

const checklist = Array.from(document.querySelectorAll("#demoChecklist input[type='checkbox']"));
const demoProgress = document.getElementById("demoProgress");
const progressLog = document.getElementById("progressLog");

function loadItems() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
    return defaults;
  }
  try { return JSON.parse(raw); } catch {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(defaults));
    return defaults;
  }
}

function saveItems() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state.items));
}

function setRuntimeInfo() {
  if (runAddress) {
    runAddress.textContent = window.location.protocol === "file:"
      ? "Local File"
      : window.location.host;
  }
  if (dataSource) {
    dataSource.textContent = "LocalStorage (browser)";
  }
}

function detectCurrentTier() {
  const tierFromSession = sessionStorage.getItem(TIER_CONTEXT_KEY);
  if (tierFromSession) {
    const matchedBySession = TIER_CONFIG.find((item) => item.key === tierFromSession);
    if (matchedBySession) {
      return matchedBySession;
    }
  }

  const normalized = window.location.pathname.toLowerCase().replace(/\\/g, "/");
  const matchedByPath = TIER_CONFIG.find((item) => normalized.includes(`/${item.key}`));
  if (matchedByPath) {
    sessionStorage.setItem(TIER_CONTEXT_KEY, matchedByPath.key);
    return matchedByPath;
  }

  return {
    key: "unknown",
    label: "Unknown Tier",
    stack: "Unknown Stack"
  };
}

function normalizeEnvironment(rawValue) {
  const value = String(rawValue || "").trim().toLowerCase();
  if (["production", "prod"].includes(value)) return "production";
  if (["staging", "stage", "uat"].includes(value)) return "staging";
  if (["development", "dev", "local"].includes(value)) return "dev";
  return "production";
}

function getRuntimeEnvironment() {
  const envFromStorage = localStorage.getItem(RUNTIME_ENV_KEY);
  if (envFromStorage) {
    return normalizeEnvironment(envFromStorage);
  }

  return normalizeEnvironment(window.APP_RUNTIME_ENV || "production");
}

function setEnvironmentInfo() {
  if (!envBadge) return;
  const runtimeEnv = getRuntimeEnvironment();

  envBadge.classList.remove("env-production", "env-staging", "env-dev");
  envBadge.classList.add(`env-${runtimeEnv}`);
  envBadge.textContent = `Env: ${runtimeEnv}`;
}

function setVersionInfo() {
  if (!appVersionEl) return;
  appVersionEl.textContent = window.APP_UI_VERSION || "v0.0.0";
}

function setTierInfo() {
  const currentTier = detectCurrentTier();
  if (currentTier.key !== "unknown") {
    sessionStorage.setItem(TIER_CONTEXT_KEY, currentTier.key);
    const cleanPath = `/${currentTier.key}`;
    if (window.location.pathname !== cleanPath) {
      window.history.replaceState({}, "", cleanPath);
    }
  }

  if (tierName) {
    tierName.textContent = currentTier.label;
  }
  if (stackName) {
    stackName.textContent = currentTier.stack;
  }
}

function currency(value) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value);
}

function filteredItems() {
  return state.items.filter((item) => {
    const term = `${item.name} ${item.color}`.toLowerCase();
    const matchSearch = term.includes(state.search.toLowerCase());
    const matchColor = !state.color || item.color === state.color;
    return matchSearch && matchColor;
  });
}

function pageData(items) {
  const totalPages = Math.max(Math.ceil(items.length / PAGE_SIZE), 1);
  if (state.page > totalPages) state.page = totalPages;
  const start = (state.page - 1) * PAGE_SIZE;
  return { totalPages, rows: items.slice(start, start + PAGE_SIZE) };
}

function populateColorFilter() {
  if (!colorFilter) return;
  const selected = state.color;
  const colors = [...new Set(state.items.map((item) => item.color))].sort((a, b) => a.localeCompare(b));
  colorFilter.innerHTML = '<option value="">All colors</option>' + colors.map((c) => `<option value="${c}">${c}</option>`).join("");
  colorFilter.value = selected;
}

function render() {
  if (!rows || !cards || !pageInfo || !prevPage || !nextPage) return;
  populateColorFilter();
  const filtered = filteredItems();
  const { rows: pagedRows, totalPages } = pageData(filtered);

  rows.innerHTML = pagedRows.map((item) => `
    <tr data-product-id="${item.id}">
      <td><img class="product-img" src="${item.imageUrl || "assets/images/placeholder.svg"}" alt="${item.name}"></td>
      <td class="fw-semibold">${item.name}</td>
      <td class="text-success fw-semibold">${currency(item.price)}</td>
      <td><span class="badge-color">${item.color}</span></td>
      <td>${item.description || "-"}</td>
      <td><div class="action-row"><button class="btn btn-sm btn-outline-secondary" onclick="editItem('${item.id}')"><span class="icon icon-edit"></span> Edit</button><button class="btn btn-sm btn-outline-danger" onclick="removeItem('${item.id}')"><span class="icon icon-delete"></span> Delete</button></div></td>
    </tr>
  `).join("");

  cards.innerHTML = pagedRows.map((item) => `
    <article class="card-mobile" data-product-id="${item.id}">
      <div class="head">
        <img class="product-img" src="${item.imageUrl || "assets/images/placeholder.svg"}" alt="${item.name}">
        <div>
          <div class="name">${item.name}</div>
          <div class="price">${currency(item.price)}</div>
          <span class="badge-color">${item.color}</span>
        </div>
      </div>
      <p class="mt-2 mb-2">${item.description || "No description"}</p>
      <div class="actions"><button class="btn btn-sm btn-outline-secondary" onclick="editItem('${item.id}')"><span class="icon icon-edit"></span> Edit</button><button class="btn btn-sm btn-outline-danger" onclick="removeItem('${item.id}')"><span class="icon icon-delete"></span> Delete</button></div>
    </article>
  `).join("");

  pageInfo.textContent = `Page ${state.page} / ${totalPages}`;
  prevPage.disabled = state.page <= 1;
  nextPage.disabled = state.page >= totalPages;

  if (totalProductsEl) {
    totalProductsEl.textContent = String(filtered.length);
  }
  if (averagePriceEl) {
    const avg = filtered.length > 0
      ? filtered.reduce((sum, item) => sum + Number(item.price || 0), 0) / filtered.length
      : 0;
    averagePriceEl.textContent = currency(avg);
  }
  if (storageModeEl) {
    storageModeEl.textContent = "LocalStorage";
  }

  animateRenderedItems(pendingAnimation);
  pendingAnimation = "";
}

function resetForm() {
  if (!productForm || !productId || !previewImage) return;
  productForm.reset();
  productId.value = "";
  previewImage.src = "assets/images/placeholder.svg";
}

function setInitialLoading(isLoading) {
  if (!appLoader || !contentShell || !tableSkeleton) return;
  if (isLoading) {
    tableSkeleton.classList.add("visible");
    contentShell.classList.add("loading");
    appLoader.classList.remove("hidden");
    return;
  }
  tableSkeleton.classList.remove("visible");
  appLoader.classList.add("hidden");
  contentShell.classList.remove("loading");
}

const addBtn = document.getElementById("btnAdd");
if (addBtn) {
  addBtn.addEventListener("click", () => {
    resetForm();
    if (modalTitle) modalTitle.textContent = "Add Product";
    modal.show();
  });
}

if (modalEl) {
  modalEl.addEventListener("click", (event) => {
    if (event.target === modalEl) {
      modal.hide();
    }
  });
}

function closeConfirmModal() {
  if (!confirmModalEl) return;
  confirmModalEl.classList.remove("open");
  confirmModalEl.setAttribute("aria-hidden", "true");
  document.body.style.overflow = "";
}

function openConfirmModal(message, id) {
  if (!confirmModalEl) return;
  pendingDeleteId = id;
  if (confirmTextEl) {
    confirmTextEl.textContent = message;
  }
  confirmModalEl.classList.add("open");
  confirmModalEl.setAttribute("aria-hidden", "false");
  document.body.style.overflow = "hidden";
}

if (confirmModalEl) {
  confirmModalEl.addEventListener("click", (event) => {
    if (event.target === confirmModalEl) {
      closeConfirmModal();
    }
  });
}

document.querySelectorAll("[data-modal-dismiss='confirmModal']").forEach((btn) => {
  btn.addEventListener("click", () => closeConfirmModal());
});

if (confirmDeleteBtn) {
  confirmDeleteBtn.addEventListener("click", () => {
    if (!pendingDeleteId) {
      closeConfirmModal();
      return;
    }
    const deleteId = pendingDeleteId;
    animateDeleteBeforeRemove(deleteId, () => {
      state.items = state.items.filter((p) => p.id !== deleteId);
      saveItems();
      pendingDeleteId = null;
      closeConfirmModal();
      pendingAnimation = "remove";
      render();
      showToast("success", "Product Deleted", "The product was removed successfully.");
    });
  });
}

document.querySelectorAll("[data-bs-dismiss='modal']").forEach((btn) => {
  btn.addEventListener("click", () => modal.hide());
});

window.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    modal.hide();
    closeConfirmModal();
  }
});

if (productForm) {
  productForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const id = (productId && productId.value) || createId();

    const upsert = (imageUrl) => {
      const payload = {
        id,
        name: nameInput ? nameInput.value.trim() : "",
        price: priceInput ? Number(priceInput.value) : NaN,
        color: colorInput ? colorInput.value.trim() : "",
        description: descriptionInput ? descriptionInput.value.trim() : "",
        imageUrl: imageUrl || (previewImage ? previewImage.src : "assets/images/placeholder.svg") || "assets/images/placeholder.svg"
      };

      if (!payload.name || !payload.color || Number.isNaN(payload.price) || payload.price <= 0) {
        showToast("error", "Invalid Input", "Please provide valid name, color, and price > 0.");
        return;
      }

      const index = state.items.findIndex((item) => item.id === id);
      const action = index >= 0 ? "edit" : "add";
      if (index >= 0) state.items[index] = payload; else state.items.unshift(payload);

      saveItems();
      modal.hide();
      pendingAnimation = action;
      render();
      showToast("success", action === "add" ? "Product Added" : "Product Updated", action === "add" ? "New product created successfully." : "Product details updated successfully.");
    };

    const file = imageInput && imageInput.files ? imageInput.files[0] : null;
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => upsert(e.target.result);
      reader.readAsDataURL(file);
    } else {
      upsert();
    }
  });
}

if (imageInput) {
  imageInput.addEventListener("change", () => {
    const file = imageInput.files[0];
    if (!file || !previewImage) return;
    const reader = new FileReader();
    reader.onload = (e) => { previewImage.src = e.target.result; };
    reader.readAsDataURL(file);
  });
}

if (searchInput) searchInput.addEventListener("input", () => { state.search = searchInput.value; state.page = 1; render(); });
if (colorFilter) colorFilter.addEventListener("change", () => { state.color = colorFilter.value; state.page = 1; render(); });
if (prevPage) prevPage.addEventListener("click", () => { if (state.page > 1) { state.page -= 1; render(); } });
if (nextPage) nextPage.addEventListener("click", () => { state.page += 1; render(); });

window.editItem = (id) => {
  const item = state.items.find((p) => p.id === id);
  if (!item) return;
  modalTitle.textContent = "Edit Product";
  productId.value = item.id;
  nameInput.value = item.name;
  priceInput.value = item.price;
  colorInput.value = item.color;
  descriptionInput.value = item.description || "";
  previewImage.src = item.imageUrl || "assets/images/placeholder.svg";
  modal.show();
};

window.removeItem = (id) => {
  const item = state.items.find((p) => p.id === id);
  if (!item) return;
  openConfirmModal(`Delete ${item.name}? This action cannot be undone.`, id);
};

function loadDemoState() {
  const raw = localStorage.getItem(DEMO_KEY);
  if (!raw) return [];
  try { return JSON.parse(raw); } catch { return []; }
}

function saveDemoState(values) {
  localStorage.setItem(DEMO_KEY, JSON.stringify(values));
}

function renderDemoProgress() {
  if (!demoProgress || !progressLog) return;
  const done = checklist.filter((cb) => cb.checked).length;
  const total = checklist.length;
  const percent = Math.round((done / total) * 100);
  demoProgress.style.width = `${percent}%`;
  demoProgress.textContent = `${percent}%`;

  progressLog.innerHTML = checklist.map((cb) => {
    const step = cb.dataset.step;
    return `<li>${cb.checked ? "Done" : "Pending"}: ${step}</li>`;
  }).join("");
}

if (checklist.length > 0) {
  const demoState = loadDemoState();
  checklist.forEach((cb, idx) => {
    cb.checked = Boolean(demoState[idx]);
    cb.addEventListener("change", () => {
      saveDemoState(checklist.map((item) => item.checked));
      renderDemoProgress();
    });
  });
}

function initializeApp() {
  try {
    setRuntimeInfo();
    setEnvironmentInfo();
    setVersionInfo();
    setTierInfo();
    setInitialLoading(true);
    window.setTimeout(() => {
      renderDemoProgress();
      render();
      setInitialLoading(false);
      showToast("info", "Offline Mode", "UI is running with LocalStorage data source.");
    }, 280);
  } catch (error) {
    console.error("App initialization error:", error);
    setInitialLoading(false);
  }
}

initializeApp();
