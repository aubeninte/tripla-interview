import pytest
import json
from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_generate_bucket_config_success(client):
    """Verifies successful generation and file response."""
    valid_payload = {
        "payload": {
            "properties": {
                "aws-region": "us-east-1",
                "bucket-name": "production-data-storage",
                "acl": "private"
            }
        }
    }
    
    response = client.post(
        '/generate-bucket-config',
        data=json.dumps(valid_payload),
        content_type='application/json'
    )
    
    assert response.status_code == 200
    assert response.headers["Content-Disposition"] == "attachment; filename=production-data-storage.tf"
    assert response.mimetype == "application/octet-stream"
    
    # Check that template contents rendered correctly
    content = response.data.decode('utf-8')
    assert 'region = "us-east-1"' in content
    assert 'bucket = "production-data-storage"' in content
    assert 'aws_s3_bucket_public_access_block' in content

def test_generate_bucket_config_missing_field(client):
    """Verifies that the Pydantic validation handles missing data correctly."""
    invalid_payload = {
        "payload": {
            "properties": {
                "aws-region": "us-west-2",
                "acl": "public-read"
                # Missing bucket-name
            }
        }
    }
    
    response = client.post(
        '/generate-bucket-config',
        data=json.dumps(invalid_payload),
        content_type='application/json'
    )
    
    assert response.status_code == 400
    json_data = response.get_json()
    assert json_data["error"] == "Validation failed"
    assert len(json_data["details"]) > 0