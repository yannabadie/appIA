import os
import random

from supabase import Client, create_client
from textblob import TextBlob


class JARVYS_AI:
    def __init__(self):
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_SERVICE_ROLE")
        self.client: Client = create_client(self.supabase_url, self.supabase_key)
        self.llm_models = ["model_a", "model_b", "model_c"]  # Mock LLM models
        self.memory_table = "ai_memory"

    def analyze_sentiment(self, input_text: str) -> float:
        blob = TextBlob(input_text)
        return blob.sentiment.polarity

    def quantum_inspired_decision(self, options: list, probabilities: list) -> str:
        if len(options) != len(probabilities):
            raise ValueError("Options and probabilities must match in length")
        normalized_probs = [p / sum(probabilities) for p in probabilities]
        return random.choices(options, weights=normalized_probs, k=1)[0]

    def route_to_llm(self, input_text: str) -> str:
        sentiment = self.analyze_sentiment(input_text)
        if sentiment > 0.5:
            probs = [0.7, 0.2, 0.1]  # Bias towards model_a for positive
        elif sentiment < -0.5:
            probs = [0.1, 0.7, 0.2]  # Bias towards model_b for negative
        else:
            probs = [0.3, 0.3, 0.4]  # Balanced for neutral
        selected_model = self.quantum_inspired_decision(self.llm_models, probs)
        # Mock LLM call
        return f"Routed to {selected_model} with response: Processed '{input_text}'"

    def store_memory(self, key: str, value: str):
        data = {"key": key, "value": value}
        self.client.table(self.memory_table).insert(data).execute()

    def retrieve_memory(self, key: str) -> str:
        response = (
            self.client.table(self.memory_table)
            .select("value")
            .eq("key", key)
            .execute()
        )
        if response.data:
            return response.data[0]["value"]
        return None

    def self_improve(self, feedback: str) -> str:
        sentiment = self.analyze_sentiment(feedback)
        if sentiment < 0:
            enhancement = "Add more robust error handling."
        else:
            enhancement = "Integrate additional LLM models."
        # Proactive enhancement: Suggest quantum simulation improvement
        quantum_suggest = "Enhance quantum decision with actual Qiskit integration."
        return (
            f"Self-improvement suggestion: {enhancement} | Proactive: {quantum_suggest}"
        )


if __name__ == "__main__":
    ai = JARVYS_AI()
    test_input = "This is a great day!"
    routed = ai.route_to_llm(test_input)
    print(routed)
    ai.store_memory("test_input", test_input)
    retrieved = ai.retrieve_memory("test_input")
    print(f"Retrieved: {retrieved}")
    improvement = ai.self_improve("The routing could be better.")
    print(improvement)
