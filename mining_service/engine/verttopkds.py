"""
VertTopKDS / FHM-DS  —  Top-K High Utility Itemset Mining for Data Streams
===========================================================================
Implements:
  • Vertical Utility-List structure (fragmented by batch)
  • Depth-First Search with two-pointer utility-list join
  • THREE pruning strategies:
      1. TWU pruning
      2. FMAP co-occurrence pruning
      3. Remaining-utility pruning
  • Dynamic Top-K threshold raising via min-heap
  • Items sorted by ascending TWU for consistent RU computation
"""

from __future__ import annotations

import heapq
from collections import defaultdict
from typing import Dict, FrozenSet, List, NamedTuple, Tuple


# ── Data Structures ─────────────────────────────────────────────────────────

class Element(NamedTuple):
    """One entry inside a utility list, tied to a single transaction."""
    tid: int        # Transaction ID
    eu: float       # Exact utility of the itemset in this transaction
    ru: float       # Remaining utility after this itemset in the transaction


class UtilityList:
    """
    Vertical utility list for one itemset.
    Stores elements and running sums for quick pruning checks.
    """
    __slots__ = ("items", "elements", "sum_iutils", "sum_rutils")

    def __init__(self, items: FrozenSet[int]):
        self.items: FrozenSet[int] = items
        self.elements: List[Element] = []
        self.sum_iutils: float = 0.0
        self.sum_rutils: float = 0.0

    def add_element(self, elem: Element) -> None:
        self.elements.append(elem)
        self.sum_iutils += elem.eu
        self.sum_rutils += elem.ru

    def __repr__(self) -> str:
        return (
            f"UL({set(self.items)}, "
            f"iutil={self.sum_iutils:.0f}, rutil={self.sum_rutils:.0f}, "
            f"elems={len(self.elements)})"
        )


class TopKResult(NamedTuple):
    """One entry in the final Top-K output."""
    itemset: List[int]
    utility: float


# ── FMAP Structure ──────────────────────────────────────────────────────────

class FMAPEntry:
    """Stores aggregated TWU for a pair of items across all transactions."""
    __slots__ = ("sum_twu",)

    def __init__(self) -> None:
        self.sum_twu: float = 0.0


# ── Main Mining Engine ──────────────────────────────────────────────────────

