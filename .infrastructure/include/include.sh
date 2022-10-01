GREEN="\033[0;32m"
NO_COLOR="\033[0m"

export MSYS_NO_PATHCONV=1

gcloud() { 
  gcloudVersion=403.0.0-slim
  
  docker run \
  -i \
  --rm \
  --workdir="/codebase" \
  --mount type=bind,source="$(pwd)",target=/codebase \
  --mount type=volume,src=gcloud-config,dst=/home/cloudsdk \
  --user cloudsdk \
  gcr.io/google.com/cloudsdktool/google-cloud-cli:${gcloudVersion} \
  gcloud "$@"
}
