# syntax=docker/dockerfile:1
#
# x86_64 C dev environment: gcc/clang, gdb, objdump, strace, etc.
# Run this image as: docker run --platform=linux/amd64 ...
#
FROM ubuntu:24.04

# set environment variables for tzdata
ARG TZ=America/New_York
ENV TZ=${TZ}

ARG DEBIAN_FRONTEND=noninteractive

# Core tooling for C + debugging + disassembly
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang llvm lldb \
    gdb gdbserver \
    binutils \
    make cmake ninja-build \
    nasm \
    git curl wget \
    pkg-config \
    strace ltrace \
    man-db manpages manpages-dev \
    less vim nano \
    file \
    zip unzip \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# create user and group if they do not already exist
ARG USERNAME=student
ARG USER_UID=1000
ARG USER_GID=1000

RUN set -eux; \
    # --- Handle GID collision (reuse existing group name if GID exists) ---
    if getent group "${USER_GID}" >/dev/null 2>&1; then \
        EXISTING_GROUP="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        echo "GID ${USER_GID} exists as group ${EXISTING_GROUP}; reusing"; \
        GROUP_NAME="${EXISTING_GROUP}"; \
    else \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
        GROUP_NAME="${USERNAME}"; \
    fi; \
    \
    # --- Handle UID collision ---
    if getent passwd "${USER_UID}" >/dev/null 2>&1; then \
        EXISTING_USER="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
        echo "UID ${USER_UID} exists as user ${EXISTING_USER}; will not create UID-matching ${USERNAME}"; \
        # Create ${USERNAME} with a free UID (no --uid), but still put them in the desired group
        if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
            useradd --gid "${USER_GID}" -m "${USERNAME}"; \
        fi; \
    else \
        # UID is free; create exactly as requested
        if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
            useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}"; \
        fi; \
    fi; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends sudo; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    rm -rf /var/lib/apt/lists/*



RUN cat > /home/${USERNAME}/.gdbinit <<'EOF' && \
    chown ${USERNAME}:${GID} /home/${USERNAME}/.gdbinit
set disassembly-flavor att
set print pretty on
# Show next instruction at $pc when stopped
display/i $pc
EOF


# Workspace
WORKDIR /workspace
USER ${USERNAME}

# Default to an interactive shell
CMD ["bash", "-il"]

