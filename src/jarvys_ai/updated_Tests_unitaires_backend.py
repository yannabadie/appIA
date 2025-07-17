```python
# imports
import unittest
import os
from typing import Optional, Dict, Any
from flask.testing import FlaskClient
from app import create_app
from supabase import create_client, Client
import logging

logger = logging.getLogger(__name__)

class BackendTestCase(unittest.TestCase):
    """Test cases for backend API endpoints with Supabase integration"""

    supabase: Optional[Client] = None
    test_data_ids: Dict[str, list] = {'roles': [], 'users': []}

    @classmethod
    def setUpClass(cls) -> None:
        """Set up class-level resources including Supabase client"""
        supabase_url = os.environ.get('SUPABASE_URL')
        supabase_key = os.environ.get('SUPABASE_KEY')
        
        if not supabase_url or not supabase_key:
            raise ValueError("Missing required environment variables: SUPABASE_URL, SUPABASE_KEY")
        
        try:
            cls.supabase = create_client(supabase_url, supabase_key)
        except Exception as e:
            logger.error(f"Failed to create Supabase client: {e}")
            raise

    def setUp(self) -> None:
        """Set up test variables and initialize the application"""
        self.app = create_app(config_name="testing")
        self.client: FlaskClient = self.app.test_client()
        self.app_context = self.app.app_context()
        self.app_context.push()
        
        # Use environment variables for test data
        self.role = {'name': f'test_admin_{os.getpid()}'}
        self.user_data = {
            'email': f'test_{os.getpid()}@example.com',
            'password': os.environ.get('TEST_PASSWORD', 'test_password_123!')
        }

    def tearDown(self) -> None:
        """Clean up test data after each test"""
        # Clean up roles
        if self.test_data_ids['roles']:
            try:
                self.supabase.table('roles').delete().in_('id', self.test_data_ids['roles']).execute()
            except Exception as e:
                logger.warning(f"Failed to clean up test roles: {e}")
        
        # Clean up users
        if self.test_data_ids['users']:
            try:
                self.supabase.table('users').delete().in_('id', self.test_data_ids['users']).execute()
            except Exception as e:
                logger.warning(f"Failed to clean up test users: {e}")
        
        self.test_data_ids = {'roles': [], 'users': []}
        self.app_context.pop()

    def test_role_creation(self) -> None:
        """Test creating a new role via API and verify in database"""
        # Make API request
        res = self.client.post(
            f"{self.app.config.get('BASE_URL', '')}/roles/",
            json=self.role
        )
        
        # Verify response
        self.assertEqual(res.status_code, 201)
        response_data = res.get_json()
        self.assertIsNotNone(response_data)
        self.assertIn('id', response_data)
        self.assertEqual(response_data.get('name'), self.role['name'])
        
        # Store ID for cleanup
        if 'id' in response_data:
            self.test_data_ids['roles'].append(response_data['id'])
        
        # Verify in database
        result = self.supabase.table('roles').select('*').eq('name', self.role['name']).execute()
        self.assertTrue(result.data, "Role not found in database")
        self.assertEqual(len(result.data), 1)
        self.assertEqual(result.data[0]['name'], self.role['name'])

    def test_user_creation(self) -> None:
        """Test creating a new user via API and verify in database"""
        # Make API request
        res = self.client.post(
            f"{self.app.config.get('BASE_URL', '')}/users/",
            json=self.user_data
        )
        
        # Verify response
        self.assertEqual(res.status_code, 201)
        response_data = res.get_json()
        self.assertIsNotNone(response_data)
        self.assertIn('id', response_data)
        self.assertEqual(response_data.get('email'), self.user_data['email'])
        
        # Store ID for cleanup
        if 'id' in response_data:
            self.test_data_ids['users'].append(response_data['id'])
        
        # Verify in database
        result = self.supabase.table('users').select('*').eq('email', self.user_data['email']).execute()
        self.assertTrue(result.data, "User not found in database")
        self.assertEqual(len(result.data), 1)
        self.assertEqual(result.data[0]['email'], self.user_data['email'])

    def test_duplicate_role_creation(self) -> None:
        """Test that creating duplicate roles is properly handled"""
        # Create first role
        res1 = self.client.post(
            f"{self.app.config.get('BASE_URL', '')}/roles/",
            json=self.role
        )
        self.assertEqual(res1.status_code, 201)
        if res1.get_json() and 'id' in res1.get_json():
            self.test_data_ids['roles'].append(res1.get_json()['id'])
        
        # Attempt to create duplicate
        res2 = self.client.post(
            f"{self.app.config.get('BASE_URL', '')}/roles/",
            json=self.role
        )
        self.assertIn(res2.status_code, [400, 409])  # Bad request or conflict

    def test_invalid_user_creation(self) -> None:
        """Test user creation with invalid data"""
        invalid_user = {'email': 'invalid-email', 'password': '123'}  # Invalid email and weak password
        res = self.client.post(
            f"{self.app.config.get('BASE_URL', '')}/users/",
            json=invalid_user
        )
        self.assertEqual(res.status_code, 400)
        response_data = res.get_json()
        self.assertIn('error', response_data)

# Main execution
if __name__ == "__main__":
    unittest.main()
```