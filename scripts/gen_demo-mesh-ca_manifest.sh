#!/bin/bash

# Root CA Certificate Generator for cert-manager
# This script generates a root CA certificate and creates TLS secret manifests

set -e

# Default configuration
DEFAULT_SUBJECT="/C=CA/ST=Demo/L=Demo/O=Demo Mesh Root CA/OU=Demo/CN=Demo Mesh Root CA"
DEFAULT_DAYS=3650
DEFAULT_FOLDER="clusters/common/pki"
CERT_FILE="ca-cert.pem"
KEY_FILE="ca-key.pem"
SECRET_NAME="demo-mesh-root-ca"
NAMESPACE="cert-manager"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate root CA certificate and create TLS secret manifests for cert-manager.

OPTIONS:
    -h, --help              Show this help message
    -s, --subject SUBJECT   Certificate subject (default: $DEFAULT_SUBJECT)
    -d, --days DAYS         Certificate validity in days (default: $DEFAULT_DAYS)
    -n, --name SECRET_NAME  Secret name (default: $SECRET_NAME)
    -ns, --namespace NS     Namespace (default: $NAMESPACE)
    -f, --folders FOLDERS   Comma-separated list of folders (default: cluster1,cluster2)
    --cert-file FILE        Certificate filename (default: $CERT_FILE)
    --key-file FILE         Private key filename (default: $KEY_FILE)

EXAMPLES:
    # Use defaults (creates manifests in cluster1/ and cluster2/)
    $0

    # Custom folders
    $0 -f "prod,staging,dev"

    # Custom subject and validity
    $0 -s "/C=CA/ST=Ontario/L=Toronto/O=MyOrg/CN=MyOrg Root CA" -d 1825

    # Custom secret name and namespace
    $0 -n "my-ca-secret" -ns "my-namespace"
EOF
}

# Function to encode file content for YAML
encode_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        print_error "File $file not found"
        return 1
    fi
    # Use -i flag for input file to be compatible with macOS base64
    base64 -i "$file" 2>/dev/null | tr -d '\n' || return 1
}

# Function to create TLS secret manifest
create_manifest() {
    local folder="$1"
    local manifest_file="$folder/demo-mesh-ca.yaml"
    
    print_info "Creating manifest in $folder/"
    
    # Create folder if it doesn't exist
    mkdir -p "$folder"
    
    # Encode certificate and key
    local cert_b64=$(encode_file "$CERT_FILE")
    local key_b64=$(encode_file "$KEY_FILE")
    
    if [[ -z "$cert_b64" || -z "$key_b64" ]]; then
        print_error "Failed to encode certificate files"
        return 1
    fi
    
    # Create the manifest
    cat > "$manifest_file" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: kubernetes.io/tls
data:
  tls.crt: $cert_b64
  tls.key: $key_b64
---
# Example CA Issuer using this secret
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: demo-ca-issuer
spec:
  ca:
    secretName: $SECRET_NAME
EOF
    
    print_success "Created manifest: $manifest_file"
}

# Function to generate root CA certificate
generate_ca_cert() {
    print_info "Generating root CA certificate..."
    print_info "Subject: $SUBJECT"
    print_info "Validity: $DAYS days"
    
    # Generate the certificate and key
    openssl req -x509 -new -nodes \
        -keyout "$KEY_FILE" \
        -sha256 \
        -days "$DAYS" \
        -out "$CERT_FILE" \
        -subj "$SUBJECT"
    
    print_success "Generated certificate files:"
    print_success "  - Certificate: $CERT_FILE"
    print_success "  - Private Key: $KEY_FILE"
    
    # Show certificate details
    print_info "Certificate details:"
    openssl x509 -in "$CERT_FILE" -text -noout | grep -E "(Subject:|Not Before|Not After|Serial Number)"
}

# Parse command line arguments
FOLDERS_STR=""
SUBJECT="$DEFAULT_SUBJECT"
DAYS="$DEFAULT_DAYS"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--subject)
            SUBJECT="$2"
            shift 2
            ;;
        -d|--days)
            DAYS="$2"
            shift 2
            ;;
        -n|--name)
            SECRET_NAME="$2"
            shift 2
            ;;
        -ns|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -f|--folders)
            FOLDERS_STR="$2"
            shift 2
            ;;
        --cert-file)
            CERT_FILE="$2"
            shift 2
            ;;
        --key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Parse folders
if [[ -n "$FOLDERS_STR" ]]; then
    IFS=',' read -ra FOLDERS <<< "$FOLDERS_STR"
else
    FOLDERS=("$DEFAULT_FOLDER")
fi

# Validate inputs
if [[ ! "$DAYS" =~ ^[0-9]+$ ]] || [[ "$DAYS" -le 0 ]]; then
    print_error "Days must be a positive integer"
    exit 1
fi

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL is not installed or not in PATH"
    exit 1
fi

# Main execution
print_info "Starting root CA certificate generation..."
print_info "Target folders: ${FOLDERS[*]}"

# Generate the certificate
generate_ca_cert

# Create manifests for each folder
print_info "Creating TLS secret manifests..."
for folder in "${FOLDERS[@]}"; do
    create_manifest "$folder"
done

# Clean up certificate files
print_info "Cleaning up temporary certificate files..."
rm -f "$CERT_FILE" "$KEY_FILE"
print_success "Temporary certificate files removed"

print_success "All done building demo mesh CA! 🎉"