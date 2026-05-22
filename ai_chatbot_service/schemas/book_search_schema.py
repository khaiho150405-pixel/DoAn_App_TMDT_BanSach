from pydantic import BaseModel, Field, model_validator


class BookSearchRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=150)
    category: str | None = Field(default=None, min_length=1, max_length=50)
    author: str | None = Field(default=None, min_length=1, max_length=100)
    min_price: float | None = Field(default=None, ge=0, alias="minPrice")
    max_price: float | None = Field(default=None, ge=0, alias="maxPrice")
    in_stock_only: bool = Field(default=True, alias="inStockOnly")
    limit: int = Field(default=10, ge=1, le=50)
    offset: int = Field(default=0, ge=0)

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "example": {
                "title": "Clean Code",
                "category": "Cong nghe",
                "author": "Robert",
                "minPrice": 100000,
                "maxPrice": 500000,
                "inStockOnly": True,
                "limit": 10,
                "offset": 0,
            }
        },
    }

    @model_validator(mode="after")
    def validate_price_range(self) -> "BookSearchRequest":
        if (
            self.min_price is not None
            and self.max_price is not None
            and self.min_price > self.max_price
        ):
            raise ValueError("minPrice must be less than or equal to maxPrice")
        return self


class BookSearchResult(BaseModel):
    book_id: int = Field(alias="bookId")
    title: str
    image: str | None = None
    description: str | None = None
    price: float
    stock_quantity: int = Field(alias="stockQuantity")
    author_id: int = Field(alias="authorId")
    author: str
    category_id: int = Field(alias="categoryId")
    category: str

    model_config = {"populate_by_name": True}


class BookSearchResponse(BaseModel):
    items: list[BookSearchResult] = Field(default_factory=list)
    total: int = 0
    limit: int
    offset: int
