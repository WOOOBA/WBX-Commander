# WBX Commander

<p align="center">
    <img src="./banner.png" />
</p>

[![License: MIT](https://badgen.now.sh/badge/license/MIT)](https://opensource.org/licenses/MIT)

> An easy to use bash script for managing a Blockpool Node

## Getting Started

**DO NOT RUN WBX COMMANDER AS ROOT**

### Create a user

1. Use the adduser command to add a new user to your system. Be sure to replace username with the user that you want to create.

	`adduser username`

2. Set and confirm the new user's password at the prompt. A strong password is highly recommended!

3. Follow the prompts to set the new user's information. It is fine to accept the defaults to leave all of this information blank.

4. Use the usermod command to add the user to the sudo group.

	`usermod -aG sudo username`
	
	Again replacing username with the name used in step #1

5. Switch to the new user

	`su - username`

### Get WBX Commander

#### Via Git

Clone the repo

`git clone https://github.com/WOOOBA/WBX-Commander.git`

#### Via wget

`wget https://raw.githubusercontent.com/WOOOBA/WBX-Commander/master/WBXcommander.sh -P ~/WBX-Commander`

This will create the folder WBX-Commander in the root of your Home folder with the script inside.

### Launch WBX Commander

```bash
# move to the folder
cd WBX-Commander

# make the script executable
chmod +x WBXcommander.sh

# start WBX Commander
./WBXcommander.sh
```

Follow the on screen directions from here on out.

## Authors
- [Edgar Goetzendorff](https://github.com/dated)
- [Brandon Cook](https://github.com/locohammerhead)
- [All Contributors](../../contributors)

## License
[MIT](LICENSE) © [Blockpool](https://blockpool.io)
