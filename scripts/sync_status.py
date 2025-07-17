#!/usr/bin/env python3
"""
sync_status.py - Update JARVYS_AI status in Supabase
"""

import requests
import json
import os
from datetime import datetime

def main():
    print("🔄 Synchronisation avec JARVYS_DEV")
    
    # Mettre à jour le statut JARVYS_AI  
    status_data = {
        'agent_id': 'jarvys_ai_local',
        'status': 'active',
        'last_seen': datetime.now().isoformat(),
        'capabilities': ['code_analysis', 'local_execution', 'repository_management'],
        'location': 'github_actions',
        'version': '1.0.0'
    }

    headers = {
        'apikey': os.environ['SUPABASE_KEY'],
        'Authorization': 'Bearer ' + os.environ['SUPABASE_KEY'],
        'Content-Type': 'application/json'
    }

    try:
        response = requests.post(
            os.environ['SUPABASE_URL'] + '/rest/v1/jarvys_agents_status',
            headers=headers,
            json=status_data
        )
        print(f'✅ Statut mis à jour: {response.status_code}')
    except Exception as e:
        print(f'⚠️ Erreur sync: {e}')
    
    print("✅ Synchronisation terminée")

if __name__ == "__main__":
    main()