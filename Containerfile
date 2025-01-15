# Use Fedora 41 image
FROM fedora:41

# Install lorax
RUN dnf install -y lorax && dnf clean all

# Set the working directory to /var/run
WORKDIR /root

# Set the default command to run bash as root
CMD ["bash"]