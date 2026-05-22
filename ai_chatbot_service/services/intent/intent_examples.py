from __future__ import annotations


INTENT_EXAMPLES: dict[str, list[str]] = {
    "greeting": [
        "xin chao",
        "chao ban",
        "hello",
        "hi",
        "hey",
        "tu van giup minh",
        "ban oi",
    ],
    "faq": [
        "phi ship",
        "van chuyen",
        "doi tra",
        "hoan tien",
        "bao hanh",
        "thanh toan",
        "cod",
        "giao hang bao lau",
        "lien he cua hang",
        "gio lam viec",
    ],
    "search_book": [
        "tim sach",
        "kiem sach",
        "co sach",
        "sach ten",
        "sach cua tac gia",
        "the loai",
        "gia tu",
        "duoi",
        "tren",
        "con hang",
    ],
    "recommend_book": [
        "goi y",
        "de xuat",
        "nen doc",
        "sach hay",
        "tuong tu",
        "giong",
        "phu hop",
        "minh thich",
        "recommend",
    ],
    "promotion": [
        "khuyen mai",
        "giam gia",
        "uu dai",
        "sale",
        "voucher",
        "ma giam gia",
        "flash sale",
        "dang sale",
    ],
}


INTENT_PRIORITY: dict[str, int] = {
    "promotion": 5,
    "recommend_book": 4,
    "search_book": 3,
    "faq": 2,
    "greeting": 1,
}
