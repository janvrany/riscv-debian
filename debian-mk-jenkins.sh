#/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT> <JENKINS_SSH_PUBLIC_KEY_FILE>"
    exit 1
fi

if [ ! -f "$2" ]; then
    echo "usage: $(basename $0) <ROOT> <JENKINS_SSH_PUBLIC_KEY_FILE>"
    exit 1
fi

JENKINS_UID=500
JENKINS_GID=500

ensure_ROOT "$1"

echo "Creating user jenkins..."
sudo chroot "${ROOT}" groupadd --gid "$JENKINS_GID" --system jenkins
sudo chroot "${ROOT}" useradd  --uid "$JENKINS_UID" --gid "$JENKINS_GID" --system --create-home --home-dir /var/lib/jenkins jenkins

echo "Installing public key $2..."
sudo mkdir -p                 "${ROOT}/var/lib/jenkins/.ssh"
sudo cp "$2"                 "${ROOT}/var/lib/jenkins/.ssh/authorized_keys"
sudo chown -R "$JENKINS_UID" "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod -R go-rwx         "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod -R u=rw           "${ROOT}/var/lib/jenkins/.ssh"
sudo chmod    u=rwx          "${ROOT}/var/lib/jenkins/.ssh"

echo "Installing JDK"
sudo chroot "${ROOT}" /usr/bin/apt-get update
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    default-jdk 

sudo chroot "${ROOT}" /usr/bin/apt-get clean




