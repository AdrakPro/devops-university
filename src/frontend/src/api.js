const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })

  if (!response.ok) {
    const body = await response.json().catch(() => ({}))
    throw new Error(body.detail || `Request failed (${response.status})`)
  }

  if (response.status === 204) return null
  return response.json()
}

export function getMovies() {
  return request('/movies')
}

export function createMovie(movie) {
  return request('/movies', {
    method: 'POST',
    body: JSON.stringify(movie),
  })
}

export function deleteMovie(id) {
  return request(`/movies/${id}`, { method: 'DELETE' })
}
