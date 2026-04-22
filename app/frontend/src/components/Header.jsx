const APP_VERSION = import.meta.env.VITE_APP_VERSION || 'v1.0.0'

function normalizeHost(host) {
  if (!host) return '-'
  return String(host).split(',')[0].trim()
}

export default function Header({ sourceInfo, loading }) {
  const statusLabel = loading ? 'Connecting' : (sourceInfo?.status || 'Online')
  const hostLabel = normalizeHost(sourceInfo?.host)
  const sourceLabel = sourceInfo?.source ? String(sourceInfo.source) : '-'
  const versionLabel = sourceInfo?.version || APP_VERSION

  return (
    <header className="header">
      <div className="header-main">
        <div className="header-title-row">
          <span className="header-logo" aria-hidden="true">PM</span>
          <h1>Product Management System</h1>
        </div>
        <p className="muted">Manage products, inventory, and content from one control panel.</p>
      </div>
      <div className="meta-panel">
        <div className="meta-panel-title">Runtime Info</div>
        <div className="meta-grid">
          <span className="meta-label">Status</span>
          <span className="meta-value">{statusLabel}</span>

          <span className="meta-label">Host</span>
          <span className="meta-value">{hostLabel}</span>

          <span className="meta-label">Source</span>
          <span className="meta-value">{sourceLabel}</span>

          <span className="meta-label">Tier</span>
          <span className="meta-value">{sourceInfo?.tier || '-'}</span>

          <span className="meta-label">Version</span>
          <span className="meta-value">{versionLabel}</span>
        </div>
      </div>
    </header>
  )
}
