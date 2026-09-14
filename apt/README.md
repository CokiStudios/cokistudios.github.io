# Coki Studios APT Repository

Official Debian/Ubuntu APT repository for **Looping**, **Ruuping**, and **Holo Looping OoS**.

## Quick Install (One-Liner)
```bash
curl -fsSL https://cokistudios.github.io/apt/install.sh | sudo bash
```

## Manual Setup
1. Add the repository to your APT sources:
```bash
echo "deb [trusted=yes] https://cokistudios.github.io/apt stable main" | sudo tee /etc/apt/sources.list.d/cokistudios.list
```

2. Update and install:
```bash
sudo apt update
sudo apt install looping
```

## Direct .deb Download
- [looping_2.1.0-1_all.deb](https://cokistudios.github.io/apt/pool/main/l/looping/looping_2.1.0-1_all.deb)
- [looping_2.1.0-1_amd64.deb](https://cokistudios.github.io/apt/pool/main/l/looping/looping_2.1.0-1_amd64.deb)

Install with:
```bash
sudo apt install ./looping_2.1.0-1_all.deb
```
