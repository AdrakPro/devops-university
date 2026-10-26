from pydantic import BaseModel, ConfigDict, Field


class MovieCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    year: int = Field(ge=1888, le=2100)
    genre: str = Field(default="", max_length=80)
    rating: float = Field(default=0, ge=0, le=10)
    description: str = ""


class MovieOut(MovieCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)
