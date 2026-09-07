from .rag import search

CUSTOMERS = {
    "demo": {"name": "Demo Customer", "favorite_style": "cold and lightly sweet", "milk": "oat milk", "budget_inr": 300},
    "u_123": {"name": "Aarav", "favorite_style": "strong and less sweet", "milk": "dairy", "budget_inr": 250},
}

def get_customer_profile(customer_id: str = "demo"):
    return CUSTOMERS.get(customer_id, {"name": "Guest", "favorite_style": "balanced", "milk": "no preference", "budget_inr": 300})

def search_coffee_knowledge(query: str, top_k: int = 4):
    return search(query, top_k)

def recommend_coffee(customer_id: str, preference_request: str = "something I would like", budget_inr: int = 300):
    profile = get_customer_profile(customer_id)
    hits = search(f"{preference_request}. Customer likes {profile['favorite_style']}; milk: {profile['milk']}; budget ₹{budget_inr}", 6)
    return {"customer": profile, "recommendations": [h for h in hits if "₹" in h.get("content", "")][:3]}

def build_order(customer_id: str, item_query: str, quantity: int = 1):
    hits = search(item_query, 3)
    if not hits:
        return {"status": "not_found", "message": "No matching menu item found."}
    return {"status": "draft", "customer_id": customer_id, "item": hits[0], "quantity": max(1, min(quantity, 10)), "payment": "not processed", "submitted": False}
