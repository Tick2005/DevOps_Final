import { useEffect, useRef, useState } from 'react'
import { FALLBACK_IMAGE } from '../api/client'

// Validation constants
const MAX_FILE_SIZE_BYTES = 100 * 1024; // 100KB
const MAX_BASE64_SIZE = 100000; // 100KB for base64 encoded string
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/jpg']
const ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.gif', '.webp']

const emptyForm = {
  name: '',
  price: '',
  color: '',
  description: '',
  category: '',
  stock: '',
  image: ''
}

const CATEGORY_OPTIONS = [
  'Electronics',
  'Accessories',
  'Cables',
  'Audio',
  'Storage',
  'Furniture'
]

export default function ProductForm({
  initialValue,
  onSubmit,
  onCancel,
  submitLabel = 'Save Product',
  canRemoveImage = false
}) {
  const [form, setForm] = useState(emptyForm)
  const [errors, setErrors] = useState('')
  const [dragging, setDragging] = useState(false)
  const fileInputRef = useRef(null)

  useEffect(() => {
    setForm({ ...emptyForm, ...(initialValue || {}) })
    setErrors('')
  }, [initialValue])

  function onChange(event) {
    const { name, value } = event.target

    setForm((prev) => ({ ...prev, [name]: value }))
  }

  function onPriceKeyDown(event) {
    if (['e', 'E', '+', '-'].includes(event.key)) {
      event.preventDefault()
    }
  }

  function onStockKeyDown(event) {
    if (['e', 'E', '+', '-', '.'].includes(event.key)) {
      event.preventDefault()
    }
  }

  function onImageFile(file) {
    if (!file) return

    // Validate file type
    if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
      setErrors(`Invalid file format. Allowed formats: ${ALLOWED_IMAGE_EXTENSIONS.join(', ')}`)
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
      return
    }

    // Validate file size
    if (file.size > MAX_FILE_SIZE_BYTES) {
      const maxSizeMB = MAX_FILE_SIZE_BYTES / (1024 * 1024)
      const fileSizeMB = (file.size / (1024 * 1024)).toFixed(2)
      setErrors(`File size (${fileSizeMB}MB) exceeds maximum allowed size of ${maxSizeMB}MB`)
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
      return
    }

    const reader = new FileReader()
    reader.onload = () => {
      const base64String = String(reader.result || '')
      
      // Validate base64 encoded size
      if (base64String.length > MAX_BASE64_SIZE) {
        setErrors(`Image data is too large after encoding. Please use a smaller or compressed image.`)
        if (fileInputRef.current) {
          fileInputRef.current.value = ''
        }
        return
      }
      
      setForm((prev) => ({ ...prev, image: base64String }))
      setErrors('') // Clear any previous errors
    }
    reader.onerror = () => {
      setErrors('Failed to read file. Please try again.')
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    }
    reader.readAsDataURL(file)
  }

  function onImageChange(event) {
    onImageFile(event.target.files && event.target.files[0])
  }

  function onDrop(event) {
    event.preventDefault()
    setDragging(false)
    onImageFile(event.dataTransfer.files && event.dataTransfer.files[0])
  }

  function clearImage() {
    setForm((prev) => ({ ...prev, image: '' }))
    setErrors('') // Clear any image-related errors
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  function submit(event) {
    event.preventDefault()
    if (!form.name.trim()) {
      setErrors('Product name is required')
      return
    }
    if (!form.color.trim()) {
      setErrors('Color is required')
      return
    }
    if (Number(form.price) <= 0) {
      setErrors('Price must be greater than 0')
      return
    }

    setErrors('')
    onSubmit(form)
  }

  return (
    <form className="form" onSubmit={submit}>
      {errors ? <p className="error full-width">{errors}</p> : null}

      <label>
        Product Name
        <input name="name" value={form.name} onChange={onChange} placeholder="Product name" required />
      </label>

      <label>
        Price
        <input
          name="price"
          value={form.price}
          onChange={onChange}
          onKeyDown={onPriceKeyDown}
          type="number"
          inputMode="decimal"
          min="0.01"
          step="0.01"
          placeholder="Price"
          required
        />
      </label>

      <label>
        Color
        <input name="color" value={form.color} onChange={onChange} placeholder="Color" required />
      </label>

      <label>
        Category
        <select name="category" value={form.category} onChange={onChange}>
          <option value="">Select category</option>
          {CATEGORY_OPTIONS.map((category) => (
            <option key={category} value={category}>{category}</option>
          ))}
        </select>
      </label>

      <label>
        Stock
        <input
          name="stock"
          value={form.stock}
          onChange={onChange}
          onKeyDown={onStockKeyDown}
          type="number"
          inputMode="numeric"
          min="0"
          step="1"
          placeholder="Stock"
        />
      </label>

      <input
        ref={fileInputRef}
        className="hidden-file-input"
        type="file"
        accept="image/*"
        onChange={onImageChange}
        title={`Allowed formats: ${ALLOWED_IMAGE_EXTENSIONS.join(', ')} (Max ${MAX_FILE_SIZE_BYTES / (1024 * 1024)}MB)`}
      />

      <div className="image-upload full-width">
        <div
          className={`image-dropzone ${dragging ? 'dragging' : ''}`}
          role="button"
          tabIndex={0}
          onClick={() => fileInputRef.current && fileInputRef.current.click()}
          onDragOver={(event) => { event.preventDefault(); setDragging(true) }}
          onDragLeave={() => setDragging(false)}
          onDrop={onDrop}
          onKeyDown={(event) => {
            if (event.key === 'Enter' || event.key === ' ') {
              event.preventDefault()
              if (fileInputRef.current) fileInputRef.current.click()
            }
          }}
        >
          <img className="preview-thumb" src={form.image || FALLBACK_IMAGE} alt="Preview" />
          <div className="upload-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" focusable="false">
              <path d="M12 3l4 4h-3v6h-2V7H8l4-4zm-7 14h14v2H5v-2z" />
            </svg>
          </div>
          <span>Click to upload or drag image here</span>
          <small className="upload-hint">Formats: JPEG, PNG, GIF, WebP • Max size: 100KB</small>
        </div>
        {canRemoveImage && form.image ? (
          <button type="button" className="ghost small remove-image-btn" onClick={clearImage}>Remove Image</button>
        ) : null}
      </div>

      <label className="full-width">
        Description
        <textarea name="description" value={form.description} onChange={onChange} placeholder="Description" rows={3} />
      </label>

      <div className="form-actions full-width">
        <button type="button" className="ghost" onClick={onCancel}>Cancel</button>
        <button type="submit">{submitLabel}</button>
      </div>
    </form>
  )
}
