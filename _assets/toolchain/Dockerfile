# Uses monkeyx/retro_builder:arm64 as base image
FROM monkeyx/retro_builder:arm64

# Install QEMU for cross-platform emulation
RUN apt-get update && apt-get install -y \
    qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

VOLUME /root/workspace
WORKDIR /root/workspace

# Starting the container with Bash
CMD ["/bin/bash"]
