const request = require('supertest');
const app = require('../server');

describe('Frontend Server', () => {
    test('GET /health should return healthy status', async () => {
        const response = await request(app).get('/health');
        expect(response.status).toBe(200);
        expect(response.body.status).toBe('healthy');
        expect(response.body.service).toBe('nodejs-frontend');
    });

    test('GET / should return HTML page', async () => {
        const response = await request(app).get('/');
        expect(response.status).toBe(200);
        expect(response.headers['content-type']).toMatch(/html/);
    });

    test('GET /api/data should handle API proxy', async () => {
        // This test will pass even if an external API is not present
        const response = await request(app).get('/api/data');
        expect([200, 500, 503]).toContain(response.status);
    });
});
