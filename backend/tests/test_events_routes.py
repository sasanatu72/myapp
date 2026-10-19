import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.mark.parametrize('path', ['/events', '/events/'])
@pytest.mark.parametrize('method', ['GET', 'POST'])
def test_event_collection_does_not_redirect_before_authentication(path, method):
    with TestClient(app) as client:
        response = client.request(method, path, follow_redirects=False)
    assert response.status_code == 401
    assert 'location' not in response.headers
