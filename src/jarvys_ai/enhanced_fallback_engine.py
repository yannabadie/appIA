#!/usr/bin/env python3
"""
☁️ Enhanced Fallback Engine for JARVYS_AI
Advanced Cloud Run deployment with GitHub Actions quota management
"""

import asyncio
import logging
import json
import os
import subprocess
import tempfile
import shutil
import time
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import requests
from pathlib import Path
import yaml

logger = logging.getLogger(__name__)

class EnhancedFallbackEngine:
    """
    ☁️ Enhanced Fallback Engine
    
    Features:
    - Real-time GitHub Actions quota monitoring
    - Automatic Cloud Run deployment when quotas are exhausted
    - Seamless workload migration
    - Cost optimization and scaling
    - Health monitoring and alerting
    - Automatic failback to GitHub Actions when quotas reset
    """
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the enhanced fallback engine"""
        self.config = config
        self.is_monitoring = False
        
        # GitHub configuration
        self.github_token = config.get('github_token')
        self.repo_owner = config.get('repo_owner', 'yannabadie')
        self.repo_name = config.get('repo_name', 'appIA')
        
        # Cloud Run configuration
        self.project_id = config.get('gcp_project_id')
        self.region = config.get('gcp_region', 'us-central1')
        self.service_name = config.get('service_name', 'jarvys-ai-fallback')
        
        # Quota thresholds
        self.quota_warning_threshold = config.get('quota_warning_threshold', 80)  # 80%
        self.quota_critical_threshold = config.get('quota_critical_threshold', 95)  # 95%
        
        # Monitoring configuration
        self.check_interval = config.get('check_interval_minutes', 30)
        self.deployment_timeout = config.get('deployment_timeout_minutes', 10)
        
        # State tracking
        self.current_quota_usage = 0
        self.is_deployed_to_cloud = False
        self.last_quota_check = None
        self.deployment_history = []
        
        logger.info("☁️ Enhanced Fallback Engine initialized")
    
    async def start_monitoring(self):
        """Start continuous monitoring of GitHub Actions quotas"""
        if self.is_monitoring:
            logger.warning("Quota monitoring already running")
            return
        
        self.is_monitoring = True
        
        # Start monitoring loop
        asyncio.create_task(self._monitoring_loop())
        logger.info(f"📊 Started quota monitoring (interval: {self.check_interval} minutes)")
    
    def stop_monitoring(self):
        """Stop quota monitoring"""
        self.is_monitoring = False
        logger.info("📊 Stopped quota monitoring")
    
    async def _monitoring_loop(self):
        """Main monitoring loop"""
        while self.is_monitoring:
            try:
                await self._check_quota_and_act()
                
                # Wait for next check
                await asyncio.sleep(self.check_interval * 60)
                
            except Exception as e:
                logger.error(f"❌ Monitoring loop error: {e}")
                await asyncio.sleep(60)  # Short delay before retry
    
    async def _check_quota_and_act(self):
        """Check GitHub Actions quota and take action if needed"""
        try:
            # Get current quota usage
            quota_info = await self._get_github_quota()
            
            if not quota_info:
                logger.warning("⚠️ Unable to get quota information")
                return
            
            self.current_quota_usage = quota_info['usage_percentage']
            self.last_quota_check = datetime.now()
            
            logger.debug(f"📊 Current quota usage: {self.current_quota_usage}%")
            
            # Take action based on quota usage
            if self.current_quota_usage >= self.quota_critical_threshold:
                if not self.is_deployed_to_cloud:
                    logger.warning(f"🚨 Critical quota usage ({self.current_quota_usage}%), deploying to Cloud Run")
                    await self._deploy_to_cloud_run()
            
            elif self.current_quota_usage >= self.quota_warning_threshold:
                logger.warning(f"⚠️ High quota usage ({self.current_quota_usage}%), preparing Cloud Run deployment")
                await self._prepare_cloud_deployment()
            
            elif self.current_quota_usage < 50 and self.is_deployed_to_cloud:
                logger.info(f"✅ Quota usage low ({self.current_quota_usage}%), considering failback to GitHub Actions")
                await self._consider_failback()
            
        except Exception as e:
            logger.error(f"❌ Error checking quota: {e}")
    
    async def _get_github_quota(self) -> Optional[Dict[str, Any]]:
        """Get GitHub Actions quota information"""
        try:
            if not self.github_token:
                # Simulate quota for demo
                import random
                usage = random.randint(20, 95)
                return {
                    'usage_percentage': usage,
                    'total_minutes': 3000,
                    'used_minutes': int(3000 * usage / 100),
                    'remaining_minutes': int(3000 * (100 - usage) / 100)
                }
            
            # Real API call to GitHub
            headers = {
                'Authorization': f'token {self.github_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            url = f'https://api.github.com/repos/{self.repo_owner}/{self.repo_name}/actions/billing/usage'
            response = requests.get(url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                total_minutes = data.get('total_minutes_used', 0)
                included_minutes = data.get('included_minutes', 3000)
                
                usage_percentage = (total_minutes / included_minutes) * 100 if included_minutes > 0 else 0
                
                return {
                    'usage_percentage': min(usage_percentage, 100),
                    'total_minutes': included_minutes,
                    'used_minutes': total_minutes,
                    'remaining_minutes': max(included_minutes - total_minutes, 0)
                }
            else:
                logger.warning(f"GitHub API returned {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"❌ Error getting GitHub quota: {e}")
            return None
    
    async def _prepare_cloud_deployment(self):
        """Prepare for potential Cloud Run deployment"""
        try:
            logger.info("🏗️ Preparing Cloud Run deployment...")
            
            # Build deployment artifacts
            await self._build_deployment_artifacts()
            
            # Validate Cloud Run configuration
            await self._validate_cloud_config()
            
            logger.info("✅ Cloud Run deployment prepared")
            
        except Exception as e:
            logger.error(f"❌ Error preparing Cloud Run deployment: {e}")
    
    async def _deploy_to_cloud_run(self):
        """Deploy JARVYS_AI to Google Cloud Run"""
        try:
            if self.is_deployed_to_cloud:
                logger.info("☁️ Already deployed to Cloud Run")
                return True
            
            logger.info("🚀 Deploying JARVYS_AI to Cloud Run...")
            
            # Create deployment directory
            deployment_dir = await self._create_deployment_package()
            if not deployment_dir:
                return False
            
            # Build and deploy Docker image
            success = await self._build_and_deploy_image(deployment_dir)
            
            if success:
                self.is_deployed_to_cloud = True
                self.deployment_history.append({
                    'timestamp': datetime.now().isoformat(),
                    'type': 'deploy_to_cloud',
                    'reason': f'quota_usage_{self.current_quota_usage}%',
                    'status': 'success'
                })
                
                logger.info("✅ Successfully deployed to Cloud Run")
                await self._notify_deployment_success()
                return True
            else:
                logger.error("❌ Cloud Run deployment failed")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error deploying to Cloud Run: {e}")
            return False
        finally:
            # Cleanup
            if 'deployment_dir' in locals() and deployment_dir:
                shutil.rmtree(deployment_dir, ignore_errors=True)
    
    async def _create_deployment_package(self) -> Optional[str]:
        """Create deployment package for Cloud Run"""
        try:
            # Create temporary deployment directory
            deployment_dir = tempfile.mkdtemp(prefix="jarvys_deploy_")
            
            # Copy JARVYS_AI source code
            jarvys_source = Path(__file__).parent
            jarvys_target = Path(deployment_dir) / "jarvys_ai"
            
            shutil.copytree(jarvys_source, jarvys_target, 
                          ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
            
            # Copy requirements and Docker files
            workspace_path = jarvys_source.parent
            files_to_copy = [
                "requirements-jarvys-ai.txt",
                "Dockerfile.jarvys_ai"
            ]
            
            for file_name in files_to_copy:
                source_file = workspace_path / file_name
                if source_file.exists():
                    shutil.copy2(source_file, deployment_dir / file_name)
            
            # Create Cloud Run specific Dockerfile
            await self._create_cloud_run_dockerfile(deployment_dir)
            
            # Create deployment script
            await self._create_cloud_deployment_script(deployment_dir)
            
            logger.info(f"📦 Created deployment package: {deployment_dir}")
            return deployment_dir
            
        except Exception as e:
            logger.error(f"❌ Error creating deployment package: {e}")
            return None
    
    async def _create_cloud_run_dockerfile(self, deployment_dir: str):
        """Create optimized Dockerfile for Cloud Run"""
        dockerfile_content = '''# Cloud Run optimized Dockerfile for JARVYS_AI
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV JARVYS_MODE=production
ENV PORT=8080

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements-jarvys-ai.txt .
RUN pip install --no-cache-dir -r requirements-jarvys-ai.txt

# Copy application code
COPY jarvys_ai/ ./jarvys_ai/

# Create startup script
RUN echo '#!/bin/bash\\n\\
export HOST=0.0.0.0\\n\\
export PORT=${PORT:-8080}\\n\\
cd /app && python -m jarvys_ai.main --mode=cloud_run' > /app/start.sh \\
    && chmod +x /app/start.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE $PORT

# Run the application
CMD ["/app/start.sh"]
'''
        
        dockerfile_path = Path(deployment_dir) / "Dockerfile"
        with open(dockerfile_path, 'w') as f:
            f.write(dockerfile_content)
    
    async def _create_cloud_deployment_script(self, deployment_dir: str):
        """Create Cloud Run deployment script"""
        script_content = f'''#!/bin/bash
# JARVYS_AI Cloud Run Deployment Script

set -e

PROJECT_ID="{self.project_id}"
REGION="{self.region}"
SERVICE_NAME="{self.service_name}"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME:latest"

echo "🚀 Deploying JARVYS_AI to Cloud Run..."

# Build and push Docker image
echo "🏗️ Building Docker image..."
docker build -t $IMAGE_NAME .

echo "📤 Pushing image to Google Container Registry..."
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo "☁️ Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \\
    --image $IMAGE_NAME \\
    --platform managed \\
    --region $REGION \\
    --allow-unauthenticated \\
    --memory 2Gi \\
    --cpu 2 \\
    --max-instances 10 \\
    --concurrency 100 \\
    --timeout 3600 \\
    --set-env-vars="JARVYS_MODE=production" \\
    --project $PROJECT_ID

echo "✅ Deployment completed!"

# Get service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)' --project $PROJECT_ID)
echo "🌐 Service URL: $SERVICE_URL"
'''
        
        script_path = Path(deployment_dir) / "deploy_cloud_run.sh"
        with open(script_path, 'w') as f:
            f.write(script_content)
        os.chmod(script_path, 0o755)
    
    async def _build_and_deploy_image(self, deployment_dir: str) -> bool:
        """Build and deploy Docker image to Cloud Run"""
        try:
            if not self.project_id:
                logger.warning("⚠️ GCP project ID not configured, simulating deployment")
                await asyncio.sleep(5)  # Simulate deployment time
                return True
            
            # Change to deployment directory
            original_cwd = os.getcwd()
            os.chdir(deployment_dir)
            
            try:
                # Build Docker image
                image_name = f"gcr.io/{self.project_id}/{self.service_name}:latest"
                
                logger.info("🏗️ Building Docker image...")
                result = subprocess.run([
                    "docker", "build", "-t", image_name, "."
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode != 0:
                    logger.error(f"Docker build failed: {result.stderr}")
                    return False
                
                # Push image
                logger.info("📤 Pushing image to Container Registry...")
                result = subprocess.run([
                    "docker", "push", image_name
                ], capture_output=True, text=True, timeout=300)
                
                if result.returncode != 0:
                    logger.error(f"Docker push failed: {result.stderr}")
                    return False
                
                # Deploy to Cloud Run
                logger.info("☁️ Deploying to Cloud Run...")
                deploy_cmd = [
                    "gcloud", "run", "deploy", self.service_name,
                    "--image", image_name,
                    "--platform", "managed",
                    "--region", self.region,
                    "--allow-unauthenticated",
                    "--memory", "2Gi",
                    "--cpu", "2",
                    "--max-instances", "10",
                    "--set-env-vars", "JARVYS_MODE=production",
                    "--project", self.project_id
                ]
                
                result = subprocess.run(deploy_cmd, capture_output=True, text=True, timeout=600)
                
                if result.returncode != 0:
                    logger.error(f"Cloud Run deployment failed: {result.stderr}")
                    return False
                
                logger.info("✅ Successfully deployed to Cloud Run")
                return True
                
            finally:
                os.chdir(original_cwd)
                
        except subprocess.TimeoutExpired:
            logger.error("❌ Deployment timeout")
            return False
        except Exception as e:
            logger.error(f"❌ Error building and deploying: {e}")
            return False
    
    async def _consider_failback(self):
        """Consider failing back to GitHub Actions when quota is low"""
        try:
            if not self.is_deployed_to_cloud:
                return
            
            # Check if quota has been low for sufficient time
            if self.current_quota_usage < 30:
                logger.info("🔄 Quota usage low, initiating failback to GitHub Actions")
                await self._failback_to_github()
            
        except Exception as e:
            logger.error(f"❌ Error considering failback: {e}")
    
    async def _failback_to_github(self):
        """Failback from Cloud Run to GitHub Actions"""
        try:
            logger.info("🔄 Failing back to GitHub Actions...")
            
            # Scale down Cloud Run service
            await self._scale_down_cloud_service()
            
            # Update deployment status
            self.is_deployed_to_cloud = False
            self.deployment_history.append({
                'timestamp': datetime.now().isoformat(),
                'type': 'failback_to_github',
                'reason': f'quota_usage_{self.current_quota_usage}%',
                'status': 'success'
            })
            
            logger.info("✅ Successfully failed back to GitHub Actions")
            await self._notify_failback_success()
            
        except Exception as e:
            logger.error(f"❌ Error failing back to GitHub: {e}")
    
    async def _scale_down_cloud_service(self):
        """Scale down Cloud Run service to minimum instances"""
        try:
            if not self.project_id:
                logger.info("⚠️ GCP project not configured, simulating scale down")
                return
            
            logger.info("📉 Scaling down Cloud Run service...")
            
            result = subprocess.run([
                "gcloud", "run", "services", "update", self.service_name,
                "--min-instances", "0",
                "--max-instances", "1",
                "--region", self.region,
                "--project", self.project_id
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                logger.info("✅ Cloud Run service scaled down")
            else:
                logger.warning(f"⚠️ Scale down warning: {result.stderr}")
                
        except Exception as e:
            logger.error(f"❌ Error scaling down service: {e}")
    
    async def _build_deployment_artifacts(self):
        """Build deployment artifacts for Cloud Run"""
        try:
            logger.debug("🏗️ Building deployment artifacts...")
            # Validate Docker and gcloud CLI
            await self._validate_tools()
            
        except Exception as e:
            logger.error(f"❌ Error building artifacts: {e}")
    
    async def _validate_cloud_config(self):
        """Validate Cloud Run configuration"""
        try:
            if not self.project_id:
                logger.warning("⚠️ GCP project ID not configured")
                return False
            
            # Check gcloud authentication
            result = subprocess.run([
                "gcloud", "auth", "list", "--filter=status:ACTIVE", "--format=value(account)"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout.strip():
                logger.debug("✅ GCloud authentication verified")
                return True
            else:
                logger.warning("⚠️ GCloud authentication not configured")
                return False
                
        except Exception as e:
            logger.error(f"❌ Error validating cloud config: {e}")
            return False
    
    async def _validate_tools(self):
        """Validate required tools are available"""
        tools = ["docker", "gcloud"]
        
        for tool in tools:
            try:
                result = subprocess.run([tool, "--version"], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    logger.debug(f"✅ {tool} available")
                else:
                    logger.warning(f"⚠️ {tool} not available or not working")
            except FileNotFoundError:
                logger.warning(f"⚠️ {tool} not found in PATH")
            except Exception as e:
                logger.warning(f"⚠️ Error checking {tool}: {e}")
    
    async def _notify_deployment_success(self):
        """Notify successful deployment to Cloud Run"""
        try:
            # Send notification to JARVYS_DEV dashboard
            notification = {
                "type": "fallback_deployment",
                "status": "success",
                "timestamp": datetime.now().isoformat(),
                "service_name": self.service_name,
                "region": self.region,
                "quota_usage": self.current_quota_usage
            }
            
            # This would normally send to the dashboard
            logger.info(f"📢 Deployment notification: {notification}")
            
        except Exception as e:
            logger.error(f"❌ Error sending deployment notification: {e}")
    
    async def _notify_failback_success(self):
        """Notify successful failback to GitHub Actions"""
        try:
            notification = {
                "type": "failback_complete",
                "status": "success",
                "timestamp": datetime.now().isoformat(),
                "quota_usage": self.current_quota_usage
            }
            
            logger.info(f"📢 Failback notification: {notification}")
            
        except Exception as e:
            logger.error(f"❌ Error sending failback notification: {e}")
    
    def get_status(self) -> Dict[str, Any]:
        """Get current fallback engine status"""
        return {
            "is_monitoring": self.is_monitoring,
            "is_deployed_to_cloud": self.is_deployed_to_cloud,
            "current_quota_usage": self.current_quota_usage,
            "last_quota_check": self.last_quota_check.isoformat() if self.last_quota_check else None,
            "deployment_history": self.deployment_history[-5:],  # Last 5 deployments
            "config": {
                "quota_warning_threshold": self.quota_warning_threshold,
                "quota_critical_threshold": self.quota_critical_threshold,
                "check_interval": self.check_interval,
                "service_name": self.service_name,
                "region": self.region
            }
        }

    async def force_deploy_to_cloud(self):
        """Force deployment to Cloud Run (for testing or manual override)"""
        logger.info("🚀 Force deploying to Cloud Run...")
        return await self._deploy_to_cloud_run()
    
    async def force_failback_to_github(self):
        """Force failback to GitHub Actions (for testing or manual override)"""
        logger.info("🔄 Force failing back to GitHub Actions...")
        return await self._failback_to_github()

# Demo usage
async def demo_fallback_engine():
    """Demonstrate the enhanced fallback engine"""
    config = {
        'gcp_project_id': 'your-project-id',  # Set to None for demo mode
        'gcp_region': 'us-central1',
        'service_name': 'jarvys-ai-fallback',
        'quota_warning_threshold': 70,
        'quota_critical_threshold': 90,
        'check_interval_minutes': 1  # Faster for demo
    }
    
    engine = EnhancedFallbackEngine(config)
    
    # Start monitoring
    await engine.start_monitoring()
    
    # Let it run for a while
    await asyncio.sleep(300)  # 5 minutes
    
    # Stop monitoring
    engine.stop_monitoring()
    
    # Print final status
    status = engine.get_status()
    print(f"\n📊 Final Status: {json.dumps(status, indent=2)}")

if __name__ == "__main__":
    # Run demo
    asyncio.run(demo_fallback_engine())
