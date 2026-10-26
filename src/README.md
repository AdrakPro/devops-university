# Movie Viewer

A simple movie viewer with three modules:

- **`database/`** — PostgreSQL schema and sample data
- **`backend/`** — Python FastAPI + SQLAlchemy
- **`frontend/`** — React + Vite

## Requirements

- Python 3.10+
- Node.js 18+
- PostgreSQL 14+

## 1. Set up the database

Create the database user and database (run as the PostgreSQL superuser):

```bash
sudo -u postgres psql -c "CREATE USER movie WITH PASSWORD 'movie';"
sudo -u postgres psql -c "CREATE DATABASE movies OWNER movie;"
```

Then create the tables and sample movies:

```bash
psql -U movie -d movies -f database/init.sql
# password: movie
```

`init.sql` is safe to run more than once.

## 2. Run the backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API is available at <http://localhost:8000>, with interactive docs at
<http://localhost:8000/docs>.

The default database connection is:

```
postgresql+psycopg2://movie:movie@localhost:5432/movies
```

Override it with the `DATABASE_URL` environment variable if yours differs:

```bash
export DATABASE_URL="postgresql+psycopg2://user:password@localhost:5432/movies"
```

## 3. Run the frontend

In a second terminal:

```bash
cd frontend
npm install
npm run dev
```

Open <http://localhost:5173>. The frontend calls the backend at
`http://localhost:8000` by default; override it with `VITE_API_URL`:

```bash
VITE_API_URL=http://localhost:8000 npm run dev
```

## Configuration

| Variable | Module | Default |
| --- | --- | --- |
| `DATABASE_URL` | backend | `postgresql+psycopg2://movie:movie@localhost:5432/movies` |
| `VITE_API_URL` | frontend | `http://localhost:8000` |

## API

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Health check |
| `GET` | `/movies` | List movies |
| `GET` | `/movies/{id}` | Get one movie |
| `POST` | `/movies` | Add a movie |
| `DELETE` | `/movies/{id}` | Delete a movie |

## Project structure

```
src/
├── database/
│   └── init.sql
├── backend/
│   ├── app/
│   │   ├── main.py        # API routes
│   │   ├── database.py    # DB connection
│   │   ├── models.py      # SQLAlchemy model
│   │   └── schemas.py     # Request/response schemas
│   └── requirements.txt
└── frontend/
    ├── src/
    │   ├── App.jsx
    │   ├── api.js
    │   └── styles.css
    ├── index.html
    ├── package.json
    └── vite.config.js
```

## Troubleshooting

- **Backend cannot connect to PostgreSQL** — verify PostgreSQL is running and
  that `DATABASE_URL` matches your user, password, host, and database name.
- **Frontend shows a network/API error** — make sure the backend is running on
  port 8000 and that `VITE_API_URL` points to it.
