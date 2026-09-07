import json
from pathlib import Path

def test_knowledge_json_valid():
    data = json.loads((Path(__file__).parents[1] / "data" / "knowledge.json").read_text())
    assert len(data) >= 5

def test_menu_records_have_prices():
    data = json.loads((Path(__file__).parents[1] / "data" / "knowledge.json").read_text())
    menus = [x for x in data if x["id"].startswith("menu-")]
    assert all("₹" in x["content"] for x in menus)
