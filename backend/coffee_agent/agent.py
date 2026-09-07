import os
from dotenv import load_dotenv
from google.adk.agents import Agent
from .tools import get_customer_profile, recommend_coffee, search_coffee_knowledge, build_order

load_dotenv()
MODEL = os.getenv("COFFEE_AGENT_MODEL", "gemini-2.5-flash")
INSTRUCTION = """You are Coffee AI, a personalized coffee-shop assistant.
Use the customer profile for personalization. Use search_coffee_knowledge for
product-specific claims and recommend_coffee for recommendations.
Never invent products, prices, ingredients, allergens, sizes, or availability.
If information is missing, say so. Do not make medical claims. For severe
allergies, advise confirmation with shop staff. Keep answers concise."""
root_agent = Agent(name="coffee_agent", model=MODEL, description="Personalized coffee recommendation and ordering assistant.", instruction=INSTRUCTION, tools=[get_customer_profile, search_coffee_knowledge, recommend_coffee, build_order])
