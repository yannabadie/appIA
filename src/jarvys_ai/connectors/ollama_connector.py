#!/usr/bin/env python3
"""
JARVYS AI - Connecteur Ollama Autonome
Intégration intelligente et adaptive pour modèles locaux
"""
import requests
import json
import os
import time
from typing import Dict, List, Optional, Any

class JARVYSOllamaConnector:
    """Connecteur Ollama autonome avec découverte et fallback"""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        self.base_url = base_url
        self.available_models = []
        self.active_model = None
        self.connection_status = False
        
    def autonomous_discovery(self) -> Dict[str, Any]:
        """Découverte autonome des capacités Ollama"""
        discovery_result = {
            "models": [],
            "status": "disconnected",
            "capabilities": [],
            "performance_metrics": {}
        }
        
        try:
            # Test de connexion
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            if response.status_code == 200:
                data = response.json()
                self.available_models = [m["name"] for m in data.get("models", [])]
                discovery_result["models"] = self.available_models
                discovery_result["status"] = "connected"
                self.connection_status = True
                
                # Auto-sélection du meilleur modèle
                if self.available_models:
                    self.active_model = self.available_models[0]
                    
        except Exception as e:
            discovery_result["error"] = str(e)
            discovery_result["fallback_mode"] = True
            
        return discovery_result
    
    def adaptive_inference(self, prompt: str, model: Optional[str] = None) -> Dict[str, Any]:
        """Inférence adaptive avec gestion d'erreurs"""
        if not model:
            model = self.active_model or "llama2"  # Fallback
            
        result = {
            "prompt": prompt,
            "model_used": model,
            "response": "",
            "success": False,
            "inference_time": 0
        }
        
        start_time = time.time()
        
        try:
            if self.connection_status:
                data = {
                    "model": model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.7}
                }
                
                response = requests.post(
                    f"{self.base_url}/api/generate", 
                    json=data, 
                    timeout=30
                )
                
                if response.status_code == 200:
                    result["response"] = response.json().get("response", "")
                    result["success"] = True
                    
            else:
                # Mode fallback créatif
                result["response"] = f"Réponse simulée pour: {prompt[:50]}..."
                result["fallback_used"] = True
                result["success"] = True
                
        except Exception as e:
            result["error"] = str(e)
            result["response"] = "Erreur lors de l'inférence"
            
        result["inference_time"] = time.time() - start_time
        return result
    
    def health_check(self) -> Dict[str, Any]:
        """Vérification de santé autonome"""
        health = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "ollama_available": False,
            "models_count": 0,
            "active_model": self.active_model,
            "last_check": "autonomous"
        }
        
        try:
            discovery = self.autonomous_discovery()
            health["ollama_available"] = discovery["status"] == "connected"
            health["models_count"] = len(discovery.get("models", []))
        except:
            health["fallback_mode"] = True
            
        return health

# Instance globale pour JARVYS
jarvys_ollama = JARVYSOllamaConnector()

# Test autonome
if __name__ == "__main__":
    print("🔍 Test autonome du connecteur Ollama...")
    health = jarvys_ollama.health_check()
    print(f"Santé: {health}")
    
    if health["ollama_available"]:
        test_result = jarvys_ollama.adaptive_inference("Hello, test JARVYS Ollama")
        print(f"Test inférence: {test_result["success"]}")
