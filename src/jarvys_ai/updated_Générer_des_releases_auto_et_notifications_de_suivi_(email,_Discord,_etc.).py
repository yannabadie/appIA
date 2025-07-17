import os
import sys
import time
import asyncio
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import traceback

from github import Github
from github.GithubException import GithubException
from discord_webhook import DiscordWebhook, DiscordEmbed
from supabase import create_client, Client
from tenacity import retry, stop_after_attempt, wait_exponential

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ReleaseAutomation:
    def __init__(self):
        self.supabase_client: Optional[Client] = None
        self.github_client: Optional[Github] = None
        self.repo = None
        self.discord_webhook_url: Optional[str] = None
        self.processed_releases: set = set()
        self._initialize_clients()
    
    def _initialize_clients(self) -> None:
        """Initialize all external service clients with proper error handling."""
        # Validate required environment variables
        required_vars = {
            'SUPABASE_URL': os.getenv('SUPABASE_URL'),
            'SUPABASE_SERVICE_ROLE_KEY': os.getenv('SUPABASE_SERVICE_ROLE_KEY'),
            'GITHUB_TOKEN': os.getenv('GITHUB_TOKEN'),
            'DISCORD_WEBHOOK_URL': os.getenv('DISCORD_WEBHOOK_URL')
        }
        
        missing_vars = [k for k, v in required_vars.items() if not v]
        if missing_vars:
            logger.critical(f"Missing required environment variables: {missing_vars}")
            sys.exit(1)
        
        try:
            # Initialize Supabase
            self.supabase_client = create_client(
                required_vars['SUPABASE_URL'],
                required_vars['SUPABASE_SERVICE_ROLE_KEY']
            )
            
            # Initialize GitHub
            self.github_client = Github(required_vars['GITHUB_TOKEN'])
            repo_name = os.getenv('GITHUB_REPO', 'yannabadie/appia-dev')
            self.repo = self.github_client.get_repo(repo_name)
            
            # Store Discord webhook URL
            self.discord_webhook_url = required_vars['DISCORD_WEBHOOK_URL']
            
            logger.info("All clients initialized successfully")
            
        except Exception as e:
            logger.critical(f"Failed to initialize clients: {str(e)}")
            sys.exit(1)
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
    def create_release(self, tag_name: str, name: str, body: Optional[str] = None) -> Optional[Any]:
        """Create a new release on GitHub with retry logic."""
        try:
            # Check if release already exists
            existing_releases = self.repo.get_releases()
            for release in existing_releases:
                if release.tag_name == tag_name:
                    logger.warning(f"Release {tag_name} already exists, skipping")
                    return None
            
            release = self.repo.create_git_release(
                tag=tag_name,
                name=name,
                message=body or '',
                draft=False,
                prerelease=False
            )
            logger.info(f"Successfully created release: {tag_name}")
            return release
            
        except GithubException as e:
            logger.error(f"GitHub API error creating release {tag_name}: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error creating release {tag_name}: {str(e)}")
            raise
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
    def send_discord_notification(self, release: Any) -> None:
        """Send a notification to Discord when a new release is created."""
        try:
            webhook = DiscordWebhook(url=self.discord_webhook_url)
            
            # Create embed for better formatting
            embed = DiscordEmbed(
                title=f"🚀 New Release: {release.name}",
                description=release.body[:2000] if release.body else "No description provided",
                color='03b2f8',
                url=release.html_url
            )
            
            embed.set_timestamp()
            embed.add_embed_field(name="Tag", value=release.tag_name, inline=True)
            embed.add_embed_field(name="Author", value=release.author.login, inline=True)
            
            webhook.add_embed(embed)
            response = webhook.execute()
            
            if response.status_code == 200:
                logger.info(f"Discord notification sent for release: {release.tag_name}")
            else:
                logger.error(f"Discord webhook returned status: {response.status_code}")
                
        except Exception as e:
            logger.error(f"Error sending Discord notification: {str(e)}")
            raise
    
    def get_pending_releases(self) -> List[Dict[str, Any]]:
        """Fetch pending releases from Supabase."""
        try:
            # Assuming the RPC function returns a list of dicts
            response = self.supabase_client.rpc('get_pending_releases').execute()
            
            if response.data:
                return response.data
            return []
            
        except Exception as e:
            logger.error(f"Error fetching updates from Supabase: {str(e)}")
            return []
    
    def mark_release_processed(self, release_id: str) -> None:
        """Mark a release as processed in Supabase."""
        try:
            self.supabase_client.table('releases').update({
                'processed': True,
                'processed_at': datetime.utcnow().isoformat()
            }).eq('id', release_id).execute()
            
        except Exception as e:
            logger.error(f"Error marking release as processed: {str(e)}")
    
    async def check_and_create_releases(self) -> None:
        """Check for pending releases and process them."""
        try:
            pending_releases = self.get_pending_releases()
            
            if not pending_releases:
                logger.debug("No pending releases found")
                return
            
            logger.info(f"Found {len(pending_releases)} pending releases")
            
            for release_data in pending_releases:
                try:
                    # Extract release information
                    release_id = release_data.get('id')
                    tag_name = release_data.get('tag')
                    name = release_data.get('name')
                    body = release_data.get('description')
                    
                    # Validate required fields
                    if not all([release_id, tag_name, name]):
                        logger.warning(f"Skipping invalid release data: {release_data}")
                        continue
                    
                    # Skip if already processed
                    if release_id in self.processed_releases:
                        continue
                    
                    # Create GitHub release
                    github_release = self.create_release(tag_name, name, body)
                    
                    if github_release:
                        # Send Discord notification
                        self.send_discord_notification(github_release)
                        
                        # Mark as processed
                        self.mark_release_processed(release_id)
                        self.processed_releases.add(release_id)
                        
                        # Add delay to avoid rate limiting
                        await asyncio.sleep(2)
                        
                except Exception as e:
                    logger.error(f"Error processing release {release_data}: {str(e)}")
                    continue
                    
        except Exception as e:
            logger.error(f"Error in check_and_create_releases: {str(e)}")
    
    async def run(self) -> None:
        """Main execution loop with graceful shutdown."""
        logger.info("Starting release automation service")
        
        while True:
            try:
                await self.check_and_create_releases()
                
                # Dynamic sleep interval based on activity
                sleep_interval = 3600  # Default 1 hour
                if len(self.processed_releases) > 10:
                    sleep_interval = 1800  # 30 minutes if busy
                    
                logger.debug(f"Sleeping for {sleep_interval} seconds")
                await asyncio.sleep(sleep_interval)
                
            except KeyboardInterrupt:
                logger.info("Received shutdown signal")
                break
            except Exception as e:
                logger.error(f"Unexpected error in main loop: {str(e)}")
                await asyncio.sleep(60)  # Wait 1 minute before retrying

def main():
    """Entry point for the application."""
    automation = ReleaseAutomation()
    
    try:
        asyncio.run(automation.run())
    except KeyboardInterrupt:
        logger.info("Application shutdown complete")
    except Exception as e:
        logger.critical(f"Fatal error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()