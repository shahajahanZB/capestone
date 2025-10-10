"""
Tests for FastAPI backend
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "timestamp" in data

def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_get_data():
    """Test data endpoint"""
    response = client.get("/api/data")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert data["total"] == 3

def test_create_data():
    """Test create data endpoint"""
    test_item = {"name": "Test Item", "value": 999}
    response = client.post("/api/data", json=test_item)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Item created successfully"

def test_status():
    """Test status endpoint"""
    response = client.get("/api/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "operational"
