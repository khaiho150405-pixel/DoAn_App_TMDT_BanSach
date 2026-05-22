# VertTopKDS / FHM-DS Algorithm Knowledge Base

## Overview

VertTopKDS is a Top-K High Utility Itemset Mining algorithm designed for data stream environments using a sliding window model.

The algorithm focuses on discovering the K most profitable itemsets based on utility instead of frequency.

This project uses VertTopKDS to:
- identify highly profitable books
- identify profitable book combinations
- generate automatic promotions
- generate combo promotions
- optimize business revenue

---

# Core Concepts

## Utility Mining

Unlike frequent itemset mining, utility mining considers:
- quantity
- profit
- business value

### Definitions

#### Internal Utility
Quantity of an item inside a transaction.

Example:
Book A purchased 3 times.

#### External Utility
Business profit/value of an item.

Example:
Book A profit = 50,000 VND.

#### Utility of an Item

Utility(item) =
Internal Utility × External Utility

#### Utility of an Itemset

Utility(X) =
Sum of all utilities of X across transactions.

---

# Sliding Window Model

The system processes transaction streams using:
- sliding windows
- batch-based updates

Old transactions are removed when the window moves forward.

Benefits:
- real-time mining
- lower memory usage
- adaptive business intelligence

---

# Vertical Utility List Structure

The algorithm uses a fragmented vertical utility-list structure customized for data streams. 
Instead of a flat array, each item or itemset maintains a FIFO queue or map partitioned by Batch IDs to allow quick insertion and deletion of expired stream data without re-scanning.

Each UtilityList instance contains:
- item: ID of the item/itemset
- sumIutils: total exact utility in the current window
- sumRutils: total remaining utility in the current window
- batches: HashMap<Integer, Batch> where the key is batch_id

Each Batch instance contains:
- elements: List of Element tuples: (tid, eu, ru)
- sum_batch_iutils: accumulated exact utility for this specific batch
- sum_batch_rutils: accumulated remaining utility for this specific batch

# Mining Strategy

The algorithm uses:
- depth-first search
- utility-list joins
- vertical mining

instead of:
- Apriori candidate generation
- FP-Growth tree structures

---

# Pruning Strategies

## 1. TWU Pruning (Transaction Weighted Utility)
Transaction Weighted Utility (TWU) is calculated for single items. Items with a total TWU across the current window less than the current Top-K threshold are eliminated immediately before constructing utility lists.

## 2. FMAP Co-occurrence Pruning (The Core FHM Optimization)
The system must maintain an Estimated Utility Co-occurrence Structure via a map named `mapFMAP` (Matrix of Item Pairs -> TWU sum across batches).
- Before performing a Utility List Join between item X and item Y, the system must look up the pair (X, Y) in `mapFMAP`.
- If `mapFMAP.get(X).get(Y).sumTWU < current_top_k_threshold`, the algorithm MUST skip the join process entirely, avoiding memory allocation and pointer traversal for that branch.

## 3. Remaining Utility Pruning (Deeper DFS Cuts)
During Depth-First Search (DFS) extension:
If `X.sumIutils + X.sumRutils < current_top_k_threshold`, then itemset X and all of its possible ancestral supersets are pruned immediately.
# Item Sorting and Consistency Strategy

To maintain mathematical accuracy for Remaining Utility (RU) computation and deterministic utility list intersection:
1. All items within any transaction must be sorted in **Ascending Order of their total TWU (Transaction Weighted Utility)**.
2. The item ordering matrix established in the very first window (`initial_call_FHM`) must be locked and reused consistently for all subsequent window updates (`update_FHM`). Do NOT recalculate the global item sorting order from scratch upon every sliding step, as it breaks the vertical list lookup chain.
3. During the DFS mining process, when exploring extensions, only combine the current itemset with items that rank AFTER it according to this pre-defined global sorting order.

# Top-K Threshold Initialization (Pre-insertion)

To avoid scanning the search space with a loose threshold of 0:
1. Before invoking the recursive Miner engine, the system must calculate the exact utility of all single distinct items in the window.
2. Push these single items directly into the Top-K Priority Queue.
3. Once the queue reaches size K, extract the minimum utility score in the queue and set it as the initial dynamic `current_top_k_threshold`.
4. Additionally, reuse the top-k threshold computed from the overlapping (common) batches of the previous window to seed the minimum threshold for the newly shifted window.
## TWU Pruning

Transaction Weighted Utility (TWU) is used to eliminate low-potential itemsets early.

If:
TWU(X) < current threshold

Then:
X is pruned.

---

## Remaining Utility Pruning

Upper-bound pruning using remaining utility.

If:
EU(X) + RU(X) < threshold

Then:
X is pruned.

---

# Dynamic Top-K Threshold Raising

Instead of a fixed minimum utility threshold:

The system dynamically raises the threshold as better itemsets are discovered.

Benefits:
- fewer candidates
- faster mining
- better scalability

---

# Utility List Join

New itemsets are generated by joining utility lists.

Optimization:
- two-pointer traversal
- avoid binary search
- avoid full rescans

Pseudo Flow:
1. scan two utility lists
2. match tids
3. combine utilities
4. compute remaining utility

---

# Sliding Window Update Logic

When a new batch arrives:
1. insert new transactions
2. remove expired transactions
3. update utility lists
4. update top-k threshold
5. rerun mining incrementally

---

# Business Mapping

## Single Itemset

If an itemset contains:
1 item

Then:
- generate discount promotion

Example:
- Book A → 15% OFF

---

## Combo Itemset

If an itemset contains:
multiple items

Then:
- generate combo promotion

Example:
- Book A + Book B
- Combo price discount

---

# Promotion Generation Rules

## Single Product Promotion

Conditions:
- high utility
- high profitability

Actions:
- create discount campaign
- prioritize homepage visibility

---

## Combo Promotion

Conditions:
- strong co-purchase utility
- high combined profit

Actions:
- create combo package
- display combo banner
- recommend together

---

# Performance Requirements

The implementation must:
- support large transaction streams
- support incremental updates
- avoid full rescans
- minimize memory usage
- support production-scale datasets

---

# Technical Requirements

Preferred Stack:
- Python
- FastAPI
- SQLAlchemy
- Pandas (optional)

Optimization Requirements:
- modular architecture
- reusable services
- clean architecture
- repository pattern

---

# Forbidden Replacements

Do NOT replace VertTopKDS with:
- Apriori
- FP-Growth
- association-rule-only mining
- frequency-only mining

The system must preserve:
- utility-based mining
- top-k mining
- sliding-window processing
- utility-list structure

---

# Project Integration

Architecture:

Flutter
→ ASP.NET Core API
→ FastAPI Mining Service
→ SQL Server

---

# Expected Outputs

The mining engine should return:

```json
{
  "rank": 1,
  "itemset": ["Book A", "Book B"],
  "utilityScore": 1520000,
  "promotionType": "combo"
}