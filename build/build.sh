#!/usr/bin/env bash
set -euo pipefail

device=${1:-"cpu"}

echo "Sourcing config.sh"
source config.sh

cd "${project_dir}"

# Tune these for your machine
BAZEL_JOBS="${BAZEL_JOBS:-2}"
BAZEL_RAM_MB="${BAZEL_RAM_MB:-8192}"

COMMON_BAZEL_FLAGS=(
  "--jobs=${BAZEL_JOBS}"
  "--local_ram_resources=${BAZEL_RAM_MB}"
  "--verbose_failures"
)

echo "Configuring build..."
if [ "$#" -ne 1 ]; then
    echo "Building without CUDA support"
    printf '\n\n\n\n\n\n' | ./configure
elif [ "$1" = "cuda" ]; then
    echo "Building with CUDA support"
    printf '\n\n\ny\n\n\n\n\n\n\n' | ./configure
elif [ "$1" = "tpu" ]; then
    echo "Building with CUDA and tpu support"
    printf '\n\n\ny\n\n7.0\n\n\n\n\n' | ./configure
fi

if [ "${device}" = "cpu" ]; then
    bazel --output_user_root="${output_user_cpu}" \
      build "${COMMON_BAZEL_FLAGS[@]}" \
      //tensorflow/tools/pip_package:build_pip_package

    ./bazel-bin/tensorflow/tools/pip_package/build_pip_package \
      --dst "${build_output_cpu}"

elif [ "${device}" = "tpu" ]; then
    bazel --output_user_root="${output_user_root_tpu}" \
      build "${COMMON_BAZEL_FLAGS[@]}" \
      --config=tpu \
      //tensorflow/tools/pip_package:build_pip_package

    ./bazel-bin/tensorflow/tools/pip_package/build_pip_package \
      --dst "${build_output_tpu}"

elif [ "${device}" = "cuda" ]; then
    bazel --output_user_root="${output_user_root_cuda}" \
      build "${COMMON_BAZEL_FLAGS[@]}" \
      --host_linkopt=-lm \
      //tensorflow/tools/pip_package:build_pip_package

    ./bazel-bin/tensorflow/tools/pip_package/build_pip_package \
      --dst "${build_output_cuda}"
fi