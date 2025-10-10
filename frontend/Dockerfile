# Frontend multi-stage Dockerfile
FROM node:18-alpine AS build
WORKDIR /usr/src/app
COPY package.json package-lock.json* ./
RUN npm install --production=false
COPY . .
RUN npm run build 2>/dev/null || true

FROM node:18-alpine AS runtime
WORKDIR /usr/src/app
COPY --from=build /usr/src/app .
ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "server.js"]
