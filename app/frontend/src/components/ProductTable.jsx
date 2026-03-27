import { FALLBACK_IMAGE } from '../api/client'

function formatCurrency(value) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value)
}

export default function ProductTable({ products, onView, onEdit, onDelete }) {
  if (!products.length) {
    return <p className="muted">No products found. Try changing filters or add a new product.</p>
  }

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>Image</th>
            <th>Name</th>
            <th>Price</th>
            <th>Color</th>
            <th>Category</th>
            <th>Stock</th>
            <th>Description</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {products.map((item) => (
            <tr key={item.id}>
              <td>
                <img
                  className="thumb"
                  src={item.image || FALLBACK_IMAGE}
                  alt={item.name}
                />
              </td>
              <td>{item.name}</td>
              <td>{formatCurrency(item.price)}</td>
              <td>{item.color}</td>
              <td>{item.category || '-'}</td>
              <td>{item.stock ?? 0}</td>
              <td>{item.description || '-'}</td>
              <td className="actions-cell">
                <div className="actions-row">
                  <button className="ghost small" type="button" onClick={() => onView(item)}>View</button>
                  <button className="small" type="button" onClick={() => onEdit(item)}>Edit</button>
                  <button className="danger small" type="button" onClick={() => onDelete(item)}>Delete</button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
