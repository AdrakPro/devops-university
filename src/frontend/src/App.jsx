import { useEffect, useState } from 'react'

import { createMovie, deleteMovie, getMovies } from './api'

const emptyForm = {
  title: '',
  year: new Date().getFullYear(),
  genre: '',
  rating: 7,
  description: '',
}

export default function App() {
  const [movies, setMovies] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  async function loadMovies() {
    try {
      setError('')
      setMovies(await getMovies())
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadMovies()
  }, [])

  function updateField(event) {
    const { name, value } = event.target
    setForm((current) => ({ ...current, [name]: value }))
  }

  async function handleSubmit(event) {
    event.preventDefault()
    try {
      setError('')
      await createMovie({
        ...form,
        year: Number(form.year),
        rating: Number(form.rating),
      })
      setForm(emptyForm)
      await loadMovies()
    } catch (err) {
      setError(err.message)
    }
  }

  async function handleDelete(id) {
    try {
      setError('')
      await deleteMovie(id)
      setMovies((current) => current.filter((movie) => movie.id !== id))
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="page">
      <header className="header">
        <h1>Movie Viewer</h1>
        <p>A tiny React + FastAPI + PostgreSQL boilerplate.</p>
      </header>

      <main className="layout">
        <section className="panel">
          <h2>Add a movie</h2>
          <form className="form" onSubmit={handleSubmit}>
            <label>
              Title
              <input
                name="title"
                value={form.title}
                onChange={updateField}
                placeholder="The Matrix"
                required
              />
            </label>

            <div className="row">
              <label>
                Year
                <input
                  name="year"
                  type="number"
                  min="1888"
                  max="2100"
                  value={form.year}
                  onChange={updateField}
                  required
                />
              </label>
              <label>
                Rating
                <input
                  name="rating"
                  type="number"
                  min="0"
                  max="10"
                  step="0.1"
                  value={form.rating}
                  onChange={updateField}
                />
              </label>
            </div>

            <label>
              Genre
              <input
                name="genre"
                value={form.genre}
                onChange={updateField}
                placeholder="Sci-Fi"
              />
            </label>

            <label>
              Description
              <textarea
                name="description"
                rows="3"
                value={form.description}
                onChange={updateField}
                placeholder="What is it about?"
              />
            </label>

            <button type="submit">Add movie</button>
          </form>
        </section>

        <section className="panel">
          <div className="panel-heading">
            <h2>Movies</h2>
            <span className="count">{movies.length}</span>
          </div>

          {error && <p className="error">{error}</p>}
          {loading && <p className="muted">Loading…</p>}
          {!loading && movies.length === 0 && (
            <p className="muted">No movies yet. Add the first one.</p>
          )}

          <ul className="movie-list">
            {movies.map((movie) => (
              <li key={movie.id} className="movie-card">
                <div className="movie-main">
                  <h3>{movie.title}</h3>
                  <p className="movie-meta">
                    {movie.year}
                    {movie.genre && ` · ${movie.genre}`}
                    {` · ★ ${Number(movie.rating).toFixed(1)}`}
                  </p>
                  {movie.description && (
                    <p className="movie-description">{movie.description}</p>
                  )}
                </div>
                <button
                  type="button"
                  className="danger"
                  onClick={() => handleDelete(movie.id)}
                  aria-label={`Delete ${movie.title}`}
                >
                  Delete
                </button>
              </li>
            ))}
          </ul>
        </section>
      </main>
    </div>
  )
}
