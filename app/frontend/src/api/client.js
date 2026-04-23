const API_BASE = import.meta.env.VITE_API_BASE || '/api'

export const FALLBACK_IMAGE = `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 160 160"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="#dfe8fb"/><stop offset="100%" stop-color="#f3f7ff"/></linearGradient></defs><rect width="160" height="160" rx="80" fill="url(#g)"/><circle cx="80" cy="62" r="24" fill="#a9bde7"/><rect x="38" y="100" width="84" height="36" rx="18" fill="#bdd0f4"/></svg>')}`

function resolveId(item) {
  const rawId = item?.id ?? item?.productId ?? item?._id ?? null
  return rawId === null || rawId === undefined ? '' : String(rawId)
}

function normalizeProduct(item) {
  return {
    id: resolveId(item),
    name: item.name || '',
    price: Number(item.price || 0),
    color: item.color || '-',
    category: item.category || '-',
    stock: Number(item.stock || 0),
    description: item.description || '',
    image: item.image || item.imageUrl || '',
    source: item.source || '-',
    host: item.host || '-',
    tier: item.tier || '-',
    createdAt: item.createdAt || null
  }
}

function toPayload(payload) {
  return {
    name: payload.name.trim(),
    color: payload.color.trim(),
    description: payload.description.trim(),
    category: (payload.category || '').trim(),
    image: payload.image || '',
    stock: Number(payload.stock || 0),
    price: Number(payload.price)
  }
}

function assertValidId(id) {
  const value = id === null || id === undefined ? '' : String(id).trim()
  if (!value) {
    throw new Error('Invalid product id. Please refresh and try again.')
  }
  return value
}

async function request(path, options) {
  let response
  try {
    response = await fetch(`${API_BASE}${path}`, {
      headers: { 'Content-Type': 'application/json' },
      ...options
    })
  } catch {
    throw new Error('Backend is starting. Please wait a moment and press Refresh.')
  }

  if (!response.ok) {
    if ([502, 503, 504].includes(response.status)) {
      throw new Error('Backend is warming up. Please wait a few seconds and try again.')
    }
    throw new Error(`Request failed (${response.status}). Please try again.`)
  }

  if (response.status === 204) {
    return null
  }

  return response.json()
}

export async function listProducts() {
  const data = await request('/products', { method: 'GET' })
  let runtime = null
  try {
    runtime = await request('/health/runtime', { method: 'GET' })
  } catch {
    runtime = null
  }

  const items = Array.isArray(data) ? data.map(normalizeProduct) : []
  const first = items[0] || null
  const sourceLabel = runtime?.source || first?.source || 'Unknown'

  return {
    items,
    source: 'API + MongoDB',
    sourceInfo: {
      status: runtime?.status || 'Online',
      source: sourceLabel,
      host: runtime?.host || first?.host || '-',
      tier: runtime?.tier || first?.tier || '-',
      version: runtime?.version || null
    }
  }
}

export async function createProduct(payload) {
  return normalizeProduct(await request('/products', {
    method: 'POST',
    body: JSON.stringify(toPayload(payload))
  }))
}

export async function updateProduct(id, payload) {
  const safeId = assertValidId(id)
  return normalizeProduct(await request(`/products/${safeId}`, {
    method: 'PUT',
    body: JSON.stringify(toPayload(payload))
  }))
}

export async function deleteProduct(id) {
  const safeId = assertValidId(id)
  await request(`/products/${safeId}`, { method: 'DELETE' })
}