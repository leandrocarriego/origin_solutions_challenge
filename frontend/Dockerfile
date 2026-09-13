# syntax=docker/dockerfile:1

# --- build ------------------------------------------------------------------------------------
FROM node:22-alpine AS builder

WORKDIR /app

# npm ci needs both files and reinstalls only when the lockfile moves.
COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src

RUN npm run build

# --- runtime: static files behind nginx, nothing else ------------------------------------------
FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/ || exit 1
