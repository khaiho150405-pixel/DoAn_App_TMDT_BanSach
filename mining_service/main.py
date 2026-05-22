"""
Mining Service — FastAPI microservice for VertTopKDS Top-K Utility Mining.

Endpoints:
  GET  /health       → Health check
  POST /mine/topk    → Run Top-K High Utility Itemset Mining
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from engine.verttopkds import VertTopKDS

# ── FastAPI App ──────────────────────────────────────────────────────────────

app = FastAPI(
    title="BookStore Mining Service (VertTopKDS)",
    description="Top-K High Utility Itemset Mining for bookstore transactions",
    version="1.0.0",
)


# ── Request / Response Models ────────────────────────────────────────────────

class TransactionItem(BaseModel):
    item_id: int = Field(alias="itemId")
    quantity: int = 1
    book_name: Optional[str] = Field(default=None, alias="bookName")
    book_image: Optional[str] = Field(default=None, alias="bookImage")

    model_config = {"populate_by_name": True}


class Transaction(BaseModel):
    tid: int
    items: List[TransactionItem]


class MineRequest(BaseModel):
    k: int = Field(default=10, ge=1, le=100)
    transactions: List[Transaction]
    external_utilities: Dict[str, float] = Field(
        default_factory=dict, alias="externalUtilities"
    )
    # Metadata mapping item_id -> book info for response enrichment
    book_metadata: Dict[str, Dict[str, Any]] = Field(
        default_factory=dict, alias="bookMetadata"
    )

    model_config = {"populate_by_name": True}


class MineResultItem(BaseModel):
    rank: int
    itemset: List[int]
    item_names: List[str] = Field(alias="itemNames")
    item_images: List[str] = Field(alias="itemImages")
    utility_score: float = Field(alias="utilityScore")
    promotion_type: str = Field(alias="promotionType")  # "single" or "combo"

    model_config = {"populate_by_name": True}


class MineResponse(BaseModel):
    k: int
    total_transactions: int = Field(alias="totalTransactions")
    total_items: int = Field(alias="totalItems")
    results: List[MineResultItem]
    threshold: float

    model_config = {"populate_by_name": True}


# ── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok", "service": "mining-verttopkds"}


@app.post("/mine/topk", response_model=MineResponse)
def mine_topk(request: MineRequest) -> MineResponse:
    """
    Run VertTopKDS Top-K mining on the provided transactions.
    """
    if not request.transactions:
        return MineResponse(
            k=request.k,
            totalTransactions=0,
            totalItems=0,
            results=[],
            threshold=0,
        )

    # Convert external utilities keys from string to int
    ext_utils: Dict[int, float] = {}
    for key, value in request.external_utilities.items():
        try:
            ext_utils[int(key)] = value
        except (ValueError, TypeError):
            continue

    # Convert transactions to engine format
    engine_transactions = []
    all_items = set()
    for txn in request.transactions:
        items = []
        for item in txn.items:
            items.append({
                "item_id": item.item_id,
                "quantity": item.quantity,
            })
            all_items.add(item.item_id)
            # Auto-fill external utility from items if not provided
            if item.item_id not in ext_utils:
                ext_utils[item.item_id] = 1.0  # default
        engine_transactions.append({
            "tid": txn.tid,
            "items": items,
        })

    # Run mining engine with a larger internal K to allow robust filtering of duplicates
    internal_k = max(request.k * 5, 100)
    try:
        engine = VertTopKDS(k=internal_k)
        raw_results = engine.mine(engine_transactions, ext_utils)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Mining engine error: {e}")

    # Filter out duplicate items (each item/book can only appear once in the final list)
    filtered_results = []
    seen_items = set()
    for result in raw_results:
        # If any item in the itemset has already been seen in a higher utility result, skip it
        if any(item in seen_items for item in result.itemset):
            continue
        filtered_results.append(result)
        seen_items.update(result.itemset)
        # Limit to the requested K
        if len(filtered_results) >= request.k:
            break

    # Enrich results with book metadata
    results: List[MineResultItem] = []
    for rank, result in enumerate(filtered_results, start=1):
        item_names = []
        item_images = []
        for item_id in result.itemset:
            meta = request.book_metadata.get(str(item_id), {})
            item_names.append(meta.get("name", f"Sách #{item_id}"))
            item_images.append(meta.get("image", "default_book.jpg"))

        results.append(MineResultItem(
            rank=rank,
            itemset=result.itemset,
            itemNames=item_names,
            itemImages=item_images,
            utilityScore=round(result.utility, 0),
            promotionType="single" if len(result.itemset) == 1 else "combo",
        ))

    return MineResponse(
        k=request.k,
        totalTransactions=len(request.transactions),
        totalItems=len(all_items),
        results=results,
        threshold=engine._min_utility if raw_results else 0,
    )
