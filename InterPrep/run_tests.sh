#!/bin/bash
cd "$(dirname "$0")"

RECORD_MODE=""
if [[ "${1:-}" == "record" || "${1:-}" == "--record" || "${1:-}" == "-r" ]]; then
  RECORD_MODE="record"
  export SNAPSHOT_RECORDING_MODE=record
  echo "Режим записи снепшотов: включён (SNAPSHOT_RECORDING_MODE=record)"
  shift
fi

xcodebuild test \
  -workspace InterPrep.xcworkspace \
  -scheme InterPrep-Workspace \
  -destination 'platform=iOS Simulator,id=DA47FF14-264B-4126-B7BE-37DA60EC32B5' \
  -only-testing:AuthFeatureTests \
  -only-testing:OnboardingFeatureTests \
  -only-testing:DiscoveryModuleTests \
  -only-testing:ResumeUploadFeatureTests \
  -only-testing:ChatFeatureTests \
  -only-testing:InterPrepTests \
  "$@"
