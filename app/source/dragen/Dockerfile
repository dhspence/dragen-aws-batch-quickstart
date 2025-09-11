FROM public.ecr.aws/docker/library/oraclelinux:8

# Enable EPEL and CRB repositories
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && /usr/bin/crb enable

# Install packages including mdadm
RUN dnf update -y \
    && dnf install -y \
        awscli \
        bzip2-libs \
        ca-certificates \
        coreutils \
        curl \
        e2fsprogs \
        gdb \
        ipmitool \
        mdadm \
        perl \
        python3.12 \
        python3.12-pip \
        R \
        rsync \
        smartmontools \
        sos \
        systemd-libs \
        time \
        tree \
        unzip \
        util-linux \
    && dnf clean all

# Add RAID configuration script - retaining for backup
COPY configure-raid.sh /usr/local/bin/configure-raid.sh
RUN chmod +x /usr/local/bin/configure-raid.sh
