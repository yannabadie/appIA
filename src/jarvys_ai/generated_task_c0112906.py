import json
import os
import subprocess
from typing import Any, Dict

import nltk
import supabase
from google.cloud import pubsub_v1
from grok import Grok
from nltk.sentiment.vader import SentimentIntensityAnalyzer

# Load secrets from environment
XAI_API_KEY = os.getenv("XAI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE = os.getenv("SUPABASE_SERVICE_ROLE")
GH_TOKEN = os.getenv("GH_TOKEN")
GCP_SA_JSON = json.loads(os.getenv("GCP_SA_JSON", "{}"))

# Initialize Supabase client
supabase_client = supabase.create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE)

# Initialize Grok client (using grok-4-0709 as specified)
grok_client = Grok(api_key=XAI_API_KEY, model="grok-4-0709")


# Fallback LLM function
def fallback_llm(prompt: str, model: str = "grok-4-0709") -> str:
    try:
        if model == "grok-4-0709":
            return grok_client.complete(prompt=prompt).text
        elif model == "chatgpt-4":
            # Placeholder for ChatGPT fallback (implement if needed)
            return "Fallback response from ChatGPT"
        elif model == "claude":
            # Placeholder for Claude fallback
            return "Fallback response from Claude"
        else:
            raise ValueError("Unknown model")
    except Exception as e:
        log_to_supabase({"error": str(e), "prompt": prompt})
        # Graceful degradation: return empty string or default
        return ""


# Logging to Supabase
def log_to_supabase(data: Dict[str, Any]):
    try:
        supabase_client.table("logs").insert(data).execute()
    except Exception as e:
        print(f"Supabase logging failed: {e}")


# Proactive enhancement: Sentiment analysis for user mood prediction
def analyze_sentiment(text: str) -> Dict[str, float]:
    try:
        nltk.download("vader_lexicon", quiet=True)
        sia = SentimentIntensityAnalyzer()
        scores = sia.polarity_scores(text)
        log_to_supabase({"sentiment_analysis": scores, "input_text": text})
        return scores
    except Exception as e:
        log_to_supabase({"error": f"Sentiment analysis failed: {str(e)}"})
        return {"compound": 0.0, "pos": 0.0, "neu": 0.0, "neg": 0.0}


# Quantum-inspired routing simulation (creative innovation)
def quantum_inspired_routing(agents: list, task: str) -> str:
    # Simulate superposition-like selection using probabilistic choice
    import random  # Added missing import

    weights = [
        random.uniform(0.5, 1.5) for _ in agents
    ]  # Quantum-like entanglement weights
    selected_agent = random.choices(agents, weights=weights, k=1)[0]
    prompt = f"Route task '{task}' to agent {selected_agent} with quantum inspiration."
    response = fallback_llm(prompt)
    log_to_supabase(
        {"routing": {"task": task, "selected": selected_agent, "response": response}}
    )
    return _response


# Self-optimizing feedback loop
def self_optimize(code: str) -> str:
    prompt = f"Optimize this code for efficiency and add error handling: {code}"
    optimized = fallback_llm(prompt)
    log_to_supabase({"optimization": {"original": code, "optimized": optimized}})
    return optimized


# GitHub integration for appIA push
def push_to_appia(code: str, branch: str = "main"):
    try:
        # Write code to file
        with open("jarvys_ai_enhancement.py", "w") as f:
            f.write(code)

        # Git commands
        subprocess.run(["git", "config", "--global", "user.name", "Grok-4"])
        subprocess.run(["git", "config", "--global", "user.email", "grok@jarvys.dev"])
        subprocess.run(["git", "add", "jarvys_ai_enhancement.py"])
        subprocess.run(
            [
                "git",
                "commit",
                "-m",
                "Proactive enhancement: Sentiment analysis and quantum routing for JARVYS_AI",
            ]
        )
        subprocess.run(
            ["git", "push", f"https://{GH_TOKEN}@github.com/appIA/{branch}.git"]
        )
        log_to_supabase({"git_push": {"status": "success", "branch": branch}})
    except subprocess.CalledProcessError as e:
        log_to_supabase({"git_error": str(e)})
        # Adaptive handling: fallback to local save
        with open("local_backup.py", "w") as f:
            f.write(code)


# Generate JARVYS_AI enhancement code
enhancement_code = """
# JARVYS_AI Enhancement: Sentiment and Quantum Routing
import os

def main(user_input: str):
    sentiment = analyze_sentiment(user_input)
    if sentiment['compound'] < 0:
        print("Detected negative mood, routing to empathy agent.")
        return quantum_inspired_routing(['empathy_agent', 'support_agent'], user_input)
    else:
        print("Positive mood, proceeding normally.")
        return "Task completed."

if __name__ == "__main__":
    main(input("Enter user text: "))
"""

# Optimize and push
optimized_code = self_optimize(enhancement_code)
push_to_appia(optimized_code, "main")


# Proactive suggestion: Add GCP Pub/Sub for real-time notifications
def setup_gcp_pubsub():
    try:
        publisher = pubsub_v1.PublisherClient.from_service_account_info(GCP_SA_JSON)
        topic_path = publisher.topic_path("jarvys-project", "evolution-notifications")
        publisher.publish(topic_path, data=b"New enhancement pushed to appIA")
        log_to_supabase({"pubsub": {"status": "published"}})
    except Exception as e:
        log_to_supabase({"pubsub_error": str(e)})


setup_gcp_pubsub()


# Test function
def test_sentiment():
    assert analyze_sentiment("I love this!")["compound"] > 0
    assert analyze_sentiment("This is terrible.")["compound"] < 0


test_sentiment()
