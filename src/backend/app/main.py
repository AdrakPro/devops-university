from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models, schemas
from .database import Base, engine, get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Boilerplate convenience: create missing tables on startup. In a real
    # deployment, schema changes should go through migrations instead.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="Movie Viewer API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/movies", response_model=list[schemas.MovieOut])
def list_movies(db: Session = Depends(get_db)):
    return db.scalars(select(models.Movie).order_by(models.Movie.title)).all()


@app.get("/movies/{movie_id}", response_model=schemas.MovieOut)
def get_movie(movie_id: int, db: Session = Depends(get_db)):
    movie = db.get(models.Movie, movie_id)
    if movie is None:
        raise HTTPException(status_code=404, detail="Movie not found")
    return movie


@app.post(
    "/movies",
    response_model=schemas.MovieOut,
    status_code=status.HTTP_201_CREATED,
)
def create_movie(payload: schemas.MovieCreate, db: Session = Depends(get_db)):
    movie = models.Movie(**payload.model_dump())
    db.add(movie)
    db.commit()
    db.refresh(movie)
    return movie


@app.delete("/movies/{movie_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_movie(movie_id: int, db: Session = Depends(get_db)):
    movie = db.get(models.Movie, movie_id)
    if movie is None:
        raise HTTPException(status_code=404, detail="Movie not found")
    db.delete(movie)
    db.commit()
