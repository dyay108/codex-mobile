FROM node:22-alpine AS build

RUN apk add --no-cache g++ make python3 \
  && corepack enable \
  && corepack prepare pnpm@10.15.1 --activate

WORKDIR /app

COPY package.json .npmrc ./
COPY scripts/fix-pty-native-build.cjs scripts/fix-pty-native-build.cjs
RUN pnpm install

COPY . .
RUN pnpm run build \
  && pnpm prune --prod

FROM node:22-alpine AS runtime

RUN apk add --no-cache \
    bash \
    build-base \
    curl \
    fd \
    git \
    git-lfs \
    github-cli \
    jq \
    less \
    openssh-client \
    patch \
    py3-pip \
    python3 \
    ripgrep \
    rsync \
    unzip \
  && corepack enable \
  && npm install --global @openai/codex \
  && npm cache clean --force

ENV NODE_ENV=production \
  CODEX_HOME=/home/node/.codex \
  CODEXAPP_PORT=18923

WORKDIR /app

RUN mkdir -p /home/node/.codex /workspace \
  && chown -R node:node /home/node/.codex /workspace

COPY --from=build --chown=node:node /app/dist ./dist
COPY --from=build --chown=node:node /app/dist-cli ./dist-cli
COPY --from=build --chown=node:node /app/package.json ./package.json
COPY --from=build --chown=node:node /app/node_modules ./node_modules

USER node

EXPOSE 18923

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --quiet --output-document=- http://localhost:18923/ >/dev/null || exit 1

CMD ["node", "dist-cli/index.js"]