class VertTopKDS:
    """
    Top-K High Utility Itemset Miner using Vertical Utility Lists.

    Parameters
    ----------
    k : int
        Number of top itemsets to discover.

    Usage
    -----
    >>> engine = VertTopKDS(k=5)
    >>> results = engine.mine(transactions, external_utilities)
    """

    def __init__(self, k: int = 10):
        if k < 1:
            raise ValueError("k must be >= 1")
        self.k = k

        # Min-heap of (-utility, frozenset) — we negate so heapq gives us
        # the *smallest* utility at heap[0], i.e. the threshold boundary.
        self._topk_heap: List[Tuple[float, int, FrozenSet[int]]] = []
        self._heap_counter: int = 0  # tie-breaker for heap stability

        self._min_utility: float = 0.0  # current dynamic threshold

        # Global TWU per single item
        self._twu: Dict[int, float] = {}

        # FMAP: item -> item -> FMAPEntry
        self._fmap: Dict[int, Dict[int, FMAPEntry]] = defaultdict(
            lambda: defaultdict(FMAPEntry)
        )

        # Ordered list of items by ascending TWU (set once, reused)
        self._item_order: List[int] = []
        self._item_rank: Dict[int, int] = {}  # item -> position in _item_order

    # ── Public API ──────────────────────────────────────────────────────

    def mine(
        self,
        transactions: List[Dict],
        external_utilities: Dict[int, float],
    ) -> List[TopKResult]:
        """
        Run Top-K mining on a set of transactions.

        Parameters
        ----------
        transactions : list of dict
            Each dict: {"tid": int, "items": [{"item_id": int, "quantity": int}]}
        external_utilities : dict
            Mapping item_id -> profit/unit (external utility).

        Returns
        -------
        List of TopKResult, sorted by utility descending.
        """
        if not transactions:
            return []

        # Reset state
        self._topk_heap.clear()
        self._heap_counter = 0
        self._min_utility = 0.0
        self._twu.clear()
        self._fmap.clear()

        # ── Phase 1: Calculate TWU for all single items ─────────────
        # TWU(item) = sum of TU for all transactions containing item
        # TU(transaction) = sum of utility of all items in that transaction
        transaction_utilities: Dict[int, float] = {}
        for txn in transactions:
            tid = txn["tid"]
            tu = 0.0
            for entry in txn["items"]:
                iid = entry["item_id"]
                qty = entry["quantity"]
                eu = external_utilities.get(iid, 0)
                tu += qty * eu
            transaction_utilities[tid] = tu

            for entry in txn["items"]:
                iid = entry["item_id"]
                self._twu[iid] = self._twu.get(iid, 0) + tu

        # ── Phase 2: Item ordering — ascending TWU ──────────────────
        self._item_order = sorted(self._twu.keys(), key=lambda x: self._twu[x])
        self._item_rank = {item: rank for rank, item in enumerate(self._item_order)}

        # ── Phase 3: Pre-seed Top-K with single-item exact utilities ─
        single_utils: Dict[int, float] = defaultdict(float)
        for txn in transactions:
            for entry in txn["items"]:
                iid = entry["item_id"]
                qty = entry["quantity"]
                eu = external_utilities.get(iid, 0)
                single_utils[iid] += qty * eu

        for item_id, util in single_utils.items():
            self._insert_topk(frozenset([item_id]), util)

        # ── Phase 4: Build FMAP (co-occurrence TWU matrix) ──────────
        for txn in transactions:
            tu = transaction_utilities[txn["tid"]]
            items_sorted = sorted(
                [e["item_id"] for e in txn["items"]],
                key=lambda x: self._item_rank.get(x, 0),
            )
            for i, item_x in enumerate(items_sorted):
                for j in range(i + 1, len(items_sorted)):
                    item_y = items_sorted[j]
                    self._fmap[item_x][item_y].sum_twu += tu
                    self._fmap[item_y][item_x].sum_twu += tu

        # ── Phase 5: Build initial utility lists for single items ───
        # TWU pruning: skip items whose TWU < threshold
        valid_items = [
            item for item in self._item_order
            if self._twu[item] >= self._min_utility
        ]

        utility_lists: Dict[int, UtilityList] = {}
        for item in valid_items:
            utility_lists[item] = UtilityList(frozenset([item]))

        for txn in transactions:
            tid = txn["tid"]
            # Sort items in transaction by global TWU ascending
            entries_sorted = sorted(
                txn["items"],
                key=lambda e: self._item_rank.get(e["item_id"], 0),
            )

            # Only keep valid items
            entries_valid = [
                e for e in entries_sorted if e["item_id"] in utility_lists
            ]

            for idx, entry in enumerate(entries_valid):
                iid = entry["item_id"]
                qty = entry["quantity"]
                eu = qty * external_utilities.get(iid, 0)

                # Remaining utility = sum of utilities of items AFTER this one
                ru = 0.0
                for later in entries_valid[idx + 1:]:
                    ru += later["quantity"] * external_utilities.get(
                        later["item_id"], 0
                    )

                utility_lists[iid].add_element(Element(tid=tid, eu=eu, ru=ru))

        # ── Phase 6: DFS Mining ─────────────────────────────────────
        # Process items in ascending TWU order
        valid_uls = [utility_lists[item] for item in valid_items if item in utility_lists]

        for i, ul_x in enumerate(valid_uls):
            extensions = valid_uls[i + 1:]
            self._dfs_mine(ul_x, extensions, external_utilities)

        # ── Collect results ─────────────────────────────────────────
        results = []
        for neg_util, _counter, itemset in self._topk_heap:
            results.append(TopKResult(
                itemset=sorted(itemset),
                utility=-neg_util,
            ))
        results.sort(key=lambda r: r.utility, reverse=True)
        return results

    # ── DFS Mining Core ─────────────────────────────────────────────

    def _dfs_mine(
        self,
        prefix_ul: UtilityList,
        extensions: List[UtilityList],
        ext_utils: Dict[int, float],
    ) -> None:
        """Depth-first exploration of the search space."""

        # Try to insert prefix itself
        self._insert_topk(prefix_ul.items, prefix_ul.sum_iutils)

        # Remaining utility pruning: if iutil + rutil < threshold, prune
        if prefix_ul.sum_iutils + prefix_ul.sum_rutils < self._min_utility:
            return

        new_extensions: List[UtilityList] = []

        for ext_ul in extensions:
            # ── FMAP co-occurrence pruning ──────────────────────────
            # Check all pairs between prefix items and extension item
            skip = False
            ext_item = next(iter(ext_ul.items - prefix_ul.items), None)
            if ext_item is not None:
                for prefix_item in prefix_ul.items:
                    fmap_entry = self._fmap.get(prefix_item, {}).get(ext_item)
                    if fmap_entry and fmap_entry.sum_twu < self._min_utility:
                        skip = True
                        break
            if skip:
                continue

            # ── Utility-list join (two-pointer merge) ──────────────
            joined = self._join(prefix_ul, ext_ul)
            if joined is None:
                continue

            # Pruning after join
            if joined.sum_iutils + joined.sum_rutils >= self._min_utility:
                new_extensions.append(joined)
                # Recurse
                idx = new_extensions.index(joined)
                self._dfs_mine(
                    joined,
                    new_extensions[idx + 1:],
                    ext_utils,
                )

    # ── Utility-List Join ───────────────────────────────────────────

    def _join(
        self,
        ul_p: UtilityList,
        ul_x: UtilityList,
    ) -> UtilityList | None:
        """
        Join two utility lists using two-pointer traversal.
        Returns a new UtilityList for the combined itemset, or None if empty.
        """
        new_items = ul_p.items | ul_x.items
        joined = UtilityList(new_items)

        i = j = 0
        elems_p = ul_p.elements
        elems_x = ul_x.elements

        while i < len(elems_p) and j < len(elems_x):
            ep = elems_p[i]
            ex = elems_x[j]

            if ep.tid == ex.tid:
                # Both present in same transaction
                new_eu = ep.eu + ex.eu
                new_ru = min(ep.ru, ex.ru)
                # Adjust: subtract the utility of the extension item from ru
                # since it's now part of the itemset
                new_ru = ex.ru  # remaining utility after the later item
                joined.add_element(Element(tid=ep.tid, eu=new_eu, ru=new_ru))
                i += 1
                j += 1
            elif ep.tid < ex.tid:
                i += 1
            else:
                j += 1

        if not joined.elements:
            return None
        return joined

    # ── Top-K Management ────────────────────────────────────────────

    def _insert_topk(self, itemset: FrozenSet[int], utility: float) -> None:
        """Insert an itemset into the top-k heap and raise threshold."""
        if utility <= 0:
            return

        if len(self._topk_heap) < self.k:
            self._heap_counter += 1
            heapq.heappush(
                self._topk_heap,
                (-utility, self._heap_counter, itemset),
            )
            if len(self._topk_heap) == self.k:
                # Threshold = utility of the weakest entry
                self._min_utility = -self._topk_heap[0][0]
        elif utility > self._min_utility:
            self._heap_counter += 1
            heapq.heapreplace(
                self._topk_heap,
                (-utility, self._heap_counter, itemset),
            )
            self._min_utility = -self._topk_heap[0][0]
