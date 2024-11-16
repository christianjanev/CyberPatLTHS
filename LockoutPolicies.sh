#!/bin/sh

if [ ! -d "./backups" ]; then
    mkdir ./backups
fi

cp /etc/pam.d/common-auth ./backups/common-auth

echo "Removing nullok from /etc/pam.d/common-auth"
sudo sed -i 's/nullok//g' /etc/pam.d/common-auth

echo "Creating lockout policy"
sudo touch /usr/share/pam-configs/faillock

cat <<EOF | sudo tee /usr/share/pam-configs/faillock > /dev/null
Name: Enforce failed login attempt counter
Default: yes
Priority: 0
Auth-Type: Primary
Auth: [default=die]   pam_faillock.so authfail
Auth: sufficient      pam_faillock.so authsucc
EOF

echo "Created /usr/share/pam-configs/faillock"
sudo touch /usr/share/pam-configs/faillock_notify

cat <<EOF | sudo tee /usr/share/pam-configs/faillock_notify > /dev/null
Name: Notify on failed login attempts
Default: yes
Priority: 1024
Auth-Type: Primary
Auth: requisite   pam_faillock.so preauth
EOF

echo "Created /usr/share/pam-configs/faillock_notify"

sudo chmod 644 /usr/share/pam-configs/faillock
sudo chmod 644 /usr/share/pam-configs/faillock_notify

echo "Updating PAM configuration"

sudo debconf-set-selections <<EOF
pam-auth-update shared/pam-configs/faillock boolean true
pam-auth-update shared/pam-configs/faillock_notify boolean true
EOF

sudo pam-auth-update --package --force
