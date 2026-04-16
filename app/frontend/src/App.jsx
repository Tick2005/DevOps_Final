import { useEffect, useMemo, useState } from 'react'
import Header from './components/Header'
import ProductForm from './components/ProductForm'
import ProductTable from './components/ProductTable'
import { FALLBACK_IMAGE, createProduct, deleteProduct, listProducts, updateProduct } from './api/client'

export default function App() {
  const [products, setProducts] = useState([])
  const [loading, setLoading] = useState(true)
  const [keyword, setKeyword] = useState('')
  const [colorFilter, setColorFilter] = useState('')
  const [page, setPage] = useState(1)
  const [error, setError] = useState('')
  const [sourceInfo, setSourceInfo] = useState({ source: '-', host: '-', tier: '-' })
  const [toast, setToast] = useState(null)
  const [formOpen, setFormOpen] = useState(false)
  const [viewOpen, setViewOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [activeProduct, setActiveProduct] = useState(null)
  const [formMode, setFormMode] = useState('add')
  const pageSize = 5

  function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }

  async function loadProducts() {
    try {
      setLoading(true)
      setError('')

      let data = null
      let lastError = null
      for (let attempt = 1; attempt <= 3; attempt += 1) {
        try {
          data = await listProducts()
          break
        } catch (err) {
          lastError = err
          if (attempt < 3) {
            await wait(1200)
          }
        }
      }

      if (!data) {
        throw lastError || new Error('Failed to load products')
      }

      setProducts(data.items)
      setSourceInfo(data.sourceInfo)
    } catch (err) {
      setError(err.message || 'Failed to load products')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadProducts()
  }, [])

  function notify(message, type = 'success') {
    setToast({ message, type })
  }

  useEffect(() => {
    if (!toast) return
    const timer = setTimeout(() => setToast(null), 2400)
    return () => clearTimeout(timer)
  }, [toast])

  useEffect(() => {
    function onEscape(event) {
      if (event.key !== 'Escape') return

      if (deleteOpen) {
        setDeleteOpen(false)
        return
      }
      if (viewOpen) {
        setViewOpen(false)
        return
      }
      if (formOpen) {
        setFormOpen(false)
      }
    }

    window.addEventListener('keydown', onEscape)
    return () => window.removeEventListener('keydown', onEscape)
  }, [formOpen, viewOpen, deleteOpen])

  async function handleCreate(form) {
    try {
      setError('')
      const created = await createProduct(form)
      setProducts((prev) => [created, ...prev])
      setFormOpen(false)
      notify('Product created successfully')
    } catch (err) {
      setError(err.message || 'Failed to create product')
      notify('Unable to create product', 'error')
    }
  }

  async function handleEdit(form) {
    if (!activeProduct) return
    try {
      setError('')
      const updated = await updateProduct(activeProduct.id, form)
      setProducts((prev) => prev.map((item) => (item.id === updated.id ? updated : item)))
      setFormOpen(false)
      setActiveProduct(null)
      notify('Product updated successfully')
    } catch (err) {
      setError(err.message || 'Failed to update product')
      notify('Unable to update product', 'error')
    }
  }

  async function handleDeleteConfirmed() {
    if (!activeProduct) return
    try {
      setError('')
      await deleteProduct(activeProduct.id)
      setProducts((prev) => prev.filter((item) => item.id !== activeProduct.id))
      setDeleteOpen(false)
      setActiveProduct(null)
      notify('Product deleted successfully')
    } catch (err) {
      setError(err.message || 'Failed to delete product')
      notify('Unable to delete product', 'error')
    }
  }

  const filtered = useMemo(() => {
    const q = keyword.trim().toLowerCase()
    return products.filter((item) => {
      const keywordMatch = !q || `${item.name} ${item.color} ${item.description || ''} ${item.category || ''}`.toLowerCase().includes(q)
      const colorMatch = !colorFilter || item.color === colorFilter
      return keywordMatch && colorMatch
    })
  }, [products, keyword, colorFilter])

  const colors = useMemo(() => {
    const values = Array.from(new Set(products.map((item) => item.color).filter(Boolean)))
    return values.sort((a, b) => a.localeCompare(b))
  }, [products])

  const summary = useMemo(() => {
    const total = filtered.length
    const avgPrice = total ? filtered.reduce((sum, item) => sum + Number(item.price || 0), 0) / total : 0
    const totalStock = filtered.reduce((sum, item) => sum + Number(item.stock || 0), 0)
    return { total, avgPrice, totalStock }
  }, [filtered])

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize))
  const paged = useMemo(() => {
    const start = (page - 1) * pageSize
    return filtered.slice(start, start + pageSize)
  }, [filtered, page])

  useEffect(() => {
    setPage(1)
  }, [keyword, colorFilter])

  useEffect(() => {
    if (page > totalPages) {
      setPage(totalPages)
    }
  }, [page, totalPages])

  function openAddModal() {
    setFormMode('add')
    setActiveProduct(null)
    setFormOpen(true)
  }

  function openEditModal(product) {
    setFormMode('edit')
    setActiveProduct(product)
    setFormOpen(true)
  }

  function openViewModal(product) {
    setActiveProduct(product)
    setViewOpen(true)
  }

  function openDeleteModal(product) {
    setActiveProduct(product)
    setDeleteOpen(true)
  }

  function resetFilters() {
    setKeyword('')
    setColorFilter('')
    setPage(1)
  }

  return (
    <div className="app-shell">
      <Header
        sourceInfo={sourceInfo}
        loading={loading}
      />

      <section className="card">
        <div className="toolbar">
          <input
            value={keyword}
            onChange={(event) => setKeyword(event.target.value)}
            placeholder="Search products by name, color, category"
          />
          <select value={colorFilter} onChange={(event) => setColorFilter(event.target.value)}>
            <option value="">All colors</option>
            {colors.map((color) => (
              <option key={color} value={color}>{color}</option>
            ))}
          </select>
          <button type="button" className="ghost" onClick={resetFilters}>
            Clear Filters
          </button>
          <button onClick={loadProducts} type="button">Refresh</button>
          <button onClick={openAddModal} type="button">Add Product</button>
        </div>
      </section>

      <section className="card">
        <h2>Product Table ({filtered.length})</h2>
        <div className="summary-row">
          <span>Total: <strong>{summary.total}</strong></span>
          <span>Avg price: <strong>{new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(summary.avgPrice)}</strong></span>
          <span>Total stock: <strong>{summary.totalStock}</strong></span>
        </div>
        {loading ? (
          <div className="loading-block">
            <div className="loading-line" />
            <div className="loading-line" />
            <div className="loading-line short" />
            <p className="muted">Waiting for backend and MongoDB...</p>
          </div>
        ) : null}
        {!loading && error ? <p className="error">{error}</p> : null}
        {!loading ? <ProductTable products={paged} onView={openViewModal} onEdit={openEditModal} onDelete={openDeleteModal} /> : null}
        <div className="pager">
          <button type="button" onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page <= 1}>Previous</button>
          <span>Page {page} / {totalPages}</span>
          <button type="button" onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page >= totalPages}>Next</button>
        </div>
      </section>

      {formOpen ? (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal-card form-modal">
            <div className="modal-header">
              <h3>{formMode === 'add' ? 'Add Product' : 'Edit Product'}</h3>
              <button type="button" className="ghost" onClick={() => setFormOpen(false)}>Close</button>
            </div>
            <ProductForm
              initialValue={activeProduct}
              canRemoveImage={formMode === 'edit'}
              submitLabel={formMode === 'add' ? 'Create Product' : 'Save Changes'}
              onCancel={() => setFormOpen(false)}
              onSubmit={formMode === 'add' ? handleCreate : handleEdit}
            />
          </div>
        </div>
      ) : null}

      {viewOpen && activeProduct ? (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal-card detail-modal">
            <div className="modal-header">
              <h3>Product Detail</h3>
              <button type="button" className="ghost" onClick={() => setViewOpen(false)}>Close</button>
            </div>
            <div className="detail-grid">
              <div className="detail-image-frame">
                <img className="detail-image" src={activeProduct.image || FALLBACK_IMAGE} alt={activeProduct.name} />
              </div>
              <div className="detail-panel">
                <div className="detail-item">
                  <span>Name</span>
                  <strong>{activeProduct.name || '-'}</strong>
                </div>
                <div className="detail-item">
                  <span>Price</span>
                  <strong>{new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(activeProduct.price)}</strong>
                </div>
                <div className="detail-item">
                  <span>Color</span>
                  <strong>{activeProduct.color || '-'}</strong>
                </div>
                <div className="detail-item">
                  <span>Category</span>
                  <strong>{activeProduct.category || '-'}</strong>
                </div>
                <div className="detail-item">
                  <span>Stock</span>
                  <strong>{activeProduct.stock ?? 0}</strong>
                </div>
                <div className="detail-item">
                  <span>Created At</span>
                  <strong>{activeProduct.createdAt ? new Date(activeProduct.createdAt).toLocaleString() : '-'}</strong>
                </div>
                <div className="detail-item full-span">
                  <span>Description</span>
                  <strong>{activeProduct.description || '-'}</strong>
                </div>
                <div className="detail-item">
                  <span>Source</span>
                  <strong>{activeProduct.source || '-'}</strong>
                </div>
                <div className="detail-item">
                  <span>Host</span>
                  <strong>{activeProduct.host || '-'}</strong>
                </div>
                <div className="detail-item full-span">
                  <span>Tier</span>
                  <strong>{activeProduct.tier || '-'}</strong>
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {deleteOpen && activeProduct ? (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal-card small-modal delete-modal">
            <h3>Delete Product</h3>
            <p>This action cannot be undone.</p>
            <p>Are you sure you want to delete <strong>{activeProduct.name}</strong>?</p>
            <div className="form-actions">
              <button type="button" className="ghost" onClick={() => setDeleteOpen(false)}>Cancel</button>
              <button type="button" className="danger" onClick={handleDeleteConfirmed}>Delete</button>
            </div>
          </div>
        </div>
      ) : null}

      {toast ? <div className={`toast ${toast.type === 'error' ? 'toast-error' : ''}`}>{toast.message}</div> : null}
    </div>
  )
}