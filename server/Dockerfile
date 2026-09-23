FROM node:22-bookworm-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --chown=node:node package.json *.mjs ./
USER node
EXPOSE 8080
CMD ["node", "server.mjs"]
