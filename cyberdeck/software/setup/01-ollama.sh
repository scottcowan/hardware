#!/bin/bash
# Install Ollama and pull base models for Jetson Orin Nano 8GB

set -e

echo "==> Installing Ollama"
curl -fsSL https://ollama.com/install.sh | sh

echo "==> Enabling Ollama service"
sudo systemctl enable ollama
sudo systemctl start ollama

# Wait for daemon to be ready
sleep 3

echo "==> Pulling models"
ollama pull llama3.2:3b-instruct-q4_K_M   # fast, fits comfortably in 8GB shared RAM
ollama pull nomic-embed-text               # embeddings, useful for local RAG

echo "==> Ollama ready. Test with: ollama run llama3.2:3b-instruct-q4_K_M"
