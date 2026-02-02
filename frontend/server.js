const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const API_BASE_URL = process.env.API_BASE_URL || '/';

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'nodejs-frontend',
        uptime: process.uptime()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API proxy endpoints
app.get('/api/data', async (req, res) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/api/data`);
        res.json(response.data);
    } catch (error) {
        console.error('API Error:', error.message);
        res.status(500).json({ 
            error: 'Failed to fetch data from API',
            message: error.message 
        });
    }
});

app.post('/api/data', async (req, res) => {
    try {
        const response = await axios.post(`${API_BASE_URL}/api/data`, req.body);
        res.json(response.data);
    } catch (error) {
        console.error('API Error:', error.message);
        res.status(500).json({ 
            error: 'Failed to create data in API',
            message: error.message 
        });
    }
});

// API health-check proxy (for convenience) — proxies to configured API if available
app.get('/api/health-proxy', async (req, res) => {
    try {
        const response = await axios.get(`${API_BASE_URL}/health`);
        res.json(response.data);
    } catch (error) {
        res.status(503).json({ 
            status: 'api-unavailable',
            message: error.message 
        });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        error: 'Something went wrong!',
        message: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Not found',
        path: req.path 
    });
});

// Start server
if (require.main === module) {
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Frontend server running on port ${PORT}`);
        console.log(`API Base URL: ${API_BASE_URL}`);
        console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
}

module.exports = app;
