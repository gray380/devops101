#!/bin/bash

# ==============================================================================
# Kubectl Plugin: Metrics Exporter
# ==============================================================================
# Description:
#   This plugin fetches pod or node metrics and outputs them in a CSV-like format:
#   "Resource, Namespace, Name, CPU, Memory"
#
# Usage:
#   ./kubeplugin.sh [pod|node] [-n namespace]
#
# Arguments:
#   pod           : Fetch metrics for pods (default)
#   node          : Fetch metrics for nodes
#   -n namespace  : Specify the namespace (only applicable for pods)
#
# Installation as kubectl plugin:
#   1. Rename this script to something starting with kubectl-, e.g., kubectl-my_metrics
#      mv kubeplugin.sh kubectl-my_metrics
#   2. Make it executable:
#      chmod +x kubectl-my_metrics
#   3. Move it to a directory in your PATH:
#      sudo mv kubectl-my_metrics /usr/local/bin/
#   4. Run it via kubectl:
#      kubectl my-metrics [pod|node] [-n namespace]
# ==============================================================================

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <pod|node> <namespace>"
    echo ""
    echo "Examples:"
    echo "  $0 pod kube-system   # Get pod metrics from kube-system namespace"
    echo "  $0 node my-node      # Get node metrics (namespace argument is ignored for nodes but required by script format)"
    exit 1
}

# Check argument count
if [[ $# -lt 2 ]]; then
    usage
fi

# Parse arguments
RESOURCE_TYPE="$1"
NAMESPACE="$2"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in your PATH."
    exit 1
fi

# Header for the CSV output
echo "Resource, Namespace, Name, CPU, Memory"

if [[ "$RESOURCE_TYPE" == "node" ]]; then
    # Note: Nodes are cluster-scoped, so namespace is technically irrelevant, but we accept it as per requirements.
    kubectl top node --no-headers 2>/dev/null | awk '{print "Node, <Cluster>, " $1 ", " $2 ", " $4}' || echo "Error fetching node metrics. Ensure metrics-server is running."

elif [[ "$RESOURCE_TYPE" == "pod" ]]; then
    kubectl top pod -n "$NAMESPACE" --no-headers 2>/dev/null | awk -v ns="$NAMESPACE" '{print "Pod, " ns ", " $1 ", " $2 ", " $3}' || echo "Error fetching pod metrics for namespace $NAMESPACE."

else
    echo "Error: Invalid resource type '$RESOURCE_TYPE'. Must be 'pod' or 'node'."
    usage
fi