FROM node:20-alpine

WORKDIR /app

# Install dependencies terlebih dahulu (layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY src/ ./src/

# Non-root user untuk security
RUN addgroup -S kreasea && adduser -S kreasea -G kreasea
USER kreasea

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s \
  CMD wget -qO- http://localhost:3001/api/v1/health || exit 1

CMD ["node", "src/app.js"]
